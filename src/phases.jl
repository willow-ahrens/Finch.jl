@kwdef struct Phase
    head = nothing
    body
    stride = nothing
end

isliteral(::Phase) = false

@kwdef struct PhaseStride
    ctx
    idx
    ext
end

function (ctx::PhaseStride)(node)
    if istree(node)
        return mapreduce(ctx, reducedim, arguments(node))
    else
        return nodim
    end
end

(ctx::PhaseStride)(node::Phase) = Narrow(Extent(start = getstart(ctx.ext), stop = node.stride === nothing ? getstop(ctx.ext) : node.stride(getstart(ctx.ext))))
(ctx::PhaseStride)(node::Shift) = shiftdim(PhaseStride(;kwfields(ctx)..., ext = shiftdim(ctx.ext, call(-, node.shift)))(node.body), node.shift)

@kwdef struct PhaseBodyVisitor <: AbstractTransformVisitor
    ctx
    idx
    ext
    ext_2
end
(ctx::PhaseBodyVisitor)(node::Phase, ::DefaultStyle) = node.body(getstart(ctx.ext_2), getstop(ctx.ext_2))
(ctx::PhaseBodyVisitor)(node::Spike, ::DefaultStyle) = truncate(node, ctx.ctx, ctx.ext, ctx.ext_2)

(ctx::PhaseBodyVisitor)(node::Shift, ::DefaultStyle) = PhaseBodyVisitor(ctx.ctx, ctx.idx, shiftdim(ctx.ext, call(-, node.shift)), shiftdim(ctx.ext_2, call(-, node.shift)))(node.body)

struct PhaseStyle end

#isliteral(::Step) = false

make_style(root::Chunk, ctx::LowerJulia, node::Phase) = PhaseStyle()

combine_style(a::DefaultStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::PhaseStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::SimplifyStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::AcceptRunStyle, b::PhaseStyle) = PhaseStyle()
combine_style(a::CaseStyle, b::PhaseStyle) = CaseStyle()
combine_style(a::ThunkStyle, b::PhaseStyle) = ThunkStyle()

function (ctx::LowerJulia)(root::Chunk, ::PhaseStyle)
    i = getname(root.idx)
    i0=ctx.freshen(i)

    body = root.body

    ext_2 = NoDimension()
    Postwalk(node->begin
        ext_2 = resultdim(ext_2, phase_range(node, ctx, root.idx, root.ext))
        nothing
    end)(body)

    ext_2 = cache!(ctx, :phase, resolvedim(resultdim(Narrow(root.ext), resolvedim(ext_2))))

    body = Postwalk(node->phase_body(node, ctx, root.idx, root.ext, ext_2))(body)
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

    if simplify(@i $(getlower(ext_2)) >= 1) == true
        return body
    else
        return quote
            if $(ctx(getstop(ext_2))) >= $(ctx(getstart(ext_2)))
                $body
            end
        end
    end
end

phase_range(node, ctx, idx, ext) = NoDimension()
phase_range(node::Phase, ctx, idx, ext) = PhaseStride(ctx, idx, ext)(node)

phase_body(node, ctx, idx, ext, ext_2) = truncate(node, ctx, ext, ext_2)
phase_body(node::Phase, ctx, idx, ext, ext_2) = node.body(getstart(ext_2), getstop(ext_2))
function phase_body(node::Shift, ctx, idx, ext, ext_2)
    body_2 = phase_body(node.body, ctx, idx, shiftdim(ext, call(-, node.shift)), shiftdim(ext_2, call(-, node.shift)))
    if body_2 != nothing
        return Shift(body = body_2, shift=node.shift)
    end
end