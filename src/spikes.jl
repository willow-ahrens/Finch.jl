@kwdef struct Spike
    body
    tail
end

isliteral(::Spike) = false

struct SpikeStyle end

(ctx::Stylize{LowerJulia})(node::Spike) = SpikeStyle()
combine_style(a::DefaultStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::RunStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::ThunkStyle, b::SpikeStyle) = ThunkStyle()
combine_style(a::SimplifyStyle, b::SpikeStyle) = SimplifyStyle()
combine_style(a::AcceptRunStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::SpikeStyle, b::SpikeStyle) = SpikeStyle()

function (ctx::LowerJulia)(root::Chunk, ::SpikeStyle)
    root_body = SpikeBodyVisitor(ctx, root.idx, root.ext, Extent(spike_body_getstop(getstop(root.ext), ctx), getstop(root.ext)))(root.body)
    if extent(root.ext) == 1
        body_expr = quote end
    else
        #TODO check body nonempty
        body_expr = contain(ctx) do ctx_2
            (ctx_2)(Chunk(
                idx = root.idx,
                ext = spike_body_range(root.ext, ctx),
                body = root_body,
            ))
        end
    end
    root_tail = SpikeTailVisitor(ctx, root.idx, getstop(root.ext))(root.body)
    tail_expr = contain(ctx) do ctx_2
        (ctx_2)(Chunk(
            idx = root.idx,
            ext = Extent(start = getstop(root.ext), stop = getstop(root.ext), lower = 1, upper = 1),
            body = root_tail,
        ))
    end
    return Expr(:block, body_expr, tail_expr)
end

@kwdef struct SpikeBodyVisitor <: AbstractTransformVisitor
    ctx
    idx
    ext
    ext_2
end

function (ctx::SpikeBodyVisitor)(node::Access, ::DefaultStyle)
    return Access(truncate(node.tns, ctx.ctx, ctx.ext, ctx.ext_2), node.mode, node.idxs)
end

function (ctx::SpikeBodyVisitor)(node::Access{Spike}, ::DefaultStyle)
    return Access(Run(node.tns.body), node.mode, node.idxs)
end

spike_body_getstop(stop, ctx) = :($(ctx(stop)) - 1)
spike_body_getstop(stop::Integer, ctx) = stop - 1

spike_body_range(ext, ctx) = Extent(getstart(ext), spike_body_getstop(getstop(ext), ctx))

@kwdef struct SpikeTailVisitor <: AbstractTransformVisitor
    ctx
    idx
    val
end

function (ctx::SpikeTailVisitor)(node::Access{Spike}, ::DefaultStyle)
    return node.tns.tail
end

function (ctx::ForLoopVisitor)(node::Access{Spike}, ::DefaultStyle)
    return node.tns.tail
end

supports_shift(::SpikeStyle) = true
(ctx::SpikeBodyVisitor)(node::Shift, ::DefaultStyle) = SpikeBodyVisitor(ctx.ctx, ctx.idx, call(-, ctx.start, node.shift), call(-, ctx.step, node.shift), call(-, ctx.stop, node.shift))(node.body)

@kwdef mutable struct AcceptSpike
    val
    tail
end

default(node::AcceptSpike) = node.val #TODO is this semantically... okay?

function (ctx::ForLoopVisitor)(node::Access{AcceptSpike}, ::DefaultStyle)
    node.tns.tail(ctx.ctx, ctx.val)
end

function truncate(node::Spike, ctx, ext, ext_2)
    return Cases([
        :($(ctx(getstop(ext_2))) < $(ctx(getstop(ext)))) => Run(node.body),
        true => node,
    ])
end
truncate_weak(node::Spike, ctx, ext, ext_2) = node
truncate_strong(node::Spike, ctx, ext, ext_2) = Run(node.body)