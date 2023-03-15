Base.mapreducedim!

"""
    reduce_rep(op, tns, dims)

Return a trait object representing the result of reducing a tensor represented
by `tns` on `dims` by `op`.
"""
function reduce_rep(op, rep, dims) end

reduce_rep(op, tns, dims) = reduce_rep_def(op, tns, map(n -> n in dims ? Drop(n) : n, 1:ndims(tns))...)

reduce_rep_def(op, fbr::HollowData, idxs...) = HollowData(reduce_rep_def(op, fbr.lvl, idxs...))

reduce_rep_def(op, lvl::SparseData, idx::Drop, idxs...) = HollowData(reduce_rep_def(op, lvl.lvl, idxs...))
reduce_rep_def(op, lvl::SparseData, idx, idxs...) = HollowData(SparseData(reduce_rep_def(op, lvl.lvl, idxs...)))
reduce_rep_def(op, lvl::SparseData, idx::Type{<:Base.Slice}, idxs...) = SparseData(reduce_rep_def(op, lvl.lvl, idxs...))

reduce_rep_def(op, lvl::DenseData, idx::Drop, idxs...) = reduce_rep_def(op, lvl.lvl, idxs...)
reduce_rep_def(op, lvl::DenseData, idx, idxs...) = SolidData(reduce_rep_def(op, lvl.lvl, idxs...))

reduce_rep_def(op, lvl::ElementData) = lvl

reduce_rep_def(op, lvl::RepeatData, idx::Drop) = SolidData(ElementData(lvl.default, lvl.eltype))
reduce_rep_def(op, lvl::RepeatData, idx) = SolidData(ElementData(lvl.default, lvl.eltype))
reduce_rep_def(op, lvl::RepeatData, idx::Type{<:AbstractUnitRange}) = SolidData(ElementData(lvl.default, lvl.eltype))

function reduce!(op, bc::Broadcasted{FinchStyle{N}}, dims) where {N}
    T = Base.combine_eltypes(bc.f, bc.args::Tuple)
end