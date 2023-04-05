struct Null
end

FinchNotation.finch_leaf(x::Null) = virtual(x)
virtual_default(f::Null) = Some(f.default)

struct NullStyle <: AbstractPreSimplifyStyle end

(ctx::Stylize)(::Null) = NullStyle()

function (ctx::LowerJulia)(root::FinchNode, ::NullStyle)
    ctx(Postwalk(@rule assign(access(~a::isvirtual, ~m, ~i...), ~op, ~rhs) => if a.val isa Null Simplify(sequence()) end)(root))
end