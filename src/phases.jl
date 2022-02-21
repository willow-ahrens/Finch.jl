@kwdef struct Pipeline
    phases
end

@kwdef struct Phase
    body
    stride = nothing
    guard = nothing
end

isliteral(::Pipeline) = false
isliteral(::Phase) = false

struct PipelineStyle end

make_style(root, ctx::LowerJulia, node::Pipeline) = PipelineStyle()
combine_style(a::DefaultStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::ThunkStyle, b::PipelineStyle) = ThunkStyle()
combine_style(a::RunStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::AcceptRunStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::AcceptSpikeStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::PipelineStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::PipelineStyle, b::CaseStyle) = CaseStyle()
combine_style(a::SpikeStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::StepperStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::JumperStyle, b::PipelineStyle) = PipelineStyle()

struct PipelineVisitor <: AbstractCollectVisitor
    ctx
end

function (ctx::LowerJulia)(root, ::PipelineStyle)
    phases = Dict(PipelineVisitor(ctx)(root))
    children(key) = intersect(map(i->(key_2 = copy(key); key_2[i] += 1; key_2), 1:length(key)), keys(phases))
    parents(key) = intersect(map(i->(key_2 = copy(key); key_2[i] -= 1; key_2), 1:length(key)), keys(phases))

    i = getname(root.idxs[1])
    i0 = ctx.freshen(i, :_start)
    step = ctx.freshen(i, :_step)
    thunk = quote
        $i0 = $(ctx(ctx.dims[i].start))
    end

    ctx_2s = Dict(minimum(keys(phases)) => ctx)
    visited = Set()
    frontier = [minimum(keys(phases))]

    while !isempty(frontier)
        key = pop!(frontier)
        body = phases[key]
        ctx_2 = ctx_2s[key]

        push!(thunk.args, scope(ctx_2) do ctx_3
            body = ThunkVisitor(ctx_3)(body)
            guards = (PhaseGuardVisitor(ctx_3, i, i0))(body)
            strides = (PhaseStrideVisitor(ctx_3, i, i0))(body)
            strides = [strides; ctx(ctx.dims[i].stop)]
            body = (PhaseBodyVisitor(ctx_3, i, i0, step))(body)
            block = quote
                $(scope(ctx_3) do ctx_4
                    restrict(ctx_4, i => Extent(Virtual{Any}(i0), Virtual{Any}(step))) do
                        (ctx_4)(body)
                    end
                end)
                $i0 = $step + 1
            end
            if length(key) > 1
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

        push!(visited, key)
        for key_2 in children(key)
            unify!(get!(ctx_2s, key_2, diverge(ctx_2)), ctx_2)
            if parents(key_2) ⊆ visited
                push!(frontier, key_2)
            end
        end
    end

    unify!(ctx, ctx_2s[maximum(keys(phases))])

    return thunk
end

function postvisit!(node, ctx::PipelineVisitor, args)
    res = map(flatten((product(args...),))) do phases
        keys = map(first, phases)
        bodies = map(last, phases)
        return (reduce(vcat, keys),
            similarterm(node, operation(node), collect(bodies)))
    end
end
postvisit!(node, ctx::PipelineVisitor) = [([], node)]
(ctx::PipelineVisitor)(node::Pipeline, ::DefaultStyle) = enumerate(node.phases)

@kwdef struct PhaseGuardVisitor <: AbstractCollectVisitor
    ctx
    idx
    start
end
collect_op(::PhaseGuardVisitor) = (args) -> vcat(args...) #flatten?
collect_zero(::PhaseGuardVisitor) = []
(ctx::PhaseGuardVisitor)(node::Phase, ::DefaultStyle) = node.guard === nothing ? [] : [something(node.guard)(ctx.start)]

@kwdef struct PhaseStrideVisitor <: AbstractCollectVisitor
    ctx
    idx
    start
end
collect_op(::PhaseStrideVisitor) = (args) -> vcat(args...) #flatten?
collect_zero(::PhaseStrideVisitor) = []
(ctx::PhaseStrideVisitor)(node::Phase, ::DefaultStyle) = node.stride === nothing ? [] : [something(node.stride)(ctx.start)]

@kwdef struct PhaseBodyVisitor <: AbstractTransformVisitor
    ctx
    idx
    start
    step
end
(ctx::PhaseBodyVisitor)(node::Phase, ::DefaultStyle) = node.body(ctx.start, ctx.step)
(ctx::PhaseBodyVisitor)(node::Stepper, ::DefaultStyle) = truncate(node, ctx.ctx, ctx.start, ctx.step, (ctx.ctx)(ctx.ctx.dims[ctx.idx].stop))
(ctx::PhaseBodyVisitor)(node::Spike, ::DefaultStyle) = truncate(node, ctx.ctx, ctx.start, ctx.step, (ctx.ctx)(ctx.ctx.dims[ctx.idx].stop))