abstract type AbstractAlgebra end
struct DefaultAlgebra<:AbstractAlgebra end

struct Chooser{D} end

(f::Chooser{D})(x) where {D} = x
function (f::Chooser{D})(x, y, tail...) where {D}
    if x == D
        return f(y, tail...)
    else
        return x
    end
end

choose(d) = Chooser{d}()

isassociative(alg) = (f) -> isassociative(alg, f)
isassociative(alg, f::IndexNode) = f.kind === literal && isassociative(alg, f.val)
"""
    isassociative(algebra, f)

Return true when `f(a..., f(b...), c...) = f(a..., b..., c...)` in `algebra`.
"""
isassociative(::Any, f) = false
isassociative(::AbstractAlgebra, ::typeof(right)) = true
isassociative(::AbstractAlgebra, ::typeof(or)) = true
isassociative(::AbstractAlgebra, ::typeof(and)) = true
isassociative(::AbstractAlgebra, ::typeof(coalesce)) = true
isassociative(::AbstractAlgebra, ::typeof(+)) = true
isassociative(::AbstractAlgebra, ::typeof(*)) = true
isassociative(::AbstractAlgebra, ::typeof(min)) = true
isassociative(::AbstractAlgebra, ::typeof(max)) = true
isassociative(::AbstractAlgebra, ::Chooser) = true

iscommutative(alg) = (f) -> iscommutative(alg, f)
iscommutative(alg, f::IndexNode) = f.kind === literal && iscommutative(alg, f.val)
"""
    iscommutative(algebra, f)

Return true when for all permutations p, `f(a...) = f(a[p]...)` in `algebra`.
"""
iscommutative(::Any, f) = false
iscommutative(::AbstractAlgebra, ::typeof(or)) = true
iscommutative(::AbstractAlgebra, ::typeof(and)) = true
iscommutative(::AbstractAlgebra, ::typeof(+)) = true
iscommutative(::AbstractAlgebra, ::typeof(*)) = true
iscommutative(::AbstractAlgebra, ::typeof(min)) = true
iscommutative(::AbstractAlgebra, ::typeof(max)) = true

isabelian(alg) = (f) -> isabelian(alg, f)
isabelian(alg, f) = isassociative(alg, f) && iscommutative(alg, f)

isdistributive(alg) = (f, g) -> isdistributive(alg, f, g)
isdistributive(alg, f::IndexNode, x::IndexNode) = isliteral(f) && isliteral(x) && isdistributive(alg, f.val, x.val)
"""
    isidempotent(algebra, f)

Return true when `f(a, b) = f(f(a, b), b)` in `algebra`.
"""
isdistributive(::Any, f, g) = false
isdistributive(::AbstractAlgebra, ::typeof(+), ::typeof(*)) = true

isidempotent(alg) = (f) -> isidempotent(alg, f)
isidempotent(alg, f::IndexNode) = f.kind === literal && isidempotent(alg, f.val)
"""
    isidempotent(algebra, f)

Return true when `f(a, b) = f(f(a, b), b)` in `algebra`.
"""
isidempotent(::Any, f) = false
isidempotent(::AbstractAlgebra, ::typeof(right)) = true
isidempotent(::AbstractAlgebra, ::typeof(min)) = true
isidempotent(::AbstractAlgebra, ::typeof(max)) = true
isidempotent(::AbstractAlgebra, ::Chooser) = true

