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

@kwdef struct PhaseBodyVisitor
    ctx
    ext
    ext_2
end

function (ctx::PhaseBodyVisitor)(node)
    if istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end
function (ctx::PhaseBodyVisitor)(node::FinchNode)
    if node.kind === virtual
        ctx(node.val)
    elseif istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end

(ctx::PhaseBodyVisitor)(node::Phase) = node.body(ctx.ctx, ctx.ext_2)
(ctx::PhaseBodyVisitor)(node::Spike) = truncate(node, ctx.ctx, ctx.ext, ctx.ext_2) #TODO This should be called on everything

(ctx::PhaseBodyVisitor)(node::Shift) = Shift(PhaseBodyVisitor(ctx.ctx, shiftdim(ctx.ext, call(-, node.delta)), shiftdim(ctx.ext_2, call(-, node.delta)))(node.body), node.delta)

struct PhaseStyle end

supports_shift(::PhaseStyle) = true

(ctx::Stylize{LowerJulia})(node::Phase) = ctx.root.kind === chunk ? PhaseStyle() : DefaultStyle()

combine_style(a::DefaultStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::PhaseStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::PhaseStyle, b::RunStyle) = PhaseStyle()
combine_style(a::PhaseStyle, b::SpikeStyle) = PhaseStyle()
combine_style(a::SimplifyStyle, b::PhaseStyle) = a
combine_style(a::AcceptRunStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::SwitchStyle, b::PhaseStyle) = SwitchStyle()
combine_style(a::ThunkStyle, b::PhaseStyle) = ThunkStyle()

function (ctx::LowerJulia)(root::FinchNode, ::PhaseStyle)
    if root.kind === chunk
        i = getname(root.idx)
        i0=ctx.freshen(i)

        body = root.body

        ext_2 = resolvedim(mapreduce((node)->phase_range(node, ctx, root.ext), (a, b) -> resultdim(ctx, a, b), PostOrderDFS(body), init=nodim))
        ext_2 = cache_dim!(ctx, :phase, resolvedim(resultdim(ctx, Narrow(root.ext), ext_2)))

        body = PhaseBodyVisitor(ctx, root.ext, ext_2)(body)
        body = quote
            $i0 = $i
            $(contain(ctx) do ctx_4
                (ctx_4)(chunk(
                    root.idx,
                    ext_2,
                    body
                ))
            end)
            $i = $(ctx(getstop(ext_2))) + $(Int8(1))
        end

        if query(call(>, measure(ext_2), 0), ctx)
            return body
        else
            return quote
                if $(ctx(getstop(ext_2))) >= $(ctx(getstart(ext_2)))
                    $body
                end
            end
        end
    else
        error("unimplemented")
    end
end