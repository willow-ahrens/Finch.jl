@kwdef struct Phase
    body
    start = (ctx, ext) -> nothing
    stop = (ctx, ext) -> nothing
    range = (ctx, ext) -> Extent(something(start(ctx, ext), getstart(ext)), something(stop(ctx, ext), getstop(ext)))
end
FinchNotation.finch_leaf(x::Phase) = virtual(x)

Base.show(io::IO, ex::Phase) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Phase)
    print(io, "Phase()")
end

function phase_range(node::FinchNode, ctx, ext)
    if @capture node access(~tns::isvirtual, ~i...)
        phase_range(tns.val, ctx, ext)
    else
        return nodim
    end
end

phase_range(node, ctx, ext) = nodim
phase_range(node::Phase, ctx, ext) = Narrow(node.range(ctx, ext))

function phase_body(node::FinchNode, ctx, ext, ext_2)
    if @capture node access(~tns::isvirtual, ~m, ~i...)
        access(phase_body(tns.val, ctx, ext, ext_2), m, i...)
    else
        return node
    end
end
phase_body(node::Phase, ctx, ext, ext_2) = node.body(ctx, ext_2)
phase_body(node, ctx, ext, ext_2) = truncate(node, ctx, ext, ext_2)

abstract type PhaseStyle end
struct PipelinePhaseStyle <: PhaseStyle end
struct StepperPhaseStyle <: PhaseStyle end
struct JumperPhaseStyle <: PhaseStyle end

(ctx::Stylize{<:AbstractCompiler})(node::Phase) = ctx.root.kind === loop ? PipelinePhaseStyle() : DefaultStyle()

combine_style(a::DefaultStyle, b::PhaseStyle) = b
combine_style(a::LookupStyle, b::PhaseStyle) = b
combine_style(a::T, b::T) where {T<:PhaseStyle} = b
combine_style(a::PhaseStyle, b::RunStyle) = a
combine_style(a::PhaseStyle, b::SpikeStyle) = a
combine_style(a::SimplifyStyle, b::PhaseStyle) = b
combine_style(a::AcceptRunStyle, b::PhaseStyle) = b
combine_style(a::SwitchStyle, b::PhaseStyle) = a
combine_style(a::ThunkStyle, b::PhaseStyle) = a

function lower(root::FinchNode, ctx::AbstractCompiler,  ::PhaseStyle)
    if root.kind === loop
        i = getname(root.idx)
        i0=ctx.freshen(i)

        body = root.body

        ext_2 = resolvedim(mapreduce((node)->phase_range(node, ctx, root.ext), (a, b) -> resultdim(ctx, a, b), PostOrderDFS(body), init=nodim))

        ext_3 = resolvedim(resultdim(ctx, Narrow(root.ext), ext_2))

        #if query(call(==, getstart(ext_3), getstart(ext_2)), ctx) && query(call(==, getstop(ext_3), getstop(ext_2)), ctx)
        #    ext_3 = ext_2
        #end

        ext_4 = cache_dim!(ctx, :phase, ext_3)

        body = Rewrite(Postwalk(node->phase_body(node, ctx, root.ext, ext_4)))(body)
        body = quote
            $i0 = $i
            $(contain(ctx) do ctx_4
                (ctx_4)(loop(
                    root.idx,
                    ext_4,
                    body
                ))
            end)
            $i = $(ctx(getstop(ext_4))) + $(Int8(1))
        end


        if query(call(>=, measure(ext_4), 1), ctx) 
            return body
        else
            return quote
                if $(ctx(getstop(ext_4))) >= $(ctx(getstart(ext_4)))
                    $body
                end
            end
        end
    else
        error("unimplemented")
    end
end
