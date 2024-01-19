using Base: Broadcast
using Base.Broadcast: Broadcasted, BroadcastStyle, AbstractArrayStyle
using Base: broadcasted
const AbstractArrayOrBroadcasted = Union{AbstractArray,Broadcasted}

mutable struct LogicTensor{T, N}
    data
    extrude::NTuple{N, Bool}
end
LogicTensor{T}(data, extrude::NTuple{N, Bool}) where {T, N} = LogicTensor{T, N}(data, extrude)

Base.ndims(::Type{LogicTensor{T, N}}) where {T, N} = N
Base.eltype(::Type{<:LogicTensor{T}}) where {T} = T

function identify(data)
    lhs = alias(gensym())
    subquery(query(lhs, data), lhs)
end

LogicTensor(data::Number) = LogicTensor{typeof(data), 0}(immediate(data), ())
LogicTensor{T}(data::Number) where {T} = LogicTensor{T, 0}(immediate(data), ())
LogicTensor(arr::Base.AbstractArrayOrBroadcasted) = LogicTensor{eltype(arr)}(arr)
function LogicTensor{T}(arr::Base.AbstractArrayOrBroadcasted) where {T}
    name = alias(gensym(:A))
    idxs = [field(gensym(:i)) for _ in 1:ndims(arr)]
    extrude = ntuple(n -> size(arr, n) == 1, ndims(arr))
    tns = subquery(query(name, table(immediate(arr), idxs...)), name)
    LogicTensor{eltype(arr), ndims(arr)}(tns, extrude)
end
LogicTensor(data::LogicTensor) = data

Base.sum(arr::LogicTensor; kwargs...) = reduce(+, arr; kwargs...)
Base.prod(arr::LogicTensor; kwargs...) = reduce(*, arr; kwargs...)
Base.any(arr::LogicTensor; kwargs...) = reduce(or, arr; init = false, kwargs...)
Base.all(arr::LogicTensor; kwargs...) = reduce(and, arr; init = true, kwargs...)
Base.minimum(arr::LogicTensor; kwargs...) = reduce(min, arr; init = Inf, kwargs...)
Base.maximum(arr::LogicTensor; kwargs...) = reduce(max, arr; init = -Inf, kwargs...)

function Base.mapreduce(f, op, src::LogicTensor, args...; kw...)
    reduce(op, map(f, src, args...); kw...)
end

function Base.map(f, src::LogicTensor, args...)
    args = (src, args...)
    idxs = [field(gensym()) for _ in src.extrude]
    ldatas = map(args) do arg
        larg = LogicTensor(arg)
        @assert larg.extrude == src.extrude "Logic only supports matching size and number of dimensions"
        return relabel(larg.data, idxs...)
    end
    T = combine_eltypes(f, args)
    data = mapjoin(immediate(f), ldatas...)
    return LogicTensor{T}(identify(data), src.extrude)
end

function Base.map!(dst, f, src::LogicTensor, args...)
    res = map(f, src, args...)
    return LogicTensor(identify(reformat(dst, res.data)), res.extrude)
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

function Base.reduce(op, arg::LogicTensor{T, N}; dims=:, init = initial_value(op, Float64)) where {T, N}
    dims = dims == Colon() ? (1:N) : collect(dims)
    extrude = ((arg.extrude[n] for n in 1:N if !(n in dims))...,)
    fields = [field(gensym()) for _ in 1:N]
    S = fixpoint_type(op, init, arg)
    data = aggregate(immediate(op), immediate(init), relabel(arg.data, fields), fields[dims]...)
    LogicTensor{S}(identify(data), extrude)
end

struct LogicStyle{N} <: BroadcastStyle end
Base.Broadcast.BroadcastStyle(F::Type{<:LogicTensor{T, N}}) where {T, N} = LogicStyle{N}()
Base.Broadcast.broadcastable(tns::LogicTensor) = tns
Base.Broadcast.BroadcastStyle(a::LogicStyle{M}, b::LogicStyle{N}) where {M, N} = LogicStyle{max(M, N)}()
Base.Broadcast.BroadcastStyle(a::LogicStyle{M}, b::FinchStyle{N}) where {M, N} = LogicStyle{max(M, N)}()
Base.Broadcast.BroadcastStyle(a::LogicStyle{M}, b::Broadcast.AbstractArrayStyle{N}) where {M, N} = LogicStyle{max(M, N)}()

