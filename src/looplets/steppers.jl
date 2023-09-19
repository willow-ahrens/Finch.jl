struct StepperStyle end

@kwdef struct Stepper
    preamble = nothing
    stop = (ctx, ext) -> nothing
    chunk = nothing
    next = (ctx, ext) -> nothing
    body = (ctx, ext) -> chunk
    seek = (ctx, start) -> error("seek not implemented error")
    finalstop = (ctx, ext) -> nothing
end

@kwdef struct AcceptStepper
    stepper
end

Base.show(io::IO, ex::Stepper) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Stepper)
    print(io, "Stepper()")
end

FinchNotation.finch_leaf(x::Stepper) = virtual(x)
FinchNotation.finch_leaf(x::AcceptStepper) = virtual(x)

(ctx::Stylize{<:AbstractCompiler})(node::Stepper) = ctx.root.kind === loop ? StepperStyle() : DefaultStyle()

combine_style(a::DefaultStyle, b::StepperStyle) = StepperStyle()
combine_style(a::LookupStyle, b::StepperStyle) = StepperStyle()
combine_style(a::StepperStyle, b::SequenceStyle) = SequenceStyle()
combine_style(a::StepperStyle, b::StepperStyle) = StepperStyle()
combine_style(a::StepperStyle, b::RunStyle) = RunStyle()
combine_style(a::SimplifyStyle, b::StepperStyle) = a
combine_style(a::StepperStyle, b::AcceptRunStyle) = StepperStyle()
combine_style(a::StepperStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::StepperStyle, b::SwitchStyle) = SwitchStyle()
combine_style(a::ThunkStyle, b::StepperStyle) = ThunkStyle()
combine_style(a::StepperStyle, b::JumperStyle) = JumperStyle()
combine_style(a::StepperStyle, b::PhaseStyle) = b

stepper_seek(node::Stepper, ctx, ext) = node.seek(ctx, ext)
stepper_seek(node, ctx, ext) = quote end

stepper_body(node::Stepper, ctx, ext) = AcceptStepper(node)
stepper_body(node, ctx, ext) = node

function lower(root::FinchNode, ctx::AbstractCompiler,  style::StepperStyle)
    root.kind === loop || error("unimplemented")
    
    i = getname(root.idx)
    i0 = freshen(ctx.code, i, :_start)
    push!(ctx.code.preamble, quote
        $i = $(ctx(getstart(root.ext)))
    end)

    guard = :($i <= $(ctx(getstop(root.ext))))

    foreach(filter(isvirtual, collect(PostOrderDFS(root.body)))) do node
        push!(ctx.code.preamble, stepper_seek(node.val, ctx, root.ext))
    end

    body_1 = Rewrite(Postwalk(@rule access(~tns::isvirtual, ~mode, ~idxs...) => begin
        tns_2 = stepper_body(tns.val, ctx, root.ext)
        access(tns_2, mode, idxs...)
    end))(root.body)

    body_2 = contain(ctx) do ctx_2
        push!(ctx_2.code.preamble, :($i0 = $i))
        i1 = freshen(ctx_2.code, i)

        ext_1 = bound_measure_below!(ctx_2, similar_extent(root.ext, value(i0), getstop(root.ext)), get_smallest_measure(root.ext))
        ext_2 = mapreduce((node)->phase_range(node, ctx_2, ext_1), (a, b) -> virtual_intersect(ctx_2, a, b), PostOrderDFS(body_1))

        ext_3 = virtual_intersect(ctx_2, ext_1, ext_2)
        
        ext_4 = cache_dim!(ctx_2, :phase, ext_3)

        body = Rewrite(Postwalk(node->phase_body(node, ctx_2, ext_1, ext_4)))(body_1)
        body = quote
            $i1 = $i
            $(contain(ctx_2) do ctx_3
                ctx_3(loop(root.idx, ext_4, body))
            end)
            
            $i = $(ctx_2(getstop(ext_4))) + $(ctx_2(getunit(ext_4)))
        end

        body

    end

    @assert isvirtual(root.ext)

    if query(call(==, measure(root.ext.val), get_smallest_measure(root.ext.val)), ctx)
        body_2
    else
        return quote
            while $guard
                $body_2
            end
        end
    end
end

function phase_range(node::AcceptStepper, ctx, ext)
    node = node.stepper
    push!(ctx.code.preamble, node.preamble !== nothing ? node.preamble : quote end)
    if node.finalstop(ctx, ext) !== nothing
        ext_2 = similar_extent(ext, getstart(ext), bound_above!(ctx, node.stop(ctx, ext), node.finalstop(ctx, ext)))
    else
        ext_2 = similar_extent(ext, getstart(ext), node.stop(ctx, ext))
    end
    bound_measure_below!(ctx, ext_2, get_smallest_measure(ext))
end

function phase_body(node::AcceptStepper, ctx, ext, ext_2)
    node = node.stepper
    next = node.next(ctx, ext_2)
    if next !== nothing
        Switch([
            value(:($(ctx(node.stop(ctx, ext))) == $(ctx(getstop(ext_2))))) => Thunk(
                body = (ctx) -> truncate(node.chunk, ctx, ext, similar_extent(ext, getstart(ext_2), getstop(ext))),
                epilogue = next
            ),
            literal(true) => 
                truncate(node.chunk, ctx, ext, similar_extent(ext, getstart(ext_2), bound_above!(ctx, getstop(ext_2), call(-, getstop(ext), getunit(ext))))),
        ])
    else
        node.body(ctx, ext_2)
    end
end
