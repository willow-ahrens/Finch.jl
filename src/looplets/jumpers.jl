struct JumperStyle end

@kwdef struct Jumper
    body
end

FinchNotation.finch_leaf(x::Jumper) = virtual(x)

(ctx::Stylize{<:AbstractCompiler})(node::Jumper) = ctx.root.kind === loop ? JumperStyle() : DefaultStyle()

combine_style(a::DefaultStyle, b::JumperStyle) = JumperStyle()
combine_style(a::JumperStyle, b::JumperStyle) = JumperStyle()
combine_style(a::JumperStyle, b::RunStyle) = RunStyle()
combine_style(a::SimplifyStyle, b::JumperStyle) = a
combine_style(a::JumperStyle, b::AcceptRunStyle) = JumperStyle()
combine_style(a::JumperStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::JumperStyle, b::SwitchStyle) = SwitchStyle()
combine_style(a::JumperStyle, b::PipelineStyle) = PipelineStyle()
combine_style(a::ThunkStyle, b::JumperStyle) = ThunkStyle()

function (ctx::AbstractCompiler)(root::FinchNode, style::JumperStyle)
    if root.kind === loop
        return lower_cycle(root, ctx, root.idx, root.ext, style)
    else
        error("unimplemented")
    end
end

(ctx::CycleVisitor{JumperStyle})(node::Jumper) = node.body

@kwdef struct Jump
    seek = nothing
    stop
    body
    next = nothing
end

FinchNotation.finch_leaf(x::Jump) = virtual(x)

(ctx::Stylize{<:AbstractCompiler})(node::Jump) = ctx.root.kind === loop ? PhaseStyle() : DefaultStyle()

function phase_range(node::Jump, ctx, ext)
    push!(ctx.preamble, node.seek !== nothing ? node.seek(ctx, ext) : quote end)
    Widen(Extent(getstart(ext), node.stop(ctx, ext)))
end

phase_body(node::Jump, ctx, ext, ext_2) = node.body(ctx, ext, ext_2)

supports_shift(::JumperStyle) = true

Base.show(io::IO, ex::Jumper) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Jumper)
	print(io, "Jumper(...)")
end

Base.show(io::IO, ex::Jump) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Jump)
	print(io, "Jump(...)")
end