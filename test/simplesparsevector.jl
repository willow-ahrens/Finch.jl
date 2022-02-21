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
    sym = ctx.freshen(tag)
    push!(ctx.preamble, :($sym = $ex))
    VirtualSimpleSparseVector{Tv, Ti}(sym, tag, D)
end

(ctx::Finch.LowerJulia)(tns::VirtualSimpleSparseVector) = tns.ex

function Finch.initialize!(arr::VirtualSimpleSparseVector{D, Tv}, ctx::Finch.LowerJulia) where {D, Tv}
    push!(ctx.preamble, quote
        $(arr.ex).idx = [$(arr.ex).idx[end]]
        $(arr.ex).val = $Tv[]
    end)
    arr
end 

function Finch.getdims(arr::VirtualSimpleSparseVector{Tv, Ti}, ctx::Finch.LowerJulia, mode) where {Tv, Ti}
    ex = ctx.freshen(arr.name, :_stop)
    push!(ctx.preamble, :($ex = $size($(arr.ex))[1]))
    (Extent(1, Virtual{Ti}(ex)),)
end
Finch.getsites(arr::VirtualSimpleSparseVector) = (1,)
Finch.getname(arr::VirtualSimpleSparseVector) = arr.name
Finch.setname(arr::VirtualSimpleSparseVector, name) = (arr_2 = deepcopy(arr); arr_2.name = name; arr_2)
Finch.make_style(root::Loop, ctx::Finch.LowerJulia, node::Access{<:VirtualSimpleSparseVector}) =
    getname(root.idxs[1]) == getname(node.idxs[1]) ? Finch.ChunkStyle() : Finch.DefaultStyle()

function (ctx::Finch.ChunkifyVisitor)(node::Access{VirtualSimpleSparseVector{Tv, Ti}, Read}, ::Finch.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    my_i = ctx.ctx.freshen(getname(vec), :_i0)
    my_i′ = ctx.ctx.freshen(getname(vec), :_i1)
    my_p = ctx.ctx.freshen(getname(vec), :_p)
    if getname(ctx.idx) == getname(node.idxs[1])
        tns = Thunk(
            preamble = quote
                $my_p = 1
                $my_i = 1
                $my_i′ = $(vec.ex).idx[$my_p]
            end,
            body = Stepper(
                name = Symbol(vec.ex, :_stepper),
                seek = (ctx, start) -> quote
                    $my_p = searchsortedfirst($(vec.ex).idx, $start, $my_p, length($(vec.ex).idx), Base.Forward)
                    $my_i = $start
                    $my_i′ = $(vec.ex).idx[$my_p]
                end,
                body = Phase(
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
        )
        Access(tns, node.mode, node.idxs)
    else
        node
    end
end

function (ctx::Finch.ChunkifyVisitor)(node::Access{VirtualSimpleSparseVector{Tv, Ti}, <:Union{Write, Update}}, ::Finch.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    my_p = ctx.ctx.freshen(node.tns.name, :_p)
    my_I = ctx.ctx.freshen(node.tns.name, :_I)
    if getname(ctx.idx) == getname(node.idxs[1])
        push!(ctx.ctx.preamble, quote
            $my_p = 0
            $my_I = $(ctx.ctx(ctx.ctx.dims[getname(node.idxs[1])].stop)) + 1
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
                    $(vec.ex).idx[$my_p] = $(ctx(idx))
                end
            )
        )
        Access(tns, node.mode, node.idxs)
    else
        node
    end
end

Finch.register()