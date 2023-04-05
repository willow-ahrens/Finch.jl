struct Fill
    body::FinchNode
    Fill(x) = new(finch_leaf(x))
end

FinchNotation.finch_leaf(x::Fill) = virtual(x)
virtual_default(f::Fill) = Some(f.body)

struct FillStyle <: AbstractPreSimplifyStyle end

(ctx::Stylize)(::Fill) = FillStyle()

function (ctx::LowerJulia)(root::FinchNode, ::FillStyle)
    ctx(Postwalk(@rule access(~a::isvirtual, ~m, ~i...) => if a.val isa Fill Simplify(a.val.body) end)(root))
end