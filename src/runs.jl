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
    #TODO add a simplify step here perhaps
    root = annihilate_index(root)
    visit!(root, ctx)
end

struct AccessRunContext <: Pigeon.AbstractTransformContext
    root
end

function Pigeon.visit!(node::Access{Run, Read}, ctx::AccessRunContext, ::DefaultStyle)
    if length(node.idxs) == 1 && node.idxs[1] == ctx.root.idxs[1]
        return Access(node.tns.body, Read(), [])
    end
    return node
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
        return visit!(root, ctx, DefaultStyle()) #TODO most correct thing to do here is to resolve a backup style.
    end
end

Base.@kwdef mutable struct DirtyRunContext <: Pigeon.AbstractCollectContext
    idx
end

Pigeon.collector(ctx::DirtyRunContext) = any

Pigeon.postvisit!(node, ctx::DirtyRunContext) = false 

function Pigeon.visit!(node::Access, ctx::DirtyRunContext, ::DefaultStyle)
    return ctx.idx in node.idxs
end

Base.@kwdef mutable struct AcceptRunContext <: Pigeon.AbstractTransformContext
    root
    idx
    ctx
end

function Pigeon.visit!(node::Access{AcceptRun, <:Union{Write, Update}}, ctx::AcceptRunContext, ::DefaultStyle)
    @assert node.idxs == [ctx.idx]
    ext = ctx.ctx.dims[getname(ctx.idx)]
    Access(node.tns.body(ctx.ctx, ext.start, ext.stop), node.mode, [])
end

function Pigeon.visit!(node::Access{AcceptRun}, ctx::ForLoopContext, ::DefaultStyle)
    @assert node.idxs == [ctx.idx]
    Access(node.tns.body(ctx.ctx, ctx.val, ctx.val), node.mode, [])
end