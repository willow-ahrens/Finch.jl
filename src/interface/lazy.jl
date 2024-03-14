using Base: Broadcast
using Base.Broadcast: Broadcasted, BroadcastStyle, AbstractArrayStyle
using Base: broadcasted
using LinearAlgebra
const AbstractArrayOrBroadcasted = Union{AbstractArray,Broadcasted}

mutable struct LazyTensor{T, N}
    data
    extrude::NTuple{N, Bool}
end
LazyTensor{T}(data, extrude::NTuple{N, Bool}) where {T, N} = LazyTensor{T, N}(data, extrude)

Base.ndims(::Type{LazyTensor{T, N}}) where {T, N} = N
Base.eltype(::Type{<:LazyTensor{T}}) where {T} = T

function identify(data)
    lhs = alias(gensym(:A))
    subquery(query(lhs, data), lhs)
end

LazyTensor(data::Number) = LazyTensor{typeof(data), 0}(immediate(data), ())
LazyTensor{T}(data::Number) where {T} = LazyTensor{T, 0}(immediate(data), ())
LazyTensor(arr::Base.AbstractArrayOrBroadcasted) = LazyTensor{eltype(arr)}(arr)
function LazyTensor{T}(arr::Base.AbstractArrayOrBroadcasted) where {T}
    name = alias(gensym(:A))
    idxs = [field(gensym(:i)) for _ in 1:ndims(arr)]
    extrude = ntuple(n -> size(arr, n) == 1, ndims(arr))
    tns = subquery(query(name, table(immediate(arr), idxs...)), name)
    LazyTensor{eltype(arr), ndims(arr)}(tns, extrude)
end
LazyTensor(arr::Tensor) = LazyTensor{eltype(arr)}(arr)
LazyTensor(swizzle_arr::SwizzleArray{dims, <:Tensor}) where {dims} = permutedims(LazyTensor(swizzle_arr.body), dims)
function LazyTensor{T}(arr::Tensor) where {T}
    name = alias(gensym(:A))
    idxs = [field(gensym(:i)) for _ in 1:ndims(arr)]
    extrude = ntuple(n -> size(arr)[n] == 1, ndims(arr))
    tns = subquery(query(name, table(immediate(arr), idxs...)), name)
    LazyTensor{eltype(arr), ndims(arr)}(tns, extrude)
end
LazyTensor(data::LazyTensor) = data

Base.sum(arr::LazyTensor; kwargs...) = reduce(+, arr; kwargs...)
Base.prod(arr::LazyTensor; kwargs...) = reduce(*, arr; kwargs...)
Base.any(arr::LazyTensor; kwargs...) = reduce(or, arr; init = false, kwargs...)
Base.all(arr::LazyTensor; kwargs...) = reduce(and, arr; init = true, kwargs...)
Base.minimum(arr::LazyTensor; kwargs...) = reduce(min, arr; init = Inf, kwargs...)
Base.maximum(arr::LazyTensor; kwargs...) = reduce(max, arr; init = -Inf, kwargs...)

function Base.mapreduce(f, op, src::LazyTensor, args...; kw...)
    reduce(op, map(f, src, args...); kw...)
end

function Base.map(f, src::LazyTensor, args...)
    largs = map(LazyTensor, (src, args...))
    extrude = largs[something(findfirst(arg -> length(arg.extrude) > 0, largs), 1)].extrude
    idxs = [field(gensym(:i)) for _ in src.extrude]
    ldatas = map(largs) do larg
        if larg.extrude == extrude
            return relabel(larg.data, idxs...)
        elseif larg.extrude == ()
            return relabel(larg.data)
        else
            throw(DimensionMismatch("Cannot map across arrays with different sizes."))
        end
    end
    T = combine_eltypes(f, args)
    data = mapjoin(immediate(f), ldatas...)
    return LazyTensor{T}(identify(data), src.extrude)
end

function Base.map!(dst, f, src::LazyTensor, args...)
    res = map(f, src, args...)
    return LazyTensor(identify(reformat(dst, res.data)), res.extrude)
