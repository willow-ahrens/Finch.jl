@kwdef struct Pipeline
    phases
end

Base.show(io::IO, ex::Pipeline) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Pipeline)
    print(io, "Pipeline()")
end

FinchNotation.finch_leaf(x::Pipeline) = virtual(x)

struct PipelineStyle end

(ctx::Stylize{<:AbstractCompiler})(node::Pipeline) = ctx.root.kind === loop ? PipelineStyle() : DefaultStyle()
combine_style(a::DefaultStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::ThunkStyle, b::PipelineStyle) = ThunkStyle()
combine_style(a::RunStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::SimplifyStyle, b::PipelineStyle) = a
combine_style(a::AcceptRunStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::PipelineStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::PipelineStyle, b::SwitchStyle) = SwitchStyle()
combine_style(a::SpikeStyle, b::PipelineStyle) = SpikeStyle() #PipelineStyle()

supports_shift(::PipelineStyle) = true

function lower(root::FinchNode, ctx::AbstractCompiler,  ::PipelineStyle)
    if root.kind === loop
        phases = Dict(PipelineVisitor(ctx, root.idx, root.ext)(root.body))
        children(key) = intersect(map(i->(key_2 = copy(key); key_2[i] += 1; key_2), 1:length(key)), keys(phases))
        parents(key) = intersect(map(i->(key_2 = copy(key); key_2[i] -= 1; key_2), 1:length(key)), keys(phases))
       
        # If there are n phases, there will be (n+1) endpoints
        endpoints = Dict(PipelineEndpointsCollector(ctx, root.ext)(root.body))
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

            start_points = endpoints[key]
            stop_points = endpoints[key .+ 1]
            phase_extents = resolvedim(mapreduce(x -> Narrow(Extent(start = call(+, x[1], 1), stop = x[2])), 
                                      (a, b) -> resultdim(ctx, a, b),
                                      collect(zip(start_points,stop_points)),
                                      init = Narrow(Extent(start = getstart(root.ext), stop = getstop(root.ext)))))
            push!(thunk.args, contain(ctx) do ctx_2
                #push!(ctx_2.preamble, :($i0 = $i))
                #ctx_2(loop(root.idx, Extent(start = value(i0), stop = getstop(root.ext)), body))
                ctx_2(loop(root.idx, phase_extents, body))
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
            return reduce(vcat, keys, init=[]) => similarterm(node, operation(node), collect(bodies))
        end
    else
        [[] => node]
    end
end
function (ctx::PipelineVisitor)(node::FinchNode)
    if node.kind === virtual
        ctx(node.val)
    elseif istree(node)
        map(flatten((product(map(ctx, arguments(node))...),))) do phases
            keys = map(first, phases)
            bodies = map(last, phases)
            return reduce(vcat, keys, init=[]) => similarterm(node, operation(node), collect(bodies))
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


# Collecting End Points of Phase in Pipelines
Base.@kwdef struct PipelineEndpointsCollector
    ctx
    ext
end

function (ctx::PipelineEndpointsCollector)(node)
    if istree(node)
        map(flatten((product(map(ctx, arguments(node))...),))) do phases
            keys = map(first, phases)
            bodies = map(last, phases)
            return reduce(vcat, keys, init=[]) => reduce(vcat, bodies, init=[]) 
        end

    else
      return [[] => []]
    end
end
function (ctx::PipelineEndpointsCollector)(node::FinchNode)
    if node.kind === virtual
        ctx(node.val)
    elseif istree(node)
        map(flatten((product(map(ctx, arguments(node))...),))) do phases
            keys = map(first, phases)
            bodies = map(last, phases)
            return reduce(vcat, keys, init=[]) => reduce(vcat, bodies, init=[]) 
        end
    else
      return [[] => []]
    end
end

function (ctx::PipelineEndpointsCollector)(node::Pipeline) 
  phasestops = map((phase) -> (isnothing(phase.stop(ctx.ctx, ctx.ext)) ? getstop(ctx.ext) : phase.stop(ctx.ctx, ctx.ext)), 
                   node.phases)
  return enumerate(append!([simplify(call(-,getstart(ctx.ext), 1), ctx.ctx)], phasestops))
end


