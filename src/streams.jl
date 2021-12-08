struct StreamStyle end

Base.@kwdef struct Stream
    body
end

Base.@kwdef struct Packet
    body
    step
end

Pigeon.isliteral(::Stream) = false
Pigeon.isliteral(::Packet) = false

Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Stream) = StreamStyle()
Pigeon.combine_style(a::DefaultStyle, b::StreamStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::StreamStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::RunAccessStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::RunAssignStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::SpikeStyle) = StreamStyle() #Not sure on this one
Pigeon.combine_style(a::StreamStyle, b::CaseStyle) = CaseStyle()
#Pigeon.combine_style(a::StreamStyle, b::PipelineStyle) = PipelineStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::StreamStyle)
    i = getname(root.idxs[1])
    thunk = Expr(:block)
    i0 = gensym(Symbol("_", i))
    i1 = gensym(Symbol("_", i))
    body = postmap(node->stream_body!(node, ctx), root)
    return quote
        $i0 = $(ctx.dims[i].start)
        $i1 = $i0 - 1
        while $i1 < $(visit!(ctx.dims[i].stop, ctx))
            $(scope(ctx) do ctx′
                stop = postmapreduce(node->packet_step!(node, ctx′, i0, i1), vcat, body, [])
                body = postmap(node->packet_body!(node, ctx′, i0, i1), body)
                push!(ctx′.preamble, :($i1 = min($(stop...))))
                restrict(ctx′, i => Extent(Virtual{Any}(i0), Virtual{Any}(i1))) do
                    visit!(body, ctx′)
                end
            end)
        end
    end
end

stream_body!(node, ctx) = nothing
stream_body!(node::Stream, ctx) = node.body(ctx)

packet_step!(node, ctx, start, stop) = nothing
packet_step!(node::Packet, ctx, start, stop) = [node.step(ctx, start, stop)]
packet_body!(node, ctx, start, stop) = nothing
packet_body!(node::Packet, ctx, start, stop) = node.body(ctx, start, stop)