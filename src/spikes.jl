@kwdef struct Spike
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

function (ctx::LowerJulia)(root::Loop, ::SpikeStyle)
    @assert !isempty(root.idxs)
    idx = root.idxs[1]
    root_body = AccessSpikeBodyVisitor(root, ctx, idx)(root)
    #TODO arguably we could take several better alternative approaches to rediminsionalization here
    body_expr = restrict(ctx, getname(root.idxs[1]) => spike_body_range(ctx.dims[getname(root.idxs[1])], ctx)) do
        scope(ctx) do ctx_2
            (ctx_2)(annihilate_index(root_body))
        end
    end
    val = stop(ctx.dims[getname(root.idxs[1])])
    tail_expr = bind(ctx, getname(root.idxs[1]) => val) do 
        scope(ctx) do ctx_2
            root_tail = AccessSpikeTailVisitor(root, ctx_2, idx, val)(Loop(root.idxs[2:end], root.body))
            #The next call is a convenient fallback, but make no mistake, all chunks must work with all other chunks.
            #It's a handshake problem and you can't get around it.
            root_tail = ForLoopVisitor(ctx_2, idx, val)(root_tail)
            (ctx_2)(annihilate_index(root_tail))
        end
    end
    return Expr(:block, body_expr, tail_expr)
end


@kwdef struct AccessSpikeBodyVisitor <: AbstractTransformVisitor
    root
    ctx
    idx
end

function (ctx::AccessSpikeBodyVisitor)(node::Spike, ::DefaultStyle)
    return Run(node.body)
end

function (ctx::AccessSpikeBodyVisitor)(node::Run, ::DefaultStyle)
    return node
end

spike_body_stop(stop, ctx) = :($(ctx(stop)) - 1)
spike_body_stop(stop::Integer, ctx) = stop - 1

spike_body_range(ext::Extent, ctx) = Extent(start(ext), spike_body_stop(stop(ext), ctx))

@kwdef struct AccessSpikeTailVisitor <: AbstractTransformVisitor
    root
    ctx
    idx
    val
end

function (ctx::AccessSpikeTailVisitor)(node::Access{Spike}, ::DefaultStyle)
    return node.tns.tail
end

function (ctx::ForLoopVisitor)(node::Access{Spike}, ::DefaultStyle)
    return node.tns.tail
end

@kwdef mutable struct AcceptSpike
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

function (ctx::LowerJulia)(root::Loop, ::AcceptSpikeStyle)
    #call DefaultStyle because we didn't simplify away the body or tail of
    #corresponding Spikes, and need to set all the elements of the spike.
    return ctx(Loop(root.idxs[1:end], root.body), DefaultStyle())
end

@kwdef mutable struct AcceptSpikeVisitor <: AbstractTransformVisitor
    root
    ctx
end

function (ctx::ForLoopVisitor)(node::Access{AcceptSpike}, ::DefaultStyle)
    node.tns.tail(ctx.ctx, ctx.val)
end