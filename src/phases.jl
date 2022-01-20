Base.@kwdef struct Pipeline
    phases
end

Base.@kwdef struct Phase
    preamble = quote end
    body
    stride = nothing
    guard = nothing
    epilogue = quote end
end

Pigeon.isliteral(::Pipeline) = false
Pigeon.isliteral(::Phase) = false

struct PipelineStyle end

Pigeon.make_style(root, ctx::LowerJuliaContext, node::Pipeline) = PipelineStyle()
Pigeon.combine_style(a::DefaultStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::ThunkStyle, b::PipelineStyle) = ThunkStyle()
Pigeon.combine_style(a::RunStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::AcceptRunStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::AcceptSpikeStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::SpikeStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::PipelineStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::PipelineStyle, b::CaseStyle) = CaseStyle()

struct PipelineContext <: Pigeon.AbstractCollectContext
    ctx
end

function Pigeon.visit!(root, ctx::LowerJuliaContext, ::PipelineStyle)
    phases = visit!(root, PipelineContext(ctx))
    maxkey = maximum(map(maximum, map(((keys, body),)->keys, phases)))
    phases = sort(phases, by=(((keys, body),)->map(l->count(k->k>l, keys), 1:maxkey)))
    i = getname(root.idxs[1])
    i0 = gensym(Symbol("_", i))
    step = gensym(Symbol("_", i))
    thunk = quote
        $i0 = $(ctx(ctx.dims[i].start))
    end

    if length(phases[1][1]) == 1 #only one phaser
        for (keys, body) in phases
            push!(thunk.args, scope(ctx) do ctx′
                visit!(body, PhaseThunkContext(ctx′, i, i0))
                strides = visit!(body, PhaseStrideContext(ctx′, i, i0))
                strides = [strides; visit!(ctx.dims[i].stop, ctx)]
                body = visit!(body, PhaseBodyContext(ctx′, i, i0, step))
                quote
                    $step = min($(strides...))
                    $(scope(ctx′) do ctx′′
                        restrict(ctx′′, i => Extent(Virtual{Any}(i0), Virtual{Any}(step))) do
                            visit!(body, ctx′′)
                        end
                    end)
                    $i0 = $step + 1
                end
            end)
        end
    else
        for (n, (keys, body)) in enumerate(phases)
            push!(thunk.args, scope(ctx) do ctx′
                visit!(body, PhaseThunkContext(ctx′, i, i0))
                guards = visit!(body, PhaseGuardContext(ctx′, i, i0))
                strides = visit!(body, PhaseStrideContext(ctx′, i, i0))
                strides = [strides; visit!(ctx.dims[i].stop, ctx)]
                body = visit!(body, PhaseBodyContext(ctx′, i, i0, step))
                block = quote
                    $(scope(ctx′) do ctx′′
                        restrict(ctx′′, i => Extent(Virtual{Any}(i0), Virtual{Any}(step))) do
                            visit!(body, ctx′′)
                        end
                    end)
                    $i0 = $step + 1
                end
                if n > 1 && length(keys) > 1 #length of keys should be constant, TODO check this
                    block = quote
                        if $i0 <= $step
                            $block
                        end
                    end
                end
                quote
                    $step = min($(strides...))
                    $block
                end
            end)
        end
    end

    return thunk
end

function Pigeon.postvisit!(node, ctx::PipelineContext, args)
    res = map(flatten((product(args...),))) do phases
        keys = map(first, phases)
        bodies = map(last, phases)
        return (reduce(vcat, keys),
            similarterm(node, operation(node), collect(bodies)),
        )
    end
end
Pigeon.postvisit!(node, ctx::PipelineContext) = [([], node)]
Pigeon.visit!(node::Pipeline, ctx::PipelineContext, ::DefaultStyle) = enumerate(node.phases)

Base.@kwdef struct PhaseThunkContext <: Pigeon.AbstractWalkContext
    ctx
    idx
    start
end
function Pigeon.visit!(node::Phase, ctx::PhaseThunkContext, ::DefaultStyle)
    push!(ctx.ctx.preamble, node.preamble)
    push!(ctx.ctx.epilogue, node.epilogue)
    node
end

Base.@kwdef struct PhaseGuardContext <: Pigeon.AbstractCollectContext
    ctx
    idx
    start
end
Pigeon.collect_op(::PhaseGuardContext) = (args) -> vcat(args...) #flatten?
Pigeon.collect_zero(::PhaseGuardContext) = []
Pigeon.visit!(node::Phase, ctx::PhaseGuardContext, ::DefaultStyle) = node.guard === nothing ? [] : [something(node.guard)(ctx.start)]

Base.@kwdef struct PhaseStrideContext <: Pigeon.AbstractCollectContext
    ctx
    idx
    start
end
Pigeon.collect_op(::PhaseStrideContext) = (args) -> vcat(args...) #flatten?
Pigeon.collect_zero(::PhaseStrideContext) = []
Pigeon.visit!(node::Phase, ctx::PhaseStrideContext, ::DefaultStyle) = node.stride === nothing ? [] : [something(node.stride)(ctx.start)]

Base.@kwdef struct PhaseBodyContext <: Pigeon.AbstractTransformContext
    ctx
    idx
    start
    step
end
Pigeon.visit!(node::Phase, ctx::PhaseBodyContext, ::DefaultStyle) = node.body(ctx.start, ctx.step)
Pigeon.visit!(node::Stepper, ctx::PhaseBodyContext, ::DefaultStyle) = truncate(node, ctx.start, ctx.step, visit!(ctx.ctx.dims[ctx.idx].stop, ctx.ctx))
Pigeon.visit!(node::Spike, ctx::PhaseBodyContext, ::DefaultStyle) = truncate(node, ctx.start, ctx.step, visit!(ctx.ctx.dims[ctx.idx].stop, ctx.ctx))