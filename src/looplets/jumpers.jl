struct JumperStyle end

@kwdef struct Jumper
    body
end

FinchNotation.finch_leaf(x::Jumper) = virtual(x)

(ctx::Stylize{LowerJulia})(node::Jumper) = ctx.root.kind === chunk ? JumperStyle() : DefaultStyle()

combine_style(a::DefaultStyle, b::JumperStyle) = JumperStyle()
combine_style(a::JumperStyle, b::JumperStyle) = JumperStyle()
combine_style(a::JumperStyle, b::RunStyle) = RunStyle()
combine_style(a::SimplifyStyle, b::JumperStyle) = a
combine_style(a::JumperStyle, b::AcceptRunStyle) = JumperStyle()
combine_style(a::JumperStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::JumperStyle, b::SwitchStyle) = SwitchStyle()
combine_style(a::JumperStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::ThunkStyle, b::JumperStyle) = ThunkStyle()

function (ctx::LowerJulia)(root::FinchNode, style::JumperStyle)
    if root.kind === chunk
        return lower_cycle(root, ctx, root.idx, root.ext, style)
    else
        error("unimplemented")
    end
end

(ctx::CycleVisitor{JumperStyle})(node::Jumper) = node.body

@kwdef struct Jump
    seek = nothing
    stride
    body
    next = nothing
end

FinchNotation.finch_leaf(x::Jump) = virtual(x)

(ctx::Stylize{LowerJulia})(node::Jump) = ctx.root.kind === chunk ? PhaseStyle() : DefaultStyle()

function (ctx::PhaseStride)(node::Jump)
    push!(ctx.ctx.preamble, node.seek !== nothing ? node.seek(ctx.ctx, ctx.ext) : quote end)
    Widen(Extent(getstart(ctx.ext), node.stride(ctx.ctx, ctx.ext)))
end

(ctx::PhaseBodyVisitor)(node::Jump) = node.body(ctx.ctx, ctx.ext, ctx.ext_2)

supports_shift(::JumperStyle) = true

Base.show(io::IO, ex::Jumper) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Jumper)
	print(io, "Jumper(...)")
end

Base.show(io::IO, ex::Jump) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Jump)
	print(io, "Jump(...)")
end