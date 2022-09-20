@kwdef mutable struct Run
    body
end

Base.show(io::IO, ex::Run) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Run)
    print(io, "Run(body = ")
    print(io, ex.body)
    print(io, ")")
end

isliteral(::Run) = false

#A minor revelation: There's no reason to store extents in chunks, they just modify the extents of the context.

getname(arr::Run) = getname(arr.body)

struct RunStyle end

(ctx::Stylize{LowerJulia})(node::Run) = RunStyle()
combine_style(a::DefaultStyle, b::RunStyle) = RunStyle()
combine_style(a::ThunkStyle, b::RunStyle) = ThunkStyle()
combine_style(a::SimplifyStyle, b::RunStyle) = SimplifyStyle()
combine_style(a::RunStyle, b::RunStyle) = RunStyle()

function (ctx::LowerJulia)(root::Chunk, ::RunStyle)
    root = (AccessRunVisitor(root))(root)
    if Stylize(root, ctx)(root) isa RunStyle #TODO do we need this always? Can we do this generically?
        error("run style couldn't lower runs")
    end
    ctx(root)
end

@kwdef struct AccessRunVisitor
    root
end
function (ctx::AccessRunVisitor)(node)
    if istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end

(ctx::AccessRunVisitor)(node::Access) = something(unchunk(node.tns, ctx), node)
unchunk(node::Run, ::AccessRunVisitor) = node.body
unchunk(node::Shift, ctx::AccessRunVisitor) = unchunk(node.body, ctx)


#assume ssa

@kwdef mutable struct AcceptRun
    body
    val = nothing
end

default(node::AcceptRun) = node.val

Base.show(io::IO, ex::AcceptRun) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::AcceptRun)
    print(io, "AcceptRun(…)")
end

struct AcceptRunStyle end

(ctx::Stylize{LowerJulia})(node::AcceptRun) = AcceptRunStyle()
combine_style(a::DefaultStyle, b::AcceptRunStyle) = AcceptRunStyle()
combine_style(a::ThunkStyle, b::AcceptRunStyle) = ThunkStyle()
combine_style(a::SimplifyStyle, b::AcceptRunStyle) = SimplifyStyle()
combine_style(a::AcceptRunStyle, b::AcceptRunStyle) = AcceptRunStyle()
combine_style(a::RunStyle, b::AcceptRunStyle) = RunStyle()

(ctx::LowerJulia)(::Pass, ::AcceptRunStyle) = quote end#TODO this shouldn't need to be specified, I think that Pass needs not to declare a style
function (ctx::LowerJulia)(root::Chunk, ::AcceptRunStyle)
    body = (AcceptRunVisitor(root, root.idx, root.ext, ctx))(root.body)
    if getname(root.idx) in getunbound(body)
        #call DefaultStyle, the only style that AcceptRunStyle promotes with
        return ctx(root, DefaultStyle())
    else
        return ctx(body)
    end
end

@kwdef struct AcceptRunVisitor
    root
    idx
    ext
    ctx
end

function (ctx::AcceptRunVisitor)(node)
    if istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end

(ctx::AcceptRunVisitor)(node::Access) = node.mode === Read() ? node : something(unchunk(node.tns, ctx), node)
unchunk(node::AcceptRun, ctx::AcceptRunVisitor) = node.body(ctx.ctx, getstart(ctx.ext), getstop(ctx.ext))
unchunk(node::Shift, ctx::AcceptRunVisitor) = unchunk(node.body, AcceptRunVisitor(;kwfields(ctx)..., ext = shiftdim(ctx.ext, call(-, node.delta))))

unchunk(node::AcceptRun, ctx::ForLoopVisitor) = node.body(ctx.ctx, ctx.val, ctx.val)

supports_shift(::RunStyle) = true
supports_shift(::AcceptRunStyle) = true