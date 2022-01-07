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
    val = ctx.dims[getname(root.idxs[1])].stop
    tail_expr = bind(ctx, getname(root.idxs[1]) => val) do 
        scope(ctx) do ctx′
            root_tail = visit!(Loop(root.idxs[2:end], root.body), AccessSpikeTailContext(root, ctx′, idx, val))
            #The next call is a convenient fallback, but make no mistake, all chunks must work with all other chunks.
            #It's a handshake problem and you can't get around it.
            root_tail = visit!(root_tail, ForLoopContext(ctx′, idx, val))
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

spike_body_stop(stop, ctx) = :($(visit!(stop, ctx)) - 1)
spike_body_stop(stop::Integer, ctx) = stop - 1

spike_body_range(ext::Extent, ctx) = Extent(ext.start, spike_body_stop(ext.stop, ctx))

Base.@kwdef struct AccessSpikeTailContext <: Pigeon.AbstractTransformContext
    root
    ctx
    idx
    val
end

function Pigeon.visit!(node::Access{Spike}, ctx::AccessSpikeTailContext, ::DefaultStyle)
    #TODO we should get rid of this assertion. Anytime we see a spike we should know that 
    #it corresponds to the current index
    @assert getname(ctx.idx) == getname(node.idxs[1])
    return Access(node.tns.tail, node.mode, node.idxs[2:end])
end

function Pigeon.visit!(node::Access{Spike}, ctx::ForLoopContext, ::DefaultStyle)
    @assert getname(ctx.idx) == getname(node.idxs[1])
    return Access(node.tns.tail, node.mode, node.idxs[2:end])
end

Base.@kwdef mutable struct AcceptSpike
    val
    tail
end

function access_spike_tail(node::Access{AcceptSpike}, ctx, idx)
    @assert map(getname, node.idxs) == map(getname, ctx.root.idxs[1:1])
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
    @assert map(getname, node.idxs) == [getname(ctx.idx)]
    Access(node.tns.tail(ctx.ctx, ctx.val), node.mode, [])
end