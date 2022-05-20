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

function Finch.virtualize(ex, ::Type{SingleSpike{D, Tv}}, ctx, tag=:tns) where {D, Tv}
    sym = ctx.freshen(tag)
    push!(ctx.preamble, :($sym = $ex))
    VirtualSingleSpike{Tv}(sym, tag, D)
end

(ctx::Finch.LowerJulia)(tns::VirtualSingleSpike) = tns.ex

function Finch.getdims(arr::VirtualSingleSpike{Tv}, ctx::Finch.LowerJulia, mode) where {Tv}
    ex = ctx.freshen(arr.name, :_stop)
    push!(ctx.preamble, :($ex = $size($(arr.ex))[1]))
    (Extent(1, Virtual{Int}(ex)),)
end
Finch.setdims!(arr::VirtualSingleSpike, ctx::Finch.LowerJulia, mode, dims...) = arr
Finch.getname(arr::VirtualSingleSpike) = arr.name
Finch.setname(arr::VirtualSingleSpike, name) = (arr_2 = deepcopy(arr); arr_2.name = name; arr_2)
Finch.make_style(root::Loop, ctx::Finch.LowerJulia, node::Access{<:VirtualSingleSpike}) =
    getname(root.idx) == getname(node.idxs[1]) ? Finch.ChunkStyle() : Finch.DefaultStyle()

function (ctx::Finch.ChunkifyVisitor)(node::Access{VirtualSingleSpike{Tv}, Read}, ::Finch.DefaultStyle) where {Tv}
    vec = node.tns
    if getname(ctx.idx) == getname(node.idxs[1])
        tns = Spike(
            body = Simplify(zero(Tv)),
            tail = Virtual{Tv}(:($(vec.ex).tail))
        )
        Access(tns, node.mode, node.idxs)
    else
        node
    end
end

Finch.register()