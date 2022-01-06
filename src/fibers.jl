export SparseLevel
export DenseLevel
export ScalarLevel

struct Fiber{Tv, N, R, Lvls<:Tuple, Poss<:Tuple, Idxs<:Tuple} <: AbstractArray{Tv, N}
    lvls::Lvls
    poss::Poss
    idxs::Idxs
end

Fiber{Tv}(lvls::Lvls) where {Tv, N, Lvls} = Fiber{Tv, length(lvls) - 1, 1}(lvls, (true,), ())
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



abstract type AbstractVirtualFiber end

Pigeon.make_style(root::Loop, ctx::Finch.LowerJuliaContext, node::Access{<:AbstractVirtualFiber}) =
    root.idxs[1] == node.idxs[1] ? Finch.ChunkStyle() : DefaultStyle()

mutable struct VirtualFiber <: AbstractVirtualFiber
    name
    ex
    N
    Tv
    R
    lvls
    poss
    idxs
end

function Pigeon.lower_axes(arr::VirtualFiber, ctx::LowerJuliaContext) where {T <: AbstractArray}
    dims = map(i -> gensym(Symbol(arr.name, :_, i, :_stop)), 1:arr.ndims)
    for (dim, lvl) in zip(dims, lvls)
        #Could unroll more manually, but I'm not convinced it's worth it.
        push!(ctx.preamble, :($dim = dimension($lvl)))
    end
    return map(i->Extent(1, Virtual{Int}(dims[i])), 1:arr.ndims)
end

function virtualize(ex, ::Type{<:Fiber{Tv, N, R, Lvls, Poss, Idxs}}, ctx; tag=gensym(), kwargs...) where {Tv, N, R, Lvls, Poss, Idxs}
    sym = Symbol(:tns_, tag)
    push!(ctx.preamble, :($sym = $ex))
    lvls = map(enumerate(Lvls.parameters)) do (n, Lvl)
        virtualize(:($ex.poss[$n]), Lvl, ctx)
    end
    poss = map(enumerate(Poss.parameters)) do (n, Pos)
        virtualize(:($ex.poss[$n]), Pos, ctx)
    end
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($ex.idxs[$n]), Idx, ctx)
    end
    VirtualFiber(tag, sym, N, Tv, R, lvls, poss, idxs)
end

function virtual_refurl(fbr::VirtualFiber, p, i)
    res = deepcopy(fbr)
    res.N = fbr.N - 1
    res.R = fbr.R + 1
    push!(res.poss, p)
    push!(res.idxs, i)
    return res
end

function Pigeon.visit!(node::Access{VirtualFiber}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle) where {Tv, Ti}
    if ctx.idx == node.idxs[1]
        refurl = (p, i) -> Access(virtual_refurl(node.tns, p, i), node.mode, node.idxs[2:end])
        virtual_unfurl(fbr.lvls[R], ctx, node.tns, refurl)
    else
        node
    end
end


struct VirtualSparseLevel
    ex
    Tv
    Ti
end

function virtualize(ex, ::Type{<:SparseLevel{Tv, Ti}}, ctx; kwargs...) where {Tv, Ti}
    VirtualSparseLevel(ex, Tv, Ti)
end

function virtual_unfurl(lvl::VirtualSparseLevel, ctx::Finch.ChunkifyContext, ::Pigeon.Read, tns::VirtualFiber, refurl)
    r = fiber.R
    name = Symbol(:tns_, Pigeon.getname(tns), :_, R)
    my_p = Symbol(name, :_p)

    q = fbr.poss[R]
    p = (q - 1) * lvl.I + i
    Virtual{Ti}((q - 1) * lvl.I + i)
    Thunk(
        preamble = quote
            $my_p = $(lvl.ex).pos[$(tns.poss[R])]
            $my_i = 1
            $my_i′ = $(lvl.ex).idx[$my_p]
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
                                tail = refurl(Virtual{lvl.T}(my_p), Virtual{lvl.Ti}(my_i′)),
                            ),
                            epilogue = quote
                                $my_p += 1
                                $my_i = $my_i′ + 1
                                $my_i′ = $(lvl.ex).idx[$my_p]
                            end
                        ),
                ])
            end
        )
    )
end