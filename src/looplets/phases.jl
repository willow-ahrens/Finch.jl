@kwdef struct Phase
    head = nothing
    body
    stop = (ctx, ext) -> nothing
    range = (ctx, ext) -> Extent(getstart(ext), something(stop(ctx, ext), getstop(ext)))
end
FinchNotation.finch_leaf(x::Phase) = virtual(x)

Base.show(io::IO, ex::Phase) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Phase)
    print(io, "Phase()")
end

function phase_range(node::FinchNode, ctx, ext)
    if @capture node access(~tns::isvirtual, ~i...)
        phase_range(tns.val, ctx, ext)
    else
        return nodim
    end
end

phase_range(node, ctx, ext) = nodim
phase_range(node::Phase, ctx, ext) = Narrow(node.range(ctx, ext))
phase_range(node::Shift, ctx, ext) = shiftdim(phase_range(node.body, ctx, shiftdim(ext, call(-, node.delta))), node.delta)

function phase_body(node::FinchNode, ctx, ext, ext_2)
    if @capture node access(~tns::isvirtual, ~i...)
        access(phase_body(tns.val, ctx, ext, ext_2), i...)
    else
        return node
    end
end
phase_body(node::Phase, ctx, ext, ext_2) = node.body(ctx, ext_2)
phase_body(node::Spike, ctx, ext, ext_2) = truncate(node, ctx, ext, ext_2) #TODO This should be called on everything
phase_body(node, ctx, ext, ext_2) = node
phase_body(node::Shift, ctx, ext, ext_2) = Shift(phase_body(node.body, ctx, shiftdim(ext, call(-, node.delta)), shiftdim(ext_2, call(-, node.delta))), node.delta)

struct PhaseStyle end

supports_shift(::PhaseStyle) = true

(ctx::Stylize{LowerJulia})(node::Phase) = ctx.root.kind === loop ? PhaseStyle() : DefaultStyle()

combine_style(a::DefaultStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::PhaseStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::PhaseStyle, b::RunStyle) = PhaseStyle()
combine_style(a::PhaseStyle, b::SpikeStyle) = PhaseStyle()
combine_style(a::SimplifyStyle, b::PhaseStyle) = a
combine_style(a::AcceptRunStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::SwitchStyle, b::PhaseStyle) = SwitchStyle()
combine_style(a::ThunkStyle, b::PhaseStyle) = ThunkStyle()

function (ctx::LowerJulia)(root::FinchNode, ::PhaseStyle)
    if root.kind === loop
        i = getname(root.idx)
        i0=ctx.freshen(i)

        body = root.body

        ext_2 = resolvedim(mapreduce((node)->phase_range(node, ctx, root.ext), (a, b) -> resultdim(ctx, a, b), PostOrderDFS(body), init=nodim))

        ext_3 = resolvedim(resultdim(ctx, Narrow(root.ext), ext_2))

        #if query(call(==, getstart(ext_3), getstart(ext_2)), ctx) && query(call(==, getstop(ext_3), getstop(ext_2)), ctx)
        #    ext_3 = ext_2
        #end

        ext_4 = cache_dim!(ctx, :phase, ext_3)

        body = Rewrite(Postwalk(node->phase_body(node, ctx, root.ext, ext_4)))(body)
        body = quote
            $i0 = $i
            $(contain(ctx) do ctx_4
                (ctx_4)(loop(
                    root.idx,
                    ext_4,
                    body
                ))
            end)
            $i = $(ctx(getstop(ext_4))) + $(Int8(1))
        end

        if query(call(>=, measure(ext_4), 1), ctx)
            return body
        else
            return quote
                if $(ctx(getstop(ext_4))) >= $(ctx(getstart(ext_4)))
                    $body
                end
            end
        end
    else
        error("unimplemented")
    end
end