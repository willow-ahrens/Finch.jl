struct StepperStyle end

@kwdef struct Stepper
    body
    seek = (ctx, start) -> error("seek not implemented error")
end

isliteral(::Stepper) = false

make_style(root::Chunk, ctx::LowerJulia, node::Stepper) = StepperStyle()

combine_style(a::DefaultStyle, b::StepperStyle) = StepperStyle()
combine_style(a::StepperStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::StepperStyle, b::StepperStyle) = StepperStyle()
combine_style(a::StepperStyle, b::RunStyle) = RunStyle()
combine_style(a::SimplifyStyle, b::StepperStyle) = SimplifyStyle()
combine_style(a::StepperStyle, b::AcceptRunStyle) = StepperStyle()
combine_style(a::StepperStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::StepperStyle, b::CaseStyle) = CaseStyle()
combine_style(a::ThunkStyle, b::StepperStyle) = ThunkStyle()
combine_style(a::StepperStyle, b::JumperStyle) = JumperStyle()
combine_style(a::StepperStyle, b::PhaseStyle) = PhaseStyle()

function (ctx::LowerJulia)(root::Chunk, style::StepperStyle)
    lower_cycle(root, ctx, root.ext, style)
end

function unwrap_cycle(node::Stepper, ctx, ext, ::StepperStyle)
    push!(ctx.preamble, node.seek(ctx, ext))
    node.body
end

@kwdef struct Step
    stride
    next = (ctx, idx, ext) -> quote end
    chunk = nothing
    body = (ctx, idx, ext, ext_2) -> Cases([
        :($(ctx(stride(ctx, idx, ext))) == $(ctx(getstop(ext_2)))) => Thunk(
            body = truncate_weak(chunk, ctx, ext, ext_2),
            epilogue = next(ctx, idx, ext_2)
        ),
        true => 
            truncate_strong(chunk, ctx, ext, ext_2),
        ])
end

isliteral(::Step) = false

make_style(root::Chunk, ctx::LowerJulia, node::Step) = PhaseStyle()

(ctx::PhaseStride)(node::Step) = Narrow(Extent(start = getstart(ctx.ext), stop = node.stride(ctx.ctx, ctx.idx, ctx.ext), lower = 1))

phase_body(node::Step, ctx, idx, ext, ext_2) = node.body(ctx, idx, ext, ext_2)

supports_shift(::StepperStyle) = true