@kwdef struct Phase
    head = nothing
    body
    stride = nothing
    guard = nothing
end

isliteral(::Phase) = false

@kwdef struct PhaseGuardVisitor <: AbstractCollectVisitor
    ctx
    idx
    start
end
collect_op(::PhaseGuardVisitor) = (args) -> vcat(args...) #flatten?
collect_zero(::PhaseGuardVisitor) = []
(ctx::PhaseGuardVisitor)(node::Phase, ::DefaultStyle) = node.guard === nothing ? [] : [something(node.guard)(ctx.start)]

@kwdef struct PhaseStrideVisitor <: AbstractCollectVisitor
    ctx
    idx
    start
end
collect_op(::PhaseStrideVisitor) = (args) -> vcat(args...) #flatten?
collect_zero(::PhaseStrideVisitor) = []
(ctx::PhaseStrideVisitor)(node::Phase, ::DefaultStyle) = node.stride === nothing ? [] : [something(node.stride)(ctx.start)]

@kwdef struct PhaseBodyVisitor <: AbstractTransformVisitor
    ctx
    idx
    start
    step
    stop
end
(ctx::PhaseBodyVisitor)(node::Phase, ::DefaultStyle) = node.body(ctx.start, ctx.step)
(ctx::PhaseBodyVisitor)(node::Spike, ::DefaultStyle) = truncate(node, ctx.ctx, ctx.start, ctx.step, ctx.stop)

(ctx::PhaseStrideVisitor)(node::Shift, ::DefaultStyle) = map(stride -> call(+, stride, node.shift), ctx(node.body))
(ctx::PhaseBodyVisitor)(node::Shift, ::DefaultStyle) = PhaseBodyVisitor(ctx.ctx, ctx.idx, call(-, ctx.start, node.shift), call(-, ctx.step, node.shift), call(-, ctx.stop, node.shift))(node.body)

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
        ext_2 = resultdim(ctx, false, ext_2, phase_range(node, ctx, root.idx, root.ext))
        nothing
    end)(body)

    ext_2 = resolvedim(ctx, combinedim(ctx, false, Narrow(root.ext), resolvedim(ctx, ext_2)))

    body = Postwalk(node->phase_body(node, ctx, root.idx, root.ext, ext_2))(body)
    quote
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
end

phase_range(node, ctx, idx, ext) = NoDimension()
phase_range(node::Phase, ctx, idx, ext) = Narrow(Extent(getstart(ext), PhaseStrideVisitor(ctx, idx, getstart(ext))(node)[1]))

phase_body(node, ctx, idx, ext, ext_2) = nothing
phase_body(node, ctx, idx, ext, ext_2) = PhaseBodyVisitor(ctx, idx, ctx(getstart(ext_2)), ctx(getstop(ext_2)), ctx(getstop(ext)))(node)