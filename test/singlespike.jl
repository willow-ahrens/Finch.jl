mutable struct SingleSpike{D, Tv} <: AbstractVector{Tv}
    n
    tail::Tv
end

Base.size(vec::SingleSpike) = (vec.n,)

function Base.getindex(vec::SingleSpike{D}, i) where {D}
    i == vec.n ? vec.tail : D
end

mutable struct VirtualSingleSpike{Tv}
    ex
    name
    D
end

function Finch.virtualize(ex, ::Type{SingleSpike{D, Tv}}; tag=gensym(), kwargs...) where {D, Tv}
    VirtualSingleSpike{Tv}(ex, tag, D)
end

function Finch.revirtualize!(node::VirtualSingleSpike, ctx::Finch.LowerJuliaContext)
    ex′ = Symbol(:tns_, node.name)
    push!(ctx.preamble, :($ex′ = $(node.ex)))
    node = deepcopy(node)
    node.ex = ex′
    node
end

function Pigeon.lower_axes(arr::VirtualSimpleRunLength{Tv, Ti}, ctx::Finch.LowerJuliaContext) where {Tv, Ti}
    ex = Symbol(:tns_, arr.name, :_stop)
    push!(ctx.preamble, :($ex = $size($(arr.ex))[1]))
    (Extent(1, Virtual{Ti}(ex)),)
end
Pigeon.getsites(arr::VirtualSimpleRunLength) = (1,)
Pigeon.getname(arr::VirtualSimpleRunLength) = arr.name
Pigeon.make_style(root::Loop, ctx::Finch.LowerJuliaContext, node::Access{<:VirtualSimpleRunLength}) =
    root.idxs[1] == node.idxs[1] ? Finch.ChunkStyle() : DefaultStyle()

function Pigeon.visit!(node::Access{VirtualSimpleRunLength{Tv, Ti}, Pigeon.Read}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    my_i′ = Symbol(:tns_, Pigeon.getname(vec), :_i1)
    my_p = Symbol(:tns_, Pigeon.getname(vec), :_p)
    if ctx.idx == node.idxs[1]
        tns = Thunk(
            preamble = quote
                $my_p = 1
                $my_i′ = $(vec.ex).idx[$my_p]
            end,
            body = Stream(
                step = (ctx, start, stop) -> my_i′,
                body = (ctx, start, stop) -> Thunk(
                    body = Run(
                        body = Virtual{Tv}(:($(vec.ex).val[$my_p])),
                    ),
                    epilogue = quote
                        if $my_i′ == $stop && $my_p < length($(vec.ex).idx)
                            $my_p += 1
                            $my_i′ = $(vec.ex).idx[$my_p]
                        end
                    end
                )
            )
        )
        Access(tns, node.mode, node.idxs)
    else
        node
    end
end

function Pigeon.visit!(node::Access{<:VirtualSimpleRunLength{Tv, Ti}, <: Union{Pigeon.Write, Pigeon.Update}}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    my_p = Symbol(:tns_, node.tns.name, :_p)
    if ctx.idx == node.idxs[1]
        tns = Thunk(
            preamble = quote
                $my_p = 0
                $(vec.ex).idx = $Ti[]
                $(vec.ex).val = $Tv[]
            end,
            body = AcceptRun(
                body = (ctx, start, stop) -> Thunk(
                    preamble = quote
                        push!($(vec.ex).val, zero($Tv))
                        $my_p += 1
                    end,
                    body = Scalar(Virtual{Tv}(:($(vec.ex).val[$my_p]))),
                    epilogue = quote
                        push!($(vec.ex).idx, $(Pigeon.visit!(stop, ctx)))
                    end
                )
            )
        )
        Access(tns, node.mode, node.idxs)
    else
        node
    end
end

Finch.register()