@kwdef struct Phase
    body
    start = (ctx, ext) -> nothing
    stop = (ctx, ext) -> nothing
    range = (ctx, ext) -> similar_extent(ext, something(start(ctx, ext), getstart(ext)), something(stop(ctx, ext), getstop(ext)))
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
        return dimless
    end
end

phase_range(node, ctx, ext) = dimless
phase_range(node::Phase, ctx, ext) = node.range(ctx, ext)

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
struct SequencePhaseStyle <: PhaseStyle end
struct StepperPhaseStyle <: PhaseStyle end
struct JumperPhaseStyle <: PhaseStyle end

phase_op(::SequencePhaseStyle) = virtual_intersect
phase_op(::StepperPhaseStyle) = virtual_intersect
phase_op(::JumperPhaseStyle) = virtual_union

(ctx::Stylize{<:AbstractCompiler})(node::Phase) = ctx.root.kind === loop ? SequencePhaseStyle() : DefaultStyle()

combine_style(a::DefaultStyle, b::PhaseStyle) = b
combine_style(a::LookupStyle, b::PhaseStyle) = b
combine_style(a::T, b::T) where {T<:PhaseStyle} = b
combine_style(a::PhaseStyle, b::RunStyle) = a
combine_style(a::PhaseStyle, b::SpikeStyle) = a
combine_style(a::SimplifyStyle, b::PhaseStyle) = b
combine_style(a::AcceptRunStyle, b::PhaseStyle) = b
combine_style(a::SwitchStyle, b::PhaseStyle) = a
combine_style(a::ThunkStyle, b::PhaseStyle) = a

function lower(root::FinchNode, ctx::AbstractCompiler,  style::PhaseStyle)
    if root.kind === loop
        i = getname(root.idx)
        i0=freshen(ctx.code, i)

        body = root.body

        ext_2 = mapreduce((node)->phase_range(node, ctx, root.ext), (a, b) -> phase_op(style)(ctx, a, b), PostOrderDFS(body))
        
        ext_3 = virtual_intersect(ctx, root.ext.val, ext_2)
        
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
            
            $i = $(ctx(getstop(ext_4))) + $(ctx(getunit(ext_4)))
        end


        if query_z3(call(>=, measure(ext_4), get_smallest_measure(ext_4)), ctx)  
            return body
        elseif query_z3(call(<=, measure(ext_4), get_smallest_measure(ext_4)), ctx)
            return quote
                if $(ctx(getstop(ext_4))) == $(ctx(getstart(ext_4)))
                    $body
                end
            end
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
