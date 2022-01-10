Base.@kwdef struct Pipeline
    phases
end

Base.@kwdef struct Phase
    body
    stride = nothing
end

Pigeon.isliteral(::Pipeline) = false
Pigeon.isliteral(::Phase) = false

struct PipelineStyle end

Pigeon.make_style(root, ctx::LowerJuliaContext, node::Pipelines) = PipelineStyle()
Pigeon.combine_style(a::DefaultStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::ThunkStyle, b::PipelineStyle) = ThunkStyle()
Pigeon.combine_style(a::RunStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::AcceptRunStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::AcceptSpikeStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::SpikeStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::PipelineStyle, b::PipelineStyle) = PipelineStyle()
Pigeon.combine_style(a::PipelineStyle, b::CasesStyle) = CasesStyle()

struct PipelineContext <: Pigeon.AbstractCollectContext
    ctx
end

function Pigeon.visit!(stmt, ctx::LowerJuliaContext, ::PipelineStyle)
    phases = visit!(stmt, PipelineContext(ctx))
    maxkey = maximum(map(maximum, map(((keys, bodies),)->keys, phases)))
    phases = sort(phases, by=(((keys, bodies),)->map(l->count(k->k>l, keys), 1:maxkey))
    i = getname(root.idxs[1])
    i0 = gensym(Symbol("_", i))
    step = gensym(Symbol("_", i))
    thunk = quote
        $i0 = $(ctx.dims[i].start)
    end

    for phase in phases
        push!(thunk.args, scope(ctx) do ctx′
            strides = visit!(root, PhaseStrideContext(ctx′, i, i0))
            strides = [strides; visit!(ctx.dims[i].stop, ctx)]
            :($step = min($(strides...)))
        end
        push!(thunk.args, scope(ctx) do ctx′
            body = visit!(root, PhaseBodyContext(ctx′, i, i0, step))
            quote
                if $i0 < $step
                    $(restrict(ctx′, i => Extent(Virtual{Any}(i0), Virtual{Any}(step))) do
                        visit!(body, ctx′)
                    end)
                end
            end
        end)
    end

    return thunk
end

function Pigeon.postvisit!(node, ctx::PipelineContext, args)
    map(product(args...)) do phases
        keys = map(first, phases)
        bodies = map(last, phases)
        return (
            keys = reduce(vcat, keys),
            bodies = similarterm(node, operation(node), collect(bodies)),
        )
    end
end
Pigeon.postvisit!(node, ctx::PipelineContext) = [([], node)]
Pigeon.visit!(node::Pipeline, ctx::PipelineContext, ::DefaultStyle) = enumerate(node.phases)

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
Pigeon.visit!(node::Stream, ctx::PhaseBodyContext, ::DefaultStyle) = truncate(node, ctx.start, ctx.step, visit!(ctx.ctx.dims[ctx.idx].stop, ctx.ctx))
Pigeon.visit!(node::Spike, ctx::PhaseBodyContext, ::DefaultStyle) = truncate(node, ctx.start, ctx.step, visit!(ctx.ctx.dims[ctx.idx].stop, ctx.ctx))