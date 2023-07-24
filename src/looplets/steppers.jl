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
    if root.kind === loop
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
    body
    next = (ctx, ext) -> quote end
end

FinchNotation.finch_leaf(x::Step) = virtual(x)

(ctx::Stylize{<:AbstractCompiler})(node::Step) = ctx.root.kind === loop ? PhaseStyle() : DefaultStyle()

function phase_range(node::Step, ctx, ext)
    ext2 = similar_extent(ext, getstart(ext), node.stop(ctx, ext))
    Narrow(bound_measure_below!(ext2, getunit(ext)))
end

phase_body(node::Step, ctx, ext, ext_2) =
      Switch([
          value(:($(ctx(node.stop(ctx, ext))) == $(ctx(getstop(ext_2))))) => Thunk(
              body = (ctx) -> truncate(node.body, ctx, ext, similar_extent(ext, getstart(ext_2), getstop(ext))),
              epilogue = node.next(ctx, ext_2)
          ),
          literal(true) => 
              truncate(node.body, ctx, ext, similar_extent(ext, getstart(ext_2), bound_above!(getstop(ext_2), call(-, getstop(ext), getunit(ext))))),
          ])

