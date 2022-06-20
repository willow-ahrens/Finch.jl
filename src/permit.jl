struct Permit{T}
    I::T
end

const permit = Permit(nodim)

Base.size(vec::Permit) = stop(vec.I) - start(vec.I) + 1

function Base.getindex(vec::Permit, i)
    start(vec.I) <= i <= stop(vec.I) ? i : missing
end

struct VirtualPermit
    I
end

isliteral(::VirtualPermit) = false

function virtualize(ex, ::Type{Permit{T}}, ctx) where {T}
    return VirtualPermit(virtualize(:($ex.I), T, ctx))
end

function (ctx::Finch.LowerJulia)(tns::VirtualPermit)
    quote
        Permit($(ctx(tns.I)))
    end
end

function Finch.getdims(arr::VirtualPermit, ctx::Finch.LowerJulia, mode)
    return arr.I
end
Finch.setdims!(arr::VirtualPermit, ctx::Finch.LowerJulia, mode, dim) = VirtualPermit(dim)

function (ctx::InferDimensions)(node::Access{VirtualPermit}, ext)
    @assert length(node.idxs) == 1
    ctx(node.idx, ext)
    return ext
end

(ctx::InferDimensions)(node::Protocol, ext) = ctx(node.idx, ext)

function unfurl(tns, ctx, mode, idx::Permit)
    obj = unfurl(tns, ctx, mode, idx)
    Pipeline([
        Phase(
            stride(start) = idx
            body = ...

        ),
        Phase(
            stride(start) = idx
            body = ...

        )
    ])
    truncate(ctx, obj, )
end