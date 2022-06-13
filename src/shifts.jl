@kwdef struct Shift
    shift
    body
end

isliteral(::Shift) = false

supports_shift(style) = false
supports_shift(::DefaultStyle) = true
function make_style(root, ctx::LowerJulia, node::Shift)
    style = make_style(root, ctx, node.body)
    @assert supports_shift(style)
    style
end
function (ctx::ForLoopVisitor)(node::Shift, ::DefaultStyle)
    ctx_2 = ForLoopVisitor(ctx.ctx, ctx.idx, call(+, ctx.val, node.shift))
    ctx_2(node.body)
end
function (ctx::ForLoopVisitor)(node::Access{Shift}, ::DefaultStyle)
    ctx_2 = ForLoopVisitor(ctx.ctx, ctx.idx, call(+, ctx.val, node.tns.shift))
    ctx_2(node.tns.body)
end

function shiftdim(ext::Extent, ctx, delta)
    Extent(
        start = cache!(ctx, ctx.freshen(:start), call(+, ext.start, delta)),
        stop = cache!(ctx, ctx.freshen(:stop), call(+, ext.stop, delta)),
        lower = ext.lower,
        upper = ext.upper
    )
end

shiftdim(ext::Widen, ctx, delta) = Widen(shiftdim(ext.ext, ctx, delta))
shiftdim(ext::Narrow, ctx, delta) = Narrow(shiftdim(ext.ext, ctx, delta))
shiftdim(ext::NoDimension, ctx, delta) = NoDimension()