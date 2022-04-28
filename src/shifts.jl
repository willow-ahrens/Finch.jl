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