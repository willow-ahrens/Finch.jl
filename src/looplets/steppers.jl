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

(ctx::Stylize{LowerJulia})(node::Stepper) = ctx.root.kind === chunk ? StepperStyle() : DefaultStyle()

combine_style(a::DefaultStyle, b::StepperStyle) = StepperStyle()
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

function (ctx::LowerJulia)(root::FinchNode, style::StepperStyle)
    if root.kind === chunk
        return lower_cycle(root, ctx, root.idx, root.ext, style)
    else
        error("unimplemented")
    end
end

function (ctx::CycleVisitor{StepperStyle})(node::Stepper)
    push!(ctx.ctx.preamble, node.seek(ctx.ctx, ctx.ext))
    node.body
end

@kwdef struct Step
    stop
    next = (ctx, ext) -> quote end
    chunk = nothing
    body = (ctx, ext, ext_2) -> Switch([
        value(:($(ctx(stop(ctx, ext))) == $(ctx(getstop(ext_2))))) => Thunk(
            body = (ctx) -> truncate_weak(chunk, ctx, ext, ext_2),
            epilogue = next(ctx, ext_2)
        ),
        literal(true) => 
            truncate_strong(chunk, ctx, ext, ext_2),
        ])
end

FinchNotation.finch_leaf(x::Step) = virtual(x)

(ctx::Stylize{LowerJulia})(node::Step) = ctx.root.kind === chunk ? PhaseStyle() : DefaultStyle()

function phase_range(node::Step, ctx, ext)
    s = node.stop(ctx, ctx)
    Narrow(Extent(start = getstart(ext), stop = call(cached, s, call(max, s, call(+, getstart(ext), 1))), lower = literal(1)))
end

phase_body(node::Step, ctx, ext, ext_2) = node.body(ctx, ext, ext_2)

supports_shift(::StepperStyle) = true