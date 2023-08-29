struct ReplayStyle end

@kwdef mutable struct Replay 
    body
    seek = (ctx, start) -> error("seek not implemented error")
end

Base.show(io::IO, ex::Replay) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Replay)
	print(io, "Replay(...)")
end

FinchNotation.finch_leaf(x::Replay) = virtual(x)

(ctx::Stylize{<:AbstractCompiler})(node::Replay) = ctx.root.kind === loop ? ReplayStyle() : DefaultStyle()

combine_style(a::DefaultStyle, b::ReplayStyle) = ReplayStyle()
combine_style(a::LookupStyle, b::ReplayStyle) = ReplayStyle()
combine_style(a::ReplayStyle, b::ReplayStyle) = ReplayStyle()
combine_style(a::ReplayStyle, b::RunStyle) = RunStyle()
combine_style(a::SimplifyStyle, b::ReplayStyle) = a
combine_style(a::ReplayStyle, b::AcceptRunStyle) = ReplayStyle()
combine_style(a::ReplayStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::ReplayStyle, b::SwitchStyle) = SwitchStyle()
combine_style(a::ReplayStyle, b::SequenceStyle) = SequenceStyle()
combine_style(a::ThunkStyle, b::ReplayStyle) = ThunkStyle()
combine_style(a::ReplayStyle, b::PhaseStyle) = b

function replay_seek(node::Replay, ctx, ext)
  if node.body isa Jump
    node.body = Jump(seek = node.seek, #Propagating Replay's seek to Jump 
                     preamble = node.body.preamble,
                     stop = node.body.stop,
                     chunk = node.body.chunk,
                     next = node.body.next)
  end
  return node.seek(ctx, ext)
end
replay_seek(node, ctx, ext) = quote end

function replay_body(node::Replay, ctx, ext)
  node.body isa Step || node.body isa Jump || error("Replay's body must be either Step or Jump")
  return node.body
end

replay_body(node, ctx, ext) = node

function lower(root::FinchNode, ctx::AbstractCompiler,  style::ReplayStyle)
    root.kind === loop || error("unimplemented")
    
    i = getname(root.idx)
    i0 = ctx.freshen(i, :_start)
    push!(ctx.preamble, quote
        $i = $(ctx(getstart(root.ext)))
    end)

    guard = :($i <= $(ctx(getstop(root.ext))))

    foreach(filter(isvirtual, collect(PostOrderDFS(root.body)))) do node
        push!(ctx.preamble, replay_seek(node.val, ctx, root.ext))
    end

    body_2 = Rewrite(Postwalk(@rule access(~tns::isvirtual, ~mode, ~idxs...) => begin
        tns_2 = replay_body(tns.val, ctx, root.ext)
        access(tns_2, mode, idxs...)
    end))(root.body)

    body_3 = contain(ctx) do ctx_2
        push!(ctx_2.preamble, :($i0 = $i))
        if is_continuous_extent(root.ext) 
            ctx_2(loop(root.idx, bound_measure_below!(ContinuousExtent(start = value(i0), stop = getstop(root.ext)), literal(0)), body_2))
        else
            ctx_2(loop(root.idx, bound_measure_below!(Extent(start = value(i0), stop = getstop(root.ext)), literal(1)), body_2))
        end
    end

    @assert isvirtual(root.ext)

    target = is_continuous_extent(root.ext.val) ? 0 : 1
    if query(call(==, measure(root.ext.val), target), ctx)
        body_3
    else
        return quote
            while $guard
                $body_3
            end
        end
    end
end

