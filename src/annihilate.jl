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
isassociative(alg, f::FinchNode) = f.kind === literal && isassociative(alg, f.val)
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
iscommutative(alg, f::FinchNode) = f.kind === literal && iscommutative(alg, f.val)
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
isdistributive(alg, f::FinchNode, x::FinchNode) = isliteral(f) && isliteral(x) && isdistributive(alg, f.val, x.val)
"""
    isidempotent(algebra, f)

Return true when `f(a, b) = f(f(a, b), b)` in `algebra`.
"""
isdistributive(::Any, f, g) = false
isdistributive(::AbstractAlgebra, ::typeof(+), ::typeof(*)) = true

isidempotent(alg) = (f) -> isidempotent(alg, f)
isidempotent(alg, f::FinchNode) = f.kind === literal && isidempotent(alg, f.val)
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
isidentity(alg, f::FinchNode, x::FinchNode) = isliteral(f) && isliteral(x) && isidentity(alg, f.val, x.val)
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
isannihilator(alg, f::FinchNode, x::FinchNode) = isliteral(f) && isliteral(x) && isannihilator(alg, f.val, x.val)
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
isinverse(alg, f::FinchNode, g::FinchNode) = isliteral(f) && isliteral(g) && isinverse(alg, f.val, g.val)
"""
    isinverse(algebra, f, g)

Return true when `f(a, g(a))` is the identity under `f` in `algebra`.
"""
isinverse(::Any, f, g) = false
isinverse(::AbstractAlgebra, ::typeof(-), ::typeof(+)) = true
isinverse(::AbstractAlgebra, ::typeof(inv), ::typeof(*)) = true

isinvolution(alg) = (f) -> isinvolution(alg, f)
isinvolution(alg, f::FinchNode) = isliteral(f) && isinvolution(alg, f.val)
"""
    isinvolution(algebra, f)

Return true when `f(f(a)) = a` in `algebra`.
"""
isinvolution(::Any, f) = false
isinvolution(::AbstractAlgebra, ::typeof(-)) = true
isinvolution(::AbstractAlgebra, ::typeof(inv)) = true

struct Fill
    body::FinchNode
    default
    Fill(x, d=nothing) = new(index_leaf(x), d)
end

FinchNotation.isliteral(::Fill) = false
virtual_default(f::Fill) = something(f.default)

isfill(tns) = false
isfill(tns::FinchNode) = tns.kind == virtual && tns.val isa Fill
isvar(tns::FinchNode) = tns.kind == variable

getvars(arr::AbstractArray) = mapreduce(getvars, vcat, arr, init=[])
function getvars(node::FinchNode) 
    if node.kind == variable
        return [node]
    elseif istree(node)
        return mapreduce(getvars, vcat, arguments(node), init=[])
    else
        return []
    end
end

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
        (@rule access(~a::isfill, ~m, ~i...) => a.val.body), #TODO flesh this out

        (@rule call(~f, ~a...) => if isliteral(f) && all(isliteral, a) && length(a) >= 1 literal(getvalue(f)(getvalue.(a)...)) end),

        #TODO default needs to get defined on all writable chunks
        #TODO Does it really though
        #TODO I don't think this is safe to assume if we allow arbitrary updates
        (@rule assign(access(~a, ~m, ~i...), $(literal(right)), ~b) => if virtual_default(resolve(a, ctx)) != nothing && b == literal(something(virtual_default(resolve(a, ctx)))) pass(access(a, m)) end),

        #TODO we probably can just drop modes from pass
        (@rule pass(~a..., access(~b, updater(modify())), ~c...) => pass(a..., c...)),

        (@rule loop(~i, pass(~a...)) => pass(a...)),
        (@rule chunk(~i, ~a, pass(~b...)) => pass(b...)),
        (@rule sequence(~a..., sequence(~b...), ~c...) => sequence(a..., b..., c...)),
        (@rule sequence(~a..., pass(), ~b...) => sequence(a..., b...)),
        (@rule sequence(pass()) => pass()),
        (@rule sequence() => pass()),

        (@rule loop(~i, assign(access(~a, updater(~m), ~j...), ~f::isidempotent(alg), ~b)) => begin
            if i ∉ j && getname(i) ∉ getunbound(b) #=TODO this doesn't work because chunkify temporarily drops indicies so we add =# && isliteral(b)
                assign(access(a, updater(m), j...), f, b)
            end
        end),

        (@rule sequence(~s1..., declare(~a), ~s2..., assign(access(~a, ~m), ~f, ~b::isliteral), ~s3...) =>
            if !(a in getvars(s2)) && f != literal(right)
                sequence(s1..., s2..., declare(a), assign(access(a, m), right, call(f, virtual_default(resolve(a, ctx)), b)), s3...)
            end
        ),
        
        (@rule sequence(~s1..., assign(access(~a::isvar, ~m), $(literal(right)), ~b::isliteral), ~s2...,
            assign(access(~a, ~m), ~f, ~c), ~s3...) =>
            if !(a in getvars(s2))
                sequence(s1..., s2..., assign(access(a, m), right, call(f, b, c)), s3...)
            end
        ),
        (@rule sequence(~s1..., declare(~a), ~s2..., assign(access(~a, ~m), $(literal(right)), ~b::isliteral), ~s3..., freeze(~a), ~s4...) =>
            if !(a in getvars([s2, s3]))
                s4 = Postwalk(@rule access(a, reader()) => b)(sequence(s4...))
                if s4 !== nothing
                    sequence(s1..., declare(a), s2..., assign(access(a, m), right, b), s3..., freeze(a), s4)
                end
            end
        ),
        (@rule sequence(~s1..., declare(~a), ~s2..., freeze(~a), ~s3...) =>
            if !(a in getvars(s2))
                s3 = Postwalk(@rule access(a, reader(), i...) => virtual_default(resolve(a, ctx)))(sequence(s3...))
                if s3 !== nothing
                    sequence(s1..., declare(a), s2..., freeze(a), s3)
                end
            end
        ),
        (@rule loop(~i..., sequence(~s1..., declare(~a), ~s2..., freeze(~a), ~s3...)) =>
            if !(a in getvars(s3))
                s2 = Rewrite(Postwalk(@rule assign(access(a, updater(~a), ~j...), ~f, ~b) => sequence()))(sequence(s2...))
                loop(i..., sequence(s1..., s2, s3...))
            end
        ),

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
            call(g, call(f, a), map(c -> call(f, call(g, c)), b)...)
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
        (@rule chunk(~i, ~a, assign(access(~b, updater(~m), ~j...), $(literal(+)), ~d)) => begin
            if i ∉ j && getname(i) ∉ getunbound(d)
                assign(access(b, updater(m), j...), +, call(*, extent(a), d))
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
    root = simplify(root, ctx)
    ctx(root)
end

FinchNotation.isliteral(::Simplify) = false