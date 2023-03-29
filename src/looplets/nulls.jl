struct Null
end

FinchNotation.isliteral(::Null) = false
virtual_default(f::Null) = Some(f.default)

(ctx::Stylize{LowerJulia})(::Null) = SimplifyStyle()

function base_rules(alg, ctx::LowerJulia, ::Null) 
    return [
        (@rule assign(access(~a::isvirtual, ~m, ~i...), ~op, ~rhs) => if a.val isa Null sequence() end),
    ]
end