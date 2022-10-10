@kwdef struct Pipeline
    phases
end

Base.show(io::IO, ex::Pipeline) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Pipeline)
    print(io, "Pipeline()")
end

IndexNotation.isliteral(::Pipeline) =  false

struct PipelineStyle end

(ctx::Stylize{LowerJulia})(node::Pipeline) = PipelineStyle()
combine_style(a::DefaultStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::ThunkStyle, b::PipelineStyle) = ThunkStyle()
combine_style(a::RunStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::SimplifyStyle, b::PipelineStyle) = SimplifyStyle()
combine_style(a::AcceptRunStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::PipelineStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::PipelineStyle, b::SwitchStyle) = SwitchStyle()
combine_style(a::SpikeStyle, b::PipelineStyle) = PipelineStyle()

supports_shift(::PipelineStyle) = true

function (ctx::LowerJulia)(root::CINNode, ::PipelineStyle)
    if root.head === chunk
        phases = Dict(PipelineVisitor(ctx, root.idx, root.ext)(root.body))
        children(key) = intersect(map(i->(key_2 = copy(key); key_2[i] += 1; key_2), 1:length(key)), keys(phases))
        parents(key) = intersect(map(i->(key_2 = copy(key); key_2[i] -= 1; key_2), 1:length(key)), keys(phases))

        i = getname(root.idx)
        i0 = ctx.freshen(i, :_start)
        step = ctx.freshen(i, :_step)
        
        thunk = quote
            $i = $(ctx(getstart(root.ext)))
        end

        visited = Set()
        frontier = [minimum(keys(phases))]

        while !isempty(frontier)
            key = pop!(frontier)
            body = phases[key]

            push!(thunk.args, contain(ctx) do ctx_2
                push!(ctx_2.preamble, :($i0 = $i))
                ctx_2(chunk(root.idx, Extent(start = value(i0), stop = getstop(root.ext), lower = literal(1)), body))
            end)

            push!(visited, key)
            for key_2 in children(key)
                if parents(key_2) ⊆ visited
                    push!(frontier, key_2)
                end
            end
        end

        return thunk
    else
        error("unimplemented")
    end
end

Base.@kwdef struct PipelineVisitor
    ctx
    idx
    ext
end

function (ctx::PipelineVisitor)(node)
    if istree(node)
        map(flatten((product(map(ctx, arguments(node))...),))) do phases
            keys = map(first, phases)
            bodies = map(last, phases)
            return reduce(vcat, keys) => similarterm(node, operation(node), collect(bodies))
        end
    else
        [[] => node]
    end
end
function (ctx::PipelineVisitor)(node::CINNode)
    if node.head === virtual
        ctx(node.val)
    elseif istree(node)
        map(flatten((product(map(ctx, arguments(node))...),))) do phases
            keys = map(first, phases)
            bodies = map(last, phases)
            return reduce(vcat, keys) => similarterm(node, operation(node), collect(bodies))
        end
    else
        [[] => node]
    end
end
(ctx::PipelineVisitor)(node::Pipeline) = enumerate(node.phases)

function (ctx::PipelineVisitor)(node::Shift)
    map(PipelineVisitor(; kwfields(ctx)..., ext = shiftdim(ctx.ext, call(-, node.delta)))(node.body)) do (keys, body)
        return keys => Shift(body, node.delta)
    end
end