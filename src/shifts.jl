@kwdef struct Shift
    shift
    body
end

isliteral(::Shift) = false

supports_shift(style) = false
function make_style(root, ctx::LowerJulia, node::Shift)
    style = make_style(root, ctx, node.body)
    @assert supports_shift(style)
end
function (ctx::ForLoopVisitor)(node::Shift, ::DefaultStyle)
    ctx_2 = ForLoopVisitor(ctx, idx, Call(+, val, node.shift))
    ctx_2(node.body)
end