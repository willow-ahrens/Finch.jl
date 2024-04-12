struct SwizzleArray{dims, Body} <: AbstractCombinator
    body::Body
end

SwizzleArray(body, dims) = SwizzleArray{dims}(body)
SwizzleArray{dims}(body::Body) where {dims, Body} = SwizzleArray{dims, Body}(body)

Base.ndims(arr::SwizzleArray) = ndims(typeof(arr))
Base.ndims(::Type{SwizzleArray{dims, Body}}) where {dims, Body} = ndims(Body)
Base.eltype(arr::SwizzleArray) = eltype(typeof(arr.body))
Base.eltype(::Type{SwizzleArray{dims, Body}}) where {dims, Body} = eltype(Body)
default(arr::SwizzleArray) = default(typeof(arr))
default(::Type{SwizzleArray{dims, Body}}) where {dims, Body} = default(Body)

Base.to_indices(A::SwizzleArray, I::Tuple{AbstractVector}) = Base.to_indices(A, axes(A), I)

function Base.getindex(arr::SwizzleArray{perm}, inds...) where {perm}
    inds_2 = Base.to_indices(arr, inds)
    perm_2 = collect(invperm(perm))
    res = getindex(arr.body, inds_2[perm_2]...)
    perm_3 = sortperm(filter(n -> ndims(inds_2[n]) > 0, perm_2))
    if issorted(perm_3)
        return res
    else 
        return swizzle(res, perm_3...)
    end
end

function Base.setindex!(arr::SwizzleArray{perm}, v, inds...) where {perm}
    inds_2 = Base.to_indices(arr, inds)
    perm_2 = collect(invperm(perm))
    res = setindex!(arr.body, v, inds_2[perm_2]...)
    arr
end

Base.size(arr::SwizzleArray{dims}) where {dims} = map(n->size(arr.body)[n], dims)

Base.show(io::IO, ex::SwizzleArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::SwizzleArray{dims}) where {dims}
	print(io, "SwizzleArray($(ex.body), $(dims))")
end

#Base.getindex(arr::SwizzleArray, i...) = ...

struct VirtualSwizzleArray <: AbstractVirtualCombinator
    body
    dims
end

#is_injective(ctx, lvl::VirtualSwizzleArray) = is_injective(ctx, lvl.body)
#is_atomic(ctx, lvl::VirtualSwizzleArray) = is_atomic(ctx, lvl.body)

Base.show(io::IO, ex::VirtualSwizzleArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualSwizzleArray)
	print(io, "VirtualSwizzleArray($(ex.body), $(ex.dims))")
end

Base.summary(io::IO, ex::VirtualSwizzleArray) = print(io, "VSwizzle($(summary(ex.body)), $(ex.dims))")

FinchNotation.finch_leaf(x::VirtualSwizzleArray) = virtual(x)

function virtualize(ctx, ex, ::Type{SwizzleArray{dims, Body}}) where {dims, Body}
    VirtualSwizzleArray(virtualize(ctx, :($ex.body), Body), dims)
end

"""
    swizzle(tns, dims)

Create a `SwizzleArray` to transpose any tensor `tns` such that
```
    swizzle(tns, dims)[i...] == tns[i[dims]]
```
"""
swizzle(body, dims::Int...) = SwizzleArray(body, dims)
swizzle(body::SwizzleArray{dims}, dims_2::Int...) where {dims} = SwizzleArray(body.body, ntuple(n-> dims[dims_2[n]], ndims(body)))

function virtual_call(ctx, ::typeof(swizzle), body, dims...)
    @assert All(isliteral)(dims)
    VirtualSwizzleArray(body, map(dim -> dim.val, collect(dims)))
end
unwrap(ctx, arr::VirtualSwizzleArray, var) = call(swizzle, unwrap(ctx, arr.body, var), arr.dims...)

lower(tns::VirtualSwizzleArray, ctx::AbstractCompiler, ::DefaultStyle) = :(SwizzleArray($(ctx(tns.body)), $((tns.dims...,))))

function virtual_default(ctx::AbstractCompiler, arr::VirtualSwizzleArray)
    virtual_default(ctx, arr.body)
end

function virtual_size(ctx::AbstractCompiler, arr::VirtualSwizzleArray)
    virtual_size(ctx, arr.body)[arr.dims]
end

function virtual_resize!(ctx::AbstractCompiler, arr::VirtualSwizzleArray, dims...)
    virtual_resize!(ctx, arr.body, dims[invperm(arr.dims)]...)
end

function instantiate(arr::VirtualSwizzleArray, ctx, mode, protos)
    VirtualSwizzleArray(instantiate(arr.body, ctx, mode, protos), arr.dims)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualSwizzleArray) = ctx(node.body)
function stylize_access(ctx::Stylize{<:AbstractCompiler}, node, tns::VirtualSwizzleArray)
    stylize_access(ctx, node, tns.body)
end

getroot(tns::VirtualSwizzleArray) = getroot(tns.body)

function lower_access(ctx::AbstractCompiler, node, tns::VirtualSwizzleArray)
    if !isempty(node.idxs)
        error("SwizzleArray not lowered completely")
    end
    lower_access(ctx, node, tns.body)
end