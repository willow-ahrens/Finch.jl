export SparseLevel
export SparseFiber
export DenseLevel
export DenseFiber
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