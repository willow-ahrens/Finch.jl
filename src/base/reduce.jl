Base.mapreducedim!

"""
    reduce_rep(op, tns, dims)

Return a trait object representing the result of reducing a tensor represented
by `tns` on `dims` by `op`.
"""
function reduce_rep(op, rep, dims) end

reduce_rep(op, tns, dims) =
    reduce_rep_def(op, tns, map(n -> n in dims ? Drop(n) : n, 1:ndims(tns))...)

function fixpoint_type(op, z, tns)
    S = Union{}
    T = typeof(z)
    while T != S
        S = T
        T = Union{T, Base.combine_eltypes(op, (T, eltype(tns)))}
    end
    T
end

reduce_rep_def(op, z, fbr::HollowData, idxs...) = HollowData(reduce_rep_def(op, z, fbr.lvl, idxs...))
function reduce_rep_def(op, z, lvl::HollowData, idx, idxs...)
    if op(z, default(lvl)) == z
        HollowData(reduce_rep_def(op, z, lvl.lvl, idxs...))
    else
        HollowData(reduce_rep_def(op, z, lvl.lvl, idxs...))
    end
end

reduce_rep_def(op, z, lvl::SparseData, idx::Drop, idxs...) = reduce_rep_def(op, z, lvl.lvl, idxs...)
function reduce_rep_def(op, z, lvl::SparseData, idx, idxs...)
    if op(z, default(lvl)) == z
        SparseData(reduce_rep_def(op, z, lvl.lvl, idxs...))
    else
        DenseData(reduce_rep_def(op, z, lvl.lvl, idxs...))
    end
end

reduce_rep_def(op, z, lvl::DenseData, idx::Drop, idxs...) = reduce_rep_def(op, z, lvl.lvl, idxs...)
reduce_rep_def(op, z, lvl::DenseData, idx, idxs...) = DenseData(reduce_rep_def(op, z, lvl.lvl, idxs...))

reduce_rep_def(op, z, lvl::ElementData) = ElementData(op, z, fixpoint_type(op, z, lvl))

reduce_rep_def(op, z, lvl::RepeatData, idx::Drop) = reduce_rep_def(op, ElementData(lvl.default, lvl.eltype))
reduce_rep_def(op, z, lvl::RepeatData, idx) = RepeatData(op, z, fixpoint_type(op, z))

function reduce!(op, bc::Broadcasted{FinchStyle{N}}, dims) where {N}

end