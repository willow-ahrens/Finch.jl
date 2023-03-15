using Base.Broadcast: Broadcasted

"""
    SparseData(lvl)
    
Represents a tensor `A` where `A[:, ..., :, i]` is sometimes entirely default(lvl)
and is sometimes represented by `lvl`.
"""
struct SparseData
    lvl
end
Finch.isliteral(::SparseData) = false

Base.ndims(fbr::SparseData) = 1 + ndims(fbr.lvl)
default(fbr::SparseData) = default(fbr.lvl)

"""
    DenseData(lvl)
    
Represents a tensor `A` where each `A[:, ..., :, i]` is represented by `lvl`.
"""
struct DenseData
    lvl
end
Finch.isliteral(::DenseData) = false
default(fbr::DenseData) = default(fbr.lvl)

Base.ndims(fbr::DenseData) = 1 + ndims(fbr.lvl)

"""
    ExtrudeData(lvl)
    
Represents a tensor `A` where `A[:, ..., :, 1]` is the only slice, and is represented by `lvl`.
"""
struct ExtrudeData
    lvl
end
Finch.isliteral(::ExtrudeData) = false
default(fbr::ExtrudeData) = default(fbr.lvl)

Base.ndims(fbr::ExtrudeData) = 1 + ndims(fbr.lvl)

"""
    HollowData(lvl)
    
Represents a tensor which is represented by `lvl` but is sometimes entirely `default(lvl)`.
"""
struct HollowData
    lvl
end
Finch.isliteral(::HollowData) = false
default(fbr::HollowData) = default(fbr.lvl)

Base.ndims(fbr::HollowData) = ndims(fbr.lvl)

"""
    ElementData(default, eltype)
    
Represents a scalar element of type `eltype` and default `default`.
"""
struct ElementData
    default
    eltype
end
Finch.isliteral(::ElementData) = false
default(fbr::ElementData) = fbr.default

Base.ndims(fbr::ElementData) = 0

"""
    RepeatData(default, eltype)
    
Represents an array A[i] with many repeated runs of elements of type `eltype`
and default `default`.
"""
struct RepeatData
    default
    eltype
end
Finch.isliteral(::RepeatData) = false
default(fbr::RepeatData) = fbr.default

Base.ndims(fbr::RepeatData) = 1

"""
    data_rep(tns)

Return a trait object representing everything that can be learned about the data
based on the storage format (type) of the tensor
"""
data_rep(tns) = (DenseData^(ndims(tns)))(ElementData(default(tns), eltype(tns)))

data_rep(T::Type{<:Number}) = ElementData(zero(T), T)

"""
    data_rep(tns)

Normalize a trait object to collapse subfiber information into the parent fiber.
"""
collapse_rep(fbr) = fbr

collapse_rep(fbr::HollowData) = collapse_rep(fbr, fbr.lvl)
collapse_rep(::HollowData, lvl::HollowData) = collapse_rep(lvl)
collapse_rep(::HollowData, lvl) = HollowData(collapse_rep(lvl))

collapse_rep(fbr::DenseData) = collapse_rep(fbr, fbr.lvl)
collapse_rep(::DenseData, lvl::HollowData) = collapse_rep(SparseData(lvl.lvl))
collapse_rep(::DenseData, lvl) = DenseData(collapse_rep(lvl))

collapse_rep(fbr::SparseData) = collapse_rep(fbr, fbr.lvl)
collapse_rep(::SparseData, lvl::HollowData) = collapse_rep(SparseData(lvl.lvl))
collapse_rep(::SparseData, lvl) = SparseData(collapse_rep(lvl))

collapse_rep(::RepeatData, lvl::HollowData) = collapse_rep(SparseData(lvl.lvl))
collapse_rep(::RepeatData, lvl) = DenseData(collapse_rep(lvl))

"""
    fiber_ctr(tns)

Return an expression that would construct a fiber suitable to hold data with a
representation described by `tns`. Assumes representation is collapsed.
"""
function fiber_ctr end
fiber_ctr(fbr::HollowData) = fiber_ctr_hollow(fbr.lvl)
fiber_ctr_hollow(fbr::DenseData) = :(Fiber!($(level_ctr(SparseData(fbr.lvl)))))
fiber_ctr_hollow(fbr::RepeatData) = :(Fiber!($(level_ctr(SparseData(ElementData(fbr.default, fbr.eltype)))))) #This is the best format we have for this case right now
fiber_ctr_hollow(fbr::SparseData) = :(Fiber!($(level_ctr(fbr))))
fiber_ctr(fbr) = :(Fiber!($(level_ctr(fbr))))

level_ctr(fbr::SparseData) = :(SparseList($(level_ctr(fbr.lvl))))
level_ctr(fbr::DenseData) = :(Dense($(level_ctr(fbr.lvl))))
level_ctr(fbr::RepeatData) = :(Repeat{$(fbr.default), $(fbr.eltype)}())
level_ctr(fbr::ElementData) = :(Element{$(fbr.default), $(fbr.eltype)}())