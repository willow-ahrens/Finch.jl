struct JumperStyle end

@kwdef struct Jumper
    body
    status = gensym()
end

isliteral(::Jumper) = false

(ctx::Stylize{LowerJulia})(node::Jumper) = JumperStyle()

combine_style(a::DefaultStyle, b::JumperStyle) = JumperStyle()
combine_style(a::JumperStyle, b::JumperStyle) = JumperStyle()
combine_style(a::JumperStyle, b::RunStyle) = RunStyle()
combine_style(a::SimplifyStyle, b::JumperStyle) = SimplifyStyle()
combine_style(a::JumperStyle, b::AcceptRunStyle) = JumperStyle()
combine_style(a::JumperStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::JumperStyle, b::CaseStyle) = CaseStyle()
combine_style(a::JumperStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::ThunkStyle, b::JumperStyle) = ThunkStyle()

function (ctx::LowerJulia)(root::Chunk, style::JumperStyle)
    lower_cycle(root, ctx, root.idx, root.ext, style)
end

(ctx::CycleVisitor{JumperStyle})(node::Jumper) = node.body

@kwdef struct Jump
    seek = nothing
    stride
    body
    next = nothing
end

isliteral(::Jump) = false

(ctx::Stylize{LowerJulia})(node::Jump) = PhaseStyle()

function (ctx::PhaseStride)(node::Jump)
    push!(ctx.ctx.preamble, node.seek !== nothing ? node.seek(ctx.ctx, ctx.ext) : quote end)
    Widen(Extent(getstart(ctx.ext), node.stride(ctx.ctx, ctx.ext)))
end

(ctx::PhaseBodyVisitor)(node::Jump) = node.body(ctx.ctx, ctx.ext, ctx.ext_2)

supports_shift(::JumperStyle) = true