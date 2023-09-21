@kwdef struct Sequence
    phases
end

Base.show(io::IO, ex::Sequence) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Sequence)
    print(io, "Sequence()")
end

FinchNotation.finch_leaf(x::Sequence) = virtual(x)

struct SequenceStyle end

(ctx::Stylize{<:AbstractCompiler})(node::Sequence) = ctx.root.kind === loop ? SequenceStyle() : DefaultStyle()
combine_style(a::DefaultStyle, b::SequenceStyle) = SequenceStyle()
combine_style(a::LookupStyle, b::SequenceStyle) = SequenceStyle()
combine_style(a::ThunkStyle, b::SequenceStyle) = ThunkStyle()
combine_style(a::RunStyle, b::SequenceStyle) = SequenceStyle()
combine_style(a::SimplifyStyle, b::SequenceStyle) = a
combine_style(a::AcceptRunStyle, b::SequenceStyle) = SequenceStyle()
combine_style(a::SequenceStyle, b::SequenceStyle) = SequenceStyle()
combine_style(a::SequenceStyle, b::SwitchStyle) = SwitchStyle()
combine_style(a::SpikeStyle, b::SequenceStyle) = SequenceStyle()
combine_style(a::SequenceStyle, b::PhaseStyle) = b

function lower(root::FinchNode, ctx::AbstractCompiler,  ::SequenceStyle)
    if root.kind === loop
        phases = SequenceVisitor(ctx, root.idx, root.ext)(root.body)
        
        i = getname(root.idx)
        i0 = freshen(ctx.code, i, :_start)
        step = freshen(ctx.code, i, :_step)
        
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

Base.@kwdef struct SequenceVisitor
    ctx
    idx
    ext
end

(ctx::SequenceVisitor)(node) = [[] => node]
function (ctx::SequenceVisitor)(node::FinchNode)
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

function (ctx::SequenceVisitor)(node::Sequence) 
  new_phases = []

  prev_stop = call(-, getstart(phase_range(node.phases[1], ctx.ctx, ctx.ext)), getunit(ctx.ext))
  #is_prev_stop_nothing = node.phases[1].start(ctx.ctx, ctx.ext) == nothing
  
  for curr in node.phases
    curr_start = call(+, prev_stop, getunit(ctx.ext))

    is_curr_stop_nothing = curr.stop(ctx.ctx, ctx.ext) == nothing
    if !is_curr_stop_nothing
        curr_stop = bound_below!(ctx.ctx, getstop(phase_range(curr, ctx.ctx, ctx.ext)), curr_start)
    else
        curr_stop = getstop(phase_range(curr, ctx.ctx, ctx.ext))
    end
    push!(new_phases, Phase(body = curr.body, start = (ctx, ext) -> curr_start, stop = (ctx, ext) -> curr_stop))

    prev_stop = curr_stop
    #is_prev_stop_nothing = is_curr_stop_nothing
  end
  
  return enumerate(new_phases)
end
