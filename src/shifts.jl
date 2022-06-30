@kwdef struct Shift
    shift
    body
end

isliteral(::Shift) = false

#TODO can't we do this more pretty?
supports_shift(style) = false
supports_shift(::DefaultStyle) = true
(ctx::Stylize{LowerJulia})(node::Shift) = (@assert supports_shift(ctx(node.body)); ctx(node.body))

function (ctx::ForLoopVisitor)(node::Shift, ::DefaultStyle)
    ctx_2 = ForLoopVisitor(ctx.ctx, ctx.idx, call(+, ctx.val, node.shift))
    ctx_2(node.body)
end
function (ctx::ForLoopVisitor)(node::Access{Shift}, ::DefaultStyle)
    ctx_2 = ForLoopVisitor(ctx.ctx, ctx.idx, call(+, ctx.val, node.tns.shift))
    ctx_2(node.tns.body)
end

function shiftdim(ext::Extent, delta)
    Extent(
        start = call(+, ext.start, delta),
        stop = call(+, ext.stop, delta),
        lower = ext.lower,
        upper = ext.upper
    )
end

shiftdim(ext::Widen, delta) = Widen(shiftdim(ext.ext, delta))
shiftdim(ext::Narrow, delta) = Narrow(shiftdim(ext.ext, delta))
shiftdim(ext::NoDimension, delta) = NoDimension()