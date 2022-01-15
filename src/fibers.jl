export SparseLevel
export DenseLevel
export ScalarLevel

struct Fiber{Tv, N, R, Lvls<:Tuple, Poss<:Tuple, Idxs<:Tuple} <: AbstractArray{Tv, N}
    lvls::Lvls
    poss::Poss
    idxs::Idxs
end

Fiber{Tv}(lvls::Lvls) where {Tv, N, Lvls} = Fiber{Tv, length(lvls) - 1, 1}(lvls, (1,), ())
Fiber{Tv, N, R}(lvls, poss, idxs) where {Tv, N, R} = Fiber{Tv, N, R, typeof(lvls), typeof(poss), typeof(idxs)}(lvls, poss, idxs)

Base.size(fbr::Fiber{Tv, N, R}) where {Tv, N, R} = map(dimension, fbr.lvls[R:end-1])

function Base.getindex(fbr::Fiber{Tv, N}, idxs::Vararg{<:Any, N}) where {Tv, N}
    readindex(fbr, idxs...)
end

function readindex(fbr::Fiber{Tv, N, R}, idxs...) where {Tv, N, R}
    unfurl(fbr.lvls[R], fbr, idxs...)
end

function refurl(fbr::Fiber{Tv, N, R}, p, i) where {Tv, N, R}
    return Fiber{Tv, N - 1, R + 1}(fbr.lvls, (fbr.poss..., p), (fbr.idxs..., i))
end



struct SparseLevel{Tv, Ti}
    I::Ti
    pos::Vector{Ti}
    idx::Vector{Ti}
end

function SparseLevel{Tv}(I::Ti, pos::Vector{Ti}, idx::Vector{Ti}) where {Tv, Ti}
    SparseLevel{Tv, Ti}(I, pos, idx)
end

dimension(lvl::SparseLevel) = lvl.I
cardinality(lvl::SparseLevel) = pos[end] - 1

function unfurl(lvl::SparseLevel{Tv, Ti}, fbr::Fiber{Tv, N, R}, i, tail...) where {Tv, Ti, N, R}
    q = fbr.poss[R]
    r = searchsorted(@view(lvl.idx[lvl.pos[q]:lvl.pos[q + 1] - 1]), i)
    p = lvl.pos[q] + first(r) - 1
    length(r) == 0 ? zero(Tv) : readindex(refurl(fbr, p, i), tail...)
end



struct DenseLevel{Ti}
    I::Ti
end

dimension(lvl::DenseLevel) = lvl.I
cardinality(lvl::DenseLevel) = lvl.I

function unfurl(lvl::DenseLevel{Ti}, fbr::Fiber{Tv, N, R}, i, tail...) where {Tv, Ti, N, R}
    q = fbr.poss[R]
    p = (q - 1) * lvl.I + i
    readindex(refurl(fbr, p, i), tail...)
end



struct ScalarLevel{Tv}
    val::Vector{Tv}
end

function unfurl(lvl::ScalarLevel, fbr::Fiber{Tv, N, R}) where {Tv, N, R}
    q = fbr.poss[R]
    return lvl.val[q]
end



mutable struct VirtualFiber
    name
    ex
    N
    Tv
    R
    lvls::Vector{Any}
    poss::Vector{Any}
    idxs::Vector{Any}
end

Pigeon.isliteral(::VirtualFiber) = false

function Pigeon.make_style(root::Loop, ctx::Finch.LowerJuliaContext, node::Access{VirtualFiber})
    if isempty(node.idxs)
        return AccessStyle()
    elseif getname(root.idxs[1]) == getname(node.idxs[1])
        return ChunkStyle()
    else
        return DefaultStyle()
    end
end

function Pigeon.make_style(root, ctx::Finch.LowerJuliaContext, node::Access{VirtualFiber})
    if isempty(node.idxs)
        return AccessStyle()
    else
        return DefaultStyle()
    end
end

function Pigeon.lower_axes(arr::VirtualFiber, ctx::LowerJuliaContext) where {T <: AbstractArray}
    dims = map(i -> gensym(Symbol(arr.name, :_, i, :_stop)), 1:arr.N)
    for (dim, lvl) in zip(dims, arr.lvls)
        #Could unroll more manually, but I'm not convinced it's worth it.
        push!(ctx.preamble, :($dim = dimension($(lvl.ex)))) #TODO we don't know if every level has a .ex
    end
    return map(i->Extent(1, Virtual{Int}(dims[i])), 1:arr.N)
end

Pigeon.getsites(arr::VirtualFiber) = 1:arr.N
Pigeon.getname(arr::VirtualFiber) = arr.name

function virtualize(ex, ::Type{<:Fiber{Tv, N, R, Lvls, Poss, Idxs}}, ctx, tag=gensym()) where {Tv, N, R, Lvls, Poss, Idxs}
    sym = Symbol(:tns_, tag)
    push!(ctx.preamble, :($sym = $ex))
    lvls = map(enumerate(Lvls.parameters)) do (n, Lvl)
        virtualize(:($sym.lvls[$n]), Lvl, ctx)
    end
    poss = map(enumerate(Poss.parameters)) do (n, Pos)
        virtualize(:($sym.poss[$n]), Pos, ctx)
    end
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($sym.idxs[$n]), Idx, ctx)
    end
    VirtualFiber(tag, sym, N, Tv, R, lvls, poss, idxs)
