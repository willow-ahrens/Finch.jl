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
Pigeon.combine_style(a::AcceptRunStyle, b::AcceptRunStyle) = AcceptRunStyle()
Pigeon.combine_style(a::RunStyle, b::AcceptRunStyle) = RunStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::AcceptRunStyle)
    root = visit!(root, AcceptRunContext(root, ctx))
    @assert !visit!(root, DirtyRunContext(root.idxs[1]))
    return visit!(Loop(root.idxs[2:end], root.body), ctx)
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
    ctx
end

function Pigeon.visit!(node::Access{AcceptRun, <:Union{Write, Update}}, ctx::AcceptRunContext, ::DefaultStyle)
    @assert node.idxs == ctx.root.idxs[1:1]
    ext = ctx.ctx.dims[getname(ctx.root.idxs[1])]
    Access(node.tns.body(ctx.ctx, ext.start, ext.stop), node.mode, [])
end