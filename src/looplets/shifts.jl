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

FinchNotation.finch_leaf(x::Shift) = virtual(x)

#TODO can't we do this more pretty?
supports_shift(style) = false
supports_shift(::DefaultStyle) = true
(ctx::Stylize{LowerJulia})(node::Shift) = (@assert supports_shift(ctx(node.body)) "$(ctx(node.body))"; ctx(node.body))

get_point_body(node::Shift, ctx, idx) = get_point_body(node.body, ctx, call(-, idx, node.delta))

supports_shift(::ThunkStyle) = true
(ctx::ThunkVisitor)(node::Shift) = Shift(;kwfields(node)..., body = ctx(node.body))

function shiftdim(ext::Extent, delta)
    Extent(
        start = call(+, ext.start, delta),
        stop = call(+, ext.stop, delta),
    )
end

shiftdim(ext::Widen, delta) = Widen(shiftdim(ext.ext, delta))
shiftdim(ext::Narrow, delta) = Narrow(shiftdim(ext.ext, delta))
shiftdim(ext::NoDimension, delta) = nodim

function shiftdim(ext::FinchNode, body)
    if ext.kind === virtual
        shiftdim(ext.val, body)
    else
        error("unimplemented")
    end
end


truncate(node::Shift, ctx, ext, ext_2) = Shift(truncate(node.body, ctx, shiftdim(ext, node.delta), shiftdim(ext_2, node.delta)), node.delta)
truncate_weak(node::Shift, ctx, ext, ext_2) = Shift(truncate_weak(node.body, ctx, shiftdim(ext, node.delta), shiftdim(ext_2, node.delta)), node.delta)
truncate_strong(node::Shift, ctx, ext, ext_2) = Shift(truncate_strong(node.body, ctx, shiftdim(ext, node.delta), shiftdim(ext_2, node.delta)), node.delta)