end

function initial_value(op, T)
    try
        reduce(op, Vector{T}())
    catch
        throw(ArgumentError("Please supply initial value for reduction of $T with $op."))
    end
end

function fixpoint_type(op, z, tns)
    S = Union{}
    T = typeof(z)
    while T != S
        S = T
        T = Union{T, combine_eltypes(op, (T, eltype(tns)))}
    end
    T
end

function Base.reduce(op, arg::LazyTensor{T, N}; dims=:, init = initial_value(op, Float64)) where {T, N}
    dims = dims == Colon() ? (1:N) : collect(dims)
    extrude = ((arg.extrude[n] for n in 1:N if !(n in dims))...,)
    fields = [field(gensym(:i)) for _ in 1:N]
    S = fixpoint_type(op, init, arg)
    data = aggregate(immediate(op), immediate(init), relabel(arg.data, fields), fields[dims]...)
    LazyTensor{S}(identify(data), extrude)
end

# tensordot takes in two tensors `A` and `B` and performs a product and contraction
function tensordot(A::LazyTensor{T1, N1}, B::LazyTensor{T2, N2}, idxs; mult_op=*, add_op=+, init = initial_value(add_op, Float64)) where {T1, T2, N1, N2}
    if idxs isa Number
        idxs = ([i for i in 1:idxs], [i for i in 1:idxs])
    end
    A_idxs = idxs[1]
    B_idxs = idxs[2]
    if length(A_idxs) != length(B_idxs)
        throw(ArgumentError("lists of contraction indices must be the same length for both inputs"))
    end
    if any([i > N1 for i in A_idxs]) || any([i > N2 for i in B_idxs])
        throw(ArgumentError("contraction indices cannot be greater than the number of dimensions"))
    end

    extrude = ((A.extrude[n] for n in 1:N1 if !(n in A_idxs))...,
                (B.extrude[n] for n in 1:N2 if !(n in B_idxs))...,)
    A_fields = [field(gensym(:i)) for _ in 1:N1]
    B_fields = [field(gensym(:i)) for _ in 1:N2]
    reduce_fields = []
    for i in eachindex(A_idxs)
        B_fields[B_idxs[i]] = A_fields[A_idxs[i]]
        push!(reduce_fields, A_fields[A_idxs[i]])
    end
    AB = mapjoin(immediate(mult_op), relabel(A.data, A_fields), relabel(B.data, B_fields))
    AB_reduce = aggregate(immediate(add_op), immediate(init), AB, reduce_fields...)
    S = fixpoint_type(add_op, init, AB_reduce)
    return LazyTensor{S}(identify(AB_reduce), extrude)
end

# einsum represents an expression of the form Out[`out_idxs`] += ∏ F[F_idxs]
# where each entry in args is a (lazy) tensor and a set of indices (F, F_idxs)
function einsum(out_idxs, args...;add_op=+, mult_op=*, init = initial_value(add_op, Float64))
    if any([length(arg) != 2 for arg in args])
        throw(ArgumentError("einsum arguments must be a tuple of length 2 `(T::LazyTensor, Idxs::Tuple{String,...})`"))
    end

    if any([ length(arg[2]) != length(arg[1].extrude) for arg in args])
        throw(ArgumentError("einsum arguments must have an equal number of dimensions and named indices"))
    end
    args = [(arg[1], [string(idx) for idx in arg[2]]) for arg in args]
    # For some reason, union automatically translates single character strings to type `Char`
    s_idxs::Vector{String} = [string(idx) for idx in union(flatten([arg[2] for arg in args])...)]
    s_to_idx = Dict(s_idx => field(gensym(Symbol(s_idx))) for s_idx in s_idxs)
    factors = []
    for arg in args
        push!(factors, relabel(arg[1].data, [s_to_idx[s_idx] for s_idx in arg[2]]...))
    end
    out_fields = [s_to_idx[s_idx] for s_idx in out_idxs]
    reduce_fields = [s_to_idx[s_idx] for s_idx in s_idxs if !(s_idx in out_idxs)]

    extrude = []
    for idx in out_idxs
        is_extruded = true
        for arg in args
            idx_pos = findfirst(isequal(idx), arg[2])
            isnothing(idx_pos) && continue
            is_extruded = is_extruded && arg[1].extrude[idx_pos]
        end
        push!(extrude, is_extruded)
    end
    out_fields_in_input_order = [s_to_idx[s_idx] for s_idx in s_idxs if s_idx in out_idxs]
    t_prod = mapjoin(immediate(mult_op), factors...)
    t_sum = aggregate(immediate(add_op), immediate(init), t_prod, reduce_fields...)
    t_ordered = reorder(relabel(t_sum, out_fields_in_input_order...), out_fields...)
    S = fixpoint_type(add_op, init, t_ordered)
    return LazyTensor{S}(identify(t_ordered), Tuple(extrude))
