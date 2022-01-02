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
    idx = root.idxs[1]
    root_body = Pigeon.visit!(root, AccessSpikeBodyContext(root, ctx, idx))
    #TODO arguably we could take several better alternative approaches to rediminsionalization here
    body_expr = restrict(ctx, getname(root.idxs[1]) => spike_body_range(ctx.dims[getname(root.idxs[1])], ctx)) do
        scope(ctx) do ctx′
            visit!(annihilate_index(root_body), ctx′)
        end
    end
    root_tail = visit!(Loop(root.idxs[2:end], root.body), AccessSpikeTailContext(ctx, root))
    tail_expr = bind(ctx, root.idxs[1] => ctx.dims[getname(root.idxs[1])].stop) do 
        scope(ctx) do ctx′
            visit!(annihilate_index(root_tail), ctx′)
        end
    end
    return Expr(:block, body_expr, tail_expr)
end


Base.@kwdef struct AccessSpikeBodyContext <: Pigeon.AbstractTransformContext
    root
    ctx
    idx
end

function Pigeon.visit!(node::Spike, ctx::AccessSpikeBodyContext, ::DefaultStyle)
    return Run(node.body)
end

function Pigeon.visit!(node::Run, ctx::AccessSpikeBodyContext, ::DefaultStyle)
    return node
end



function access_spike_tail(node::Access{Run}, ctx, idx)
    @assert ctx.root.idxs[1:1] == node.idxs
    return Access(node.tns.body, node.mode, [])
end

function access_spike_tail(node::Access{AcceptRun}, ctx, idx)
    @assert node.idxs == ctx.root.idxs[1:1]
    ext = ctx.ctx.dims[getname(ctx.root.idxs[1])]
    return Access(node.tns.body(ctx.ctx, ext.stop, ext.stop), node.mode, [])
end

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

function Pigeon.visit!(node::Access{Spike}, ctx::ForLoopContext, ::DefaultStyle)
    @assert node.idxs == [ctx.idx]
    Access(node.tns.tail, node.mode, [])
end

Base.@kwdef mutable struct AcceptSpike
    val
    tail
end

function access_spike_tail(node::Access{AcceptSpike}, ctx, idx)
    @assert node.idxs == ctx.root.idxs[1:1]
    ext = ctx.ctx.dims[getname(ctx.root.idxs[1])]
    return Access(node.tns.tail(ctx.ctx, ext.stop), node.mode, [])
end

struct AcceptSpikeStyle end

Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Access{AcceptSpike, <:Union{Write, Update}}) = AcceptSpikeStyle()
Pigeon.combine_style(a::DefaultStyle, b::AcceptSpikeStyle) = AcceptSpikeStyle()
Pigeon.combine_style(a::ThunkStyle, b::AcceptSpikeStyle) = ThunkStyle()
Pigeon.combine_style(a::AcceptSpikeStyle, b::AcceptSpikeStyle) = AcceptSpikeStyle()
Pigeon.combine_style(a::AcceptRunStyle, b::AcceptSpikeStyle) = AcceptSpikeStyle()
Pigeon.combine_style(a::RunStyle, b::AcceptSpikeStyle) = RunStyle()
Pigeon.combine_style(a::SpikeStyle, b::AcceptSpikeStyle) = SpikeStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::AcceptSpikeStyle)
    #call DefaultStyle because we didn't simplify away the body or tail of
    #corresponding Spikes, and need to set all the elements of the spike.
    return visit!(Loop(root.idxs[1:end], root.body), ctx, DefaultStyle())
end

Base.@kwdef mutable struct AcceptSpikeContext <: Pigeon.AbstractTransformContext
    root
    ctx
end

function Pigeon.visit!(node::Access{AcceptSpike}, ctx::ForLoopContext, ::DefaultStyle)
    @assert node.idxs == [ctx.idx]
    Access(node.tns.tail(ctx.ctx, ctx.val), node.mode, [])
end