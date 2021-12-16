struct StreamStyle end

Base.@kwdef struct Stream
    body
    step
end

Pigeon.isliteral(::Stream) = false

Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Stream) = StreamStyle()
Pigeon.combine_style(a::DefaultStyle, b::StreamStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::StreamStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::RunStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::AcceptRunStyle) = StreamStyle()
Pigeon.combine_style(a::StreamStyle, b::SpikeStyle) = StreamStyle() #Not sure on this one
Pigeon.combine_style(a::StreamStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::ThunkStyle, b::StreamStyle) = ThunkStyle()
#Pigeon.combine_style(a::StreamStyle, b::PipelineStyle) = PipelineStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::StreamStyle)
    i = getname(root.idxs[1])
    thunk = Expr(:block)
    i0 = gensym(Symbol("_", i))
    i1 = gensym(Symbol("_", i))
    return quote
        $i0 = $(ctx.dims[i].start)
        $i1 = $i0 - 1
        while $i1 < $(visit!(ctx.dims[i].stop, ctx))
            $(scope(ctx) do ctx′
                stop = postmapreduce(node->stream_step!(node, ctx′, i0, i1), vcat, root, [])
                body = postmap(node->stream_body!(node, ctx′, i0, i1), root)
                push!(ctx′.preamble, :($i1 = min($(stop...))))
                restrict(ctx′, i => Extent(Virtual{Any}(i0), Virtual{Any}(i1))) do
                    visit!(body, ctx′)
                end
            end)
        end
    end
end

stream_step!(node, ctx, start, stop) = nothing
stream_step!(node::Stream, ctx, start, stop) = [node.step(ctx, start, stop)]
stream_body!(node, ctx, start, stop) = nothing
stream_body!(node::Stream, ctx, start, stop) = node.body(ctx, start, stop)