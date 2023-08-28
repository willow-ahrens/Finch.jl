@kwdef struct Jump
    seek = nothing
    preamble = nothing
    stop
    body
    next = nothing
end

FinchNotation.finch_leaf(x::Jump) = virtual(x)

(ctx::Stylize{<:AbstractCompiler})(node::Jump) = ctx.root.kind === loop ? JumperPhaseStyle() : DefaultStyle()

function phase_range(node::Jump, ctx, ext)
    push!(ctx.preamble, node.preamble !== nothing ? node.preamble : quote end)
    similar_extent(ext, getstart(ext), node.stop(ctx, ext))
end

phase_body(node::Jump, ctx, ext, ext_2) = node.body(ctx, ext, ext_2)

Base.show(io::IO, ex::Jump) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Jump)
	print(io, "Jump(...)")
end
