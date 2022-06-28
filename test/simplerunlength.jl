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
    sym = ctx.freshen(tag)
    push!(ctx.preamble, :($sym = $ex))
    VirtualSimpleRunLength{Tv, Ti}(sym, tag)
end

(ctx::Finch.LowerJulia)(tns::VirtualSimpleRunLength) = tns.ex

function Finch.initialize!(arr::VirtualSimpleRunLength{Tv}, ctx::Finch.LowerJulia, mode::Union{Write, Update}, idxs...) where {Tv}
    push!(ctx.preamble, quote 
        $(arr.ex).idx = [$(arr.ex).idx[end]]
        $(arr.ex).val = [$(zero(Tv))]
    end)
    access(arr, mode, idxs...)
end 

function Finch.getdims(arr::VirtualSimpleRunLength{Tv, Ti}, ctx::Finch.LowerJulia, mode) where {Tv, Ti}
    ex = Symbol(arr.name, :_stop)
    push!(ctx.preamble, :($ex = $size($(arr.ex))[1]))
    (Extent(1, Virtual{Ti}(ex)),)
end
Finch.setdims!(arr::VirtualSimpleRunLength{Tv, Ti}, ctx::Finch.LowerJulia, mode, dims...) where {Tv, Ti} = arr
Finch.getname(arr::VirtualSimpleRunLength) = arr.name
Finch.setname(arr::VirtualSimpleRunLength, name) = (arr_2 = deepcopy(arr); arr_2.name = name; arr_2)
function (ctx::Finch.Stylize{LowerJulia})(node::Access{<:VirtualSimpleRunLength})
    if ctx.root isa Loop && ctx.root.idx == get_furl_root(node.idxs[1])
        Finch.ChunkStyle()
    else
        mapreduce(ctx, result_style, arguments(node))
    end
end

function (ctx::Finch.ChunkifyVisitor)(node::Access{VirtualSimpleRunLength{Tv, Ti}, Read}, ::Finch.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    my_i′ = ctx.ctx.freshen(getname(vec), :_i1)
    my_p = ctx.ctx.freshen(getname(vec), :_p)
    if getname(ctx.idx) == getname(node.idxs[1])
        tns = Thunk(
            preamble = quote
                $my_p = 1
                $my_i′ = $(vec.ex).idx[$my_p]
            end,
            body = Stepper(
                seek = (ctx, ext) -> quote
                    $my_p = searchsortedfirst($(vec.ex).idx, $(ctx(getstart(ext))), $my_p, length($(vec.ex).idx), Base.Forward)
                    $my_i′ = $(vec.ex).idx[$my_p]
                end,
                body = Step(
                    stride = (ctx, idx, ext) -> my_i′,
                    chunk = Run(
                        body = Simplify(Virtual{Tv}(:($(vec.ex).val[$my_p]))),
                    ),
                    next = (ctx, idx, ext) -> quote
                        if $my_p < length($(vec.ex).idx)
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

function (ctx::Finch.ChunkifyVisitor)(node::Access{<:VirtualSimpleRunLength{Tv, Ti}, <: Union{Write, Update}}, ::Finch.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    my_p = ctx.ctx.freshen(node.tns.name, :_p)
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
                    body = Virtual{Tv}(:($(vec.ex).val[$my_p])),
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