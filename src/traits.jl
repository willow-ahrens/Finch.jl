struct SparseData
    lvl
end

struct DenseData
    lvl
end

struct MaybeFill
    lvl
end

struct ElementData end

function getindex_output(lvl::SparseData, ind, inds...)
    sublvl = getindex_output(lvl.lvl, inds...)
    ndims(ind) == 0 && return MaybeFill(sublvl)
    return getindex_output_sparse(sublvl, ind)
end
getindex_output_sparse(sublvl::MaybeFill, ind) = getindex_output_sparse(sublvl.lvl, ind)
getindex_output_sparse(sublvl::Union{SparseData, DenseData, ElementData}, ind) = MaybeFill(SparseData(sublvl))
getindex_output_sparse(sublvl::Union{SparseData, DenseData, ElementData}, ind::Slice) = SparseData(sublvl)

function getindex_output(lvl::DenseData, ind, inds...)
    sublvl = getindex_output(lvl.lvl, inds...)
    ndims(ind) == 0 && return sublvl
    return getindex_output_dense(sublvl, ind)
end
getindex_output_dense(sublvl::Union{SparseData, DenseData, ElementData}, ind) = DenseData(sublvl)
getindex_output_dense(sublvl::MaybeFill, ind) = SparseData(sublvl.lvl)

getindex_output(lvl::ElementData) = lvl