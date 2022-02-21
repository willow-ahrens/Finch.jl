struct JumperStyle end

@kwdef struct Jumper
    body
    seek = (ctx, start) -> error("seek not implemented error")
    name = gensym()
end

isliteral(::Stepper) = false

make_style(root::Loop, ctx::LowerJulia, node::Jumper) = JumperStyle()
combine_style(a::DefaultStyle, b::JumperStyle) = JumperStyle()
combine_style(a::JumperStyle, b::JumperStyle) = JumperStyle()
combine_style(a::JumperStyle, b::RunStyle) = RunStyle()
combine_style(a::JumperStyle, b::AcceptRunStyle) = JumperStyle()
combine_style(a::JumperStyle, b::AcceptSpikeStyle) = JumperStyle()
combine_style(a::JumperStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::JumperStyle, b::CaseStyle) = CaseStyle()
combine_style(a::ThunkStyle, b::JumperStyle) = ThunkStyle()
combine_style(a::StepperStyle, b::JumperStyle) = JumperStyle()

function (ctx::LowerJulia)(root::Loop, ::JumperStyle)
    i = getname(root.idxs[1])
    i0 = ctx.freshen(i, :_start)
    push!(ctx.preamble, quote
        $i0 = $(ctx(ctx.dims[i].start))
    end)
    guard = nothing
    body = JumperVisitor(i0, ctx)(root)
    body_2 = :(error("this code should not run"))

    while true
        ctx_2 = diverge(ctx)
        body_2 = scope(ctx_2) do ctx_3
            body_3 = ThunkVisitor(ctx_3)(body)
            guards = (PhaseGuardVisitor(ctx_3, i, i0))(body_3)
            strides = (PhaseStrideVisitor(ctx_3, i, i0))(body_3)
            if isempty(strides)
                step = ctx_3(ctx.dims[i].stop)
                step_min = quote end
            else
                step = ctx.freshen(i, :_step)
                step_min = quote
                    $step = min(max($(map(ctx_3, strides)...)), $(ctx_3(ctx.dims[i].stop)))
                end
                if length(strides) == 1 && length(guards) == 1
                    guard = guards[1]
                else
                    guard = :($i0 <= $(ctx_3(ctx.dims[i].stop)))
                end
            end
            body_4 = (PhaseBodyVisitor(ctx_3, i, i0, step))(body_3)
            quote
                $step_min
                $(scope(ctx_3) do ctx_4
                    restrict(ctx_4, i => Extent(Virtual{Any}(i0), Virtual{Any}(step))) do
                        (ctx_4)(body_4)
                    end
                end)
                $i0 = $step + 1
            end
        end
        if ctx_2.state == ctx.state
            break
        else
            unify!(ctx, ctx_2)
        end
    end
    return quote
        while $guard
            $body_2
        end
    end
end

@kwdef struct JumperVisitor <: AbstractTransformVisitor
    start
    ctx
end
function (ctx::JumperVisitor)(node::Jumper, ::DefaultStyle)
    if false in get(ctx.ctx.state, node.name, Set(true))
        push!(ctx.ctx.preamble, node.seek(ctx, ctx.start))
    end
    define!(ctx.ctx, node.name, Set(true))
    node.body
end

function truncate(node::Jumper, ctx, start, step, stop)
    define!(ctx, node.name, Set(false))
    node
end