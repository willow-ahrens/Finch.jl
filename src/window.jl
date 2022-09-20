@kwdef struct StaticWindow{Dim, Target}
    dim::Dim = nodim
    target::Target = nodim
end

Base.show(io::IO, ex::StaticWindow) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::StaticWindow)
	print(io, "StaticWindow(target = ")
	print(io, ex.target)
	print(io, ")")
end

IndexNotation.value_instance(arg::StaticWindow) = arg

Base.size(vec::StaticWindow) = (stop(vec.target) - start(vec.target) + 1,)

function Base.getindex(arr::StaticWindow, i)
    getstart(arr.target) + i - 1
end

struct Window end

Base.show(io::IO, ex::Window) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Window)
	print(io, "Window()")
end

IndexNotation.value_instance(arg::Window) = arg

const window = Window()

Base.size(vec::Window) = (nodim, nodim, nodim)

function Base.getindex(arr::Window, i0, i1, i)
    StaticWindow(target = Extent(start=i0, stop=i1))[i]
end

@kwdef struct VirtualStaticWindow
    dim = nodim
    target = nodim
end

Base.show(io::IO, ex::VirtualStaticWindow) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualStaticWindow)
	print(io, "VirtualStaticWindow(dim = ")
	print(io, ex.dim)
	print(io, ")")
end


isliteral(::VirtualStaticWindow) = false

function virtualize(ex, ::Type{StaticWindow{Dim, Target}}, ctx) where {Dim, Target}
    dim = virtualize(:($ex.dim), Dim, ctx)
    target = virtualize(:($ex.target), Target, ctx)
    return VirtualStaticWindow(target =target, dim = dim)
end

(ctx::Finch.LowerJulia)(tns::VirtualStaticWindow) = :(StaticWindow(dim = $(ctx(tns.dim)), target = $(ctx(tns.target))))

function Finch.getsize(arr::VirtualStaticWindow, ctx::Finch.LowerJulia, mode)
    return (arr.target,)
end
Finch.setsize!(arr::VirtualStaticWindow, ctx::Finch.LowerJulia, mode, dim) = arr

struct VirtualWindow end

Base.show(io::IO, ex::VirtualWindow) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualWindow)
	print(io, "VirtualWindow()")
end

isliteral(::VirtualWindow) = false

virtualize(ex, ::Type{Window}, ctx) = VirtualWindow()

(ctx::Finch.LowerJulia)(tns::VirtualWindow) = :(Window($(ctx(tns.I))))

Finch.getsize(arr::VirtualWindow, ctx::Finch.LowerJulia, mode) = (nodim, nodim, nodim)
Finch.setsize!(arr::VirtualWindow, ctx::Finch.LowerJulia, mode, dim1, dim2, dim3) = arr

function (ctx::DeclareDimensions)(node::Access{VirtualStaticWindow}, dim)
    idx = ctx(node.idxs[1], shiftdim(node.tns.target, call(-, getstart(dim), getstart(node.tns.target))))
    #TODO we should check that dim is subset of ext here somehow. I think we check on the first time dim is not nodim or deferdim
    return access(VirtualStaticWindow(; kwfields(node.tns)..., dim=dim), node.mode, idx)
end

function (ctx::InferDimensions)(node::Access{VirtualStaticWindow})
    idx, ext = ctx(node.idxs[1])
    return (access(node.tns, node.mode, idx), node.tns.target) #TODO this feels only partially correct
end

Finch.getname(node::VirtualWindow) = gensym()
Finch.setname(node::VirtualWindow, name) = node

function stylize_access(node, ctx::Stylize{LowerJulia}, tns::VirtualWindow)
    if getunbound(node.idxs[1]) ⊆ keys(ctx.ctx.bindings) && getunbound(node.idxs[2]) ⊆ keys(ctx.ctx.bindings)
        return ThunkStyle()
    end
    return DefaultStyle()
end

#TODO needs its own lowering pass, or thunks need to be strictly recursive
function (ctx::ThunkVisitor)(node::Access{<:VirtualWindow})
    if getunbound(node.idxs[1]) ⊆ keys(ctx.ctx.bindings) && getunbound(node.idxs[2]) ⊆ keys(ctx.ctx.bindings)
        return access(Dimensionalize(VirtualStaticWindow(target=cache!(ctx.ctx, :window, Extent(start = ctx(node.idxs[1]), stop = ctx(node.idxs[2]))))), node.mode, ctx(node.idxs[3]))
    end
    return similarterm(node, operation(node), map(ctx, arguments(node)))
end

Finch.getname(node::VirtualStaticWindow) = gensym()
Finch.setname(node::VirtualStaticWindow, name) = node

get_furl_root(idx::Access{VirtualStaticWindow}) = get_furl_root(idx.idxs[1])
function exfurl(tns, ctx, mode, idx::Access{VirtualStaticWindow})
    node = idx.tns
    body = Shift(truncate(tns, ctx, node.dim, node.target), call(-, getstart(node.dim), getstart(node.target)))
    exfurl(body, ctx, mode, idx.idxs[1])
end