Base.@kwdef struct Spike
    body
    tail
end

isliteral(::Spike) = false

struct SpikeStyle end

make_style(root::Loop, ctx::LowerJulia, node::Spike) = SpikeStyle()
combine_style(a::DefaultStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::RunStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::ThunkStyle, b::SpikeStyle) = ThunkStyle()
combine_style(a::AcceptRunStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::SpikeStyle, b::SpikeStyle) = SpikeStyle()

function visit!(root::Loop, ctx::LowerJulia, ::SpikeStyle)
    @assert !isempty(root.idxs)
    idx = root.idxs[1]
    root_body = visit!(root, AccessSpikeBodyVisitor(root, ctx, idx))
    #TODO arguably we could take several better alternative approaches to rediminsionalization here
    body_expr = restrict(ctx, getname(root.idxs[1]) => spike_body_range(ctx.dims[getname(root.idxs[1])], ctx)) do
        scope(ctx) do ctx′
            visit!(annihilate_index(root_body), ctx′)
        end
    end
    val = ctx.dims[getname(root.idxs[1])].stop
    tail_expr = bind(ctx, getname(root.idxs[1]) => val) do 
        scope(ctx) do ctx′
            root_tail = visit!(Loop(root.idxs[2:end], root.body), AccessSpikeTailVisitor(root, ctx′, idx, val))
            #The next call is a convenient fallback, but make no mistake, all chunks must work with all other chunks.
            #It's a handshake problem and you can't get around it.
            root_tail = visit!(root_tail, ForLoopVisitor(ctx′, idx, val))
            visit!(annihilate_index(root_tail), ctx′)
        end
    end
    return Expr(:block, body_expr, tail_expr)
end


Base.@kwdef struct AccessSpikeBodyVisitor <: AbstractTransformVisitor
    root
    ctx
    idx
end

function visit!(node::Spike, ctx::AccessSpikeBodyVisitor, ::DefaultStyle)
    return Run(node.body)
end

function visit!(node::Run, ctx::AccessSpikeBodyVisitor, ::DefaultStyle)
    return node
end

spike_body_stop(stop, ctx) = :($(visit!(stop, ctx)) - 1)
spike_body_stop(stop::Integer, ctx) = stop - 1

spike_body_range(ext::Extent, ctx) = Extent(ext.start, spike_body_stop(ext.stop, ctx))

Base.@kwdef struct AccessSpikeTailVisitor <: AbstractTransformVisitor
    root
    ctx
    idx
    val
end

function visit!(node::Access{Spike}, ctx::AccessSpikeTailVisitor, ::DefaultStyle)
    return node.tns.tail
end

function visit!(node::Access{Spike}, ctx::ForLoopVisitor, ::DefaultStyle)
    return node.tns.tail
end

Base.@kwdef mutable struct AcceptSpike
    val
    tail
end

struct AcceptSpikeStyle end

make_style(root::Loop, ctx::LowerJulia, node::Access{AcceptSpike, <:Union{Write, Update}}) = AcceptSpikeStyle()
combine_style(a::DefaultStyle, b::AcceptSpikeStyle) = AcceptSpikeStyle()
combine_style(a::ThunkStyle, b::AcceptSpikeStyle) = ThunkStyle()
combine_style(a::AcceptSpikeStyle, b::AcceptSpikeStyle) = AcceptSpikeStyle()
combine_style(a::AcceptRunStyle, b::AcceptSpikeStyle) = AcceptSpikeStyle()
combine_style(a::RunStyle, b::AcceptSpikeStyle) = RunStyle()
combine_style(a::SpikeStyle, b::AcceptSpikeStyle) = SpikeStyle()

function visit!(root::Loop, ctx::LowerJulia, ::AcceptSpikeStyle)
    #call DefaultStyle because we didn't simplify away the body or tail of
    #corresponding Spikes, and need to set all the elements of the spike.
    return visit!(Loop(root.idxs[1:end], root.body), ctx, DefaultStyle())
end

Base.@kwdef mutable struct AcceptSpikeVisitor <: AbstractTransformVisitor
    root
    ctx
end

function visit!(node::Access{AcceptSpike}, ctx::ForLoopVisitor, ::DefaultStyle)
    node.tns.tail(ctx.ctx, ctx.val)
end