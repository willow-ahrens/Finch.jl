@kwdef struct Step
    preamble = nothing
    chunk = nothing
    body = (ctx, ext) -> chunk
    stop = (ctx, ext) -> nothing
    range = (ctx, ext) -> Extent(something(start(ctx, ext), getstart(ext)), something(stop(ctx, ext), getstop(ext)))
    next = (ctx, ext) -> nothing
end

FinchNotation.finch_leaf(x::Step) = virtual(x)

(ctx::Stylize{<:AbstractCompiler})(node::Step) = ctx.root.kind === loop ? StepperPhaseStyle() : DefaultStyle()

function phase_range(node::Step, ctx, ext)
    push!(ctx.code.preamble, node.preamble !== nothing ? node.preamble : quote end)
    ext_2 = similar_extent(ext, getstart(ext), node.stop(ctx, ext))
    bound_measure_below!(ext_2, getunit(ext))
end

function phase_body(node::Step, ctx, ext, ext_2)
    next = node.next(ctx, ext_2)
    if next !== nothing
        Switch([
            value(:($(ctx(node.stop(ctx, ext))) == $(ctx(getstop(ext_2))))) => Thunk(
                body = (ctx) -> truncate(node.chunk, ctx, ext, similar_extent(ext, getstart(ext_2), getstop(ext))),
                epilogue = next
            ),
            literal(true) => 
                truncate(node.chunk, ctx, ext, similar_extent(ext, getstart(ext_2), bound_above!(getstop(ext_2), call(-, getstop(ext), getunit(ext))))),
        ])
    else
        node.body(ctx, ext_2)
    end
end
