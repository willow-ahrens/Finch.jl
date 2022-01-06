Base.@kwdef mutable struct VirtualAbstractArray
    ndims
    name
    ex
end

function Pigeon.lower_axes(arr::VirtualAbstractArray, ctx::LowerJuliaContext) where {T <: AbstractArray}
    dims = map(i -> gensym(Symbol(arr.name, :_, i, :_stop)), 1:arr.ndims)
    push!(ctx.preamble, quote
        ($(dims...),) = size($(arr.ex))
    end)
    return map(i->Extent(1, Virtual{Int}(dims[i])), 1:arr.ndims)
end

function Pigeon.lower_axis_merge(ctx::Finch.LowerJuliaContext, a::Extent, b::Extent)
    push!(ctx.preamble, quote
        $(visit!(a.start, ctx)) == $(visit!(b.start, ctx)) || throw(DimensionMismatch("mismatched dimension starts"))
        $(visit!(a.stop, ctx)) == $(visit!(b.stop, ctx)) || throw(DimensionMismatch("mismatched dimension stops"))
    end)
    a #TODO could do some simplify stuff here
end
Pigeon.getsites(arr::VirtualAbstractArray) = 1:arr.ndims
Pigeon.getname(arr::VirtualAbstractArray) = arr.name

function Pigeon.visit!(arr::VirtualAbstractArray, ctx::LowerJuliaContext, ::DefaultStyle)
    return arr.ex
end

function virtualize(ex, ::Type{<:AbstractArray{T, N}}, ctx; tag=gensym(), kwargs...) where {T, N}
    VirtualAbstractArray(N, tag, ex)
end

function revirtualize!(node::VirtualAbstractArray, ctx::LowerJuliaContext)
    ex′ = Symbol(:tns_, node.name)
    push!(ctx.preamble, :($ex′ = $(node.ex)))
    node = deepcopy(node)
    node.ex = ex′
    node
end

Pigeon.isliteral(::VirtualAbstractArray) = false