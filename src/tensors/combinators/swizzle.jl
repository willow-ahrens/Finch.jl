struct SwizzleArray{dims, Body} <: AbstractCombinator
    body::Body
end

SwizzleArray(body, dims) = SwizzleArray{dims}(body)
SwizzleArray{dims}(body::Body) where {dims, Body} = SwizzleArray{dims, Body}(body)

Base.ndims(arr::SwizzleArray) = ndims(typeof(arr))
Base.ndims(::Type{SwizzleArray{dims, Body}}) where {dims, Body} = ndims(Body)
Base.eltype(arr::SwizzleArray) = eltype(arr.body)
default(arr::SwizzleArray) = default(typeof(arr))
default(::Type{SwizzleArray{dims, Body}}) where {dims, Body} = default(Body)

Base.size(arr::SwizzleArray{dims}) where {dims} = map(n->size(arr.body)[n], dims)

Base.show(io::IO, ex::SwizzleArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::SwizzleArray{dims}) where {dims}
	print(io, "SwizzleArray($(ex.body), $(dims)")
end

#Base.getindex(arr::SwizzleArray, i...) = ...

struct VirtualSwizzleArray <: AbstractVirtualCombinator
    body
    dims
end

#is_injective(lvl::VirtualSwizzleArray, ctx) = is_injective(lvl.body, ctx)
#is_atomic(lvl::VirtualSwizzleArray, ctx) = is_atomic(lvl.body, ctx)

Base.show(io::IO, ex::VirtualSwizzleArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualSwizzleArray)
	print(io, "VirtualSwizzleArray($(ex.body), $(ex.dims))")
end

Base.summary(io::IO, ex::VirtualSwizzleArray) = print(io, "VSwizzle($(summary(ex.body)), $(ex.dims))")

FinchNotation.finch_leaf(x::VirtualSwizzleArray) = virtual(x)

function virtualize(ex, ::Type{SwizzleArray{dims, Body}}, ctx) where {dims, Body}
    VirtualSwizzleArray(virtualize(:($ex.body), Body, ctx), dims)
end

swizzle(body, dims::Int...) = SwizzleArray(body, dims)
swizzle(body::SwizzleArray{dims}, dims_2::Int...) where {dims} = SwizzleArray(body.body, ntuple(n-> dims[dims_2[n]], ndims(body)))

function virtual_call(::typeof(swizzle), ctx, body, dims...)
    @assert All(isliteral)(dims)
    VirtualSwizzleArray(body, map(dim -> dim.val, collect(dims)))
end
unwrap(ctx, arr::VirtualSwizzleArray, var) = call(swizzle, unwrap(ctx, arr.body, var), arr.dims...)

lower(tns::VirtualSwizzleArray, ctx::AbstractCompiler, ::DefaultStyle) = :(SwizzleArray($(ctx(tns.body)), $((tns.dims...,))))

function virtual_default(arr::VirtualSwizzleArray, ctx::AbstractCompiler)
    virtual_default(arr.body, ctx)
end

function virtual_size(arr::VirtualSwizzleArray, ctx::AbstractCompiler)
    virtual_size(arr.body, ctx)[arr.dims]
end

function virtual_resize!(arr::VirtualSwizzleArray, ctx::AbstractCompiler, dims...)
    virtual_resize!(arr.body, ctx, dims[invperm(arr.dims)]...)
end

function instantiate(arr::VirtualSwizzleArray, ctx, mode, protos)
    VirtualSwizzleArray(instantiate(arr.body, ctx, mode, protos), arr.dims)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualSwizzleArray) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::VirtualSwizzleArray)
    stylize_access(node, ctx, tns.body)
end

getroot(tns::VirtualSwizzleArray) = getroot(tns.body)

function lower_access(ctx::AbstractCompiler, node, tns::VirtualSwizzleArray)
    if !isempty(node.idxs)
        error("SwizzleArray not lowered completely")
    end
    lower_access(ctx, node, tns.body)
end