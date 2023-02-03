@kwdef mutable struct VirtualAbstractArray
    eltype
    ndims
    name
    ex
end

function virtual_size(arr::VirtualAbstractArray, ctx::LowerJulia)
    dims = map(i -> Symbol(arr.name, :_mode, i, :_stop), 1:arr.ndims)
    push!(ctx.preamble, quote
        ($(dims...),) = size($(arr.ex))
    end)
    return map(i->Extent(literal(1), value(dims[i], Int)), 1:arr.ndims)
end

function (ctx::LowerJulia)(arr::VirtualAbstractArray, ::DefaultStyle)
    return arr.ex
end

function virtualize(ex, ::Type{<:AbstractArray{T, N}}, ctx, tag=:tns) where {T, N}
    sym = ctx.freshen(tag)
    push!(ctx.preamble, :($sym = $ex))
    VirtualAbstractArray(T, N, tag, sym)
end

function initialize!(arr::VirtualAbstractArray, ctx::LowerJulia)
    push!(ctx.preamble, quote
        fill!($(arr.ex), 0) #TODO
    end)
    arr
end

get_reader(arr::VirtualAbstractArray, ctx::LowerJulia, protos...) = arr
get_updater(arr::VirtualAbstractArray, ctx::LowerJulia, protos...) = arr

IndexNotation.isliteral(::VirtualAbstractArray) =  false

virtual_default(::VirtualAbstractArray) = 0
virtual_eltype(tns::VirtualAbstractArray) = tns.eltype