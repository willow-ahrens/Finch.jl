struct GoofyVector{Tv, Ti, D} <: AbstractVector{Tv}
    idx::Vector{Ti}
    val::Vector{Tv}
end

Base.size(vec::GoofyVector) = vec.idx[end] - 1

function Base.getindex(vec::GoofyVector{Tv, Ti, D}, i) where {Tv, Ti, D}
    p = findlast(j->j <= i, vec.idx)
    vec.idx[p] == i ? vec.val[p] : D
end

struct VirtualGoofyVector{Tv, Ti}
    ex
    name
    D
end

function Finch.virtualize(ex, ::Type{GoofyVector{Tv, Ti, D}}) where {Tv, Ti, D}
    VirtualGoofyVector{Tv, Ti}(ex, gensym(:goofy), D)
end

Pigeon.lower_axes(arr::VirtualGoofyVector{Tv, Ti}, ctx::Finch.LowerJuliaContext) where {Tv, Ti} = (Extent(1, Virtual{Ti}(:(size($(arr.ex))[1]))),)
Pigeon.getsites(arr::VirtualGoofyVector) = (1,)
Pigeon.getname(arr::VirtualGoofyVector) = arr.name
Pigeon.make_style(root::Loop, ctx::Finch.LowerJuliaContext, node::Access{<:VirtualGoofyVector}) =
    root.idxs[1] == node.idxs[1] ? Finch.ChunkStyle() : DefaultStyle()
Pigeon.visit!(node::Access{<:VirtualGoofyVector}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle) =
    ctx.idx == node.idxs[1] ? Access(chunkbody(node.tns), node.mode, node.idxs) : node.idxs

function chunkbody(vec::VirtualGoofyVector{Tv, Ti}) where {Tv, Ti}
    return Stream(
        body = (ctx) -> begin
            my_i = Symbol(Pigeon.getname(vec), :_i0)
            my_i′ = Symbol(Pigeon.getname(vec), :_i1)
            my_p = Symbol(Pigeon.getname(vec), :_p)
            push!(ctx.preamble, :($my_p = 2))
            push!(ctx.preamble, :($my_i = $(vec.ex).idx[$my_p]))
            push!(ctx.preamble, :($my_i′ = $(vec.ex).idx[$my_p + 1]))
            Packet(
                body = (ctx, start, stop) -> begin
                    push!(ctx.epilogue, :($my_p += ($my_i == $stop)))
                    push!(ctx.epilogue, :($my_i = $my_i′))
                    push!(ctx.epilogue, :($my_i′ = $(vec.ex).idx[$my_p + 1]))
                    Cases([
                        :($my_i == $stop) =>
                            Spike(
                                body = 0,
                                tail = (ctx) -> Virtual{Tv}(:($(vec.ex).val[$my_i])),
                            ),
                        :($my_i == $stop) =>
                            Run(
                                body = 0,
                            ),
                    ])
                end,
                step = (ctx, start, stop) -> my_i
            )
        end
    )
end