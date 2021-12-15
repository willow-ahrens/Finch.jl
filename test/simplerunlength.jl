struct SimpleRunLength{Tv, Ti, D} <: AbstractVector{Tv}
    idx::Vector{Ti}
    val::Vector{Tv}
end

Base.size(vec::SimpleRunLength) = vec.idx[end] - 1

function Base.getindex(vec::SimpleRunLength{Tv, Ti, D}, i) where {Tv, Ti, D}
    p = findlast(j->j <= i, vec.idx)
    vec.val[p]
end

struct VirtualSimpleRunLength{Tv, Ti}
    ex
    name
    D
end

function Finch.virtualize(ex, ::Type{SimpleRunLength{Tv, Ti, D}}) where {Tv, Ti, D}
    VirtualSimpleRunLength{Tv, Ti}(ex, gensym(:goofy), D)
end

Pigeon.lower_axes(arr::VirtualSimpleRunLength{Tv, Ti}, ctx::Finch.LowerJuliaContext) where {Tv, Ti} = (Extent(1, Virtual{Ti}(:(size($(arr.ex))[1]))),)
Pigeon.getsites(arr::VirtualSimpleRunLength) = (1,)
Pigeon.getname(arr::VirtualSimpleRunLength) = arr.name
Pigeon.make_style(root::Loop, ctx::Finch.LowerJuliaContext, node::Access{<:VirtualSimpleRunLength}) =
    root.idxs[1] == node.idxs[1] ? Finch.ChunkStyle() : DefaultStyle()

function Pigeon.visit!(node::Access{<:VirtualSimpleRunLength, Read}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle)
    if ctx.idx == node.idxs[1]
        tns = Stream(
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
                        Run(
                            body = Virtual{Tv}(:($(vec.ex).val[$my_i])),
                        )
                    end,
                    step = (ctx, start, stop) -> my_i
                )
            end
        )
        Access(tns, Read(), node.idxs)
    else
        node
    end
end

function Pigeon.visit!(node::Access{<:VirtualSimpleRunLength, <: Union{Write, Update}}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle)
    my_p = gensym(:p)
    if ctx.idx == node.idxs[1]
        push!(ctx.preamble, :($my_p = 1))
        push!(ctx.preamble, :($(vec.ex).idx = [1]))
        tns = AcceptRun(
            body = (ctx, start, stop) -> begin
                push!(ctx.epilogue, quote
                    $my_p += 1
                    push!($(vec.ex).idx, $stop + 1)
                    resize!($(vec.ex).val, $my_p)
                end)
                Virtual{Tv}(:($(vec.ex).val[$my_p]))
            end
        )
        Access(tns, node.mode, node.idxs)
    else
        node
    end
end