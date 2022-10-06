@kwdef struct Phase
    head = nothing
    body
    stride = (ctx, idx, ext) -> nothing
    range = (ctx, idx, ext) -> Extent(start = getstart(ext), stop = something(stride(ctx, idx, ext), getstop(ext)))
end
isliteral(::Phase) = false

Base.show(io::IO, ex::Phase) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Phase)
    print(io, "Phase()")
end

@kwdef struct PhaseStride
    ctx
    idx
    ext
end

function (ctx::PhaseStride)(node)
    if istree(node)
        return mapreduce(ctx, resultdim, arguments(node), init = nodim)
    else
        return nodim
    end
end

(ctx::PhaseStride)(node::Phase) = Narrow(node.range(ctx.ctx, ctx.idx, ctx.ext))
(ctx::PhaseStride)(node::Shift) = shiftdim(PhaseStride(;kwfields(ctx)..., ext = shiftdim(ctx.ext, call(-, node.delta)))(node.body), node.delta)

@kwdef struct PhaseBodyVisitor
    ctx
    idx
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

(ctx::PhaseBodyVisitor)(node::Phase) = node.body(getstart(ctx.ext_2), getstop(ctx.ext_2))
(ctx::PhaseBodyVisitor)(node::Spike) = truncate(node, ctx.ctx, ctx.ext, ctx.ext_2) #TODO This should be called on everything

#(ctx::PhaseBodyVisitor)(node::Shift) = (println(:hewwo); Shift(PhaseBodyVisitor(ctx.ctx, ctx.idx, shiftdim(ctx.ext, call(-, node.delta)), shiftdim(ctx.ext_2, call(-, node.delta)))(node.body), node.delta))
(ctx::PhaseBodyVisitor)(node::Shift) = Shift(PhaseBodyVisitor(ctx.ctx, ctx.idx, shiftdim(ctx.ext, call(-, node.delta)), shiftdim(ctx.ext_2, call(-, node.delta)))(node.body), node.delta)

struct PhaseStyle end

supports_shift(::PhaseStyle) = true

#isliteral(::Step) = false

(ctx::Stylize{LowerJulia})(node::Phase) = ctx.root isa Chunk ? PhaseStyle() : DefaultStyle()

combine_style(a::DefaultStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::PhaseStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::PhaseStyle, b::RunStyle) = PhaseStyle()
combine_style(a::PhaseStyle, b::SpikeStyle) = PhaseStyle()
combine_style(a::SimplifyStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::AcceptRunStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::SwitchStyle, b::PhaseStyle) = SwitchStyle()
combine_style(a::ThunkStyle, b::PhaseStyle) = ThunkStyle()

function (ctx::LowerJulia)(root::Chunk, ::PhaseStyle)
    i = getname(root.idx)
    i0=ctx.freshen(i)

    body = root.body

    ext_2 = resolvedim(PhaseStride(ctx, root.idx, root.ext)(body))
    ext_2 = cache!(ctx, :phase, resolvedim(resultdim(Narrow(root.ext), ext_2)))

    body = PhaseBodyVisitor(ctx, root.idx, root.ext, ext_2)(body)
    body = quote
        $i0 = $i
        $(contain(ctx) do ctx_4
            (ctx_4)(Chunk(
                idx = root.idx,
                ext = ext_2,
                body = body
            ))
        end)
        $i = $(ctx(getstop(ext_2))) + 1
    end

    if simplify(@f $(getlower(ext_2)) >= 1) == true
        return body
    else
        return quote
            if $(ctx(getstop(ext_2))) >= $(ctx(getstart(ext_2)))
                $body
            end
        end
    end
end