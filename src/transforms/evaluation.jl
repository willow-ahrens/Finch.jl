"""
    evaluate_partial(root, ctx)

"""
function evaluate_partial(root, ctx)
    Rewrite(Fixpoint(Chain(
        Postwalk(Fixpoint(Chain([
            (@rule call(~f::isliteral, ~a::(All(isliteral))...) => finch_leaf(getval(f)(getval.(a)...))),
            (@rule call(~f::isliteral, ~a::(All(isleaf))...) => virtual_call(f.val, a...)),
            (@rule sequence(~s1..., define(~a::isvariable, ~v::isconstant), ~s2...) => begin
                s2_2 = Postwalk(@rule a => v)(sequence(s2...))
                if s2_2 !== nothing
                    #We cannot remove the definition because we aren't sure if the variable gets referenced from a virtual.
                    sequence(s1..., define(a, v), s2_2.bodies...)
                end
            end),
        ])))
    )))(root)
end