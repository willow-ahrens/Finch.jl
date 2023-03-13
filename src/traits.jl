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

struct Drop{Idx}
    idx::Idx
end

"""
    getindex_rep(tns, idxs...)

Return a trait object representing the result of calling getindex(tns, idxs...)
on the tensor represented by `tns`.
"""
getindex_rep(tns, idxs...) = getindex_rep_def(tns, map(idx -> ndims(idx) == 0 ? Drop(idx) : idx, idxs)...)

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

getindex_rep_def(lvl::RepeatData, idx::Drop) = SolidData(ElementData(lvl.default, lvl.eltype))
getindex_rep_def(lvl::RepeatData, idx) = SolidData(ElementData(lvl.default, lvl.eltype))
getindex_rep_def(lvl::RepeatData, idx::Type{<:AbstractUnitRange}) = SolidData(ElementData(lvl.default, lvl.eltype))

"""
    broadcast_rep(bc)

Return a trait object representing the result of the broadcast bc on the tensor
represented by `tns`.
"""
function broadcast_rep(bc::Type{Broadcasted{Style, Axes, F, Args}}) where {Style, Axes, F, Args}
    args = map(broadcast_rep, Args.parameters)
    N = maximum(ndims.(args))
    args = map(arg -> (ExtrudeData^(N-ndims(arg)))(arg), args)
    broadcast_rep_def(bc, reduce(result_bcrep, args))
end
broadcast_rep(arr) = data_rep(arr)

combine_bcrep(a::SolidData, b) = result_bcrep(a.lvl, b)
combine_bcrep(a::HollowData, b::SolidData) = result_bcrep(a.lvl, b.lvl)
combine_bcrep(a::HollowData, b::DenseData) = result_bcrep(a.lvl, b)
combine_bcrep(a::HollowData, b::SparseData) = result_bcrep(a.lvl, b)
combine_bcrep(a::HollowData, b::RepeatData) = result_bcrep(a.lvl, b)
combine_bcrep(a::HollowData, b::HollowData) = HollowData(result_bcrep(a.lvl, b.lvl))

combine_bcrep(a::DenseData, b::ExtrudeData) = DenseData(result_bcrep(a.lvl, b.lvl))
combine_bcrep(a::DenseData, b::DenseData) = DenseData(result_bcrep(a.lvl, b.lvl))
combine_bcrep(a::DenseData, b::RepeatData) = DenseData(ElementData(nothing, b.lvl.eltype))

combine_bcrep(a::SparseData, b::ExtrudeData) = SparseData(result_bcrep(a.lvl, b.lvl))
combine_bcrep(a::SparseData, b::SparseData) = SparseData(result_bcrep(a.lvl, b.lvl))
combine_bcrep(a::SparseData, b::DenseData) = SparseData(result_bcrep(a.lvl, b.lvl))
combine_bcrep(a::SparseData, b::RepeatData) = SparseData(ElementData(nothing, b.lvl.eltype))

combine_bcrep(a::RepeatData, b::RepeatData) = RepeatData(nothing, b.lvl.eltype)
combine_bcrep(a::RepeatData, b::ExtrudeData) = RepeatData(nothing, b.lvl.eltype)

combine_bcrep(a::ElementData, b::ElementData) = ElementData(nothing, nothing)

broadcast_rep_def(bc, rep::SolidData) = SolidData(broadcast_rep_def(bc, rep.lvl))
broadcast_rep_def(bc, rep::HollowData) = HollowData(broadcast_rep_def(bc, rep.lvl))
broadcast_rep_def(bc, rep::SparseData) = SparseData(broadcast_rep_def(bc, rep.lvl))
broadcast_rep_def(bc, rep::ExtrudeData) = DenseData(broadcast_rep_def(bc, rep.lvl))
broadcast_rep_def(bc, rep::DenseData) = DenseData(broadcast_rep_def(bc, rep.lvl))
broadcast_rep_def(bc::Type{<:Broadcasted{Style, Axes, F, Args}}, rep::RepeatData) where {Style, Axes, F<:Function, Args} = RepeatData(F.instance(map(default, Args.parameters)...), Broadcast.combine_eltypes(F.instance, (Args.parameters...,)))
broadcast_rep_def(bc::Type{<:Broadcasted{Style, Axes, F, Args}}, rep::ElementData) where {Style, Axes, F<:Function, Args} = ElementData(F.instance(map(default, Args.parameters)...), Broadcast.combine_eltypes(F.instance, (Args.parameters...,)))

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