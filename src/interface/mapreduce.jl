using Base: Broadcast
using Base.Broadcast: Broadcasted, BroadcastStyle, AbstractArrayStyle
using Base.Broadcast: combine_eltypes
using Base: broadcasted
using LinearAlgebra

"""
    reduce_rep(op, tns, dims)

Return a trait object representing the result of reducing a tensor represented
by `tns` on `dims` by `op`.
"""
function reduce_rep end

#TODO we really shouldn't use Drop like this here.
reduce_rep(op, z, tns, dims) =
    reduce_rep_def(op, z, tns, reverse(map(n -> n in dims ? Drop(n) : n, 1:ndims(tns)))...)

function fixpoint_type(op, z, tns)
    S = Union{}
    T = typeof(z)
    while T != S
        S = T
        T = Union{T, combine_eltypes(op, (T, eltype(tns)))}
    end
    T
end

reduce_rep_def(op, z, fbr::HollowData, idxs...) = HollowData(reduce_rep_def(op, z, fbr.lvl, idxs...))
function reduce_rep_def(op, z, lvl::HollowData, idx, idxs...)
    if op(z, default(lvl)) == z
        HollowData(reduce_rep_def(op, z, lvl.lvl, idxs...))
    else
        HollowData(reduce_rep_def(op, z, lvl.lvl, idxs...))
    end
end

reduce_rep_def(op, z, lvl::SparseData, idx::Drop, idxs...) = ExtrudeData(reduce_rep_def(op, z, lvl.lvl, idxs...))
function reduce_rep_def(op, z, lvl::SparseData, idx, idxs...)
    if op(z, default(lvl)) == z
        SparseData(reduce_rep_def(op, z, lvl.lvl, idxs...))
    else
        DenseData(reduce_rep_def(op, z, lvl.lvl, idxs...))
    end
end

reduce_rep_def(op, z, lvl::DenseData, idx::Drop, idxs...) = ExtrudeData(reduce_rep_def(op, z, lvl.lvl, idxs...))
reduce_rep_def(op, z, lvl::DenseData, idx, idxs...) = DenseData(reduce_rep_def(op, z, lvl.lvl, idxs...))

reduce_rep_def(op, z, lvl::ElementData) = ElementData(z, fixpoint_type(op, z, lvl))

reduce_rep_def(op, z, lvl::RepeatData, idx::Drop) = ExtrudeData(reduce_rep_def(op, ElementData(lvl.default, lvl.eltype)))
reduce_rep_def(op, z, lvl::RepeatData, idx) = RepeatData(z, fixpoint_type(op, z))

function Base.reduce(op, src::Tensor; kw...)
    bc = broadcasted(identity, src)
    reduce(op, broadcasted(identity, src); kw...)
end
function Base.mapreduce(f, op, src::Tensor, args::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}...; kw...)
    reduce(op, broadcasted(f, src, args...); kw...)
end
function Base.map(f, src::Tensor, args::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}...)
    f.(src, args...)
end
function Base.map!(dst, f, src::Tensor, args::Union{Tensor, Base.AbstractArrayOrBroadcasted}...)
    copyto!(dst, Base.broadcasted(f, src, args...))
end

Base.:+(
    x::Tensor,
    y::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number},
    z::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}...
) = map(+, x, y, z...)
Base.:+(
    x::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number},
    y::Tensor,
    z::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}...
) = map(+, y, x, z...)
Base.:+(
    x::Tensor,
    y::Tensor,
    z::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}...
) = map(+, x, y, z...)
Base.:*(
    x::Tensor,
    y::Number,
    z::Number...
) = map(*, x, y, z...)
Base.:*(
    x::Number,
    y::Tensor,
    z::Number...
) = map(*, y, x, z...)

Base.:-(x::Tensor) = map(-, x)

Base.:-(x::Tensor, y::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}) = map(-, x, y)
Base.:-(x::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}, y::Tensor) = map(-, x, y)
Base.:-(x::Tensor, y::Tensor) = map(-, x, y)

Base.:/(x::Tensor, y::Number) = map(/, x, y)
Base.:/(x::Number, y::Tensor) = map(\, y, x)

function initial_value(op, T)
    try
        reduce(op, Vector{T}())
    catch
        throw(ArgumentError("Please supply initial value for reduction of $T with $op."))
    end
end

