@kwdef struct StaticOffset{Shift, Dim}
    shift::Shift
    dim::Dim = nodim
end

IndexNotation.value_instance(arg::StaticOffset) = arg

Base.size(vec::StaticOffset) = (stop(vec.dim) - start(vec.dim) + 1,)

function Base.getindex(arr::StaticOffset, i)
    arr.shift + i
end

struct Offset end

IndexNotation.value_instance(arg::Offset) = arg

const offset = Offset()

Base.size(vec::Offset) = (nodim, nodim)

function Base.getindex(arr::Offset, d, i)
    StaticOffset(shift = d)[i]
end

@kwdef struct VirtualStaticOffset
    shift
    dim = nodim
end

isliteral(::VirtualStaticOffset) = false

function virtualize(ex, ::Type{StaticOffset{Shift, Dim}}, ctx) where {Shift, Dim}
    shift = virtualize(:($ex.d), Shift, ctx)
    dim = virtualize(:($ex.I), Dim, ctx)
    return VirtualStaticOffset(shift, dim)
end

(ctx::Finch.LowerJulia)(tns::VirtualStaticOffset) = :(StaticOffset($(ctx(tns.shift)), $(ctx(tns.dim))))

function Finch.getdims(arr::VirtualStaticOffset, ctx::Finch.LowerJulia, mode)
    return (arr.dim,)
end
Finch.setdims!(arr::VirtualStaticOffset, ctx::Finch.LowerJulia, mode, dim) = VirtualStaticOffset(kwfields(arr)..., dim=dim)

struct VirtualOffset end

isliteral(::VirtualOffset) = false

virtualize(ex, ::Type{Offset}, ctx) = VirtualOffset()

(ctx::Finch.LowerJulia)(tns::VirtualOffset) = :(Offset($(ctx(tns.I))))

Finch.getdims(arr::VirtualOffset, ctx::Finch.LowerJulia, mode) = (nodim, nodim)
Finch.setdims!(arr::VirtualOffset, ctx::Finch.LowerJulia, mode, dim1, dim2) = arr

function (ctx::DeclareDimensions)(node::Access{VirtualStaticOffset}, ext)
    idx = ctx(node.idxs[1], shiftdim(ext, node.tns.delta))
    return access(VirtualStaticOffset(kwfields(node.tns)..., dim=ext), node.mode, idx)
end

function (ctx::InferDimensions)(node::Access{VirtualStaticOffset})
    idx, ext = ctx(node.idxs[1])
    return (access(node, node.mode, delta, idx), shiftdim(ext, call(-, delta)))
end

Finch.getname(node::Access{VirtualOffset}) = Finch.getname(node.idxs[2])

Finch.getname(node::VirtualOffset) = gensym()
Finch.setname(node::VirtualOffset, name) = node

function (ctx::Stylize{LowerJulia})(node::Access{<:VirtualOffset})
    if getunbound(node.idxs[1]) ⊆ keys(ctx.ctx.bindings)
        return SimplifyStyle()
    end
    return mapreduce(ctx, result_style, arguments(node))
end

unwrap_offsets(node) = nothing
function unwrap_offsets(node::Access{<:VirtualOffset})
    if getunbound(node.idxs[1]) ⊆ keys(ctx.bindings)
        shift = cache!(:ctx, node.idxs[1])
        return access(Dimensionalize(VirtualStaticOffset(shift)), ctx(node.mode), ctx(node.idxs[2]))
    end
end
push!(rules, unwrap_offsets) #TODO perhaps we need to get more specific about order of operations on rewrites

get_furl_root(idx::Access{VirtualStaticOffset}) = get_furl_root(idx.idxs[1])
function unfurl(tns, ctx, mode, idx::Access{VirtualStaticOffset}, tail...)
    shift(unfurl(tns, ctx, mode, idx.idxs[1], tail...), idx.tns.shift)
end