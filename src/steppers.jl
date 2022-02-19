struct StepperStyle end

@kwdef struct Stepper
    body
    seek = (ctx, start) -> error("seek not implemented error")
    name = gensym(:stepper)
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
    body = StepperVisitor(i0, ctx)(root)
    body_2 = :(error("this code should not run"))

    while true
        ctx_2 = diverge(ctx)
        body_2 = scope(ctx_2) do ctx_3
            body_3 = ThunkVisitor(ctx_3)(body)
            guards = (PhaseGuardVisitor(ctx_3, i, i0))(body_3)
            strides = (PhaseStrideVisitor(ctx_3, i, i0))(body_3)
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
            body_4 = (PhaseBodyVisitor(ctx_3, i, i0, step))(body_3)
            quote
                $step_min
                $(scope(ctx_3) do ctx_4
                    restrict(ctx_4, i => Extent(Virtual{Any}(i0), Virtual{Any}(step))) do
                        (ctx_4)(body_4)
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
            $body_2
        end
    end
end

@kwdef struct StepperVisitor <: AbstractTransformVisitor
    start
    ctx
end
function (ctx::StepperVisitor)(node::Stepper, ::DefaultStyle)
    if false in get(ctx.ctx.state, node.name, Set(true))
        push!(ctx.ctx.preamble, node.seek(ctx.start))
    end
    ctx.ctx.state[node.name] = Set(true)
    node.body
end

truncate(node, ctx, start, step, stop) = node
function truncate(node::Stepper, ctx, start, step, stop)
    ctx.state[node.name] = Set(false)
    node
end

function truncate(node::Spike, ctx, start, step, stop)
    return Cases([
        :($(step) < $(stop)) => Run(node.body),
        true => node,
    ])
end