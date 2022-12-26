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

IndexNotation.isliteral(::VirtualPermit) =  false

function virtualize(ex, ::Type{Permit{T}}, ctx) where {T}
    return VirtualPermit(virtualize(:($ex.I), T, ctx))
end

function (ctx::Finch.LowerJulia)(tns::VirtualPermit)
    quote
        Permit($(ctx(tns.I)))
    end
end

function Finch.getsize(arr::VirtualPermit, ctx::Finch.LowerJulia, mode)
    return arr.I
end
#Finch.setsize!(arr::VirtualPermit, ctx::Finch.LowerJulia, mode, dim) = VirtualPermit(dim)

function declare_dimensions_access(node, ctx, tns::VirtualPermit, ext)
    idx = ctx(node.idxs[1], widendim(ext))
    return access(VirtualPermit(ext), node.mode, idx)
end

function infer_dimensions_access(node, ctx, tns::VirtualPermit)
    (idx, _) = ctx(node.idxs[1])
    return (access(tns, node.mode, idx), tns.I)
end

Finch.getname(node::VirtualPermit) = gensym()
Finch.setname(node::VirtualPermit, name) = node

get_furl_root_access(idx, ::VirtualPermit) = get_furl_root(idx.idxs[1])
function exfurl_access(tns, ctx, mode, idx, node::VirtualPermit)
    ext_2 = node.I
    body = Pipeline([
        Phase(
            stride = (ctx, idx, ext) -> @f($(getstart(ext_2)) - 1),
            body = (start, step) -> Run(Simplify(Fill(literal(missing)))),
        ),
        Phase(
            stride = (ctx, idx, ext) -> getstop(ext_2),
            body = (start, step) -> truncate(tns, ctx, ext_2, Extent(start, step))
        ),
        Phase(
            body = (start, step) -> Run(Simplify(Fill(literal(missing)))),
        )
    ])

    exfurl(body, ctx, mode, idx.idxs[1])
end