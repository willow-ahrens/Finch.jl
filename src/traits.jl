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
    SolidData(lvl)
    
Represents a tensor which is represented by `lvl`
"""
struct SolidData
    lvl
end
Finch.isliteral(::SolidData) = false
default(fbr::SolidData) = default(fbr.lvl)

Base.ndims(fbr::SolidData) = ndims(fbr.lvl)

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

#const SolidData = Union{DenseData, SparseData, RepeatData, ElementData}

"""
    data_rep(tns)

Return a trait object representing everything that can be learned about the data
based on the storage format (type) of the tensor
"""
data_rep(tns) = SolidData((DenseData^(ndims(tns)))(ElementData(default(tns), eltype(tns))))

data_rep(T::Type{<:Number}) = ElementData(zero(T), T)

"""
    fiber_ctr(tns)

Return an expression that would construct a fiber suitable to hold data with a
representation described by `tns`
"""
fiber_ctr(fbr::SolidData) = :(Fiber!($(fiber_ctr_solid(fbr.lvl))))
fiber_ctr_solid(lvl::DenseData) = :(Dense($(fiber_ctr_solid(lvl.lvl))))
fiber_ctr_solid(lvl::SparseData) = :(SparseList($(fiber_ctr_solid(lvl.lvl))))
fiber_ctr_solid(lvl::ElementData) = :(Element{$(lvl.default), $(lvl.eltype)}())
fiber_ctr_solid(lvl::RepeatData) = :(Repeat{$(lvl.default), $(lvl.eltype)}())
fiber_ctr(fbr::HollowData) = :(Fiber!($(fiber_ctr_hollow(fbr.lvl))))
fiber_ctr_hollow(lvl::DenseData) = :(SparseList($(fiber_ctr_solid(lvl.lvl))))
fiber_ctr_hollow(lvl::SparseData) = :(SparseList($(fiber_ctr_solid(lvl.lvl))))
fiber_ctr_hollow(lvl::ElementData) = :(Element{$(lvl.default), $(lvl.eltype)}())
fiber_ctr_hollow(lvl::RepeatData) = :(Repeat{$(lvl.default), $(lvl.eltype)}())