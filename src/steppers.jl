struct StepperStyle end

Base.@kwdef struct Stepper
    preamble = quote end
    body
    stride
    epilogue = quote end
end

Pigeon.isliteral(::Stepper) = false

Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Stepper) = StepperStyle()
Pigeon.combine_style(a::DefaultStyle, b::StepperStyle) = StepperStyle()
Pigeon.combine_style(a::StepperStyle, b::StepperStyle) = StepperStyle()
Pigeon.combine_style(a::StepperStyle, b::RunStyle) = StepperStyle()
Pigeon.combine_style(a::StepperStyle, b::AcceptRunStyle) = StepperStyle()
Pigeon.combine_style(a::StepperStyle, b::AcceptSpikeStyle) = StepperStyle()
Pigeon.combine_style(a::StepperStyle, b::SpikeStyle) = StepperStyle() #Not sure on this one
Pigeon.combine_style(a::StepperStyle, b::CaseStyle) = CaseStyle()
Pigeon.combine_style(a::ThunkStyle, b::StepperStyle) = ThunkStyle()
#Pigeon.combine_style(a::StepperStyle, b::PipelineStyle) = PipelineStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::StepperStyle)
    i = getname(root.idxs[1])
    i0 = gensym(Symbol("_", i))
    return quote
        $i0 = $(ctx(ctx.dims[i].start))
        while $i0 <= $(visit!(ctx.dims[i].stop, ctx))
            $(scope(ctx) do ctx′
                visit!(root, StepperThunkContext(ctx′, i, i0)) #TODO we could just use actual thunks here and call a thunkcontext, would look cleaner.
                strides = visit!(root, StepperStrideContext(ctx′, i, i0))
                if isempty(strides)
                    step = ctx′(ctx.dims[i].stop)
                    step_min = quote end
                elseif length(strides) == 1
                    step = ctx′(strides[1])
                    step_min = quote end
                else
                    step = gensym(Symbol("_", i))
                    step_min = quote
                        $step = min($(map(ctx′, strides)...))
                    end
                end
                body = visit!(root, StepperBodyContext(ctx′, i, i0, step))
                quote
                    $step_min
                    $(scope(ctx′) do ctx′′
                        restrict(ctx′′, i => Extent(Virtual{Any}(i0), Virtual{Any}(step))) do
                            visit!(body, ctx′′)
                        end
                    end)
                    $i0 = $step + 1
                end
            end)
        end
    end
end

Base.@kwdef struct StepperThunkContext <: Pigeon.AbstractWalkContext
    ctx
    idx
    start
end
function Pigeon.visit!(node::Stepper, ctx::StepperThunkContext, ::DefaultStyle)
    push!(ctx.ctx.preamble, node.preamble)
    push!(ctx.ctx.epilogue, node.epilogue)
    node
end

Base.@kwdef struct StepperStrideContext <: Pigeon.AbstractCollectContext
    ctx
    idx
    start
end
Pigeon.collect_op(::StepperStrideContext) = (args) -> vcat(args...) #flatten?
Pigeon.collect_zero(::StepperStrideContext) = []
Pigeon.visit!(node::Stepper, ctx::StepperStrideContext, ::DefaultStyle) = [node.stride(ctx.start)]

Base.@kwdef struct StepperBodyContext <: Pigeon.AbstractTransformContext
    ctx
    idx
    start
    step
end
Pigeon.visit!(node::Stepper, ctx::StepperBodyContext, ::DefaultStyle) = node.body(ctx.start, ctx.step)
Pigeon.visit!(node::Spike, ctx::StepperBodyContext, ::DefaultStyle) = truncate(node, ctx.start, ctx.step, visit!(ctx.ctx.dims[ctx.idx].stop, ctx.ctx))

truncate(node, start, step, stop) = node
function truncate(node::Spike, start, step, stop)
    return Cases([
        :($(step) < $(stop)) => Run(node.body),
        true => node,
    ])
end