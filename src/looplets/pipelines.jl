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
        phases = PipelineVisitor(ctx, root.idx, root.ext)(root.body)
        endpoints = Dict(PipelineEndpointsCollector(ctx, root.ext)(root.body))

        i = getname(root.idx)
        i0 = ctx.freshen(i, :_start)
        step = ctx.freshen(i, :_step)
        
        thunk = quote
            $i = $(ctx(getstart(root.ext)))
        end

        for (key, body) in phases
            start_points = endpoints[key]
            stop_points = endpoints[key .+ 1]
            phase_extents = resolvedim(mapreduce(x -> Narrow(Extent(start = call(+, x[1], 1), stop = x[2])), 
                                      (a, b) -> resultdim(ctx, a, b),
                                      collect(zip(start_points,stop_points)),
                                      init = Narrow(root.ext)))
            push!(thunk.args, contain(ctx) do ctx_2
                ctx_2(loop(root.idx, phase_extents, body))
            end)
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

(ctx::PipelineVisitor)(node) = [[] => node]
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


