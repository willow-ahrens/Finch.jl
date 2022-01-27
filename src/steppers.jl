struct StepperStyle end

Base.@kwdef struct Stepper
    preamble = quote end
    body
    guard = nothing
    stride
    epilogue = quote end
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

function visit!(root::Loop, ctx::LowerJulia, ::StepperStyle)
    i = getname(root.idxs[1])
    i0 = ctx.freshen(i, :_start)
    guard = nothing
    body = scope(ctx) do ctx′
        visit!(root, StepperThunkVisitor(ctx′, i, i0)) #TODO we could just use actual thunks here and call a thunkcontext, would look cleaner.
        guards = visit!(root, StepperGuardVisitor(ctx′, i, i0))
        strides = visit!(root, StepperStrideVisitor(ctx′, i, i0))
        if isempty(strides)
            step = ctx′(ctx.dims[i].stop)
            step_min = quote end
        else
            step = ctx.freshen(i, :_step)
            step_min = quote
                $step = min($(map(ctx′, strides)...), $(ctx′(ctx.dims[i].stop)))
            end
            if length(strides) == 1 && length(guards) == 1
                guard = guards[1]
            else
                guard = :($i0 <= $(visit!(ctx.dims[i].stop, ctx)))
            end
        end
        body = visit!(root, StepperBodyVisitor(ctx′, i, i0, step))
        quote
            $step_min
            $(scope(ctx′) do ctx′′
                restrict(ctx′′, i => Extent(Virtual{Any}(i0), Virtual{Any}(step))) do
                    visit!(body, ctx′′)
                end
            end)
            $i0 = $step + 1
        end
    end
    return quote
        $i0 = $(ctx(ctx.dims[i].start))
        while $guard
            $body
        end
    end
end

Base.@kwdef struct StepperThunkVisitor <: AbstractWalkVisitor
    ctx
    idx
    start
end
function visit!(node::Stepper, ctx::StepperThunkVisitor, ::DefaultStyle)
    push!(ctx.ctx.preamble, node.preamble)
    push!(ctx.ctx.epilogue, node.epilogue)
    node
end

Base.@kwdef struct StepperStrideVisitor <: AbstractCollectVisitor
    ctx
    idx
    start
end
collect_op(::StepperStrideVisitor) = (args) -> vcat(args...) #flatten?
collect_zero(::StepperStrideVisitor) = []
visit!(node::Stepper, ctx::StepperStrideVisitor, ::DefaultStyle) = [node.stride(ctx.start)]


Base.@kwdef struct StepperGuardVisitor <: AbstractCollectVisitor
    ctx
    idx
    start
end
collect_op(::StepperGuardVisitor) = (args) -> vcat(args...) #flatten?
collect_zero(::StepperGuardVisitor) = []
visit!(node::Stepper, ctx::StepperGuardVisitor, ::DefaultStyle) = node.guard === nothing ? [] : [node.guard(ctx.start)]

Base.@kwdef struct StepperBodyVisitor <: AbstractTransformVisitor
    ctx
    idx
    start
    step
end
visit!(node::Stepper, ctx::StepperBodyVisitor, ::DefaultStyle) = node.body(ctx.start, ctx.step)
visit!(node::Spike, ctx::StepperBodyVisitor, ::DefaultStyle) = truncate(node, ctx.start, ctx.step, visit!(ctx.ctx.dims[ctx.idx].stop, ctx.ctx))

truncate(node, start, step, stop) = node
function truncate(node::Spike, start, step, stop)
    return Cases([
        :($(step) < $(stop)) => Run(node.body),
        true => node,
    ])
end