"""
    isidentity(algebra, f, x)

Return true when `f(a..., x, b...) = f(a..., b...)` in `algebra`.
"""
isidentity(alg) = (f, x) -> isidentity(alg, f, x)
isidentity(alg, f::IndexNode, x::IndexNode) = isliteral(f) && isliteral(x) && isidentity(alg, f.val, x.val)
isidentity(::Any, f, x) = false
isidentity(::AbstractAlgebra, ::typeof(or), x) = x == false
isidentity(::AbstractAlgebra, ::typeof(and), x) = x == true
isidentity(::AbstractAlgebra, ::typeof(coalesce), x) = ismissing(x)
isidentity(::AbstractAlgebra, ::typeof(+), x) = iszero(x)
isidentity(::AbstractAlgebra, ::typeof(*), x) = isone(x)
isidentity(::AbstractAlgebra, ::typeof(min), x) = isinf(x) && x > 0
isidentity(::AbstractAlgebra, ::typeof(max), x) = isinf(x) && x < 0
isidentity(::AbstractAlgebra, ::Chooser{D}, x) where {D} = x == D

isannihilator(alg) = (f, x) -> isannihilator(alg, f, x)
isannihilator(alg, f::IndexNode, x::IndexNode) = isliteral(f) && isliteral(x) && isannihilator(alg, f.val, x.val)
"""
    isannihilator(algebra, f, x)

Return true when `f(a..., x, b...) = x` in `algebra`.
"""
isannihilator(::Any, f, x) = false
isannihilator(::AbstractAlgebra, ::typeof(+), x) = isinf(x)
isannihilator(::AbstractAlgebra, ::typeof(*), x) = iszero(x)
isannihilator(::AbstractAlgebra, ::typeof(min), x) = isinf(x) && x < 0
isannihilator(::AbstractAlgebra, ::typeof(max), x) = isinf(x) && x > 0
isannihilator(::AbstractAlgebra, ::typeof(or), x) = x == true
isannihilator(::AbstractAlgebra, ::typeof(and), x) = x == false

isinverse(alg) = (f, g) -> isinverse(alg, f, g)
isinverse(alg, f::IndexNode, g::IndexNode) = isliteral(f) && isliteral(g) && isinverse(alg, f.val, g.val)
"""
    isinverse(algebra, f, g)

Return true when `f(a, g(a))` is the identity under `f` in `algebra`.
"""
isinverse(::Any, f, g) = false
isinverse(::AbstractAlgebra, ::typeof(-), ::typeof(+)) = true
isinverse(::AbstractAlgebra, ::typeof(inv), ::typeof(*)) = true

isinvolution(alg) = (f) -> isinvolution(alg, f)
isinvolution(alg, f::IndexNode) = isliteral(f) && isinvolution(alg, f.val)
"""
    isinvolution(algebra, f)

Return true when `f(f(a)) = a` in `algebra`.
"""
isinvolution(::Any, f) = false
isinvolution(::AbstractAlgebra, ::typeof(-)) = true
isinvolution(::AbstractAlgebra, ::typeof(inv)) = true

