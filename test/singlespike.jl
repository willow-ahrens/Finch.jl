mutable struct SingleSpike{D, Tv} <: AbstractVector{Tv}
    n
    tail::Tv
end

Base.size(vec::SingleSpike) = (vec.n,)

function SingleSpike{D}(n, tail::Tv) where {D, Tv}
    SingleSpike{D, Tv}(n, tail)
end

function Base.getindex(vec::SingleSpike{D}, i) where {D}
    i == vec.n ? vec.tail : D
end

mutable struct VirtualSingleSpike{Tv}
    ex
    name
    D
end

function Finch.virtualize(ex, ::Type{SingleSpike{D, Tv}}, ctx; tag=gensym(), kwargs...) where {D, Tv}
    sym = Symbol(:tns_, tag)
    push!(ctx.preamble, :($sym = $ex))
    VirtualSingleSpike{Tv}(sym, tag, D)
end

function Pigeon.lower_axes(arr::VirtualSingleSpike{Tv}, ctx::Finch.LowerJuliaContext) where {Tv}
    ex = Symbol(:tns_, arr.name, :_stop)
    push!(ctx.preamble, :($ex = $size($(arr.ex))[1]))
    (Extent(1, Virtual{Int}(ex)),)
end
Pigeon.getsites(arr::VirtualSingleSpike) = (1,)
Pigeon.getname(arr::VirtualSingleSpike) = arr.name
Pigeon.make_style(root::Loop, ctx::Finch.LowerJuliaContext, node::Access{<:VirtualSingleSpike}) =
    root.idxs[1] == node.idxs[1] ? Finch.ChunkStyle() : DefaultStyle()

function Pigeon.visit!(node::Access{VirtualSingleSpike{Tv}, Pigeon.Read}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle) where {Tv}
    vec = node.tns
    if ctx.idx == node.idxs[1]
        tns = Spike(
            body = 0,
            tail = Virtual{Tv}(:($(vec.ex).tail))
        )
        Access(tns, node.mode, node.idxs)
    else
        node
    end
end

Finch.register()