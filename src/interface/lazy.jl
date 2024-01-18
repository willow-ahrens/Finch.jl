using Base: Broadcast
using Base.Broadcast: Broadcasted, BroadcastStyle, AbstractArrayStyle
using Base: broadcasted
const AbstractArrayOrBroadcasted = Union{AbstractArray,Broadcasted}

struct LogicTensor{N}
    data
    extrude::NTuple{N, Bool}
end

Base.ndims(::Type{LogicTensor{N}}) where {N} = N

LogicTensor(data::Number) = LogicTensor{0}(immediate(data), ())
LogicTensor(data::Base.AbstractArrayOrBroadcasted) = LogicTensor{ndims(data)}(immediate(data), ntuple(n -> size(data, n) == 1, ndims(data)))
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
    idxs = [field(gensym()) for _ in src.extrude]
    ldatas = map(args) do arg
        larg = LogicTensor(arg)
        @assert larg.extrude == src.extrude "Logic only supports matching size and number of dimensions"
        return relabel(larg.data, idxs...)
    end
    return LogicTensor(mapjoin(immediate(f), ldatas...), src.extrude)
end

function Base.map!(dst, f, src::LogicTensor, args...)
    res = map(f, src, args...)
    return LogicTensor(reformat(dst, res.extrude))
end

function Base.reduce(op, arg::LogicTensor{N}; dims=:, init = initial_value(op, Float64)) where {N} #TODO fix eltype
    dims = dims == Colon() ? (1:N) : dims
    extrude = ((arg.extrude[n] for n in 1:N if !(n in dims))...,)
    fields = [field(gensym()) for _ in 1:N]
    LogicTensor(aggregate(immediate(op), immediate(init), relabel(arg.data, fields), fields[dims]...), extrude)
end

struct LogicStyle{N} <: BroadcastStyle end
Base.Broadcast.BroadcastStyle(F::Type{<:LogicTensor{N}}) where {N} = LogicStyle{N}()
Base.Broadcast.broadcastable(tns::LogicTensor) = tns
Base.Broadcast.BroadcastStyle(a::LogicStyle{M}, b::LogicStyle{N}) where {M, N} = LogicStyle(max(M, N))
Base.Broadcast.BroadcastStyle(a::LogicStyle{M}, b::FinchStyle{N}) where {M, N} = LogicStyle(max(M, N))
Base.Broadcast.BroadcastStyle(a::LogicStyle{M}, b::Broadcast.AbstractArrayStyle{N}) where {M, N} = LogicStyle(max(M, N))

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

function broadcast_to_query(tns::LogicTensor{N}, idxs) where {N}
    data_2 = relabel(tns.data, idxs[1:N]...)
    aggregate(immediate(overwrite), data_2, idxs[findall(!, tns.extrude)]...)
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
    return LogicTensor(reformat(out, data), extrude)
end

function Base.copy(bc::Broadcasted{LogicStyle{N}}) where {N}
    bc_lgc = broadcast_to_logic(bc)
    data = broadcast_to_query(bc_lgc, [field(gensym()) for _ in 1:N])
    extrude = ntuple(n -> broadcast_to_extrude(bc_lgc, n), N)
    return LogicTensor(data, extrude)
end