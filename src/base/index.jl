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

Base.getindex(arr::Fiber, inds...) = getindex_helper(arr, to_indices(arr, inds)...)
@generated function getindex_helper(arr::Fiber, inds...)
    @assert ndims(arr) == length(inds)
    N = ndims(arr)

    inds_ndims = ndims.(inds)
    if sum(inds_ndims) == 0
        return quote
            scl = Scalar($(default(arr)))
            @finch scl[] = arr[inds...]
            return scl[]
        end
    end

    T = eltype(arr)
    syms = [Symbol(:inds_, n) for n = 1:N]
    modes = [Symbol(:mode_, n) for n = 1:N]
    coords = map(1:N) do n
        if ndims(inds[n]) == 0
            syms[n]
        elseif inds[n] <: Base.Slice
            modes[n]
        else
            :($(syms[n])[$(modes[n])])
        end
    end
    dst_modes = modes[filter(n->ndims(inds[n]) != 0, 1:N)]
    
    dst = fiber_ctr(getindex_rep(data_rep(arr), inds...))

    quote
        win = $dst
        ($(syms...), ) = (inds...,)
        @finch begin
            win .= $(default(arr))
            @loop($(reverse(dst_modes)...), win[$(dst_modes...)] = arr[$(coords...)])
        end
        return win
    end
end

Base.setindex!(arr::Fiber, src, inds...) = setindex_helper(arr, src, to_indices(arr, inds)...)
@generated function setindex_helper(arr::Fiber, src, inds...)
    @assert ndims(arr) == length(inds)
    @assert ndims(src) == sum(ndims.(inds))
    N = ndims(arr)

    T = eltype(arr)
    syms = [Symbol(:inds_, n) for n = 1:N]
    modes = [Symbol(:mode_, n) for n = 1:N]
    coords = map(1:N) do n
        if ndims(inds[n]) == 0
            syms[n]
        elseif inds[n] <: Base.Slice
            modes[n]
        else
            :($(syms[n])[$(modes[n])])
        end
    end
    src_modes = modes[filter(n->ndims(inds[n]) != 0, 1:N)]
    
    quote
        ($(syms...), ) = (inds...,)
        @finch begin
            @loop($(reverse(src_modes)...), arr[$(coords...)] = src[$(src_modes...)])
        end
        return src
    end
end