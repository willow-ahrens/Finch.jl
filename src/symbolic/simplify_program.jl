"""
    get_program_rules(alg, shash)

Return the program rule set for Finch. One can dispatch on the `alg` trait to
specialize the rule set for different algebras. Defaults to a collection of
straightforward rules that use the algebra to check properties of functions
like associativity, commutativity, etc. `shash` is an object that can be called
to return a static hash value. This rule set simplifies, normalizes, and
propagates constants, and is the basis for how Finch understands sparsity.
"""
function get_program_rules(alg, shash)
    return [
        (@rule call(~f::isliteral, ~a::(All(isliteral))...) => literal(getval(f)(getval.(a)...))),

        (@rule loop(~i, ~a, block()) => block()),
        (@rule block(~a..., block(~b...), ~c...) => block(a..., b..., c...)),

        (@rule call(~f::isassociative(alg), ~a..., call(~f, ~b...), ~c...) => call(f, a..., b..., c...)),
        (@rule call(~f::iscommutative(alg), ~a...) => if !(issorted(a, by = shash))
            call(f, sort(a, by = shash)...)
        end),
        (@rule call(~f::isidempotent(alg), ~a...) => if !allunique(a)
            call(f, unique(a)...)
        end),
        (@rule call(~f::isassociative(alg), ~a..., ~b::isliteral, ~c::isliteral, ~d...) => call(f, a..., f.val(b.val, c.val), d...)),
        (@rule call(~f::isabelian(alg), ~a..., ~b::isliteral, ~c..., ~d::isliteral, ~e...) => call(f, a..., f.val(b.val, d.val), c..., e...)),
        (@rule call(~f, ~a..., ~b, ~c...) => if isannihilator(alg, f, b) b end),
        (@rule call(~f, ~a..., ~b, ~c, ~d...) => if isidentity(alg, f, b)
            call(f, a..., c, d...)
        end),
        (@rule call(~f, ~a..., ~b, ~c, ~d...) => if isidentity(alg, f, c)
            call(f, a..., b, d...)
        end),
        (@rule call(~f, ~a) => if isassociative(alg, f) a end), #TODO

        (@rule call(>=, ~a, ~b) => call(<=, b, a)),
        (@rule call(>, ~a, ~b) => call(<, b, a)),
        (@rule call(<, Inf, ~a) => literal(false)),
        (@rule call(<, ~a, -Inf) => literal(false)),
        (@rule call(>, ~a, Inf) => literal(false)),
        (@rule call(>, -Inf, ~a) => literal(false)),

        (@rule call(<=, ~a, call(max, ~b...)) => call(or, map(x -> call(<=, a, x), b)...)),
        (@rule call(<, ~a, call(max, ~b...)) => call(or, map(x -> call(<, a, x), b)...)),
        (@rule call(<=, call(max, ~a...), ~b) => call(and, map(x -> call(<=, x, b), a)...)),
        (@rule call(<, call(max, ~a...), ~b) => call(and, map(x -> call(<, x, b), a)...)),
        (@rule call(<=, ~a, call(min, ~b...)) => call(and, map(x -> call(<=, a, x), b)...)),
        (@rule call(<, ~a, call(min, ~b...)) => call(and, map(x -> call(<, a, x), b)...)),
        (@rule call(<=, call(min, ~a...), ~b) => call(or, map(x -> call(<=, x, b), a)...)),
        (@rule call(<, call(min, ~a...), ~b) => call(or, map(x -> call(<, x, b), a)...)),

        (@rule call(==, ~a, ~a) => literal(true)),
        (@rule call(<=, ~a, ~a) => literal(true)),
        (@rule call(<, ~a, ~a) => literal(false)), 
        (@rule assign(access(~a, updater(), ~i...), ~f, ~b) => if isidentity(alg, f, b) block() end),
        (@rule assign(access(~a, ~m, ~i...), $(literal(missing))) => block()),
        (@rule assign(access(~a, ~m, ~i..., $(literal(missing)), ~j...), ~b) => block()),
        (@rule call(coalesce, ~a..., ~b, ~c...) => if isvalue(b) && !(Missing <: b.type) || isliteral(b) && !ismissing(b.val)
            call(coalesce, a..., b)
        end),
        (@rule call(something, ~a..., ~b, ~c...) => if isvalue(b) && !(Nothing <: b.type) || isliteral(b) && b != literal(nothing)
            call(something, a..., b)
        end),

        (@rule call(~f, ~a..., cached(~b, ~c::isliteral), ~d...) => cached(call(f, a..., b, d...), literal(call(f, a..., c.val, d...)))),
        (@rule cached(cached(~a, ~b), ~c) => cached(a, c)),

        (@rule call(identity, ~a) => a),
        (@rule call(overwrite, ~a, ~b) => b),
        (@rule call(~f::isliteral, ~a, ~b) => if f.val isa InitWriter b end),
        (@rule assign(~a::isliteral, ~op, ~b) => if a.val === Null() block() end),
        (@rule call(ifelse, true, ~a, ~b) => a),
        (@rule call(ifelse, false, ~a, ~b) => b),
        (@rule call(ifelse, ~a, ~b, ~b) => b),
        (@rule $(literal(-0.0)) => literal(0.0)),

        (@rule block(~a1..., sieve(~c, ~b1), sieve(~c, ~b2), ~a2...) =>
            block(a1..., sieve(~c, block(b1, b2)), a2...)
        ),

        (@rule call(~f, call(~g, ~a, ~b...)) => if isinverse(alg, f, g) && isassociative(alg, g)
            call(g, call(f, a), map(c -> call(f, call(g, c)), b)...)
        end),

        #TODO should put a zero here, but we need types
        #=
        (@rule call(~g, ~a..., ~b, ~c..., call(~f, ~b), ~d...) => if isinverse(alg, f, g) && isassociative(alg, g)
            call(g, a..., c..., d...)
        end),
        (@rule call(~g, ~a..., call(~f, ~b), ~c..., ~b, ~d...) => if isinverse(alg, f, g) && isassociative(alg, g)
            call(g, a..., c..., d...)
        end),
        =#
        (@rule call(+, ~a..., ~b, ~c..., call(-, ~b), ~d...) => if isinverse(alg, -, +) && isassociative(alg, +)
            call(+, false, a..., c..., d...)
        end),
        (@rule call(+, ~a..., call(-, ~b), ~c..., ~b, ~d...) => if isinverse(alg, -, +) && isassociative(alg, +)
            call(+, false, a..., c..., d...)
        end),

        (@rule call(-, ~a, ~b) => call(+, a, call(-, b))),
        (@rule call(/, ~a, ~b) => call(*, a, call(inv, b))),

        (@rule call(~f::isinvolution(alg), call(~f, ~a)) => a),
        (@rule call(~f, ~a..., call(~g, ~b), ~c...) => if isdistributive(alg, g, f)
            call(g, call(f, a..., b, c...))
        end),

        (@rule call(/, ~a) => call(inv, a)),

        (@rule sieve(true, ~a) => a),
        (@rule sieve(false, ~a) => block()), #TODO should add back skipvisitor

        (@rule loop(~i, ~a::isvirtual, assign(access(~b, updater(), ~j...), ~f::isidempotent(alg), ~c)) => begin
            if i ∉ j && i ∉ getunbound(c)
                sieve(call(>, measure(a.val), 0), assign(access(b, updater(), j...), f, c))
            end
        end),
        (@rule loop(~i, ~a::isvirtual, assign(access(~b, updater(), ~j...), +, ~d)) => begin
            if i ∉ j && i ∉ getunbound(d)
                assign(access(b, updater(), j...), +, call(*, measure(a.val), d))
            end
        end),

        (@rule assign(~a, ~op, cached(~b, ~c)) => assign(a, op, b)),

        (@rule loop(~i, ~ext::isvirtual, assign(access(~a, ~m), $(literal(+)), ~b::isliteral)) =>
            assign(access(a, m), +, call(*, b, measure(ext.val)))
        ),
        (@rule loop(~i, ~ext::isvirtual, block(~s1..., assign(access(~a, ~m), $(literal(+)), ~b::isliteral), ~s2...)) => if ortho(getroot(a), s1) && ortho(getroot(a), s2)
            block(assign(access(a, m), +, call(*, b, measure(ext.val))), loop(i, ext, block(s1..., s2...)))
        end),
        (@rule loop(~i, ~ext, assign(access(~a, ~m), ~f::isidempotent(alg), ~b::isliteral)) =>
            sieve(call(>, measure(ext.val), 0), assign(access(a, m), f, b))
        ),
        (@rule loop(~i, ~ext, block(~s1..., assign(access(~a, ~m), ~f::isidempotent(alg), ~b::isliteral), ~s2...)) => if ortho(getroot(a), s1) && ortho(getroot(a), s2)
            block(sieve(call(>, measure(ext.val), 0), assign(access(a, m), f, b)), loop(i, ext, block(s1..., s2...)))
        end),

        (@rule block(~s1..., define(~a::isvariable, ~v::isconstant), ~s2...) => begin
            s2_2 = Postwalk(@rule a => v)(block(s2...))
            if s2_2 !== nothing
                #We cannot remove the definition because we aren't sure if the variable gets referenced from a virtual.
                block(s1..., define(a, v), s2_2.bodies...)
            end
        end),

        (@rule block(~s1..., thaw(~a::isvariable), ~s2..., freeze(~a), ~s3...) => if ortho(a, s2)
            block(s1..., s2..., s3...)
        end),

        (@rule block(~s1..., freeze(~a::isvariable), ~s2..., thaw(~a), ~s3...) => if ortho(a, s2)
            block(s1..., s2..., s3...)
        end),
    ]
end

@kwdef mutable struct Simplify
    body
end

struct SimplifyStyle end

(ctx::Stylize{<:AbstractCompiler})(::Simplify) = SimplifyStyle()
combine_style(a::SimplifyStyle, b::SimplifyStyle) = a


function lower(root, ctx::AbstractCompiler,  ::SimplifyStyle)
    root = Rewrite(Prewalk((x) -> if x.kind === virtual visit_simplify(x.val) end))(root)
    root = simplify(root, ctx)
    ctx(root)
end

FinchNotation.finch_leaf(x::Simplify) = virtual(x)

visit_simplify(node) = node
visit_simplify(node::Simplify) = node.body
function visit_simplify(node::FinchNode)
    if node.kind === access && node.tns.kind === virtual
        visit_simplify_access(node, node.tns.val)
    elseif node.kind === virtual
        visit_simplify(node.val)
    else
        nothing
    end
end

function simplify(root, ctx)
    Rewrite(Fixpoint(Chain([
        Prewalk(Fixpoint(Chain(ctx.program_rules))),
        Postwalk(Fixpoint(Chain(ctx.program_rules)))
    ])))(root)
end
