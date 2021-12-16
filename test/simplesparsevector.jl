struct SimpleSparseVector{Tv, Ti, D, name} <: AbstractVector{Tv}
    idx::Vector{Ti}
    val::Vector{Tv}
end

Base.size(vec::SimpleSparseVector) = vec.idx[end] - 1

function Base.getindex(vec::SimpleSparseVector{Tv, Ti, D}, i) where {Tv, Ti, D}
    p = findlast(j->j <= i, vec.idx)
    vec.idx[p] == i ? vec.val[p] : D
end

struct VirtualSimpleSparseVector{Tv, Ti}
    ex
    name
    D
end

function Finch.virtualize(ex, ::Type{SimpleSparseVector{Tv, Ti, D, name}}) where {Tv, Ti, D, name}
    VirtualSimpleSparseVector{Tv, Ti}(ex, name, D)
end

Pigeon.lower_axes(arr::VirtualSimpleSparseVector{Tv, Ti}, ctx::Finch.LowerJuliaContext) where {Tv, Ti} = (Extent(1, Virtual{Ti}(:(size($(arr.ex))[1]))),)
Pigeon.getsites(arr::VirtualSimpleSparseVector) = (1,)
Pigeon.getname(arr::VirtualSimpleSparseVector) = arr.name
Pigeon.make_style(root::Loop, ctx::Finch.LowerJuliaContext, node::Access{<:VirtualSimpleSparseVector}) =
    root.idxs[1] == node.idxs[1] ? Finch.ChunkStyle() : DefaultStyle()
Pigeon.visit!(node::Access{<:VirtualSimpleSparseVector}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle) =
    ctx.idx == node.idxs[1] ? Access(chunkbody(node.tns), node.mode, node.idxs) : node.idxs

function chunkbody(vec::VirtualSimpleSparseVector{Tv, Ti}) where {Tv, Ti}
    my_i = Symbol(Pigeon.getname(vec), :_i0)
    my_i′ = Symbol(Pigeon.getname(vec), :_i1)
    my_p = Symbol(Pigeon.getname(vec), :_p)
    return Thunk(
        preamble = quote
            $my_p = 1
            $my_i = $(vec.ex).idx[$my_p]
            $my_i′ = $(vec.ex).idx[$my_p + 1]
        end,
        body = Stream(
            step = (ctx, start, stop) -> my_i′,
            body = (ctx, start, stop) -> begin
                Cases([
                    :($my_i == $stop) =>
                        Thunk(
                            body = Spike(
                                body = 0,
                                tail = Virtual{Tv}(:($(vec.ex).val[$my_p])),
                            ),
                            epilogue = quote
                                $my_p += 1
                                $my_i = $my_i′
                                $my_i′ = $(vec.ex).idx[$my_p + 1]
                            end
                        ),
                    :($my_i < $stop) =>
                        Run(
                            body = 0,
                        ),
                ])
            end
        )
    )
end

Finch.register()