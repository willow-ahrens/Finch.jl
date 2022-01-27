Base.@kwdef mutable struct Run
    body
end

isliteral(::Run) = false

#A minor revelation: There's no readon to store extents in chunks, they just modify the extents of the context.
#Another revelation: If you want to store something in a chunk, 

getname(arr::Run) = getname(arr.body)

struct RunStyle end

make_style(root::Loop, ctx::LowerJulia, node::Run) = RunStyle()
combine_style(a::DefaultStyle, b::RunStyle) = RunStyle()
combine_style(a::ThunkStyle, b::RunStyle) = ThunkStyle()
combine_style(a::RunStyle, b::RunStyle) = RunStyle()

function visit!(root::Loop, ctx::LowerJulia, ::RunStyle)
    @assert !isempty(root.idxs)
    root = visit!(root, AccessRunVisitor(root))
    #TODO remove simplify step once we have dedicated handlers for it
    root = annihilate_index(root)
    visit!(root, ctx)
end

struct AccessRunVisitor <: AbstractTransformVisitor
    root
end

function visit!(node::Access{Run, Read}, ctx::AccessRunVisitor, ::DefaultStyle)
    return node.tns.body
end

function visit!(node::Access{Run, Read}, ctx::ForLoopVisitor, ::DefaultStyle)
    return node.tns.body
end

#assume ssa

Base.@kwdef mutable struct AcceptRun
    body
end

struct AcceptRunStyle end

make_style(root::Loop, ctx::LowerJulia, node::Access{AcceptRun, <:Union{Write, Update}}) = AcceptRunStyle()
combine_style(a::DefaultStyle, b::AcceptRunStyle) = AcceptRunStyle()
combine_style(a::ThunkStyle, b::AcceptRunStyle) = ThunkStyle()
combine_style(a::AcceptRunStyle, b::AcceptRunStyle) = AcceptRunStyle()
combine_style(a::RunStyle, b::AcceptRunStyle) = RunStyle()

function visit!(root::Loop, ctx::LowerJulia, ::AcceptRunStyle)
    idx = root.idxs[1]
    body = Loop(root.idxs[2:end], root.body)
    body = visit!(body, AcceptRunVisitor(body, idx, ctx))
    if !visit!(body, DirtyRunVisitor(idx))
        return visit!(body, ctx)
    else
        #call DefaultStyle, the only style that AcceptRunStyle promotes with
        return visit!(root, ctx, DefaultStyle())
    end
end

Base.@kwdef mutable struct DirtyRunVisitor <: AbstractCollectVisitor
    idx
end
collect_op(ctx::DirtyRunVisitor) = any
collect_zero(ctx::DirtyRunVisitor) = false
function visit!(node::Access, ctx::DirtyRunVisitor, ::DefaultStyle)
    return getname(ctx.idx) in map(getname, node.idxs)
end

Base.@kwdef mutable struct AcceptRunVisitor <: AbstractTransformVisitor
    root
    idx
    ctx
end

function visit!(node::Access{AcceptRun, <:Union{Write, Update}}, ctx::AcceptRunVisitor, ::DefaultStyle)
    ext = ctx.ctx.dims[getname(ctx.idx)]
    node.tns.body(ctx.ctx, ext.start, ext.stop)
end

function visit!(node::Access{AcceptRun}, ctx::ForLoopVisitor, ::DefaultStyle)
    node.tns.body(ctx.ctx, ctx.val, ctx.val)
end