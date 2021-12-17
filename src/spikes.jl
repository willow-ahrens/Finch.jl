using Pigeon: Read, Write, Update

Base.@kwdef struct Spike
    body
    tail
end

Pigeon.isliteral(::Spike) = false

struct SpikeStyle end

Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Spike) = SpikeStyle()
Pigeon.combine_style(a::DefaultStyle, b::SpikeStyle) = SpikeStyle()
Pigeon.combine_style(a::RunStyle, b::SpikeStyle) = SpikeStyle()
Pigeon.combine_style(a::ThunkStyle, b::SpikeStyle) = ThunkStyle()
Pigeon.combine_style(a::AcceptRunStyle, b::SpikeStyle) = SpikeStyle()
Pigeon.combine_style(a::SpikeStyle, b::SpikeStyle) = SpikeStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::SpikeStyle)
    @assert !isempty(root.idxs)
    root_body = postmap(node->spike_body(node, ctx, root.idxs[1]), root)
    #TODO arguably we could take several better alternative approaches to rediminsionalization here
    body_expr = restrict(ctx, getname(root.idxs[1]) => spike_body_range(ctx.dims[getname(root.idxs[1])], ctx)) do
        visit!(annihilate_index(root_body), ctx)
    end
    root_tail = visit!(Loop(root.idxs[2:end], root.body), AccessSpikeTailContext(ctx, root))
    tail_expr = bind(ctx, root.idxs[1] => ctx.dims[getname(root.idxs[1])].stop) do 
        visit!(annihilate_index(root_tail), ctx)
    end
    return Expr(:block, body_expr, tail_expr)
end

spike_body(node, ctx, idx) = nothing
spike_body(node::Spike, ctx, idx) = Run(node.body)

#A bit ugly. We can make this work better.
spike_body(node::Run, ctx, idx) = node
function access_spike_tail(node::Access{Run}, ctx, idx)
    @assert ctx.root.idxs[1:1] == node.idxs
    return Access(node.tns.body, node.mode, [])
end

function access_spike_tail(node::Access{AcceptRun}, ctx, idx)
    @assert node.idxs == ctx.root.idxs[1:1]
    ext = ctx.ctx.dims[getname(ctx.root.idxs[1])]
    return Access(node.tns.body(ctx.ctx, ext.stop, ext.stop), node.mode, [])
end

#TODO truncate_block needs to be called on non-chunk tensors? What do we do with non-chunk tensors? probably makes more sense to just have a visitor?

spike_body_stop(stop, ctx) = :($(visit!(stop, ctx)) - 1)
spike_body_stop(stop::Integer, ctx) = stop - 1

spike_body_range(ext::Extent, ctx) = Extent(ext.start, spike_body_stop(ext.stop, ctx))

Base.@kwdef struct AccessSpikeTailContext <: Pigeon.AbstractTransformContext
    ctx
    root
end

function Pigeon.visit!(node::Access, ctx::AccessSpikeTailContext, ::DefaultStyle)
    if ctx.root.idxs[1] in node.idxs
        return access_spike_tail(node, ctx, ctx.root.idxs[1])
    end
    return node
end

function access_spike_tail(node::Access{Run}, ctx, idx)
    @assert ctx.root.idxs[1:1] == node.idxs
    return Access(node.tns.body, node.mode, [])
end

function access_spike_tail(node::Access{Spike}, ctx, idx)
    @assert ctx.root.idxs[1:1] == node.idxs
    return Access(node.tns.tail, node.mode, [])
end

function access_spike_tail(node::Access, ctx, idx)
    return node
end

function trim_chunk_stop!(node::Spike, ctx::LowerJuliaContext, stop, stop′)
    return Cases([
        :($(visit!(stop′, ctx)) == $(visit!(stop, ctx))) => node,
        :($(visit!(stop′, ctx)) < $(visit!(stop, ctx))) => trim_chunk_stop!(node.body, ctx, stop, stop′)
    ])
end