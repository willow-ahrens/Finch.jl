struct StepperStyle end

@kwdef struct Stepper
    body
    seek = (ctx, start) -> error("seek not implemented error")
    status = gensym()
end

isliteral(::Stepper) = false

function make_style(root::Chunk, ctx::LowerJulia, node::Stepper)
    if node.status in keys(ctx.state)
        StepperStyle()
    else
        ThunkStyle()
    end
end
combine_style(a::DefaultStyle, b::StepperStyle) = StepperStyle()
combine_style(a::StepperStyle, b::StepperStyle) = StepperStyle()
combine_style(a::StepperStyle, b::RunStyle) = RunStyle()
combine_style(a::SimplifyStyle, b::StepperStyle) = SimplifyStyle()
combine_style(a::StepperStyle, b::AcceptRunStyle) = StepperStyle()
combine_style(a::StepperStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::StepperStyle, b::CaseStyle) = CaseStyle()
combine_style(a::ThunkStyle, b::StepperStyle) = ThunkStyle()

function (ctx::LowerJulia)(root::Chunk, ::StepperStyle)
    i = getname(root.idx)
    i0 = ctx.freshen(i, :_start)
    push!(ctx.preamble, quote
        $i0 = $(ctx(start(root.ext)))
    end)

    if extent(root.ext) == 1
        body = StepperVisitor(i0, ctx)(root)
        return contain(ctx) do ctx_2
            body_2 = ThunkVisitor(ctx_2)(body)
            body_3 = (PhaseBodyVisitor(ctx_2, i, i0, i0, ctx_2(stop(root.ext))))(body_2)
            (ctx_2)(body_3)
        end
    else
        guard = nothing
        body = StepperVisitor(i0, ctx)(root.body)

        body_2 = fixpoint(ctx) do ctx_2
            scope(ctx_2) do ctx_3
                body_3 = ThunkVisitor(ctx_3)(body)
                guards = (PhaseGuardVisitor(ctx_3, i, i0))(body_3)
                strides = (PhaseStrideVisitor(ctx_3, i, i0))(body_3)
                if isempty(strides)
                    step = ctx_3(stop(root.ext))
                    step_min = quote end
                else
                    step = ctx.freshen(i, :_step)
                    step_min = quote
                        $step = min($(map(ctx_3, strides)...), $(ctx_3(stop(root.ext))))
                    end
                    if length(strides) == 1 && length(guards) == 1 && false #Guards are unsafe to use alone. We need to also include a check for end of range.
                        guard = guards[1]
                    else
                        guard = :($i0 <= $(ctx_3(stop(root.ext))))
                    end
                end
                body_4 = (PhaseBodyVisitor(ctx_3, i, i0, step, ctx_3(stop(root.ext))))(body_3)
                quote
                    $step_min
                    $(contain(ctx_3) do ctx_4
                        (ctx_4)(Chunk(
                            idx = root.idx,
                            ext = Extent(Virtual{Any}(i0), Virtual{Any}(step)),
                            body = body_4
                        ))
                    end)
                    $i0 = $step + 1
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

#=
function (ctx::AccessSpikeTailVisitor)(node::Stepper, ::DefaultStyle)
    if false in get(ctx.ctx.state, node.status, Set(true))
        push!(ctx.ctx.preamble, node.seek(ctx, ctx.start))
    end
    define!(ctx.ctx, node.status, Set(true))
    body = ThunkVisitor(ctx.ctx)(node.body)
    body = PhaseBodyVisitor(ctx.ctx, ctx.idx, ctx.val, ctx.val)(body)
    ctx(body)
end
=#

@kwdef struct StepperVisitor <: AbstractTransformVisitor
    start
    ctx
end
function (ctx::StepperVisitor)(node::Stepper, ::DefaultStyle)
    if :skipped in get(ctx.ctx.state, node.status, Set())
        push!(ctx.ctx.preamble, node.seek(ctx, ctx.start))
    end
    define!(ctx.ctx, node.status, Set((:seen,)))
    node.body
end

function (ctx::SkipVisitor)(node::Stepper, ::DefaultStyle)
    define!(ctx.ctx, node.status, Set((:skipped,)))
    node
end

function (ctx::ThunkVisitor)(node::Stepper, ::DefaultStyle)
    if !haskey(ctx.ctx.state, node.status)
        define!(ctx.ctx, node.status, Set((:seen,)))
    end
    node
end

truncate(node, ctx, start, step, stop) = node
function truncate(node::Spike, ctx, start, step, stop)
    return Cases([
        :($(step) < $(stop)) => Run(node.body),
        true => node,
    ])
end

supports_shift(::StepperStyle) = true