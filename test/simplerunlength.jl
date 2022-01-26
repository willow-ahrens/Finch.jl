mutable struct SimpleRunLength{Tv, Ti} <: AbstractVector{Tv}
    idx::Vector{Ti}
    val::Vector{Tv}
end

Base.size(vec::SimpleRunLength) = (vec.idx[end], )

function Base.getindex(vec::SimpleRunLength{Tv, Ti}, i) where {Tv, Ti}
    p = findfirst(j->j >= i, vec.idx)
    vec.val[p]
end

mutable struct VirtualSimpleRunLength{Tv, Ti}
    ex
    name
end

function Finch.virtualize(ex, ::Type{SimpleRunLength{Tv, Ti}}, ctx, tag=:tns) where {Tv, Ti}
    sym = ctx.freshen(:tns_, tag)
    push!(ctx.preamble, :($sym = $ex))
    VirtualSimpleRunLength{Tv, Ti}(sym, tag)
end

function Finch.virtual_initialize!(arr::VirtualSimpleRunLength{Tv}, ctx::Finch.LowerJuliaContext) where {Tv}
    quote 
        $(arr.ex).idx = [$(arr.ex).idx[end]]
        $(arr.ex).val = [$(zero(Tv))]
    end
end 

function Finch.lower_axes(arr::VirtualSimpleRunLength{Tv, Ti}, ctx::Finch.LowerJuliaContext) where {Tv, Ti}
    ex = ctx.freshen(:tns_, arr.name, :_stop)
    push!(ctx.preamble, :($ex = $size($(arr.ex))[1]))
    (Extent(1, Virtual{Ti}(ex)),)
end
Finch.getsites(arr::VirtualSimpleRunLength) = (1,)
Finch.getname(arr::VirtualSimpleRunLength) = arr.name
Finch.make_style(root::Loop, ctx::Finch.LowerJuliaContext, node::Access{<:VirtualSimpleRunLength}) =
    getname(root.idxs[1]) == getname(node.idxs[1]) ? Finch.ChunkStyle() : Finch.DefaultStyle()

function Finch.visit!(node::Access{VirtualSimpleRunLength{Tv, Ti}, Read}, ctx::Finch.ChunkifyContext, ::Finch.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    my_i′ = ctx.ctx.freshen(:tns_, getname(vec), :_i1)
    my_p = ctx.ctx.freshen(:tns_, getname(vec), :_p)
    if getname(ctx.idx) == getname(node.idxs[1])
        tns = Thunk(
            preamble = quote
                $my_p = 1
                $my_i′ = $(vec.ex).idx[$my_p]
            end,
            body = Stepper(
                stride = (start) -> my_i′,
                body = (start, step) -> Thunk(
                    body = Run(
                        body = Virtual{Tv}(:($(vec.ex).val[$my_p])),
                    ),
                    epilogue = quote
                        if $my_i′ == $step && $my_p < length($(vec.ex).idx)
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

function Finch.visit!(node::Access{<:VirtualSimpleRunLength{Tv, Ti}, <: Union{Write, Update}}, ctx::Finch.ChunkifyContext, ::Finch.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    my_p = ctx.ctx.freshen(:tns_, node.tns.name, :_p)
    if getname(ctx.idx) == getname(node.idxs[1])
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
                    body = Access(Scalar(Virtual{Tv}(:($(vec.ex).val[$my_p]))), node.mode, []),
                    epilogue = quote
                        push!($(vec.ex).idx, $(ctx(stop)))
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