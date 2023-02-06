"""
    SparseData(lvl)
    
Represents a tensor `A` where `A[i, :, ..., :]` is sometimes entirely default(lvl)
and is sometimes represented by `lvl`.
"""
struct SparseData
    lvl
end

"""
    DenseData(lvl)
    
Represents a tensor `A` where each `A[i, :, ..., :]` is represented by `lvl`.
"""
struct DenseData
    lvl
end

"""
    HollowData(lvl)
    
Represents a tensor which is represented by `lvl` but is sometimes entirely `default(lvl)`.
"""
struct HollowData
    lvl
end

"""
    SolidData(lvl)
    
Represents a tensor which is represented by `lvl`
"""
struct SolidData
    lvl
end

"""
    ElementData(eltype, default)
    
Represents a scalar element of type `eltype` and default `default`.
"""
struct ElementData
    eltype
    default
end

"""
    RepeatData(eltype, default)
    
Represents an array A[i] with many repeated runs of elements of type `eltype`
and default `default`.
"""
struct RepeatData
    eltype
    default
end

#const SolidData = Union{DenseData, SparseData, RepeatData, ElementData}

"""
    data_rep(tns)

Return a trait object representing everything that can be learned about the data
based on the storage format (type) of the tensor
"""
data_rep(tns) = SolidData(foldl([DenseData for _ in 1:ndims(tns)], init = ElementData(eltype(tns), default(tns))))

struct Drop{Idx}
    idx::Idx
end

"""
    getindex_rep(tns, idxs...)

Return a trait object representing the result of calling getindex(tns, idxs...)
on the tensor represented by `tns`.
"""
getidxex_rep(tns, idxs...) = getidxex_rep_def(tns, map(idx -> ndims(idx) == 0 ? Drop(idx) : idx, idxs)...)

getindex_rep_def(fbr::SolidData, idxs...) = getindex_rep_def(fbr.lvl, idxs...)
getindex_rep_def(fbr::HollowData, idxs...) = getindex_rep_def_hollow(getindex_rep_def(fbr.lvl, idxs...))
getindex_rep_def_hollow(subfbr::SolidData, idxs...) = HollowData(subfbr.lvl)
getindex_rep_def_hollow(subfbr::HollowData, idxs...) = subfbr

getindex_rep_def(lvl::SparseData, idx, idxs...) = getindex_rep_def_sparse(getindex_rep_def(lvl.lvl, idxs...), idx)
getindex_rep_def_sparse(subfbr::HollowData, idx::Drop) = HollowData(subfbr.lvl)
getindex_rep_def_sparse(subfbr::HollowData, idx) = HollowData(SparseData(subfbr.lvl))
getindex_rep_def_sparse(subfbr::HollowData, idx::Type{<:Base.Slice}) = HollowData(SparseData(subfbr.lvl))
getindex_rep_def_sparse(subfbr::SolidData, idx::Drop) = HollowData(subfbr.lvl)
getindex_rep_def_sparse(subfbr::SolidData, idx) = HollowData(SparseData(subfbr.lvl))
getindex_rep_def_sparse(subfbr::SolidData, idx::Type{<:Base.Slice}) = SolidData(SparseData(subfbr.lvl))

getindex_rep_def(lvl::DenseData, idx, idxs...) = getindex_rep_def_dense(getindex_rep_def(lvl.lvl, idxs...), idx)
getindex_rep_def_dense(subfbr::HollowData, idx::Drop) = HollowData(subfbr.lvl)
getindex_rep_def_dense(subfbr::HollowData, idx) = HollowData(DenseData(subfbr.lvl))
getindex_rep_def_dense(subfbr::SolidData, idx::Drop) = SolidData(subfbr.lvl)
getindex_rep_def_dense(subfbr::SolidData, idx) = SolidData(DenseData(subfbr.lvl))

getindex_rep_def(lvl::ElementData) = SolidData(lvl)

getindex_rep_def(lvl::RepeatData, idx::Drop) = SolidData(ElementLevel(lvl.eltype, lvl.default))
getindex_rep_def(lvl::RepeatData, idx) = SolidData(DenseLevel(ElementLevel(lvl.eltype, lvl.default)))
getindex_rep_def(lvl::RepeatData, idx::Type{<:AbstractUnitRange}) = SolidData(lvl)


"""
    fiber_ctr(tns)

Return an expression that would construct a fiber suitable to hold data with a
representation described by `tns`
"""
fiber_ctr(fbr::SolidData) = :(Fiber($(fiber_ctr_solid(fbr.lvl))))
fiber_ctr_solid(lvl::DenseData) = :(Dense($(fiber_ctr_solid(lvl.lvl))))
fiber_ctr_solid(lvl::SparseData) = :(SparseList($(fiber_ctr_solid(lvl.lvl))))
fiber_ctr_solid(lvl::ElementData) = :(Element{$(lvl.default), $(lvl.eltype)}())
fiber_ctr_solid(lvl::RepeatData) = :(Repeat{$(lvl.default), $(lvl.eltype)}())
fiber_ctr(fbr::HollowData) = :(Fiber($(fiber_ctr_hollow(fbr.lvl))))
fiber_ctr_hollow(lvl::DenseData) = :(SparseList($(fiber_ctr_solid(lvl.lvl))))
fiber_ctr_hollow(lvl::SparseData) = :(SparseList($(fiber_ctr_solid(lvl.lvl))))
fiber_ctr_hollow(lvl::ElementData) = :(Element{$(lvl.default), $(lvl.eltype)}())
fiber_ctr_hollow(lvl::RepeatData) = :(Repeat{$(lvl.default), $(lvl.eltype)}())
