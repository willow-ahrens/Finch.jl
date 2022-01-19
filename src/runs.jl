Base.@kwdef mutable struct Run
    body
end

Pigeon.isliteral(::Run) = false

#A minor revelation: There's no readon to store extents in chunks, they just modify the extents of the context.
#Another revelation: If you want to store something in a chunk, 

Pigeon.getname(arr::Run) = getname(arr.body)

struct RunStyle end

Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Run) = RunStyle()
Pigeon.combine_style(a::DefaultStyle, b::RunStyle) = RunStyle()
Pigeon.combine_style(a::ThunkStyle, b::RunStyle) = ThunkStyle()
Pigeon.combine_style(a::RunStyle, b::RunStyle) = RunStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::RunStyle)
    @assert !isempty(root.idxs)
    root = visit!(root, AccessRunContext(root))
    #TODO remove simplify step once we have dedicated handlers for it
    root = annihilate_index(root)
    visit!(root, ctx)
end

struct AccessRunContext <: Pigeon.AbstractTransformContext
    root
end

function Pigeon.visit!(node::Access{Run, Read}, ctx::AccessRunContext, ::DefaultStyle)
    return node.tns.body
end

function Pigeon.visit!(node::Access{Run, Read}, ctx::ForLoopContext, ::DefaultStyle)
    return node.tns.body
end

#assume ssa

Base.@kwdef mutable struct AcceptRun
    body
end

struct AcceptRunStyle end

Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Access{AcceptRun, <:Union{Write, Update}}) = AcceptRunStyle()
Pigeon.combine_style(a::DefaultStyle, b::AcceptRunStyle) = AcceptRunStyle()
Pigeon.combine_style(a::ThunkStyle, b::AcceptRunStyle) = ThunkStyle()
Pigeon.combine_style(a::AcceptRunStyle, b::AcceptRunStyle) = AcceptRunStyle()
Pigeon.combine_style(a::RunStyle, b::AcceptRunStyle) = RunStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::AcceptRunStyle)
    idx = root.idxs[1]
    body = Loop(root.idxs[2:end], root.body)
    body = visit!(body, AcceptRunContext(body, idx, ctx))
    if !visit!(body, DirtyRunContext(idx))
        return visit!(body, ctx)
    else
        #call DefaultStyle, the only style that AcceptRunStyle promotes with
        return visit!(root, ctx, DefaultStyle())
    end
end

Base.@kwdef mutable struct DirtyRunContext <: Pigeon.AbstractCollectContext
    idx
end
Pigeon.collect_op(ctx::DirtyRunContext) = any
Pigeon.collect_zero(ctx::DirtyRunContext) = false
function Pigeon.visit!(node::Access, ctx::DirtyRunContext, ::DefaultStyle)
    return getname(ctx.idx) in map(getname, node.idxs)
end

Base.@kwdef mutable struct AcceptRunContext <: Pigeon.AbstractTransformContext
    root
    idx
    ctx
end

function Pigeon.visit!(node::Access{AcceptRun, <:Union{Write, Update}}, ctx::AcceptRunContext, ::DefaultStyle)
    ext = ctx.ctx.dims[getname(ctx.idx)]
    node.tns.body(ctx.ctx, ext.start, ext.stop)
end

function Pigeon.visit!(node::Access{AcceptRun}, ctx::ForLoopContext, ::DefaultStyle)
    node.tns.body(ctx.ctx, ctx.val, ctx.val)
end