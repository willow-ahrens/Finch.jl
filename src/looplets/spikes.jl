@kwdef struct Spike
    body
    tail
end

Base.show(io::IO, ex::Spike) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Spike)
    print(io, "Spike(body = ")
    print(io, ex.body)
    print(io, ")")
end

FinchNotation.isliteral(::Spike) =  false

struct SpikeStyle end

(ctx::Stylize{LowerJulia})(node::Spike) = ctx.root.kind === chunk ? SpikeStyle() : DefaultStyle()
combine_style(a::DefaultStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::RunStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::ThunkStyle, b::SpikeStyle) = ThunkStyle()
combine_style(a::SimplifyStyle, b::SpikeStyle) = SimplifyStyle()
combine_style(a::AcceptRunStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::SpikeStyle, b::SpikeStyle) = SpikeStyle()

function (ctx::LowerJulia)(root::FinchNode, ::SpikeStyle)
    if root.kind === chunk
        root_body = SpikeBodyVisitor(ctx, root.idx, root.ext, Extent(spike_body_getstop(getstop(root.ext), ctx), getstop(root.ext)))(root.body)
        if extent(root.ext) == 1
            body_expr = quote end
        else
            #TODO check body nonempty
            body_expr = contain(ctx) do ctx_2
                (ctx_2)(chunk(
                    root.idx,
                    spike_body_range(root.ext, ctx),
                    root_body,
                ))
            end
        end
        root_tail = SpikeTailVisitor(ctx, root.idx, getstop(root.ext))(root.body)
        tail_expr = contain(ctx) do ctx_2
            (ctx_2)(chunk(
                root.idx,
                Extent(start = getstop(root.ext), stop = getstop(root.ext), lower = 1, upper = 1),
                root_tail,
            ))
        end
        return Expr(:block, body_expr, tail_expr)
    else
        error("unimplemented")
    end
end

@kwdef struct SpikeBodyVisitor
    ctx
    idx
    ext
    ext_2
end

function (ctx::SpikeBodyVisitor)(node)
    if istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        truncate(node, ctx.ctx, ctx.ext, ctx.ext_2)
    end
end

function (ctx::SpikeBodyVisitor)(node::FinchNode)
    if node.kind === virtual
        return ctx(node.val)
    elseif istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        truncate(node, ctx.ctx, ctx.ext, ctx.ext_2)
    end
end

function (ctx::SpikeBodyVisitor)(node::Spike)
    return Run(node.body)
end

(ctx::SpikeBodyVisitor)(node::Shift) = Shift(SpikeBodyVisitor(;kwfields(ctx)..., ext = shiftdim(ctx.ext, call(-, node.delta)), ext_2 = shiftdim(ctx.ext_2, call(-, node.delta)))(node.body), node.delta)

spike_body_getstop(stop, ctx) = :($(ctx(stop)) - 1)
spike_body_getstop(stop::Integer, ctx) = stop - 1

spike_body_range(ext, ctx) = Extent(getstart(ext), spike_body_getstop(getstop(ext), ctx))

@kwdef struct SpikeTailVisitor
    ctx
    idx
    val
end

function (ctx::SpikeTailVisitor)(node)
    if istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end

function (ctx::SpikeTailVisitor)(node::FinchNode)
    if node.kind === access && node.tns.kind === virtual
        tns_2 = unchunk(node.tns.val, ctx)
        if tns_2 === nothing
            access(node.tns, node.mode, map(ctx, node.idxs)...)
        else
            access(tns_2, node.mode, map(ctx, node.idxs[1:end - 1])...)
        end
    elseif node.kind === virtual
        ctx(node.val)
    elseif istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end
unchunk(node::Spike, ctx::SpikeTailVisitor) = node.tail
unchunk(node::Shift, ctx::SpikeTailVisitor) = unchunk(node.body, SpikeTailVisitor(;kwfields(ctx)..., val = call(-, ctx.val, node.delta)))

#TODO this is sus
unchunk(node::Spike, ctx::ForLoopVisitor) = node.tail

supports_shift(::SpikeStyle) = true

@kwdef mutable struct AcceptSpike
    val
    tail
end

FinchNotation.isliteral(::AcceptSpike) = false

Base.show(io::IO, ex::AcceptSpike) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::AcceptSpike)
    print(io, "AcceptSpike(val = ")
    print(io, ex.val)
    print(io, ")")
end

virtual_default(node::AcceptSpike) = Some(node.val)

unchunk(node::AcceptSpike, ctx::ForLoopVisitor) = node.tail(ctx.ctx, ctx.val)

function truncate(node::Spike, ctx, ext, ext_2)
    return Switch([
        value(:($(ctx(getstop(ext_2))) < $(ctx(getstop(ext))))) => Run(node.body),
        literal(true) => node,
    ])
end
truncate_weak(node::Spike, ctx, ext, ext_2) = node
truncate_strong(node::Spike, ctx, ext, ext_2) = Run(node.body)