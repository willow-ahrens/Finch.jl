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

Base.size(fbr::Fiber{Tv, N, R}) where {Tv, N, R} = map(dimension, fbr.lvls[R+1:end])

function Base.getindex(fbr::Fiber{Tv, N}, idxs::Vararg{<:Any, N}) where {Tv, N}
    readindex(fbr, idxs...)
end

function readindex(fbr::Fiber{Tv, N, R}, i, tail...) where {Tv, N, R}
    unfurl(fbr.arr.lvl[R], fbr, i, idxs...)
end

function refurl(fbr::Fiber{Tv, N, R}, p, i) where {Tv, N, R}
    return Fiber{Tv, N - 1, R + 1}(fbr.lvls, (fbr.poss..., p), (fbr.idxs..., i))
end



struct SparseLevel{Tv, Ti} <: AbstractVector{Any}
    Q::Ti
    I::Ti
    pos::Vector{Ti}
    idx::Vector{Ti}
end

dimension(lvl::SparseLevel) = lvl.I
cardinality(lvl::SparseLevel) = lvl.Q

function unfurl(lvl::SparseLevel{Tv, Ti}, fbr::Fiber{Tv, N, R}, i, tail...) where {Tv, Ti, N, R}
    q = R == 0 ? 1 : fbr.poss[R]
    r = searchsorted(@view(lvl.idx[lvl.pos[q]:lvl.pos[q + 1] - 1]), i)
    p = fbr.lvl.pos[fbr.q] + first(r) - 1
    length(r) == 0 ? zero(Tv) : readindex(refurl(fbr, p, i), tail...)
end

#represents a collection of DenseFibers
struct DenseLevel{Tv, Ti, N} <: AbstractVector{Any} #should have fiber eltype
    Q::Ti
    I::Ti
end

dimension(lvl::DenseLevel) = lvl.I
cardinality(lvl::DenseLevel) = lvl.Q

function unfurl(lvl::DenseLevel{Tv, Ti}, fbr::Fiber{Tv, N, R}, i, tail...) where {Tv, Ti, N, R}
    q = R == 0 ? 1 : fbr.poss[R]
    p = (q - 1) * lvl.I + i
    readindex(refurl(fbr, p, i), tail...)
end

#represents scalars
struct ScalarLevel{Tv, V <: AbstractVector{Tv}} <: AbstractVector{Tv}
    val::V
end

dimension(lvl::ScalarLevel) = ()
cardinality(lvl::ScalarLevel) = size(lvl.val)

function unfurl(lvl::ScalarLevel, fbr::Fiber{Tv, N, R}) where {Tv, N, R}
    q = R == 0 ? 1 : fbr.poss[R]
    return lvl.val[q]
end