end

function virtual_refurl(fbr::VirtualFiber, p, i, mode, tail...)
    res = deepcopy(fbr)
    res.N = fbr.N - 1
    res.R = fbr.R + 1
    push!(res.poss, p)
    push!(res.idxs, i)
    return Access(res, mode, Any[tail...])
end

function Pigeon.visit!(node::Access{VirtualFiber}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle) where {Tv, Ti}
    if getname(ctx.idx) == getname(node.idxs[1])
        Access(virtual_unfurl(node.tns.lvls[node.tns.R], node.tns, ctx.ctx, node.mode, node.idxs...), node.mode, node.idxs)
    else
        node
    end
end

function Pigeon.visit!(node::Access{VirtualFiber}, ctx::Finch.AccessContext, ::Pigeon.DefaultStyle) where {Tv, Ti}
    if isempty(node.idxs)
        virtual_unfurl(node.tns.lvls[node.tns.R], node.tns, ctx.ctx, node.mode)
    else
        node
    end
end

struct VirtualSparseLevel
    ex
    Tv
    Ti
end

function virtualize(ex, ::Type{<:SparseLevel{Tv, Ti}}, ctx) where {Tv, Ti}
    VirtualSparseLevel(ex, Tv, Ti)
end

virtual_unfurl(lvl::VirtualSparseLevel, tns, ctx, mode::Pigeon.Read, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, walk(idx), tail...)

function virtual_unfurl(lvl::VirtualSparseLevel, tns, ctx, mode::Pigeon.Read, idx::Walk, tail...)
    R = tns.R
    sym = Symbol(:tns_, Pigeon.getname(tns), :_, R)
    my_i = Symbol(sym, :_i)
    my_p = Symbol(sym, :_p)
    my_p1 = Symbol(sym, :_p1)
    my_i1 = Symbol(sym, :_i1)

    Thunk(
        preamble = quote
            $my_p = $(lvl.ex).pos[$(ctx(tns.poss[R]))]
            $my_p1 = $(lvl.ex).pos[$(ctx(tns.poss[R])) + 1]
            if $my_p < $my_p1
                $my_i = $(lvl.ex).idx[$my_p]
                $my_i1 = $(lvl.ex).idx[$my_p1 - 1]
            else
                $my_i = 1
                $my_i1 = 0
            end
            println($(QuoteNode(Pigeon.getname(tns))), $my_i1)
        end,
        body = Pipeline([
            Phase(
                stride = (start) -> my_i1,
                body = (start, step) -> Stepper(
                    stride = (start) -> :($(lvl.ex).idx[$my_p]), #TODO cache me somehow
                    body = (start, step) -> Thunk(
                        preamble = quote
                            $my_i = $(lvl.ex).idx[$my_p]
                        end,
                        body = Cases([
                            :($step < $my_i) =>
                                Run(
                                    body = 0,
                                ),
                            true =>
                                Thunk(
                                    body = Spike(
                                        body = 0,
                                        tail = virtual_refurl(tns, Virtual{lvl.Tv}(my_p), Virtual{lvl.Ti}(my_i), mode, tail...),
                                    ),
                                    epilogue = quote
                                        $my_p += 1
                                    end
                                ),
                        ])
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(0)
            )
        ])
    )
end



struct VirtualDenseLevel
    ex
    Ti
end

function virtualize(ex, ::Type{<:DenseLevel{Ti}}, ctx) where {Ti}
    VirtualDenseLevel(ex, Ti)
end

virtual_unfurl(lvl::VirtualDenseLevel, tns, ctx, mode::Pigeon.Read, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, locate(idx), tail...)

function virtual_unfurl(lvl::VirtualDenseLevel, fbr, ctx, mode::Pigeon.Read, idx::Locate, tail...)
    R = fbr.R
    q = fbr.poss[R]
    p = Symbol(:tns_, getname(fbr), :_, R, :_p)

    Leaf(
        body = (i) -> Thunk(
            preamble = quote
                $p = ($(ctx(q)) - 1) * $(lvl.ex).I + $i
            end,
            body = virtual_refurl(fbr, Virtual{lvl.Ti}(p), i, mode, tail...),
        )
    )
end


struct VirtualScalarLevel
    ex
    Tv
end

function virtualize(ex, ::Type{<:ScalarLevel{Tv}}, ctx) where {Tv}
    VirtualScalarLevel(ex, Tv)
end

function virtual_unfurl(lvl::VirtualScalarLevel, fbr, ctx, ::Pigeon.Read)
    R = fbr.R
    val = Symbol(:tns_, getname(fbr), :_val)

    Thunk(
        preamble = quote
            $val = $(lvl.ex).val[$(ctx(fbr.poss[end]))]
        end,
        body = Virtual{lvl.Tv}(val)
    )
end