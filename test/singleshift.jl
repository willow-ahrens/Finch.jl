mutable struct SingleShift{Tv, Ti} <: AbstractVector{Tv}
    I::Ti
    shift::Ti
    val::Vector{Tv}
end

function SingleShift(I::Ti, shift::Ti, val::Vector{Tv}) where {Ti, Tv}
    SingleShift{Tv, Ti}(I, shift, val)
end

Base.size(vec::SingleShift) = (vec.I,)

function Base.getindex(vec::SingleShift{Tv, Ti}, i) where {Tv, Ti}
    vec.val[vec.shift + i]
end

mutable struct VirtualSingleShift{Tv, Ti}
    ex
    name
end

function Finch.virtualize(ex, ::Type{SingleShift{Tv, Ti}}, ctx, tag=:tns) where {Tv, Ti}
    sym = ctx.freshen(tag)
    push!(ctx.preamble, :($sym = $ex))
    VirtualSingleShift{Tv, Ti}(sym, tag)
end

(ctx::Finch.LowerJulia)(tns::VirtualSingleShift) = tns.ex

function Finch.getdims(arr::VirtualSingleShift{Tv, Ti}, ctx::Finch.LowerJulia, mode) where {Tv, Ti}
    ex = ctx.freshen(arr.name, :_stop)
    push!(ctx.preamble, :($ex = $size($(arr.ex))[1]))
    (Extent(1, Virtual{Ti}(ex)),)
end
Finch.getsites(arr::VirtualSingleShift) = (1,)
Finch.getname(arr::VirtualSingleShift) = arr.name
Finch.setname(arr::VirtualSingleShift, name) = (arr_2 = deepcopy(arr); arr_2.name = name; arr_2)
Finch.make_style(root::Loop, ctx::Finch.LowerJulia, node::Access{<:VirtualSingleShift}) =
    getname(root.idxs[1]) == getname(node.idxs[1]) ? Finch.ChunkStyle() : Finch.DefaultStyle()

function (ctx::Finch.ChunkifyVisitor)(node::Access{VirtualSingleShift{Tv, Ti}, Read}, ::Finch.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    if getname(ctx.idx) == getname(node.idxs[1])
        tns = Shift(
            body = Leaf(
                body = (i) -> :($(vec.ex).val[$(ctx.ctx(i))])
            ),
            shift = Virtual{Ti}(:($(vec.ex).shift))
        )
        Access(tns, node.mode, node.idxs)
    else
        node
    end
end

Finch.register()