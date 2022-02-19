struct StepperStyle end

@kwdef struct Stepper
    body
end

isliteral(::Stepper) = false

make_style(root::Loop, ctx::LowerJulia, node::Stepper) = StepperStyle()
combine_style(a::DefaultStyle, b::StepperStyle) = StepperStyle()
combine_style(a::StepperStyle, b::StepperStyle) = StepperStyle()
combine_style(a::StepperStyle, b::RunStyle) = RunStyle()
combine_style(a::StepperStyle, b::AcceptRunStyle) = StepperStyle()
combine_style(a::StepperStyle, b::AcceptSpikeStyle) = StepperStyle()
combine_style(a::StepperStyle, b::SpikeStyle) = StepperStyle() #Not sure on this one
combine_style(a::StepperStyle, b::CaseStyle) = CaseStyle()
combine_style(a::ThunkStyle, b::StepperStyle) = ThunkStyle()
#combine_style(a::StepperStyle, b::PipelineStyle) = PipelineStyle()

function (ctx::LowerJulia)(root::Loop, ::StepperStyle)
    i = getname(root.idxs[1])
    i0 = ctx.freshen(i, :_start)
    guard = nothing
    body = nothing

    while true
        ctx_2 = diverge(ctx)
        body = scope(ctx_2) do ctx_3
            body = StepperBodyVisitor()(root)
            body = ThunkVisitor(ctx_3)(body)
            guards = (PhaseGuardVisitor(ctx_3, i, i0))(body)
            strides = (PhaseStrideVisitor(ctx_3, i, i0))(body)
            if isempty(strides)
                step = ctx_3(ctx.dims[i].stop)
                step_min = quote end
            else
                step = ctx.freshen(i, :_step)
                step_min = quote
                    $step = min($(map(ctx_3, strides)...), $(ctx_3(ctx.dims[i].stop)))
                end
                if length(strides) == 1 && length(guards) == 1
                    guard = guards[1]
                else
                    guard = :($i0 <= $(ctx_3(ctx.dims[i].stop)))
                end
            end
            body = (PhaseBodyVisitor(ctx_3, i, i0, step))(body)
            quote
                $step_min
                $(scope(ctx_3) do ctx_4
                    restrict(ctx_4, i => Extent(Virtual{Any}(i0), Virtual{Any}(step))) do
                        (ctx_4)(body)
                    end
                end)
                $i0 = $step + 1
            end
        end
        if ctx_2.state == ctx.state
            break
        else
            unify!(ctx, ctx_2)
        end
    end
    return quote
        $i0 = $(ctx(ctx.dims[i].start))
        while $guard
            $body
        end
    end
end

@kwdef struct StepperBodyVisitor <: AbstractTransformVisitor
end
(ctx::StepperBodyVisitor)(node::Stepper, ::DefaultStyle) = node.body

truncate(node, start, step, stop) = node
function truncate(node::Spike, start, step, stop)
    return Cases([
        :($(step) < $(stop)) => Run(node.body),
        true => node,
    ])
end