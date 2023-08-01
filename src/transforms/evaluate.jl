"""
    evaluate_partial(root, ctx)

"""
function evaluate_partial(root, ctx)
    root_2 = Rewrite(Fixpoint(
        Postwalk(Fixpoint(Chain([
            (@rule call(~f::isliteral, ~a::(All(Or(isconstant, isvirtual, isvariable)))...) => virtual_call(f.val, ctx, a...)),
            (@rule call(~f::isliteral, ~a::(All(isliteral))...) => finch_leaf(getval(f)(getval.(a)...))),
            (@rule block(~s1..., define(~a::isvariable, ~v::isconstant), ~s2...) => begin
                s2_2 = Postwalk(@rule a => v)(block(s2...))
                if s2_2 !== nothing
                    #We cannot remove the definition because we aren't sure if the variable gets referenced from a virtual.
                    block(s1..., define(a, v), s2_2.bodies...)
                end
            end),
        ])))
    ))(root)
    Rewrite(Fixpoint(Chain([
        (@rule block(define(~a::isvariable, ~v::Or(isconstant, isvirtual)), ~s...) => begin
            ctx.bindings[a] = v
            block(s...)
        end),
    ])))(root_2)
end

virtual_call(f, ctx, a...) = nothing