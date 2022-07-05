struct Permit{T}
    I::T
end

Base.show(io::IO, ex::Permit) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Permit)
	print(io, "Permit()")
end


IndexNotation.value_instance(arg::Permit) = arg

const permit = Permit(nodim)

Base.size(vec::Permit) = stop(vec.I) - start(vec.I) + 1

function Base.getindex(vec::Permit, i)
    getstart(vec.I) <= i <= getstop(vec.I) ? i : missing
end

struct VirtualPermit
    I
end

Base.show(io::IO, ex::VirtualPermit) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualPermit)
	print(io, "VirtualPermit()")
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

function (ctx::DeclareDimensions)(node::Access{VirtualPermit}, ext)
    idx = ctx(node.idxs[1], Widen(ext))
    return access(VirtualPermit(ext), node.mode, idx)
end
function (ctx::InferDimensions)(node::Access{VirtualPermit})
    (idx, _) = ctx(node.idxs[1])
    return (access(node.tns, node.mode, idx), node.tns.I)
end

Finch.getname(node::Access{VirtualPermit}) = Finch.getname(first(node.idxs))

Finch.getname(node::VirtualPermit) = gensym()
Finch.setname(node::VirtualPermit, name) = node

get_furl_root(idx::Access{VirtualPermit}) = get_furl_root(idx.idxs[1])
function unfurl(tns, ctx, mode, idx::Access{VirtualPermit}, tail...)
    ext_2 = idx.tns.I
    Pipeline([
        Phase(
            stride = (ctx, idx, ext) -> @i($(getstart(ext_2)) - 1),
            body = (start, step) -> Run(Simplify(missing)),
        ),
        Phase(
            stride = (ctx, idx, ext) -> ctx(getstop(ext_2)),
            body = (start, step) -> truncate(unfurl(tns, ctx, mode, idx.idxs[1], tail...), ctx, ext_2, Extent(start, step))
        ),
        Phase(
            body = (start, step) -> Run(Simplify(missing)),
        )
    ])
end