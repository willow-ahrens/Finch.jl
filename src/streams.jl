struct StreamStyle end

@kwdef struct Stream
    extent
    body
end

@kwdef struct Packet
    body
    step
end

Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Stream) = StreamStyle()
Pigeon.combine_style(a::DefaultStyle, b::StreamStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::StreamStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::PipelineStyle) = PipelineStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::StreamStyle)
    i = getname(root.idxs[1])
    thunk = Expr(:block)
    i0 = gensym(Symbol("_", i))
    i1 = gensym(Symbol("_", i))
    body = postmap(node->stream_body!(node, ctx), root)
    return quote
        $i0 = $(ctx.dims[root.idxs[1]].start)
        $i1 = $i0 - 1
        while $i1 < $(ctx.dims[root.idxs[1]].stop)
            $(scope(ctx) do ctx′
                stop = postmapreduce(node->packet_step!(node, ctx′, i0, i1), vcat, root, [])
                body = postmapreduce(node->packet_body!(node, ctx′, i0, i1), vcat, root, [])
                push!(ctx′.preamble, :($i1 = min($(stop...))))
                trim = postmapreduce(node->trim_chunk_stop!(node, ctx′, i1), body)
                restrict(ctx′, root.idxs[1] => Extent(Virtual{Any}(i0), Virtual{Any}(i1))) do
                    visit!(trim, ctx′)
                end
            end)
        end
    end
end

stream_body!(node, ctx) = nothing
stream_body!(node::Stream, ctx) = node.body(ctx)

packet_step!(node, ctx, start, stop) = nothing
packet_step!(node::Packet, ctx, start, stop) = node.step(ctx, start, stop)
packet_body!(node, ctx, start, stop) = nothing
packet_body!(node::Packet, ctx, start, stop) = node.body(ctx, start, stop)