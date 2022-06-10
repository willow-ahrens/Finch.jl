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

function lower_cycle(root, ctx, ext::UnitExtent, style)
    i = getname(root.idx)
    i0 = ctx.freshen(i, :_start)
    push!(ctx.preamble, quote
        $i0 = $(ctx(getstart(root.ext)))
        $i = $i0
    end)

    body = Postwalk(node->unwrap_cycle(node, ctx, ext, style))(root.body)

    contain(ctx) do ctx_4
        push!(ctx_4.preamble, :($i0 = $i))
        ctx_4(Chunk(root.idx, Extent(i0, getstop(ext)), body))
    end
end

function lower_cycle(root, ctx, ext, style)
    i = getname(root.idx)
    i0 = ctx.freshen(i, :_start)
    push!(ctx.preamble, quote
        $i0 = $(ctx(getstart(root.ext)))
        $i = $i0
    end)

    guard = :($i <= $(ctx(getstop(root.ext))))
    body = Postwalk(node->unwrap_cycle(node, ctx, ext, style))(root.body)

    body_2 = fixpoint(ctx) do ctx_2
        scope(ctx_2) do ctx_3
            contain(ctx_3) do ctx_4
                push!(ctx_4.preamble, :($i0 = $i))
                ctx_4(Chunk(root.idx, Extent(i0, getstop(root.ext)), body))
            end
        end
    end
    return quote
        while $guard
            $body_2
        end
    end
end

unwrap_cycle(node, ctx, ext, style) = nothing
function unwrap_cycle(node::Stepper, ctx, ext, ::StepperStyle)
    push!(ctx.preamble, node.seek(ctx, ext))
    node.body
end

truncate(node, ctx, start, step, stop) = node
function truncate(node::Spike, ctx, start, step, stop)
    return Cases([
        :($(step) < $(stop)) => Run(node.body),
        true => node,
    ])
end

supports_shift(::StepperStyle) = true
