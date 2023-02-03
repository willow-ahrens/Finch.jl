@kwdef struct StaticOffset{Delta, Dim}
    delta::Delta
    dim::Dim = nodim
end

Base.show(io::IO, ex::StaticOffset) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::StaticOffset)
	print(io, "StaticOffset(delta = ")
	print(io, ex.delta)
	print(io, ")")
end

IndexNotation.value_instance(arg::StaticOffset) = arg

Base.size(vec::StaticOffset) = (stop(vec.dim) - start(vec.dim) + 1,)

function Base.getindex(arr::StaticOffset, i)
    arr.delta - i
end

struct Offset end

Base.show(io::IO, ex::Offset) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Offset)
	print(io, "Offset()")
end

IndexNotation.value_instance(arg::Offset) = arg

const offset = Offset()

Base.size(vec::Offset) = (nodim, nodim)

function Base.getindex(arr::Offset, d, i)
    StaticOffset(delta = d)[i]
end

@kwdef struct VirtualStaticOffset
    delta
    dim = nodim
end

Base.show(io::IO, ex::VirtualStaticOffset) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualStaticOffset)
	print(io, "VirtualStaticOffset(delta = ")
	print(io, ex.delta)
	print(io, ")")
end

IndexNotation.isliteral(::VirtualStaticOffset) =  false

function virtualize(ex, ::Type{StaticOffset{Delta, Dim}}, ctx) where {Delta, Dim}
    delta = cache!(ctx, :delta, virtualize(:($ex.delta), Delta, ctx))
    dim = virtualize(:($ex.dim), Dim, ctx)
    return VirtualStaticOffset(delta, dim)
end

(ctx::Finch.LowerJulia)(tns::VirtualStaticOffset) = :(StaticOffset($(ctx(tns.delta)), $(ctx(tns.dim))))

function Finch.virtual_size(arr::VirtualStaticOffset, ctx::Finch.LowerJulia)
    return (arr.dim,)
end
Finch.virtual_resize!(arr::VirtualStaticOffset, ctx::Finch.LowerJulia, dim) = (VirtualStaticOffset(;kwfields(arr)..., dim=dim), shiftdim(dim, call(-, tns.delta)))

struct VirtualOffset end

Base.show(io::IO, ex::VirtualOffset) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualOffset)
	print(io, "VirtualOffset()")
end

IndexNotation.isliteral(::VirtualOffset) =  false

virtualize(ex, ::Type{Offset}, ctx) = VirtualOffset()

(ctx::Finch.LowerJulia)(tns::VirtualOffset) = :(Offset($(ctx(tns.I))))

Finch.virtual_size(arr::VirtualOffset, ctx::Finch.LowerJulia) = (nodim, deferdim)
Finch.virtual_resize!(arr::VirtualOffset, ctx::Finch.LowerJulia, dim1, dim2) = (arr, nodim)

function declare_dimensions_access(node, ctx, tns::VirtualStaticOffset, ext)
    idx = ctx(node.idxs[1], shiftdim(ext, tns.delta))
    return access(VirtualStaticOffset(;kwfields(tns)..., dim=ext), node.mode, idx)
end

function infer_dimensions_access(node, ctx, tns::VirtualStaticOffset)
    idx, ext = ctx(node.idxs[1])
    return (access(tns, node.mode, idx), shiftdim(ext, call(-, tns.delta)))
end

function stylize_access(node, ctx::Stylize{LowerJulia}, tns::VirtualOffset)
    if getunbound(node.idxs[1]) ⊆ keys(ctx.ctx.bindings)
        return ThunkStyle()
    end
    return DefaultStyle()
end

function thunk_access(node, ctx, tns::VirtualOffset)
    if getunbound(node.idxs[1]) ⊆ keys(ctx.ctx.bindings)
        delta = cache!(ctx.ctx, :delta, node.idxs[1])
        return access(Dimensionalize(VirtualStaticOffset(delta=delta)), node.mode, node.idxs[2])
    end
    return similarterm(node, operation(node), map(ctx, arguments(node)))
end

get_furl_root_access(idx, ::VirtualStaticOffset) = get_furl_root(idx.idxs[1])
function exfurl_access(tns, ctx, mode, idx, node::VirtualStaticOffset)
    body = Shift(tns, node.delta)
    exfurl(body, ctx, mode, idx.idxs[1])
end