end


struct LogicStyle{N} <: BroadcastStyle end
Base.Broadcast.BroadcastStyle(F::Type{<:LazyTensor{T, N}}) where {T, N} = LogicStyle{N}()
Base.Broadcast.broadcastable(tns::LazyTensor) = tns
Base.Broadcast.BroadcastStyle(a::LazyStyle{M}, b::LazyStyle{N}) where {M, N} = LazyStyle{max(M, N)}()
Base.Broadcast.BroadcastStyle(a::LazyStyle{M}, b::Broadcast.AbstractArrayStyle{N}) where {M, N} = LazyStyle{max(M, N)}()

function broadcast_to_logic(bc::Broadcast.Broadcasted)
    broadcasted(bc.f, map(broadcast_to_logic, bc.args)...)
end

function broadcast_to_logic(tns::LazyTensor)
    tns
end

function broadcast_to_logic(tns)
    LazyTensor(tns)
end

function broadcast_to_query(bc::Broadcast.Broadcasted, idxs)
    mapjoin(immediate(bc.f), map(arg -> broadcast_to_query(arg, idxs), bc.args)...)
end

function broadcast_to_query(tns::LazyTensor{T, N}, idxs) where {T, N}
    data_2 = relabel(tns.data, idxs[1:N]...)
    reorder(data_2, idxs[findall(!, tns.extrude)]...)
end

function broadcast_to_extrude(bc::Broadcast.Broadcasted, n)
    any(map(arg -> broadcast_to_extrude(arg, n), bc.args))
end

function broadcast_to_extrude(tns::LazyTensor, n)
    get(tns.extrude, n, false)
end

function Base.materialize!(dest, bc::Broadcasted{<:LazyStyle})
    return copyto!(dest, bc)
end

function Base.materialize(bc::Broadcasted{<:LazyStyle})
    return copy(bc)
end

Base.copyto!(out, bc::Broadcasted{LazyStyle{N}}) where {N} = copyto!(out, copy(bc))

function Base.copy(bc::Broadcasted{LazyStyle{N}}) where {N}
    bc_lgc = broadcast_to_logic(bc)
    data = broadcast_to_query(bc_lgc, [field(gensym(:i)) for _ in 1:N])
    extrude = ntuple(n -> broadcast_to_extrude(bc_lgc, n), N)
    return LazyTensor{eltype(bc)}(identify(data), extrude)
end

function Base.copyto!(::LazyTensor, ::Any)
    throw(ArgumentError("cannot materialize into a LazyTensor"))
end

function Base.copyto!(dst::AbstractArray, src::LazyTensor{T, N}) where {T, N}
    return LazyTensor{T, N}(reformat(immediate(dst), src.data), src.extrude)
end

