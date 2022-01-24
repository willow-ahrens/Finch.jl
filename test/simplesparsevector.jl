mutable struct SimpleSparseVector{D, Tv, Ti} <: AbstractVector{Tv}
    idx::Vector{Ti}
    val::Vector{Tv}
end

function SimpleSparseVector{D}(idx::Vector{Ti}, val::Vector{Tv}) where {D, Ti, Tv}
    SimpleSparseVector{D, Tv, Ti}(idx, val)
end

Base.size(vec::SimpleSparseVector) = (vec.idx[end] - 1,)

function Base.getindex(vec::SimpleSparseVector{D, Tv, Ti}, i) where {D, Tv, Ti}
    p = findfirst(j->j >= i, vec.idx)
    vec.idx[p] == i ? vec.val[p] : D
end

mutable struct VirtualSimpleSparseVector{Tv, Ti}
    ex
    name
    D
end

function Finch.virtualize(ex, ::Type{SimpleSparseVector{D, Tv, Ti}}, ctx, tag=:tns) where {D, Tv, Ti}
    sym = ctx.freshen(:tns_, tag)
    push!(ctx.preamble, :($sym = $ex))
    VirtualSimpleSparseVector{Tv, Ti}(sym, tag, D)
end

function Pigeon.lower_axes(arr::VirtualSimpleSparseVector{Tv, Ti}, ctx::Finch.LowerJuliaContext) where {Tv, Ti}
    ex = ctx.freshen(:tns_, arr.name, :_stop)
    push!(ctx.preamble, :($ex = $size($(arr.ex))[1]))
    (Extent(1, Virtual{Ti}(ex)),)
end
Pigeon.getsites(arr::VirtualSimpleSparseVector) = (1,)
Pigeon.getname(arr::VirtualSimpleSparseVector) = arr.name
Pigeon.make_style(root::Loop, ctx::Finch.LowerJuliaContext, node::Access{<:VirtualSimpleSparseVector}) =
    getname(root.idxs[1]) == getname(node.idxs[1]) ? Finch.ChunkStyle() : DefaultStyle()
#TODO is there a way to share this logic with others?
#Pigeon.visit!(node::Access{<:VirtualSimpleSparseVector}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle) =
#    ctx.idx == node.idxs[1] ? Access(chunkbody(node.tns), node.mode, node.idxs) : node.idxs

function Pigeon.visit!(node::Access{VirtualSimpleSparseVector{Tv, Ti}, Pigeon.Read}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    my_i = ctx.ctx.freshen(:tns_, Pigeon.getname(vec), :_i0)
    my_i′ = ctx.ctx.freshen(:tns_, Pigeon.getname(vec), :_i1)
    my_p = ctx.ctx.freshen(:tns_, Pigeon.getname(vec), :_p)
    if getname(ctx.idx) == getname(node.idxs[1])
        tns = Thunk(
            preamble = quote
                $my_p = 1
                $my_i = 1
                $my_i′ = $(vec.ex).idx[$my_p]
            end,
            body = Stepper(
                stride = (start) -> my_i′,
                body = (start, step) -> begin
                    Cases([
                        :($step < $my_i′) =>
                            Run(
                                body = 0,
                            ),
                        true =>
                            Thunk(
                                body = Spike(
                                    body = 0,
                                    tail = Virtual{Tv}(:($(vec.ex).val[$my_p])),
                                ),
                                epilogue = quote
                                    $my_p += 1
                                    $my_i = $my_i′ + 1
                                    $my_i′ = $(vec.ex).idx[$my_p]
                                end
                            ),
                    ])
                end
            )
        )
        Access(tns, node.mode, node.idxs)
    else
        node
    end
end

function Pigeon.visit!(node::Access{VirtualSimpleSparseVector{Tv, Ti}, <:Union{Pigeon.Write, Pigeon.Update}}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    my_p = ctx.ctx.freshen(:tns_, node.tns.name, :_p)
    my_I = ctx.ctx.freshen(:tns_, node.tns.name, :_I)
    if getname(ctx.idx) == getname(node.idxs[1])
        push!(ctx.ctx.preamble, quote
            $my_p = 0
            $my_I = $(Pigeon.visit!(ctx.ctx.dims[Pigeon.getname(node.idxs[1])].stop, ctx.ctx)) + 1
            $(vec.ex).idx = $Ti[$my_I]
            $(vec.ex).val = $Tv[]
        end)
        tns = AcceptSpike(
            val = vec.D,
            tail = (ctx, idx) -> Thunk(
                preamble = quote
                    push!($(vec.ex).idx, $my_I)
                    push!($(vec.ex).val, zero($Tv))
                    $my_p += 1
                end,
                body = Access(Scalar(Virtual{Tv}(:($(vec.ex).val[$my_p]))), node.mode, []),
                epilogue = quote
                    $(vec.ex).idx[$my_p] = $(Pigeon.visit!(idx, ctx))
                end
            )
        )
        Access(tns, node.mode, node.idxs)
    else
        node
    end
end

Finch.register()