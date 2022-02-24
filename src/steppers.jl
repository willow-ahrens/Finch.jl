struct StepperStyle end

@kwdef struct Stepper
    body
    seek = (ctx, start) -> error("seek not implemented error")
    name = gensym()
end

isliteral(::Stepper) = false

make_style(root::Loop, ctx::LowerJulia, node::Stepper) = StepperStyle()
combine_style(a::DefaultStyle, b::StepperStyle) = StepperStyle()
combine_style(a::AccessStyle, b::StepperStyle) = AccessStyle()
combine_style(a::StepperStyle, b::StepperStyle) = StepperStyle()
combine_style(a::StepperStyle, b::RunStyle) = RunStyle()
combine_style(a::StepperStyle, b::AcceptRunStyle) = StepperStyle()
combine_style(a::StepperStyle, b::AcceptSpikeStyle) = StepperStyle()
combine_style(a::StepperStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::StepperStyle, b::CaseStyle) = CaseStyle()
combine_style(a::ThunkStyle, b::StepperStyle) = ThunkStyle()

function (ctx::LowerJulia)(root::Loop, ::StepperStyle)
    i = getname(root.idxs[1])
    i0 = ctx.freshen(i, :_start)
    push!(ctx.preamble, quote
        $i0 = $(ctx(start(ctx.dims[i])))
    end)

    if extent(ctx.dims[i]) == 1
        body = StepperVisitor(i0, ctx)(root)
        return contain(ctx) do ctx_2
            body_2 = ThunkVisitor(ctx_2)(body)
            body_3 = (PhaseBodyVisitor(ctx_2, i, i0, i0))(body_2)
            (ctx_2)(body_3)
        end
    else
        guard = nothing
        body = StepperVisitor(i0, ctx)(root)

        body_2 = fixpoint(ctx) do ctx_2
            scope(ctx_2) do ctx_3
                body_3 = ThunkVisitor(ctx_3)(body)
                guards = (PhaseGuardVisitor(ctx_3, i, i0))(body_3)
                strides = (PhaseStrideVisitor(ctx_3, i, i0))(body_3)
                if isempty(strides)
                    step = ctx_3(stop(ctx.dims[i]))
                    step_min = quote end
                else
                    step = ctx.freshen(i, :_step)
                    step_min = quote
                        $step = min($(map(ctx_3, strides)...), $(ctx_3(stop(ctx.dims[i]))))
                    end
                    if length(strides) == 1 && length(guards) == 1
                        guard = guards[1]
                    else
                        guard = :($i0 <= $(ctx_3(stop(ctx.dims[i]))))
                    end
                end
                body_4 = (PhaseBodyVisitor(ctx_3, i, i0, step))(body_3)
                quote
                    $step_min
                    $(contain(ctx_3) do ctx_4
                        restrict(ctx_4, i => Extent(Virtual{Any}(i0), Virtual{Any}(step))) do
                            (ctx_4)(body_4)
                        end
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
    if false in get(ctx.ctx.state, node.name, Set(true))
        push!(ctx.ctx.preamble, node.seek(ctx, ctx.start))
    end
    define!(ctx.ctx, node.name, Set(true))
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
    if :skipped in get(ctx.ctx.state, node.name, Set())
        push!(ctx.ctx.preamble, node.seek(ctx, ctx.start))
    end
    define!(ctx.ctx, node.name, Set((:seen,)))
    node.body
end

function (ctx::SkipVisitor)(node::Stepper, ::DefaultStyle)
    define!(ctx.ctx, node.name, Set((:skipped,)))
    node
end

truncate(node, ctx, start, step, stop) = node
function truncate(node::Stepper, ctx, start, step, stop)
    define!(ctx, node.name, Set())
    node
end

function truncate(node::Spike, ctx, start, step, stop)
    return Cases([
        :($(step) < $(stop)) => Run(node.body),
        true => node,
    ])
end