Base.permutedims(arg::LazyTensor{T, 2}) where {T} = permutedims(arg, [2, 1])
function Base.permutedims(arg::LazyTensor{T, N}, perm) where {T, N}
    length(perm) == N || throw(ArgumentError("permutedims given wrong number of dimensions"))
    isperm(perm) || throw(ArgumentError("permutedims given invalid permutation"))
    perm = collect(perm)
    idxs = [field(gensym(:i)) for _ in 1:N]
    return LazyTensor{T, N}(reorder(relabel(arg.data, idxs...), idxs[perm]...), arg.extrude[perm])
end

Base.:+(
    x::LazyTensor,
    y::Union{LazyTensor, Base.AbstractArrayOrBroadcasted, Number},
    z::Union{LazyTensor, Base.AbstractArrayOrBroadcasted, Number}...
) = map(+, x, y, z...)
Base.:+(
    x::Union{LazyTensor, Base.AbstractArrayOrBroadcasted, Number},
    y::LazyTensor,
    z::Union{LazyTensor, Base.AbstractArrayOrBroadcasted, Number}...
) = map(+, y, x, z...)
Base.:+(
    x::LazyTensor,
    y::LazyTensor,
    z::Union{LazyTensor, Base.AbstractArrayOrBroadcasted, Number}...
) = map(+, x, y, z...)
Base.:*(
    x::LazyTensor,
    y::Number,
    z::Number...
) = map(*, x, y, z...)
Base.:*(
    x::Number,
    y::LazyTensor,
    z::Number...
) = map(*, y, x, z...)

Base.:-(x::LazyTensor) = map(-, x)

Base.:-(x::LazyTensor, y::Union{LazyTensor, Base.AbstractArrayOrBroadcasted, Number}) = map(-, x, y)
Base.:-(x::Union{LazyTensor, Base.AbstractArrayOrBroadcasted, Number}, y::LazyTensor) = map(-, x, y)
Base.:-(x::LazyTensor, y::LazyTensor) = map(-, x, y)

Base.:/(x::LazyTensor, y::Number) = map(/, x, y)
Base.:/(x::Number, y::LazyTensor) = map(\, y, x)


min1max2((a, b), (c, d)) = (min(a, c), max(b, d))
plex(a) = (a, a)
isassociative(::AbstractAlgebra, ::typeof(min1max2)) = true
iscommutative(::AbstractAlgebra, ::typeof(min1max2)) = true
isidempotent(::AbstractAlgebra, ::typeof(min1max2)) = true
isidentity(alg::AbstractAlgebra, ::typeof(min1max2), x::Tuple) = !ismissing(x) && isinf(x[1]) && x[1] > 0 && isinf(x[2]) && x[2] < 0
isannihilator(alg::AbstractAlgebra, ::typeof(min1max2), x::Tuple) = !ismissing(x) && isinf(x[1]) && x[1] < 0 && isinf(x[2]) && x[2] > 0
Base.extrema(arr::LazyTensor; kwargs...) = mapreduce(plex, min1max2, arr; init = (Inf, -Inf), kwargs...)

struct Square{T, S}
    arg::T
    scale::S
end

@inline square(x) = Square(sign(x)^2, norm(x))

@inline root(x::Square) = sqrt(x.arg) * x.scale

@inline Base.zero(::Type{Square{T, S}}) where {T, S} = Square{T, S}(zero(T), zero(S))
@inline Base.zero(::Square{T, S}) where {T, S} = Square{T, S}(zero(T), zero(S))

function Base.promote_rule(::Type{Square{T1, S1}}, ::Type{Square{T2, S2}}) where {T1, S1, T2, S2}
    return Square{promote_type(T1, T2), promote_type(S1, S2)}
end

function Base.convert(::Type{Square{T, S}}, x::Square) where {T, S}
    return Square(convert(T, x.arg), convert(S, x.scale))
end

function Base.promote_rule(::Type{Square{T1, S1}}, ::Type{T2}) where {T1, S1, T2<:Number}
    return promote_type(T1, T2)
end

function Base.convert(T::Type{<:Number}, x::Square)
    return convert(T, root(x))
end

