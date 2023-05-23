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
combine_style(a::SpikeStyle, b::PipelineStyle) = PipelineStyle()

supports_shift(::PipelineStyle) = true

function lower(root::FinchNode, ctx::AbstractCompiler,  ::PipelineStyle)
    if root.kind === loop
        phases = PipelineVisitor(ctx, root.idx, root.ext)(root.body)
        
        i = getname(root.idx)
        i0 = ctx.freshen(i, :_start)
        step = ctx.freshen(i, :_step)
        
        thunk = quote
            $i = $(ctx(getstart(root.ext)))
        end

        for (key, body) in phases
            push!(thunk.args, contain(ctx) do ctx_2
                ctx_2(loop(root.idx, root.ext, body))
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

function (ctx::PipelineVisitor)(node::Pipeline) 
  new_phases = []

  prev_stop = call(-, getstart(ctx.ext), 1)
  for curr in node.phases
    curr_start = call(+, prev_stop, 1)
    curr_stop = getstop(phase_range(curr, ctx.ctx, ctx.ext))
    push!(new_phases, Phase(body = curr.body, 
                            start=(ctx,ext)->curr_start, 
                            stop= curr.stop)) 
    
    prev_stop = curr_stop
  end
  
  return enumerate(new_phases)
end


function (ctx::PipelineVisitor)(node::Shift)
    map(PipelineVisitor(; kwfields(ctx)..., ext = shiftdim(ctx.ext, call(-, node.delta)))(node.body)) do (keys, body)
        return keys => Shift(body, node.delta)
    end
end