function broadcast_to_logic(bc::Broadcast.Broadcasted)
    broadcasted(bc.f, map(broadcast_to_logic, bc.args)...)
end

function broadcast_to_logic(tns::LogicTensor)
    tns
end

function broadcast_to_logic(tns)
    LogicTensor(tns)
end

function broadcast_to_query(bc::Broadcast.Broadcasted, idxs)
    mapjoin(immediate(bc.f), map(arg -> broadcast_to_query(arg, idxs), bc.args)...)
end

function broadcast_to_query(tns::LogicTensor{T, N}, idxs) where {T, N}
    data_2 = relabel(tns.data, idxs[1:N]...)
    aggregate(immediate(overwrite), nothing, data_2, idxs[findall(tns.extrude)]...)
end

function broadcast_to_extrude(bc::Broadcast.Broadcasted, n)
    any(map(arg -> broadcast_to_extrude(arg, n), bc.args))
end

function broadcast_to_extrude(tns::LogicTensor, n)
    get(tns.extrude, n, false)
end

function Base.materialize!(dest, bc::Broadcasted{<:LogicStyle})
    return copyto!(dest, bc)
end

function Base.materialize(bc::Broadcasted{<:LogicStyle})
    return copy(bc)
end

function Base.copyto!(out, bc::Broadcasted{LogicStyle{N}}) where {N}
    bc_lgc = broadcast_to_logic(bc)
    data = broadcast_to_query(bc_lgc, [field(gensym()) for _ in 1:N])
    extrude = ntuple(n -> broadcast_to_extrude(bc_lgc, n), N)
    return LogicTensor{eltype(bc)}(identify(reformat(out, data)), extrude)
end

function Base.copy(bc::Broadcasted{LogicStyle{N}}) where {N}
    bc_lgc = broadcast_to_logic(bc)
    data = broadcast_to_query(bc_lgc, [field(gensym()) for _ in 1:N])
    extrude = ntuple(n -> broadcast_to_extrude(bc_lgc, n), N)
    return LogicTensor{eltype(bc)}(identify(data), extrude)
end

isolate_aggregates = Rewrite(Postwalk(
    @rule aggregate(~op, ~init, ~arg, ~idxs...) => begin
        name = alias(gensym())
        subquery(query(name, aggregate(~op, ~init, ~arg, ~idxs...)), name)
    end
))

lift_subqueries = Rewrite(Fixpoint(Postwalk(Chain([
    (@rule (~op)(~a1..., subquery(~p, ~b), ~a2...) => if op !== subquery && op !== query
        subquery(p, op(a1, b, a2))
    end),
    Fixpoint(@rule query(~a, subquery(~p, ~b)) => plan(p, query(a, b), produces(a))),
    Fixpoint(@rule plan(~a1..., plan(~b..., produces(~c...)), ~a2...) => plan(a1, b, a2)),
    (@rule plan(~args...) => plan(unique(args))),
]))))

simplify_queries = Rewrite(Fixpoint(Postwalk(Chain([
    (@rule aggregate(~op, ~init, ~arg) => mapjoin(op, init, arg)),
    (@rule mapjoin(overwrite, ~lhs, ~rhs) => rhs),
]))))

propagate_copy_queries = Rewrite(Fixpoint(Postwalk(Chain([
    (@rule plan(~a1..., query(~b, ~c), ~a2..., produces(~d...)) => if c.kind === alias && !(b in d)
        rw = Postwalk(@rule b => c)
        plan(a1..., map(rw, a2)..., produces(d...))
    end),
]))))

compute(arg) = compute((arg,))
#compute(arg) = compute((arg,))[1]
function compute(args::NTuple)
    args = collect(args)
    vars = map(arg -> alias(gensym()), args)
    bodies = map((arg, var) -> query(var, arg.data), args, vars)
    prgm = plan(bodies, produces(vars))
    display(prgm)
    prgm = isolate_aggregates(prgm)
    prgm = lift_subqueries(prgm)
    prgm = propagate_copy_queries(prgm)
    prgm = simplify_queries(prgm)
    display(prgm)
end