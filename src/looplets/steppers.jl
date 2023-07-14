struct StepperStyle end

@kwdef struct Stepper
    body
    seek = (ctx, start) -> error("seek not implemented error")
end

Base.show(io::IO, ex::Stepper) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Stepper)
    print(io, "Stepper()")
end

FinchNotation.finch_leaf(x::Stepper) = virtual(x)

(ctx::Stylize{<:AbstractCompiler})(node::Stepper) = ctx.root.kind === loop ? StepperStyle() : DefaultStyle()

combine_style(a::DefaultStyle, b::StepperStyle) = StepperStyle()
combine_style(a::LookupStyle, b::StepperStyle) = StepperStyle()
combine_style(a::StepperStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::StepperStyle, b::StepperStyle) = StepperStyle()
combine_style(a::StepperStyle, b::RunStyle) = RunStyle()
combine_style(a::SimplifyStyle, b::StepperStyle) = a
combine_style(a::StepperStyle, b::AcceptRunStyle) = StepperStyle()
combine_style(a::StepperStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::StepperStyle, b::SwitchStyle) = SwitchStyle()
combine_style(a::ThunkStyle, b::StepperStyle) = ThunkStyle()
combine_style(a::StepperStyle, b::JumperStyle) = JumperStyle()
combine_style(a::StepperStyle, b::PhaseStyle) = PhaseStyle()

function lower(root::FinchNode, ctx::AbstractCompiler,  style::StepperStyle)
    root.kind === loop || error("unimplemented")
    i = getname(root.idx)
    i0 = ctx.freshen(i, :_start)
    push!(ctx.preamble, quote
        $i = $(ctx(getstart(root.ext)))
    end)

    guard = :($i <= $(ctx(getstop(root.ext))))

    foreach(filter(isvirtual, collect(PostOrderDFS(root.body)))) do node
        push!(ctx.preamble, stepper_seek(node.val, ctx, root.ext))
    end

    body_2 = Rewrite(Postwalk(@rule access(~tns::isvirtual, ~mode, ~idxs...) => begin
        tns_2 = stepper_body(tns.val, ctx, root.ext)
        access(tns_2, mode, idxs...)
    end))(root.body)

    body_3 = contain(ctx) do ctx_2
        push!(ctx_2.preamble, :($i0 = $i))
        ctx_2(loop(root.idx, bound_measure_below!(Extent(start = value(i0), stop = getstop(root.ext)), literal(1)), body_2))
    end

    @assert isvirtual(root.ext)

    if query(call(==, measure(root.ext.val), 1), ctx)
        body_3
    else
        return quote
            while $guard
                $body_3
            end
        end
    end
end

stepper_seek(node::Stepper, ctx, ext) = node.seek(ctx, ext)
stepper_seek(node, ctx, ext) = quote end

stepper_body(node::Stepper, ctx, ext) = node.body
stepper_body(node, ctx, ext) = node

@kwdef struct Step
    stop
    body
    next = (ctx, ext) -> quote end
end

FinchNotation.finch_leaf(x::Step) = virtual(x)

(ctx::Stylize{<:AbstractCompiler})(node::Step) = ctx.root.kind === loop ? PhaseStyle() : DefaultStyle()

function phase_range(node::Step, ctx, ext)
    Narrow(bound_measure_below!(Extent(getstart(ext), node.stop(ctx, ext)), literal(1)))
end

phase_body(node::Step, ctx, ext, ext_2) =
    Switch([
        value(:($(ctx(node.stop(ctx, ext))) == $(ctx(getstop(ext_2))))) => Thunk(
            body = (ctx) -> truncate(node.body, ctx, ext, Extent(getstart(ext_2), getstop(ext))),
            epilogue = node.next(ctx, ext_2)
        ),
        literal(true) => 
            truncate(node.body, ctx, ext, Extent(getstart(ext_2), bound_above!(getstop(ext_2), call(-, getstop(ext), 1)))),
        ])