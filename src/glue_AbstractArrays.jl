@kwdef mutable struct VirtualAbstractArray
    ex
    eltype
    ndims
end

function virtual_size(arr::VirtualAbstractArray, ctx::LowerJulia)
    dims = map(i -> Symbol(arr.ex, :_mode, i, :_stop), 1:arr.ndims)
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
    VirtualAbstractArray(sym, T, N)
end

function declare!(arr::VirtualAbstractArray, ctx::LowerJulia, init)
    push!(ctx.preamble, quote
        fill!($(arr.ex), $(ctx(init)))
    end)
    arr
end

get_reader(arr::VirtualAbstractArray, ctx::LowerJulia, protos...) = arr
get_updater(arr::VirtualAbstractArray, ctx::LowerJulia, protos...) = arr

FinchNotation.isliteral(::VirtualAbstractArray) =  false

virtual_default(::VirtualAbstractArray) = 0
virtual_eltype(tns::VirtualAbstractArray) = tns.eltype