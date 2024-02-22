struct Drop{Idx}
    idx::Idx
end

"""
    getindex_rep(tns, idxs...)

Return a trait object representing the result of calling getindex(tns, idxs...)
on the tensor represented by `tns`. Assumes traits are in collapsed form.
"""
getindex_rep(tns, idxs...) = collapse_rep(getindex_rep_def(tns, map(idx -> ndims(idx) == 0 ? Drop(idx) : idx, idxs)...))

getindex_rep_def(fbr::HollowData, idxs...) = HollowData(getindex_rep_def(fbr.lvl, idxs...))

getindex_rep_def(lvl::SparseData, idx::Drop, idxs...) = HollowData(getindex_rep_def(lvl.lvl, idxs...))
getindex_rep_def(lvl::SparseData, idx, idxs...) = HollowData(SparseData(getindex_rep_def(lvl.lvl, idxs...)))
getindex_rep_def(lvl::SparseData, idx::Type{<:Base.Slice}, idxs...) = SparseData(getindex_rep_def(lvl.lvl, idxs...))

getindex_rep_def(lvl::DenseData, idx::Drop, idxs...) = getindex_rep_def(lvl.lvl, idxs...)
getindex_rep_def(lvl::DenseData, idx, idxs...) = DenseData(getindex_rep_def(lvl.lvl, idxs...))

getindex_rep_def(lvl::ElementData) = lvl

getindex_rep_def(lvl::RepeatData, idx::Drop) = SolidData(ElementData(lvl.default, lvl.eltype))
getindex_rep_def(lvl::RepeatData, idx) = SolidData(ElementData(lvl.default, lvl.eltype))
getindex_rep_def(lvl::RepeatData, idx::Type{<:AbstractUnitRange}) = SolidData(ElementData(lvl.default, lvl.eltype))

Base.getindex(arr::Tensor, inds::AbstractVector) = getindex_helper(arr, to_indices(arr, axes(arr), (inds,)))
Base.getindex(arr::Tensor, inds...) = getindex_helper(arr, to_indices(arr, inds))
@staged function getindex_helper(arr, inds)
    inds <: Type{<:Tuple}
    inds = inds.parameters
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
    exts = Expr(:block, (:($idx = _) for idx in reverse(dst_modes))...)
    
    dst = fiber_ctr(getindex_rep(data_rep(arr), inds...))

    quote
        win = $dst
        ($(syms...), ) = (inds...,)
        @finch begin
            win .= $(default(arr))
            $(Expr(:for, exts, quote
                win[$(dst_modes...)] = arr[$(coords...)]
            end))
        end
        return win
    end
end

Base.setindex!(arr::Tensor, src, inds...) = setindex_helper(arr, src, to_indices(arr, inds))
@staged function setindex_helper(arr, src, inds)
    inds <: Type{<:Tuple}
    inds = inds.parameters
    @assert ndims(arr) == length(inds)
    @assert sum(ndims.(inds)) == 0 || (ndims(src) == sum(ndims.(inds)))
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
    exts = Expr(:block, (:($idx = _) for idx in reverse(src_modes))...)
    rhs = sum(ndims.(inds)) == 0 ? :src : :(src[$(src_modes...)])

    quote
        ($(syms...), ) = (inds...,)
        @finch begin
            $(Expr(:for, exts, quote
                arr[$(coords...)] = $rhs
            end))
        end
        return src
    end
end