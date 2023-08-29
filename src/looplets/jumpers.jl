@kwdef struct Jump
    seek = nothing
    preamble = nothing
    chunk = nothing
    stop = (ctx, ext) -> nothing 
    body = nothing
    next = (ctx, ext) -> nothing
end

FinchNotation.finch_leaf(x::Jump) = virtual(x)

(ctx::Stylize{<:AbstractCompiler})(node::Jump) = ctx.root.kind === loop ? JumperPhaseStyle() : DefaultStyle()

function phase_range(node::Jump, ctx, ext)
    push!(ctx.preamble, node.preamble !== nothing ? node.preamble : quote end)
    similar_extent(ext, getstart(ext), node.stop(ctx, ext))
end

function phase_body(node::Jump, ctx, ext, ext_2) 
    next = node.next(ctx, ext_2)
    if next !== nothing
        Switch([
            value(:($(ctx(node.stop(ctx, ext))) == $(ctx(getstop(ext_2))))) => Thunk(
                body = (ctx) -> node.chunk,
                epilogue = next
            ),
            literal(true) => 
                Replay(
                    seek = node.seek, #Copied from Replay (see replay_seek)
                    body = Step(
                        preamble = node.preamble,
                        stop = node.stop,
                        chunk = node.chunk,
                        next = node.next
                        )
                    )
        ])
    else
        node.body(ctx, ext_2)
    end

end 

Base.show(io::IO, ex::Jump) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Jump)
	print(io, "Jump(...)")
end
