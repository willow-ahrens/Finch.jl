using Pigeon: Read, Write, Update

Base.@kwdef struct Spike
    body
    tail
    ext
end

Pigeon.lower_axes(arr::Spike, ctx::LowerJuliaContext) = (arr.ext,) #TODO probably wouldn't need this if tests were more realistic
Pigeon.getsites(arr::Spike) = (1,) #TODO this is wrong I think?? and probably wouldn't need this if tests were more realistic
Pigeon.getname(arr::Spike) = gensym() #Probably also wrong.

struct SpikeStyle end

Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Spike) = SpikeStyle()
Pigeon.combine_style(a::DefaultStyle, b::SpikeStyle) = SpikeStyle()
Pigeon.combine_style(a::RunStyle, b::SpikeStyle) = SpikeStyle()
Pigeon.combine_style(a::SpikeStyle, b::SpikeStyle) = SpikeStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::SpikeStyle)
    if isempty(root.idxs) println(root) end
    @assert !isempty(root.idxs)
    root_body = visit!(root, AccessSpikeBodyContext(root))
    body_expr = restrict(ctx, getname(root.idxs[1]) => spike_body_range(ctx.dims[getname(root.idxs[1])])) do
        visit!(root_body, ctx)
    end
    root_tail = visit!(Loop(root.idxs[2:end], root.body), AccessSpikeTailContext(root))
    tail_expr = bind(ctx, root.idxs[1] => ctx.dims[getname(root.idxs[1])].stop) do 
        visit!(root_tail, ctx)
    end
    return Expr(:block, body_expr, tail_expr)
end

Base.@kwdef struct AccessSpikeBodyContext <: Pigeon.AbstractTransformContext
    root
end

function Pigeon.visit!(node::Access, ctx::AccessSpikeBodyContext, ::DefaultStyle)
    if ctx.root.idxs[1] in node.idxs
        return access_spike_body(node, ctx, ctx.root.idxs[1])
    end
    return node
end

function access_spike_body(node::Access{Run}, ctx, idx)
    @assert ctx.root.idxs[1:1] == node.idxs
    tns′ = deepcopy(node.tns)
    tns′.ext.stop = spike_body_stop(tns.ext.stop)
    return Access(tns′, node.mode, ctx.root.idxs[1:1])
end

function access_spike_body(node::Access{Spike}, ctx, idx)
    @assert ctx.root.idxs[1:1] == node.idxs
    return node.tns.body
end

function access_spike_body(node::Access{}, ctx, idx)
    return node #TODO truncate_block
end

#spike_body_stop(stop::Top) = Top()
spike_body_stop(stop::Virtual{T}) where {T <: Integer} = Virtual{T}(:($(stop.ex) - 1))

spike_body_range(ext::Extent) = Extent(ext.start, spike_body_stop(ext.stop))

Base.@kwdef struct AccessSpikeTailContext <: Pigeon.AbstractTransformContext
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
    return node.body
end

function access_spike_tail(node::Access{Spike}, ctx, idx)
    @assert ctx.root.idxs[1:1] == node.idxs
    return node.tns.tail
end

function access_spike_tail(node::Access, ctx, idx)
    return node
end