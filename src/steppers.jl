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
        body = StepperVisitor(i0, ctx)(root)

        body_2 = fixpoint(ctx) do ctx_2
            scope(ctx_2) do ctx_3
                ctx_3(body)
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
combine_style(a::CasesStyle, b::StepStyle) = CasesStyle()
combine_style(a::ThunkStyle, b::StepStyle) = ThunkStyle()
combine_style(a::SimplifyStyle, b::StepStyle) = StepStyle()
combine_style(a::AcceptRunStyle, b::StepStyle) = StepStyle()

function (ctx::LowerJulia)(root::Chunk, ::StepStyle)
    i = getname(root.idx)
    i0=ctx.freshen(i)

    body = StepperVisitor(i0, ctx)(root.body)

    strides = (PhaseStrideVisitor(ctx, i, i0))(body)
    step = ctx.freshen(i, :_step)
    step_min = quote
        $step = min($(map(ctx, strides)...), $(ctx(stop(root.ext))))
    end
    body = (PhaseBodyVisitor(ctx, i, i0, step, ctx(stop(root.ext))))(body)
    quote
        $i0 = $i
        $step_min
        $(contain(ctx) do ctx_4
            (ctx_4)(Chunk(
                idx = root.idx,
                ext = Extent(Virtual{Any}(i0), Virtual{Any}(step)),
                body = body
            ))
        end)
        $i = $step + 1
    end
end

(ctx::PhaseBodyVisitor)(node::Stepper, ::DefaultStyle) = truncate(node, ctx.ctx, ctx.start, ctx.step, ctx.stop)