"""
    base_rules(alg, ctx)

The basic rule set for Finch, uses the algebra to check properties of functions
like associativity, commutativity, etc. Also assumes the context has a static
hash names `shash`. This rule set simplifies, normalizes, and propagates
constants, and is the basis for how Finch understands sparsity.
"""
function base_rules(alg, ctx)
    shash = ctx.shash
    return [
        (@rule call(~f, ~a...) => if isliteral(f) && all(isliteral, a) && length(a) >= 1 literal(getvalue(f)(getvalue.(a)...)) end),

        #TODO default needs to get defined on all writable chunks
        (@rule assign(access(~a, ~m, ~i...), $(literal(right)), ~b) => if b == literal(default(a)) pass(access(a, m)) end),

        #TODO we probably can just drop modes from pass
        (@rule pass(~a..., access(~b, updater(modify())), ~c...) => pass(a..., c...)),


        (@rule loop(~i, pass(~a...)) => pass(a...)),
        (@rule chunk(~i, ~a, pass(~b...)) => pass(b...)),
        (@rule with(pass(~a...), ~b) => pass(a...)),
        (@rule with(~a, pass()) => a),
        (@rule multi(~a..., pass(~b...), pass(~c...)) => multi(a..., pass(b..., c...))),
        (@rule multi(pass(~a...)) => pass(a...)),
        (@rule multi() => pass()),

        (@rule loop(~i, assign(access(~a, updater(~m), ~j...), ~f::isidempotent(alg), ~b)) => begin
            if i ∉ j && getname(i) ∉ getunbound(b) #=TODO this doesn't work because chunkify temporarily drops indicies so we add =# && isliteral(b)
                assign(access(a, updater(m), j...), f, b)
            end
        end),
        (@rule loop(~i, multi(~a..., assign(access(~b, updater(~m), ~j...), ~c), ~f::isidempotent(alg), ~d...)) => begin
            if i ∉ j && getname(i) ∉ getunbound(c) #=TODO this doesn't work because chunkify temporarily drops indicies so we add =# && isliteral(c)
                multi(assign(access(b, updater(m), j...), c), f, loop(i, multi(a..., d...)))
            end
        end),

        (@rule with(~a, assign(access(~b, updater(create())), ~f, ~c::isliteral)) => begin
            Rewrite(Postwalk(@rule access(~x, reader()) => if getname(x) === getname(b) call(f, default(b), c) end))(a)
        end),
        (@rule with(~a, multi(~b..., assign(access(~c, updater(create())), ~f, ~d::isliteral), ~e...)) => begin
            with(Rewrite(Postwalk(@rule access(~x, reader()) => if getname(x) === getname(c) call(f, default(c), d) end))(a), multi(b..., e...))
        end),
        (@rule with(~a, pass(~b..., access(~c, updater(create())), ~d...)) => begin
            with(Rewrite(Postwalk(@rule access(~x, reader(), ~i...) => if getname(x) === getname(c) default(c) end))(a), pass(b..., d...))
        end),
        (@rule with(~a, multi(~b..., pass(~c..., access(~d, updater(create())), ~e...), ~f...)) => begin
            with(Rewrite(Postwalk(@rule access(~x, reader(), ~i...) => if getname(x) === getname(d) default(d) end))(a), multi(b..., pass(c..., e...), f...))
        end),

        (@rule call($(literal(>=)), call($(literal(max)), ~a...), ~b) => call(or, map(x -> call(x >= b), a)...)),
        (@rule call($(literal(>)), call($(literal(max)), ~a...), ~b) => call(or, map(x -> call(x > b), a)...)),
        (@rule call($(literal(<=)), call($(literal(max)), ~a...), ~b) => call(and, map(x -> call(x <= b), a)...)),
        (@rule call($(literal(<)), call($(literal(max)), ~a...), ~b) => call(and, map(x -> call(x < b), a)...)),
        (@rule call($(literal(>=)), call($(literal(min)), ~a...), ~b) => call(and, map(x -> call(x >= b), a)...)),
        (@rule call($(literal(>)), call($(literal(min)), ~a...), ~b) => call(and, map(x -> call(x > b), a)...)),
        (@rule call($(literal(<=)), call($(literal(min)), ~a...), ~b) => call(or, map(x -> call(x <= b), a)...)),
        (@rule call($(literal(<)), call($(literal(min)), ~a...), ~b) => call(or, map(x -> call(x < b), a)...)),
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

        (@rule assign(access(~a, updater(~m), ~i...), ~f, ~b) => if isidentity(alg, f, b) pass(access(a, updater(m))) end),
        (@rule assign(access(~a, ~m, ~i...), $(literal(missing))) => pass(access(a, m))),
        (@rule assign(access(~a, ~m, ~i..., $(literal(missing)), ~j...), ~b) => pass(access(a, m))),
        (@rule call($(literal(coalesce)), ~a..., ~b, ~c...) => if isvalue(b) && !(Missing <: b.type) || isliteral(b) && !ismissing(b.val)
            call(coalesce, a..., b)
        end),

        (@rule call($(literal(right)), ~a..., ~b, ~c) => c),
        (@rule call($(literal(ifelse)), $(literal(true)), ~a, ~b) => a),
        (@rule call($(literal(ifelse)), $(literal(false)), ~a, ~b) => b),
        (@rule call($(literal(ifelse)), ~a, ~b, ~b) => b),
        (@rule $(literal(-0.0)) => literal(0.0)),


        (@rule call(~f, call(~g, ~a, ~b...)) => if isinverse(alg, f, g) && isassociative(alg, g)
            call(g, call(f, a), call(f, call(g, b...)))
        end),

        (@rule call($(literal(-)), ~a, ~b) => call(+, a, call(-, b))),
        (@rule call($(literal(/)), ~a, ~b) => call(*, a, call(inv, b))),

        (@rule call(~f::isinvolution(alg), call(~f, ~a)) => a),
        (@rule call(~f, ~a..., call(~g, ~b), ~c...) => if isdistributive(alg, g, f)
            call(g, call(f, a..., b, c...))
        end),

        (@rule call($(literal(/)), ~a) => call(inv, a)),

        (@rule sieve($(literal(true)), ~a) => a),
        (@rule sieve($(literal(false)), ~a) => pass(getresults(a)...)),

        (@rule chunk(~i, ~a, assign(access(~b, updater(~m), ~j...), ~f::isidempotent(alg), ~c)) => begin
            if i ∉ j && getname(i) ∉ getunbound(c)
                assign(access(b, updater(m), j...), f, c)
            end
        end),
        (@rule chunk(~i, ~a, multi(~b..., assign(access(~c, updater(~m), ~j...), ~d), ~f::isidempotent(alg), ~e...)) => begin
            if i ∉ j && getname(i) ∉ getunbound(d)
                multi(assign(access(b, updater(m), j...), f, d), chunk(i, a, multi(b..., e...)))
            end
        end),

        (@rule chunk(~i, ~a, assign(access(~b, updater(~m), ~j...), $(literal(+)), ~d)) => begin
            if i ∉ j && getname(i) ∉ getunbound(d)
                assign(access(b, updater(m), j...), +, call(*, extent(a), d))
            end
        end),
        (@rule chunk(~i, ~a, multi(~b..., assign(access(~c, updater(~m), ~j...), $(literal(+)), ~d), ~e...)) => begin
            if i ∉ j && getname(i) ∉ getunbound(d)
                multi(assign(access(c, updater(m), j...), +, call(*, extent(a), d)),
                    chunk(i, a, multi(b..., e...)))
            end
        end),
    ]
