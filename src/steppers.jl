struct StepperStyle end

@kwdef struct Stepper
    body
    seek = (ctx, start) -> error("seek not implemented error")
end

isliteral(::Stepper) = false

make_style(root::Chunk, ctx::LowerJulia, node::Stepper) = StepperStyle()

combine_style(a::DefaultStyle, b::StepperStyle) = StepperStyle()
combine_style(a::StepperStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::StepperStyle, b::StepperStyle) = StepperStyle()
combine_style(a::StepperStyle, b::RunStyle) = RunStyle()
combine_style(a::SimplifyStyle, b::StepperStyle) = SimplifyStyle()
combine_style(a::StepperStyle, b::AcceptRunStyle) = StepperStyle()
combine_style(a::StepperStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::StepperStyle, b::CaseStyle) = CaseStyle()
combine_style(a::ThunkStyle, b::StepperStyle) = ThunkStyle()
combine_style(a::StepperStyle, b::JumperStyle) = JumperStyle()

function (ctx::LowerJulia)(root::Chunk, ::StepperStyle)
    i = getname(root.idx)
    i0 = ctx.freshen(i, :_start)
    push!(ctx.preamble, quote
        $i0 = $(ctx(start(root.ext)))
        $i = $(ctx(start(root.ext)))
    end)

    if extent(root.ext) == 1
        body = StepperVisitor(i0, ctx)(root)
        return contain(ctx) do ctx_2
            body_2 = ThunkVisitor(ctx_2)(body)
            body_3 = (PhaseBodyVisitor(ctx_2, i, i0, i0, ctx_2(stop(root.ext))))(body_2)
            (ctx_2)(body_3)
        end
    else
        guard = :($i <= $(ctx(stop(root.ext))))
        body = StepperVisitor(i0, ctx)(root.body)

        body_2 = fixpoint(ctx) do ctx_2
            scope(ctx_2) do ctx_3
                contain(ctx_3) do ctx_4
                    push!(ctx_4.preamble, :($i0 = $i))
                    ctx_4(Chunk(root.idx, Extent(i0, stop(root.ext)), body))
                end
            end
        end
        return quote
            while $guard
                $body_2
            end
        end
    end
end

@kwdef struct StepperVisitor <: AbstractTransformVisitor
    start
    ctx
end
function (ctx::StepperVisitor)(node::Stepper, ::DefaultStyle)
    push!(ctx.ctx.preamble, node.seek(ctx, ctx.start))
    node.body
end

truncate(node, ctx, start, step, stop) = node
function truncate(node::Spike, ctx, start, step, stop)
    return Cases([
        :($(step) < $(stop)) => Run(node.body),
        true => node,
    ])
end

supports_shift(::StepperStyle) = true

struct StepStyle end

#isliteral(::Step) = false

make_style(root::Chunk, ctx::LowerJulia, node::Phase) = StepStyle()

combine_style(a::DefaultStyle, b::StepStyle) = StepStyle()
combine_style(a::StepStyle, b::StepStyle) = StepStyle()
combine_style(a::SimplifyStyle, b::StepStyle) = StepStyle()
combine_style(a::AcceptRunStyle, b::StepStyle) = StepStyle()

function (ctx::LowerJulia)(root::Chunk, ::StepStyle)
    i = getname(root.idx)
    i0=ctx.freshen(i)

    body = root.body

    ext_2 = root.ext
    Postwalk(node->begin
        ext_2 = resultdim(ctx, false, ext_2, phase_range(node, ctx, root.idx, root.ext))
        nothing
    end)(body)

    #TODO clean that up
    stop_2 = cache!(ctx, ctx.freshen(i, :_stop), stop(ext_2))
    start_2 = cache!(ctx, ctx.freshen(i, :_start), start(ext_2))
    ext_2 = Extent(start_2, stop_2)
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
        $i = $(ctx(stop(ext_2))) + 1
    end
end

phase_range(node, ctx, idx, ext) = NoDimension()
phase_range(node::Phase, ctx, idx, ext) = Narrow(Extent(start(ext), PhaseStrideVisitor(ctx, idx, start(ext))(node)[1]))

phase_body(node, ctx, idx, ext, ext_2) = nothing
phase_body(node, ctx, idx, ext, ext_2) = PhaseBodyVisitor(ctx, idx, ctx(start(ext_2)), ctx(stop(ext_2)), ctx(stop(ext)))(node)