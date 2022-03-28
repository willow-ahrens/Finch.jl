@kwdef mutable struct Run
    body
end

isliteral(::Run) = false

#A minor revelation: There's no reason to store extents in chunks, they just modify the extents of the context.

getname(arr::Run) = getname(arr.body)

struct RunStyle end

make_style(root::Loop, ctx::LowerJulia, node::Run) = RunStyle()
combine_style(a::DefaultStyle, b::RunStyle) = RunStyle()
combine_style(a::ThunkStyle, b::RunStyle) = ThunkStyle()
combine_style(a::RunStyle, b::RunStyle) = RunStyle()

function (ctx::LowerJulia)(root::Loop, ::RunStyle)
    @assert !isempty(root.idxs)
    root = (AccessRunVisitor(root))(root)
    if make_style(root, ctx) isa RunStyle
        error("run style couldn't lower runs")
    end
    #TODO remove simplify step once we have dedicated handlers for it
    root = annihilate_index(ctx)(root)
    ctx(root)
end

struct AccessRunVisitor <: AbstractTransformVisitor
    root
end

function (ctx::AccessRunVisitor)(node::Access{Run, Read}, ::DefaultStyle)
    return node.tns.body
end

#assume ssa

@kwdef mutable struct AcceptRun
    body
end

struct AcceptRunStyle end

make_style(root::Loop, ctx::LowerJulia, node::Access{AcceptRun, <:Union{Write, Update}}) = AcceptRunStyle()
combine_style(a::DefaultStyle, b::AcceptRunStyle) = AcceptRunStyle()
combine_style(a::ThunkStyle, b::AcceptRunStyle) = ThunkStyle()
combine_style(a::AcceptRunStyle, b::AcceptRunStyle) = AcceptRunStyle()
combine_style(a::RunStyle, b::AcceptRunStyle) = RunStyle()

function (ctx::LowerJulia)(root::Loop, ::AcceptRunStyle)
    idx = root.idxs[1]
    body = Loop(root.idxs[2:end], root.body)
    body = (AcceptRunVisitor(body, idx, ctx))(body)
    if !(DirtyRunVisitor(idx))(body)
        return ctx(body)
    else
        #call DefaultStyle, the only style that AcceptRunStyle promotes with
        return ctx(root, DefaultStyle())
    end
end

@kwdef mutable struct DirtyRunVisitor <: AbstractCollectVisitor
    idx
end
collect_op(ctx::DirtyRunVisitor) = any
collect_zero(ctx::DirtyRunVisitor) = false
function (ctx::DirtyRunVisitor)(node::Access, ::DefaultStyle)
    return getname(ctx.idx) in map(getname, node.idxs)
end

@kwdef mutable struct AcceptRunVisitor <: AbstractTransformVisitor
    root
    idx
    ctx
end

function (ctx::AcceptRunVisitor)(node::Access{AcceptRun, <:Union{Write, Update}}, ::DefaultStyle)
    ext = ctx.ctx.dims[getname(ctx.idx)]
    node.tns.body(ctx.ctx, start(ext), stop(ext))
end

function (ctx::ForLoopVisitor)(node::Access{AcceptRun, <:Union{Write, Update}}, ::DefaultStyle)
    node.tns.body(ctx.ctx, ctx.val, ctx.val)
end