function Base.reduce(op::Function, bc::Broadcasted{FinchStyle{N}}; dims=:, init = initial_value(op, combine_eltypes(bc.f, bc.args))) where {N}
    reduce_helper(Callable{op}(), lift_broadcast(bc), Val(dims), Val(init))
end

@staged function reduce_helper(op, bc, dims, init)
    reduce_helper_code(op, bc, dims, init)
end

function reduce_helper_code(::Type{Callable{op}}, bc::Type{<:Broadcasted{FinchStyle{N}}}, ::Type{Val{dims}}, ::Type{Val{init}}) where {op, dims, init, N}
    contain(LowerJulia()) do ctx
        idxs = [freshen(ctx.code, :idx, n) for n = 1:N]
        rep = collapse_rep(data_rep(bc))
        dst = freshen(ctx.code, :dst)
        if dims == Colon()
            dst_protos = []
            dst_rep = collapse_rep(reduce_rep(op, init, rep, 1:N))
            dst_ctr = :(Scalar{$(default(dst_rep)), $(eltype(dst_rep))}())
            dst_idxs = []
            res_ex = :($dst[])
        else
            dst_rep = collapse_rep(reduce_rep(op, init, rep, dims))
            dst_protos = [n <= maximum(dims) ? laminate : extrude for n = 1:N]
            dst_ctr = fiber_ctr(dst_rep, dst_protos)
            dst_idxs = [n in dims ? 1 : idxs[n] for n in 1:N]
            res_ex = dst
        end
        pw_ex = pointwise_finch_expr(:bc, bc, ctx, idxs)
        exts = Expr(:block, (:($idx = _) for idx in reverse(idxs))...)
        quote
            $dst = $dst_ctr
            @finch begin
                $dst .= $(init)
                $(Expr(:for, exts, quote
                    $dst[$(dst_idxs...)] <<$op>>= $pw_ex
                end))
                return dst
            end
            $res_ex
        end
    end
end

const FiberOrBroadcast = Union{<:Tensor, <:Broadcasted{FinchStyle{N}} where N}

Base.sum(arr::FiberOrBroadcast; kwargs...) = reduce(+, arr; kwargs...)
Base.prod(arr::FiberOrBroadcast; kwargs...) = reduce(*, arr; kwargs...)
Base.any(arr::FiberOrBroadcast; kwargs...) = reduce(or, arr; init = false, kwargs...)
Base.all(arr::FiberOrBroadcast; kwargs...) = reduce(and, arr; init = true, kwargs...)
Base.minimum(arr::FiberOrBroadcast; kwargs...) = reduce(min, arr; init = Inf, kwargs...)
Base.maximum(arr::FiberOrBroadcast; kwargs...) = reduce(max, arr; init = -Inf, kwargs...)

min1max2((a, b), (c, d)) = (min(a, c), max(b, d))
plex(a) = (a, a)
isassociative(::AbstractAlgebra, ::typeof(min1max2)) = true
iscommutative(::AbstractAlgebra, ::typeof(min1max2)) = true
isidempotent(::AbstractAlgebra, ::typeof(min1max2)) = true
isidentity(alg::AbstractAlgebra, ::typeof(min1max2), x::Tuple) = !ismissing(x) && isinf(x[1]) && x[1] > 0 && isinf(x[2]) && x[2] < 0
isannihilator(alg::AbstractAlgebra, ::typeof(min1max2), x::Tuple) = !ismissing(x) && isinf(x[1]) && x[1] < 0 && isinf(x[2]) && x[2] > 0
Base.extrema(arr::FiberOrBroadcast; kwargs...) = mapreduce(plex, min1max2, arr; init = (Inf, -Inf), kwargs...)

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
            ArgumentError("Cannot accurately add Powers with different exponents")
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

function LinearAlgebra.norm(arr::FiberOrBroadcast, p::Real = 2)
    if p == 2
        return root(sum(broadcasted(square, arr)))
    elseif p == 1
        return sum(broadcasted(abs, arr))
    elseif p == Inf
        return maximum(broadcasted(abs, arr))
    elseif p == 0
        return sum(broadcasted(!, broadcasted(iszero, arr)))
    elseif p == -Inf
        return minimum(broadcasted(abs, arr))
    else
        return root(sum(broadcasted(power, broadcasted(norm, arr, p), p)))
    end
end