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

FinchNotation.finch_leaf(x::Spike) = virtual(x)

struct SpikeStyle end

(ctx::Stylize{<:AbstractCompiler})(node::Spike) = ctx.root.kind === loop ? SpikeStyle() : DefaultStyle()
combine_style(a::DefaultStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::RunStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::ThunkStyle, b::SpikeStyle) = ThunkStyle()
combine_style(a::SimplifyStyle, b::SpikeStyle) = a
combine_style(a::AcceptRunStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::SpikeStyle, b::SpikeStyle) = SpikeStyle()

function lower(root::FinchNode, ctx::AbstractCompiler,  ::SpikeStyle)
    if root.kind === loop
        #body_ext = Extent(getstart(root.ext), call(-, getstop(root.ext), 1))
        body_ext = Extent(getstart(root.ext), call(-, getstop(root.ext), Eps))
        root_body = Rewrite(Postwalk(
            @rule access(~a::isvirtual, ~i...) => access(get_spike_body(a.val, ctx, root.ext, body_ext), ~i...)
        ))(root.body)
        @assert isvirtual(root.ext)
        if query(call(<=, measure(body_ext), 0), ctx) 
            body_expr = quote end
        else
            #TODO check body nonempty
            body_expr = contain(ctx) do ctx_2
                (ctx_2)(loop(
                    root.idx,
                    body_ext,
                    root_body,
                ))
            end
        end
        tail_ext = Extent(getstop(root.ext), getstop(root.ext))
        root_tail = Rewrite(Postwalk(
            @rule access(~a::isvirtual, ~i...) => access(get_spike_tail(a.val, ctx, root.ext, tail_ext), ~i...)
        ))(root.body)
        tail_expr = contain(ctx) do ctx_2
            (ctx_2)(loop(
                root.idx,
                tail_ext,
                root_tail,
            ))
        end
        return Expr(:block, body_expr, tail_expr)
    else
        error("unimplemented")
    end
end

get_spike_body(node, ctx, ext, ext_2) = node
get_spike_body(node::Spike, ctx, ext, ext_2) = Run(node.body)
get_spike_body(node::Shift, ctx, ext, ext_2) = Shift(
    body = get_spike_body(node.body, ctx,
        shiftdim(ext, call(-, node.delta)),
        shiftdim(ext_2, call(-, node.delta))),
    delta = node.delta)

get_spike_tail(node, ctx, ext, ext_2) = node
get_spike_tail(node::Spike, ctx, ext, ext_2) = Run(node.tail)
get_spike_tail(node::Shift, ctx, ext, ext_2) = Shift(
    body = get_spike_tail(node.body, ctx,
        shiftdim(ext, call(-, node.delta)),
        shiftdim(ext_2, call(-, node.delta))),
    delta = node.delta)

supports_shift(::SpikeStyle) = true

function truncate(node::Spike, ctx, ext, ext_2)
    println("YYYYYY")
    #if query(call(>=, call(-, getstop(ext), 1), getstop(ext_2)), ctx, verbose=true)
    if query(call(>=, call(-, getstop(ext), Eps), getstop(ext_2)), ctx, verbose=true)
        println("XXXXX0")
        Run(node.body)
    elseif query(call(==, getstop(ext), getstop(ext_2)), ctx)
        println("XXXXX1")
        node
    else
        println("XXXXX2")
        return Switch([
            value(:($(ctx(getstop(ext_2))) < $(ctx(getstop(ext))))) => Run(node.body),
            literal(true) => node,
        ])
    end
end
