@kwdef struct Shift
    body
    delta
end

shift(body, delta) = Shift(body, delta)

SyntaxInterface.istree(::Shift) = true
SyntaxInterface.operation(::Shift) = shift
SyntaxInterface.arguments(node::Shift) = [node.body, node.delta]

Base.show(io::IO, ex::Shift) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Shift)
    print(io, "Shift(body = ")
    print(io, ex.body)
    print(io, ", delta = ")
    print(io, ex.delta)
    print(io, ")")
end

isliteral(::Shift) = false

#TODO can't we do this more pretty?
supports_shift(style) = false
supports_shift(::DefaultStyle) = true
(ctx::Stylize{LowerJulia})(node::Shift) = (@assert supports_shift(ctx(node.body)) "$(ctx(node.body))"; ctx(node.body))

unchunk(node::Shift, ctx::ForLoopVisitor) = unchunk(node.body, ForLoopVisitor(;kwfields(ctx)..., val = call(-, ctx.val, node.delta)))

supports_shift(::ThunkStyle) = true
(ctx::ThunkVisitor)(node::Shift, ::DefaultStyle) = Shift(;kwfields(node)..., body = ctx(node.body))

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
shiftdim(ext::NoDimension, delta) = nodim
shiftdim(ext::DeferDimension, delta) = deferdim

truncate(node::Shift, ctx, ext, ext_2) = Shift(truncate(node.body, ctx, shiftdim(ext, node.delta), shiftdim(ext_2, node.delta)), node.delta)
truncate_weak(node::Shift, ctx, ext, ext_2) = Shift(truncate_weak(node.body, ctx, shiftdim(ext, node.delta), shiftdim(ext_2, node.delta)), node.delta)
truncate_strong(node::Shift, ctx, ext, ext_2) = Shift(truncate_strong(node.body, ctx, shiftdim(ext, node.delta), shiftdim(ext_2, node.delta)), node.delta)