@kwdef struct Pipeline
    phases
end

@kwdef struct Phase
    preamble = quote end
    body
    stride = nothing
    guard = nothing
    epilogue = quote end
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
combine_style(a::SpikeStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::PipelineStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::PipelineStyle, b::CaseStyle) = CaseStyle()

struct PipelineVisitor <: AbstractCollectVisitor
    ctx
end

function (ctx::LowerJulia)(root, ::PipelineStyle)
    phases = (PipelineVisitor(ctx))(root)
    maxkey = maximum(map(maximum, map(((keys, body),)->keys, phases)))
    phases = sort(phases, by=(((keys, body),)->map(l->count(k->k>l, keys), 1:maxkey)))
    i = getname(root.idxs[1])
    i0 = ctx.freshen(i, :_start)
    step = ctx.freshen(i, :_step)
    thunk = quote
        $i0 = $(ctx(ctx.dims[i].start))
    end

    if length(phases[1][1]) == 1 #only one phaser
        for (keys, body) in phases
            push!(thunk.args, scope(ctx) do ctx′
                (PhaseThunkVisitor(ctx′, i, i0))(body)
                strides = (PhaseStrideVisitor(ctx′, i, i0))(body)
                strides = [strides; ctx(ctx.dims[i].stop)]
                body = (PhaseBodyVisitor(ctx′, i, i0, step))(body)
                quote
                    $step = min($(strides...))
                    $(scope(ctx′) do ctx′′
                        restrict(ctx′′, i => Extent(Virtual{Any}(i0), Virtual{Any}(step))) do
                            (ctx′′)(body)
                        end
                    end)
                    $i0 = $step + 1
                end
            end)
        end
    else
        for (n, (keys, body)) in enumerate(phases)
            push!(thunk.args, scope(ctx) do ctx′
                (PhaseThunkVisitor(ctx′, i, i0))(body)
                guards = (PhaseGuardVisitor(ctx′, i, i0))(body)
                strides = (PhaseStrideVisitor(ctx′, i, i0))(body)
                strides = [strides; ctx(ctx.dims[i].stop)]
                body = (PhaseBodyVisitor(ctx′, i, i0, step))(body)
                block = quote
                    $(scope(ctx′) do ctx′′
                        restrict(ctx′′, i => Extent(Virtual{Any}(i0), Virtual{Any}(step))) do
                            (ctx′′)(body)
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

function postvisit!(node, ctx::PipelineVisitor, args)
    res = map(flatten((product(args...),))) do phases
        keys = map(first, phases)
        bodies = map(last, phases)
        return (reduce(vcat, keys),
            similarterm(node, operation(node), collect(bodies)),
        )
    end
end
postvisit!(node, ctx::PipelineVisitor) = [([], node)]
(ctx::PipelineVisitor)(node::Pipeline, ::DefaultStyle) = enumerate(node.phases)

@kwdef struct PhaseThunkVisitor <: AbstractTransformVisitor
    ctx
    idx
    start
end
function (ctx::PhaseThunkVisitor)(node::Phase, ::DefaultStyle)
    push!(ctx.ctx.preamble, node.preamble)
    push!(ctx.ctx.epilogue, node.epilogue)
    node
end

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
(ctx::PhaseBodyVisitor)(node::Stepper, ::DefaultStyle) = truncate(node, ctx.start, ctx.step, (ctx.ctx)(ctx.ctx.dims[ctx.idx].stop))
(ctx::PhaseBodyVisitor)(node::Spike, ::DefaultStyle) = truncate(node, ctx.start, ctx.step, (ctx.ctx)(ctx.ctx.dims[ctx.idx].stop))