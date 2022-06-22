struct Permit{T}
    I::T
end

IndexNotation.value_instance(arg::Permit) = arg

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

virtualize(ex, ::Type{NoDimension}, ctx) = nodim

function (ctx::Finch.LowerJulia)(tns::VirtualPermit)
    quote
        Permit($(ctx(tns.I)))
    end
end

function Finch.getdims(arr::VirtualPermit, ctx::Finch.LowerJulia, mode)
    return arr.I
end
#Finch.setdims!(arr::VirtualPermit, ctx::Finch.LowerJulia, mode, dim) = VirtualPermit(dim)

function (ctx::InferDimensions)(node::Access{VirtualPermit}, ext)
    @assert length(node.idxs) == 1
    ctx(node.idxs[1], Widen(ext))
    return ext
end

Finch.getname(node::Access{VirtualPermit}) = Finch.getname(first(node.idxs))

Finch.getname(node::VirtualPermit) = gensym()
Finch.setname(node::VirtualPermit, name) = node

function unfurl(tns, ctx, mode, idx::Access{VirtualPermit}, tail...)
    ext = InferDimensions(ctx=ctx, mode=define_dims, dims = ctx.dims, shapes = ctx.shapes)(idx.idxs[1])
    ext_2 = first(getdims(tns, ctx, mode)) #Is this okay?
    Pipeline([
        Phase(
            stride = (start) -> @i($(getstart(ext_2)) - 1),
            body = (start, step) -> Run(Simplify(missing)),
        ),
        Phase(
            stride = (start) -> ctx(getstop(ext_2)),
            body = (start, step) -> truncate(unfurl(tns, ctx, mode, idx.idxs[1], tail...), ctx, ext_2, Extent(start, step))
        ),
        Phase(
            body = (start, step) -> Run(Simplify(missing)),
        )
    ])
end