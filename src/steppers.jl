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

function (ctx::LowerJulia)(root::Chunk, style::StepperStyle)
    lower_cycle(root, ctx, root.ext, style)
end

function unwrap_cycle(node::Stepper, ctx, ext, ::StepperStyle)
    push!(ctx.preamble, node.seek(ctx, ext))
    node.body
end

#=
@kwdef struct Step
    body
    stride
    next = nothing
end

phase_range(node::Step, ctx, idx, ext) = Narrow(Extent(getstart(ext), node.stride(ctx, idx, ext)))

phase_body(node::Step, ctx, idx, ext, ext_2) = Cases([
    :($(ctx(node.stride(ctx, idx, ext))) == $(ctx(getstop(ext_2)))) => Thunk(
        body = truncate_weak(node.body, ctx, getstart(ext_2), getstop(ext_2), getstop(ext)),
        epilogue = node.next(ctx, idx, ext_2)
    ),
    :($(ctx(node.stride(ctx, idx, ext))) == $(ctx(getstop(ext_2)))) => 
        body = truncate_strong(node.body, ctx, getstart(ext_2), getstop(ext_2), getstop(ext)),
])
=#


truncate(node, ctx, ext, ext_2) = node
function truncate(node::Spike, ctx, ext, ext_2)
    return Cases([
        :($(ctx(getstop(ext_2))) < $(ctx(getstop(ext)))) => Run(node.body),
        true => node,
    ])
end

supports_shift(::StepperStyle) = true
