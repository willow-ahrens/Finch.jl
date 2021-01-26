module FiberArrays

export SparseLevel
export SparseFiber
export DenseLevel
export DenseFiber
export ScalarLevel

#represents consecutive groups of nonzero fibers
struct SparseLevel{Tv, Ti, N} <: AbstractVector{Any} #should have fiber eltype
    Q::Ti
    I::Ti
    pos::Vector{Ti}
    idx::Vector{Ti}
    child
end

dimension(lvl::SparseLevel) = (lvl.I, dimension(lvl.child)...)
Base.size(lvl::SparseLevel) = lvl.Q

struct SparseFiber{Tv, Ti, N} <: AbstractArray{Tv, N}
    q::Ti
    lvl::SparseLevel{Tv, Ti, N}
end

function Base.getindex(lvl::SparseLevel{Ti}, q) where {Ti}
    return SparseFiber(q, lvl)
end

Base.size(fbr::SparseFiber) = dimension(fbr.lvl)

function Base.getindex(fbr::SparseFiber{Tv, Ti}, i, tail...) where {Tv, Ti}
    r = searchsorted(@view(fbr.lvl.idx[fbr.lvl.pos[fbr.q]:fbr.lvl.pos[fbr.q + 1] - 1]), i)
    length(r) == 0 ? zero(Tv) : fbr.lvl.child[fbr.lvl.pos[fbr.q] + first(r) - 1][tail...]
end

#represents consecutive modes of nonzero fibers
struct DenseLevel{Tv, Ti, N} <: AbstractVector{Any} #should have fiber eltype
    Q::Ti
    I::Ti
    child
end

dimension(lvl::DenseLevel) = (lvl.I, dimension(lvl.child)...)
Base.size(lvl::DenseLevel) = lvl.Q

struct DenseFiber{Tv, Ti, N} <: AbstractArray{Tv, N}
    q::Ti
    lvl::DenseLevel{Tv, Ti, N}
end

function Base.getindex(lvl::DenseLevel{Ti}, q) where {Ti}
    return DenseFiber(q, lvl)
end

Base.size(fbr::DenseFiber) = dimension(fbr.lvl)

function Base.getindex(fbr::DenseFiber{Ti}, i, tail...) where {Ti}
    fbr.lvl.child[(fbr.q - 1) * fbr.lvl.I + i][tail...]
end

#represents scalars
struct ScalarLevel{Tv, V <: AbstractVector{Tv}} <: AbstractVector{Tv}
    val::V
end

dimension(lvl::ScalarLevel) = ()
Base.size(lvl::ScalarLevel) = size(lvl.val)

function Base.getindex(lvl::ScalarLevel{Ti}, q) where {Ti}
    return lvl.val[q]
end

#okay, so the next step is coiteration

end