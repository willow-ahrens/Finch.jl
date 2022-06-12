@kwdef struct Pipeline
    phases
end

isliteral(::Pipeline) = false

struct PipelineStyle end

make_style(root, ctx::LowerJulia, node::Pipeline) = PipelineStyle()
combine_style(a::DefaultStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::ThunkStyle, b::PipelineStyle) = ThunkStyle()
combine_style(a::RunStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::SimplifyStyle, b::PipelineStyle) = SimplifyStyle()
combine_style(a::AcceptRunStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::PipelineStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::PipelineStyle, b::CaseStyle) = CaseStyle()
combine_style(a::SpikeStyle, b::PipelineStyle) = PipelineStyle()

supports_shift(::PipelineStyle) = true

struct PipelineVisitor <: AbstractCollectVisitor
    ctx
end

function (ctx::LowerJulia)(root::Chunk, ::PipelineStyle)
    phases = Dict(PipelineVisitor(ctx)(root.body))
    children(key) = intersect(map(i->(key_2 = copy(key); key_2[i] += 1; key_2), 1:length(key)), keys(phases))
    parents(key) = intersect(map(i->(key_2 = copy(key); key_2[i] -= 1; key_2), 1:length(key)), keys(phases))

    i = getname(root.idx)
    i0 = ctx.freshen(i, :_start)
    step = ctx.freshen(i, :_step)
    
    thunk = quote
        $i = $(ctx(getstart(root.ext)))
    end

    ctx_2s = Dict(minimum(keys(phases)) => ctx)
    visited = Set()
    frontier = [minimum(keys(phases))]

    while !isempty(frontier)
        key = pop!(frontier)
        body = phases[key]
        ctx_2 = ctx_2s[key]

        push!(thunk.args, contain(ctx_2) do ctx_3
            push!(ctx_3.preamble, :($i0 = $i))
            ctx_3(Chunk(root.idx, Extent(start = i0, stop = getstop(root.ext), lower = 1), body))
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