end

@kwdef mutable struct Simplify
    body
end

struct SimplifyStyle end

(ctx::Stylize{LowerJulia})(::Simplify) = SimplifyStyle()
combine_style(a::DefaultStyle, b::SimplifyStyle) = SimplifyStyle()
combine_style(a::ThunkStyle, b::SimplifyStyle) = ThunkStyle()
combine_style(a::SimplifyStyle, b::SimplifyStyle) = SimplifyStyle()

@kwdef struct SimplifyVisitor
    ctx
end

function (ctx::SimplifyVisitor)(node)
    if istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end

function (ctx::SimplifyVisitor)(node::IndexNode)
    if node.kind === virtual
        convert(IndexNode, ctx(node.val))
    elseif istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end

(ctx::SimplifyVisitor)(node::Simplify) = node.body

"""
    getrules(alg, ctx)

Return an array of rules to use for annihilation/simplification during 
compilation. One can dispatch on the `alg` trait to specialize the rule set for
different algebras.
"""
getrules(alg, ctx) = base_rules(alg, ctx)

getrules(ctx::LowerJulia) = getrules(ctx.algebra, ctx)

function simplify(node, ctx)
    Rewrite(Fixpoint(Prewalk(Chain(getrules(ctx)))))(node)
end

function (ctx::LowerJulia)(root, ::SimplifyStyle)
    global rules
    root = SimplifyVisitor(ctx)(root)
    root = simplify(root, ctx)
    ctx(root)
end

IndexNotation.isliteral(::Simplify) = false