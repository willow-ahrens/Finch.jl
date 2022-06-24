struct Offset{T}
    I::T
end

IndexNotation.value_instance(arg::Offset) = arg

const offset = Offset(nodim)

Base.size(vec::Offset) = stop(vec.I) - start(vec.I) + 1

function Base.getindex(::Offset, d, i)
    d + i
end

struct VirtualOffset
    I
end

isliteral(::VirtualOffset) = false

function virtualize(ex, ::Type{Offset{T}}, ctx) where {T}
    return VirtualOffset(virtualize(:($ex.I), T, ctx))
end

virtualize(ex, ::Type{NoDimension}, ctx) = nodim

function (ctx::Finch.LowerJulia)(tns::VirtualOffset)
    quote
        Offset($(ctx(tns.I)))
    end
end

function Finch.getdims(arr::VirtualOffset, ctx::Finch.LowerJulia, mode)
    return arr.I
end
#Finch.setdims!(arr::VirtualOffset, ctx::Finch.LowerJulia, mode, dim) = VirtualOffset(dim)

function (ctx::DeclareDimensions)(node::Access{VirtualOffset}, ext)
    if getunbound(node.idxs[1]) ⊆ keys(ctx.ctx.bindings)
        delta = cache!(ctx, :delta, node.idxs[1])
        idx = ctx(node.idxs[2], shiftdim(ext, delta))
        return access(VirtualOffset(ext), node.mode, delta, idx)
    else
        delta = ctx(node.idxs[1], nodim)
        idx = ctx(node.idxs[2], nodim)
        return access(VirtualOffset(ext), node.mode, delta, idx)
    end
end

function (ctx::InferDimensions)(node::Access{VirtualOffset})
    if getunbound(node.idxs[1]) ⊆ keys(ctx.ctx.bindings)
        delta = cache!(ctx, :delta, node.idxs[1])
        idx, ext = ctx(node.idxs[2])
        return (access(VirtualOffset(ext), node.mode, delta, idx), shiftdim(ext, call(-, delta)))
    else
        (delta, _) = ctx(node.idxs[1])
        (idx, _) = ctx(node.idxs[2])
        return (access(node.tns, node.mode, delta, idx), nodim)
    end
end

Finch.getname(node::Access{VirtualOffset}) = Finch.getname(node.idxs[2])

Finch.getname(node::VirtualOffset) = gensym()
Finch.setname(node::VirtualOffset, name) = node

function unfurl(tns, ctx, mode, idx::Access{VirtualOffset}, tail...)
    shift(unfurl(tns, ctx, mode, idx.idxs[1], tail...), delta)
end