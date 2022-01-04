export SparseLevel
export SparseFiber
export DenseLevel
export DenseFiber
export ScalarLevel

struct FiberArray{Tv, N, Levels<:NTuple{N}} <: AbstractArray{Tv, N}
    levels::Levels
end

#represents a collection of SparseFibers
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

function Base.getindex(lvl::SparseLevel, q)
    return SparseFiber(q, lvl)
end

Base.size(fbr::SparseFiber) = dimension(fbr.lvl)

function Base.getindex(fbr::SparseFiber{Tv, Ti}, i, tail...) where {Tv, Ti}
    r = searchsorted(@view(fbr.lvl.idx[fbr.lvl.pos[fbr.q]:fbr.lvl.pos[fbr.q + 1] - 1]), i)
    length(r) == 0 ? zero(Tv) : fbr.lvl.child[fbr.lvl.pos[fbr.q] + first(r) - 1][tail...]
end

#represents a collection of DenseFibers
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

function Base.getindex(lvl::DenseLevel, q)
    return DenseFiber(q, lvl)
end

Base.size(fbr::DenseFiber) = dimension(fbr.lvl)

function Base.getindex(fbr::DenseFiber, i, tail...)
    fbr.lvl.child[(fbr.q - 1) * fbr.lvl.I + i][tail...]
end

#represents scalars
struct ScalarLevel{Tv, V <: AbstractVector{Tv}} <: AbstractVector{Tv}
    val::V
end

dimension(lvl::ScalarLevel) = ()
Base.size(lvl::ScalarLevel) = size(lvl.val)

function Base.getindex(lvl::ScalarLevel, q)
    return lvl.val[q]
end

struct ScalarFiber{Tv, Ti, V} <: AbstractArray{Tv, 0}
    q::Ti
    lvl::ScalarLevel{Tv, V}
end

function Base.getindex(fbr::ScalarFiber)
    fbr.lvl.val[fbr.q]
end

function lower_access(node::Virtual{T}, ctx) where {T <: ScalarFiber}
    return :($(node.expr).lvl.val[$(node.expr).q])
end