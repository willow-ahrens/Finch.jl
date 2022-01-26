Base.@kwdef mutable struct Run
    body
end

isliteral(::Run) = false

#A minor revelation: There's no readon to store extents in chunks, they just modify the extents of the context.
#Another revelation: If you want to store something in a chunk, 

getname(arr::Run) = getname(arr.body)

struct RunStyle end

make_style(root::Loop, ctx::LowerJuliaContext, node::Run) = RunStyle()
combine_style(a::DefaultStyle, b::RunStyle) = RunStyle()
combine_style(a::ThunkStyle, b::RunStyle) = ThunkStyle()
combine_style(a::RunStyle, b::RunStyle) = RunStyle()

function visit!(root::Loop, ctx::LowerJuliaContext, ::RunStyle)
    @assert !isempty(root.idxs)
    root = visit!(root, AccessRunContext(root))
    #TODO remove simplify step once we have dedicated handlers for it
    root = annihilate_index(root)
    visit!(root, ctx)
end

struct AccessRunContext <: AbstractTransformContext
    root
end

function visit!(node::Access{Run, Read}, ctx::AccessRunContext, ::DefaultStyle)
    return node.tns.body
end

function visit!(node::Access{Run, Read}, ctx::ForLoopContext, ::DefaultStyle)
    return node.tns.body
end

#assume ssa

Base.@kwdef mutable struct AcceptRun
    body
end

struct AcceptRunStyle end

make_style(root::Loop, ctx::LowerJuliaContext, node::Access{AcceptRun, <:Union{Write, Update}}) = AcceptRunStyle()
combine_style(a::DefaultStyle, b::AcceptRunStyle) = AcceptRunStyle()
combine_style(a::ThunkStyle, b::AcceptRunStyle) = ThunkStyle()
combine_style(a::AcceptRunStyle, b::AcceptRunStyle) = AcceptRunStyle()
combine_style(a::RunStyle, b::AcceptRunStyle) = RunStyle()

function visit!(root::Loop, ctx::LowerJuliaContext, ::AcceptRunStyle)
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

Base.@kwdef mutable struct DirtyRunContext <: AbstractCollectContext
    idx
end
collect_op(ctx::DirtyRunContext) = any
collect_zero(ctx::DirtyRunContext) = false
function visit!(node::Access, ctx::DirtyRunContext, ::DefaultStyle)
    return getname(ctx.idx) in map(getname, node.idxs)
end

Base.@kwdef mutable struct AcceptRunContext <: AbstractTransformContext
    root
    idx
    ctx
end

function visit!(node::Access{AcceptRun, <:Union{Write, Update}}, ctx::AcceptRunContext, ::DefaultStyle)
    ext = ctx.ctx.dims[getname(ctx.idx)]
    node.tns.body(ctx.ctx, ext.start, ext.stop)
end

function visit!(node::Access{AcceptRun}, ctx::ForLoopContext, ::DefaultStyle)
    node.tns.body(ctx.ctx, ctx.val, ctx.val)
end