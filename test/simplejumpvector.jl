mutable struct SimpleJumpVector{D, Tv, Ti} <: AbstractVector{Tv}
    idx::Vector{Ti}
    val::Vector{Tv}
end

function SimpleJumpVector{D}(idx::Vector{Ti}, val::Vector{Tv}) where {D, Ti, Tv}
    SimpleJumpVector{D, Tv, Ti}(idx, val)
end

Base.size(vec::SimpleJumpVector) = (vec.idx[end] - 1,)

function Base.getindex(vec::SimpleJumpVector{D, Tv, Ti}, i) where {D, Tv, Ti}
    p = findfirst(j->j >= i, vec.idx)
    vec.idx[p] == i ? vec.val[p] : D
end

mutable struct VirtualSimpleJumpVector{Tv, Ti}
    ex
    name
    D
end

function Finch.virtualize(ex, ::Type{SimpleJumpVector{D, Tv, Ti}}, ctx, tag=:tns) where {D, Tv, Ti}
    sym = ctx.freshen(tag)
    push!(ctx.preamble, :($sym = $ex))
    VirtualSimpleJumpVector{Tv, Ti}(sym, tag, D)
end

(ctx::Finch.LowerJulia)(tns::VirtualSimpleJumpVector) = tns.ex

function Finch.initialize!(arr::VirtualSimpleJumpVector{D, Tv}, ctx::Finch.LowerJulia, mode::Union{Write, Update}, idxs...) where {D, Tv}
    push!(ctx.preamble, quote
        $(arr.ex).idx = [$(arr.ex).idx[end]]
        $(arr.ex).val = $Tv[]
    end)
    access(arr, mode, idxs...)
end 

function Finch.getdims(arr::VirtualSimpleJumpVector{Tv, Ti}, ctx::Finch.LowerJulia, mode) where {Tv, Ti}
    ex = ctx.freshen(arr.name, :_stop)
    push!(ctx.preamble, :($ex = $size($(arr.ex))[1]))
    (Extent(1, Virtual{Ti}(ex)),)
end
Finch.getsites(arr::VirtualSimpleJumpVector) = (1,)
Finch.getname(arr::VirtualSimpleJumpVector) = arr.name
Finch.setname(arr::VirtualSimpleJumpVector, name) = (arr_2 = deepcopy(arr); arr_2.name = name; arr_2)
Finch.make_style(root::Loop, ctx::Finch.LowerJulia, node::Access{<:VirtualSimpleJumpVector}) =
    getname(root.idx) == getname(node.idxs[1]) ? Finch.ChunkStyle() : Finch.DefaultStyle()

function (ctx::Finch.ChunkifyVisitor)(node::Access{VirtualSimpleJumpVector{Tv, Ti}, Read}, ::Finch.DefaultStyle) where {Tv, Ti}
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
            body = Jumper(
                seek = (ctx, start) -> quote
                    $my_p = searchsortedfirst($(vec.ex).idx, $start, $my_p, length($(vec.ex).idx), Base.Forward)
                    $my_i = $start
                    $my_i′ = $(vec.ex).idx[$my_p]
                end,
                body = Phase(
                    stride = (start) -> my_i′,
                    body = (start, step) -> begin
                        Cases([
                            :($step == $my_i′) => Thunk(
                                body = Spike(
                                    body = Simplify(zero(Tv)),
                                    tail = Virtual{Tv}(:($(vec.ex).val[$my_p])),
                                ),
                                epilogue = quote
                                    $my_p += 1
                                    $my_i = $my_i′ + 1
                                    $my_i′ = $(vec.ex).idx[$my_p]
                                end
                            ),
                            true => Stepper(
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
                                                    body = Simplify(zero(Tv)),
                                                ),
                                            true =>
                                                Thunk(
                                                    body = Spike(
                                                        body = Simplify(zero(Tv)),
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

function (ctx::Finch.ChunkifyVisitor)(node::Access{VirtualSimpleJumpVector{Tv, Ti}, <:Union{Write, Update}}, ::Finch.DefaultStyle) where {Tv, Ti}
    vec = node.tns
    my_p = ctx.ctx.freshen(node.tns.name, :_p)
    my_I = ctx.ctx.freshen(node.tns.name, :_I)
    if getname(ctx.idx) == getname(node.idxs[1])
        push!(ctx.ctx.preamble, quote
            $my_p = 0
            $my_I = $(ctx.ctx(stop(ctx.ctx.dims[getname(node.idxs[1])]))) + 1 #TODO is this okay? Should chunkify tell us which extent to use?
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
                body = Virtual{Tv}(:($(vec.ex).val[$my_p])),
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