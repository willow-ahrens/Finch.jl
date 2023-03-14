Base.mapreducedim!

"""
    reduce_rep(op, tns, dims)

Return a trait object representing the result of reducing a tensor represented
by `tns` on `dims` by `op`.
"""
function reduce_rep(op, rep, dims) end

reduce_rep(op, tns::SolidData, dims) = SolidData(reduce_rep(op, tns.lvl, dims))
reduce_rep(op, tns::HollowData, dims) = HollowData(reduce_rep(op, tns.lvl, dims))

reduce_rep(op, tns::DenseData, dims) = reduce_rep_dense(op, reduce_rep(tns.lvl, dims), dims)
reduce_rep_sparse(op, tns, dims, subfbr::HollowData) = ndims(tns) in dims ? HollowData(subfbr.lvl) : SolidData(SparseData(subfbr.lvl))
reduce_rep_sparse(op, tns, dims, subfbr::SolidData) = ndims(tns) in dims ? HollowData(subfbr.lvl) : SolidData(SparseData(subfbr.lvl))

reduce_rep(op, tns::SparseData, dims) = reduce_rep_sparse(op, reduce_rep(tns.lvl, dims), dims)
reduce_rep_sparse(op, tns, dims, subfbr::HollowData) = ndims(tns) in dims ? HollowData(subfbr.lvl) : SolidData(SparseData(subfbr.lvl))
reduce_rep_sparse(op, tns, dims, subfbr::SolidData) = ndims(tns) in dims ? HollowData(subfbr.lvl) : SolidData(SparseData(subfbr.lvl))
    educe_rep(op, tns::HollowData, dims) = reducHollowData(reduce_rep(op, tns.lvl, dims))

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

function reduce!(op, bc::Broadcasted{FinchStyle{N}}, dims) where {N}
    T = Base.combine_eltypes(bc.f, bc.args::Tuple)
end