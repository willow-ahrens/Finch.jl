struct JumperStyle end

@kwdef struct Jumper
    body
end

FinchNotation.finch_leaf(x::Jumper) = virtual(x)

(ctx::Stylize{<:AbstractCompiler})(node::Jumper) = ctx.root.kind === loop ? JumperStyle() : DefaultStyle()

combine_style(a::DefaultStyle, b::JumperStyle) = JumperStyle()
combine_style(a::LookupStyle, b::JumperStyle) = JumperStyle()
combine_style(a::JumperStyle, b::JumperStyle) = JumperStyle()
combine_style(a::JumperStyle, b::RunStyle) = RunStyle()
combine_style(a::SimplifyStyle, b::JumperStyle) = a
combine_style(a::JumperStyle, b::AcceptRunStyle) = JumperStyle()
combine_style(a::JumperStyle, b::SpikeStyle) = SpikeStyle()
combine_style(a::JumperStyle, b::SwitchStyle) = SwitchStyle()
combine_style(a::JumperStyle, b::SequenceStyle) = SequenceStyle()
combine_style(a::ThunkStyle, b::JumperStyle) = ThunkStyle()
combine_style(a::JumperStyle, b::PhaseStyle) = b

function lower(root::FinchNode, ctx::AbstractCompiler,  style::JumperStyle)
    root.kind === loop || error("unimplemented")

    i = getname(root.idx)
    i0 = ctx.code.freshen(i, :_start)
    push!(ctx.code.preamble, quote
        $i = $(ctx(getstart(root.ext)))
    end)

    guard = :($i <= $(ctx(getstop(root.ext))))

    body_2 = Rewrite(Postwalk(@rule access(~tns::isvirtual, ~mode, ~idxs...) => begin
        tns_2 = jumper_body(tns.val, ctx, root.ext)
        access(tns_2, mode, idxs...)
    end))(root.body)

    body_3 = contain(ctx) do ctx_2
        push!(ctx_2.code.preamble, :($i0 = $i))
        if is_continuous_extent(root.ext) 
            ctx_2(loop(root.idx, bound_measure_below!(ContinuousExtent(start = value(i0), stop = getstop(root.ext)), literal(0)), body_2))
        else
            ctx_2(loop(root.idx, bound_measure_below!(Extent(start = value(i0), stop = getstop(root.ext)), literal(1)), body_2))
        end
    end

    @assert isvirtual(root.ext)

    target = is_continuous_extent(root.ext.val) ? 0 : 1
    if query(call(==, measure(root.ext.val), target), ctx)
        body_3
    else
        return quote
            while $guard
                $body_3
            end
        end
    end
end

jumper_body(node::Jumper, ctx, ext) = node.body
jumper_body(node, ctx, ext) = node

@kwdef struct Jump
    seek = nothing
    stop
    body
    next = nothing
end

FinchNotation.finch_leaf(x::Jump) = virtual(x)

(ctx::Stylize{<:AbstractCompiler})(node::Jump) = ctx.root.kind === loop ? JumperPhaseStyle() : DefaultStyle()

function phase_range(node::Jump, ctx, ext)
    push!(ctx.code.preamble, node.seek !== nothing ? node.seek(ctx, ext) : quote end)
    similar_extent(ext, getstart(ext), node.stop(ctx, ext))
end

phase_body(node::Jump, ctx, ext, ext_2) = node.body(ctx, ext, ext_2)

Base.show(io::IO, ex::Jumper) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Jumper)
	print(io, "Jumper(...)")
end

Base.show(io::IO, ex::Jump) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Jump)
	print(io, "Jump(...)")
end