@inline function Base.:+(x::T, y::T) where {T <: Square}
    if x.scale < y.scale
        (x, y) = (y, x)
    end
    if x.scale > y.scale
        if iszero(y.scale)
            return Square(x.arg + zero(y.arg) * (one(y.scale)/one(x.scale))^1, x.scale)
        else
            return Square(x.arg + y.arg * (y.scale/x.scale)^2, x.scale)
        end
    else
        return Square(x.arg + y.arg * (one(y.scale)/one(x.scale))^1, x.scale)
    end
end

@inline function Base.:*(x::Square, y::Integer)
    return Square(x.arg * y, x.scale)
end

@inline function Base.:*(x::Integer, y::Square)
    return Square(y.arg * x, y.scale)
end

struct Power{T, S, E}
    arg::T
    scale::S
    exponent::E
end

@inline power(x, p) = Power(sign(x)^p, norm(x), p)

@inline root(x::Power) = x.arg ^ inv(x.exponent) * x.scale

@inline Base.zero(::Type{Power{T, S, E}}) where {T, S, E} = Power{T, S, E}(zero(T), zero(S), one(E))
@inline Base.zero(x::Power) = Power(zero(x.arg), zero(x.scale), x.exponent)

function Base.promote_rule(::Type{Power{T1, S1, E1}}, ::Type{Power{T2, S2, E2}}) where {T1, S1, E1, T2, S2, E2}
    return Power{promote_type(T1, T2), promote_type(S1, S2), promote_type(E1, E2)}
end

function Base.convert(::Type{Power{T, S, E}}, x::Power) where {T, S, E}
    return Power(convert(T, x.arg), convert(S, x.scale), convert(E, x.exponent))
end

function Base.promote_rule(::Type{Power{T1, S1, E1}}, ::Type{T2}) where {T1, S1, E1, T2<:Number}
    return promote_type(T1, T2)
end

function Base.convert(T::Type{<:Number}, x::Power)
    return convert(T, root(x))
end

@inline function Base.:+(x::T, y::T) where {T <: Power}
    if x.exponent != y.exponent
        if iszero(x.arg) && iszero(x.scale)
            (x, y) = (y, x)
        end
        if iszero(y.arg) && iszero(y.scale)
            y = Power(y.arg, y.scale, x.exponent)
        else
            throw(ArgumentError("Cannot accurately add Powers with different exponents"))
        end
    end
    #TODO handle negative exponent
    if x.scale < y.scale
        (x, y) = (y, x)
    end
    if x.scale > y.scale
        if iszero(y.scale)
            return Power(x.arg + zero(y.arg) * (one(y.scale)/one(x.scale))^one(y.exponent), x.scale, x.exponent)
        else
            return Power(x.arg + y.arg * (y.scale/x.scale)^y.exponent, x.scale, x.exponent)
        end
    else
        return Power(x.arg + y.arg * (one(y.scale)/one(x.scale))^one(y.exponent), x.scale, x.exponent)
    end
end

@inline function Base.:*(x::Power, y::Integer)
    return Power(x.arg * y, x.scale, x.exponent)
end

@inline function Base.:*(x::Integer, y::Power)
    return Power(y.arg * x, y.scale, y.exponent)
end

function LinearAlgebra.norm(arr::LazyTensor, p::Real = 2)
    if p == 2
        return root(sum(map(square, arr)))
    elseif p == 1
        return sum(map(abs, arr))
    elseif p == Inf
        return maximum(map(abs, arr))
    elseif p == 0
        return sum(map(!, map(iszero, arr)))
    elseif p == -Inf
        return minimum(map(abs, arr))
    else
        return root(sum(map(power, map(norm, arr, p), p)))
    end
end

"""
    fused(f, args...; [optimizer=DefaultOptimizer()])

This function decorator modifies `f` to fuse the contained array
operations and optimize the resulting program. The function must return a single
array or tuple of arrays. The `optimizer` keyword argument specifies the
optimizer to use.
"""
function fused(f, args...; optimizer=DefaultOptimizer())
    compute(f(map(LazyTensor, args...)), optimizer)
end
