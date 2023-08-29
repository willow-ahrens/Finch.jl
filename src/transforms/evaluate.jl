"""
    evaluate_partial(root, ctx)

This pass evaluates tags, global variable definitions, and foldable functions
into the context bindings.
"""
function evaluate_partial(root, ctx)
    root_2 = Rewrite(Fixpoint(Postwalk(Chain([
        (@rule tag(~var, ~bind::isindex) => bind),
        (@rule tag(~var, ~bind::isvariable) => bind),
        (@rule tag(~var, ~bind::isliteral) => bind),
        (@rule tag(~var, ~bind::isvalue) => bind),
        (@rule tag(~var, ~bind::isvirtual) => begin
            get!(ctx.bindings, var, bind)
            var
        end
        )
    ]))))(root)
    root_3 = Rewrite(Fixpoint(
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
    ))(root_2)
    Rewrite(Fixpoint(Chain([
        (@rule block(define(~a::isvariable, ~v::Or(isconstant, isvirtual)), ~s...) => begin
            ctx.bindings[a] = v
            block(s...)
        end),
    ])))(root_3)
end

virtual_call(f, ctx, a...) = nothing