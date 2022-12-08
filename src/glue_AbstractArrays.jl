@kwdef mutable struct VirtualAbstractArray
    ndims
    name
    ex
end

function getsize(arr::VirtualAbstractArray, ctx::LowerJulia, mode)
    dims = map(i -> Symbol(arr.name, :_mode, i, :_stop), 1:arr.ndims)
    push!(ctx.preamble, quote
        ($(dims...),) = size($(arr.ex))
    end)
    return map(i->Extent(literal(1), value(dims[i], Int)), 1:arr.ndims)
end

getname(arr::VirtualAbstractArray) = arr.name
setname(arr::VirtualAbstractArray, name) = (arr_2 = deepcopy(arr); arr_2.name = name; arr_2)

getsites(arr::VirtualAbstractArray) = 1:arr.ndims

function (ctx::LowerJulia)(arr::VirtualAbstractArray, ::DefaultStyle)
    return arr.ex
end

function virtualize(ex, ::Type{<:AbstractArray{T, N}}, ctx, tag=:tns) where {T, N}
    sym = ctx.freshen(tag)
    push!(ctx.preamble, :($sym = $ex))
    VirtualAbstractArray(N, tag, sym)
end

function initialize!(arr::VirtualAbstractArray, ctx::LowerJulia, mode, idxs...)
    if mode.kind === updater && mode.mode.kind === create
        push!(ctx.preamble, quote
            fill!($(arr.ex), 0) #TODO
        end)
    end
    access(arr, mode, idxs...)
end

IndexNotation.isliteral(::VirtualAbstractArray) =  false

default(::VirtualAbstractArray) = 0