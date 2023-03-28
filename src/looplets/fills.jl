struct Fill
    body::FinchNode
    Fill(x) = new(finch_leaf(x))
end

FinchNotation.isliteral(::Fill) = false
virtual_default(f::Fill) = Some(f.body)

(ctx::Stylize{LowerJulia})(::Fill) = SimplifyStyle()

function base_rules(alg, ctx::LowerJulia, ::Fill) 
    return [
        (@rule access(~a::isvirtual, ~m, ~i...) => if a.val isa Fill a.val.body end),
    ]
end