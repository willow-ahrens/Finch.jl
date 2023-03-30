abstract type AbstractAlgebra end
struct DefaultAlgebra<:AbstractAlgebra end

struct Chooser{D} end

(f::Chooser{D})(x) where {D} = x
function (f::Chooser{D})(x, y, tail...) where {D}
    if isequal(x, D)
        return f(y, tail...)
    else
        return x
    end
end
"""
    choose(z)(a, b)

`choose(z)` is a function which returns whichever of `a` or `b` is not
[isequal](@ref) to `z`. If neither are `z`, then return `a`. Useful for getting
the first nonfill value in a sparse array.
```jldoctest setup=:(using Finch)
julia> a = @fiber(sl(e(0.0)), [0, 1.1, 0, 4.4, 0])
SparseList (0.0) [1:5]
├─[2]: 1.1
├─[4]: 4.4

julia> x = Scalar(0.0); @finch @loop i x[] <<choose(0.0)>>= a[i];

julia> x[]
1.1
```
"""
choose(d) = Chooser{d}()

"""
    minby(a, b)

Return the min of `a` or `b`, comparing them by `a[1]` and `b[1]`, and breaking
ties to the left. Useful for implementing argmin operations:
```jldoctest setup=:(using Finch)
julia> a = [7.7, 3.3, 9.9, 3.3, 9.9]; x = Scalar(Inf => 0);

julia> @finch @loop i x[] <<minby>>= a[i] => i;

julia> x[]
3.3 => 2
```
"""
minby(a, b) = a[1] > b[1] ? b : a

"""
    maxby(a, b)

Return the max of `a` or `b`, comparing them by `a[1]` and `b[1]`, and breaking
ties to the left. Useful for implementing argmax operations:
```jldoctest setup=:(using Finch)
julia> a = [7.7, 3.3, 9.9, 3.3, 9.9]; x = Scalar(-Inf => 0);

julia> @finch @loop i x[] <<maxby>>= a[i] => i;

julia> x[]
9.9 => 3
```
"""
maxby(a, b) = a[1] < b[1] ? b : a

isassociative(alg) = (f) -> isassociative(alg, f)
isassociative(alg, f::FinchNode) = f.kind === literal && isassociative(alg, f.val)
"""
    isassociative(algebra, f)

Return true when `f(a..., f(b...), c...) = f(a..., b..., c...)` in `algebra`.
"""
isassociative(::Any, f) = false
isassociative(::AbstractAlgebra, ::typeof(or)) = true
isassociative(::AbstractAlgebra, ::typeof(and)) = true
isassociative(::AbstractAlgebra, ::typeof(coalesce)) = true
isassociative(::AbstractAlgebra, ::typeof(something)) = true
isassociative(::AbstractAlgebra, ::typeof(+)) = true
isassociative(::AbstractAlgebra, ::typeof(*)) = true
isassociative(::AbstractAlgebra, ::typeof(min)) = true
isassociative(::AbstractAlgebra, ::typeof(max)) = true
isassociative(::AbstractAlgebra, ::typeof(minby)) = true
isassociative(::AbstractAlgebra, ::typeof(maxby)) = true
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
isidempotent(::AbstractAlgebra, ::typeof(overwrite)) = true
isidempotent(::AbstractAlgebra, ::typeof(min)) = true
isidempotent(::AbstractAlgebra, ::typeof(max)) = true
isidempotent(::AbstractAlgebra, ::typeof(minby)) = true
isidempotent(::AbstractAlgebra, ::typeof(maxby)) = true
isidempotent(::AbstractAlgebra, ::Chooser) = true

"""
    isidentity(algebra, f, x)

Return true when `f(a..., x, b...) = f(a..., b...)` in `algebra`.
"""
isidentity(alg) = (f, x) -> isidentity(alg, f, x)
isidentity(alg, f::FinchNode, x::FinchNode) = isliteral(f) && isliteral(x) && isidentity(alg, f.val, x.val)
isidentity(::Any, f, x) = false
isidentity(::AbstractAlgebra, ::typeof(or), x) = x === false
isidentity(::AbstractAlgebra, ::typeof(and), x) = x === true
isidentity(::AbstractAlgebra, ::typeof(coalesce), x) = ismissing(x)
isidentity(::AbstractAlgebra, ::typeof(something), x) = !ismissing(x) && isnothing(x)
isidentity(::AbstractAlgebra, ::typeof(+), x) = !ismissing(x) && iszero(x)
isidentity(::AbstractAlgebra, ::typeof(*), x) = !ismissing(x) && isone(x)
isidentity(::AbstractAlgebra, ::typeof(min), x) = !ismissing(x) && isinf(x) && x > 0
isidentity(::AbstractAlgebra, ::typeof(max), x) = !ismissing(x) && isinf(x) && x < 0
isidentity(::AbstractAlgebra, ::typeof(minby), x) = !ismissing(x) && isinf(x[1]) && x > 0
isidentity(::AbstractAlgebra, ::typeof(maxby), x) = !ismissing(x) && isinf(x[1]) && x < 0
isidentity(::AbstractAlgebra, ::Chooser{D}, x) where {D} = isequal(x, D)
isidentity(::AbstractAlgebra, ::InitWriter{D}, x) where {D} = isequal(x, D)

isannihilator(alg) = (f, x) -> isannihilator(alg, f, x)
isannihilator(alg, f::FinchNode, x::FinchNode) = isliteral(f) && isliteral(x) && isannihilator(alg, f.val, x.val)
"""
    isannihilator(algebra, f, x)

Return true when `f(a..., x, b...) = x` in `algebra`.
"""
isannihilator(::Any, f, x) = false
isannihilator(::AbstractAlgebra, ::typeof(+), x) = ismissing(x) || isinf(x)
isannihilator(::AbstractAlgebra, ::typeof(*), x) = ismissing(x) || iszero(x)
isannihilator(::AbstractAlgebra, ::typeof(min), x) = ismissing(x) || isinf(x) && x < 0
isannihilator(::AbstractAlgebra, ::typeof(max), x) = ismissing(x) || isinf(x) && x > 0
isannihilator(::AbstractAlgebra, ::typeof(minby), x) = ismissing(x) || isinf(x[1]) && x < 0
isannihilator(::AbstractAlgebra, ::typeof(maxby), x) = ismissing(x) || isinf(x[1]) && x > 0
isannihilator(::AbstractAlgebra, ::typeof(or), x) = ismissing(x) || x === true
isannihilator(::AbstractAlgebra, ::typeof(and), x) = ismissing(x) || x === false

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

isvar(tns::FinchNode) = tns.kind == variable

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

        (@rule loop(~i, sequence()) => sequence()),
        (@rule chunk(~i, ~a, sequence()) => sequence()),
        (@rule sequence(~a..., sequence(~b...), ~c...) => sequence(a..., b..., c...)),

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

        (@rule assign(access(~a, updater(~m), ~i...), ~f, ~b) => if isidentity(alg, f, b) sequence() end),
        (@rule assign(access(~a, ~m, ~i...), $(literal(missing))) => sequence()),
        (@rule assign(access(~a, ~m, ~i..., $(literal(missing)), ~j...), ~b) => sequence()),
        (@rule call($(literal(coalesce)), ~a..., ~b, ~c...) => if isvalue(b) && !(Missing <: b.type) || isliteral(b) && !ismissing(b.val)
            call(coalesce, a..., b)
        end),
        (@rule call($(literal(something)), ~a..., ~b, ~c...) => if isvalue(b) && !(Nothing <: b.type) || isliteral(b) && b != literal(nothing)
            call(something, a..., b)
        end),

        (@rule call($(literal(identity)), ~a) => a),
        (@rule call($(literal(overwrite)), ~a, ~b) => b),
        (@rule call(~f::isliteral, ~a, ~b) => if f.val isa InitWriter b end),
        (@rule call($(literal(ifelse)), $(literal(true)), ~a, ~b) => a),
        (@rule call($(literal(ifelse)), $(literal(false)), ~a, ~b) => b),
        (@rule call($(literal(ifelse)), ~a, ~b, ~b) => b),
        (@rule $(literal(-0.0)) => literal(0.0)),

        (@rule call(~f, call(~g, ~a, ~b...)) => if isinverse(alg, f, g) && isassociative(alg, g)
            call(g, call(f, a), map(c -> call(f, call(g, c)), b)...)
        end),

        (@rule call(~g, ~a..., ~b, ~c..., call(~f, ~b), ~d...) => if isinverse(alg, f, g) && isassociative(alg, g)
            call(g, a..., c..., d...)
        end),

        (@rule call($(literal(-)), ~a, ~b) => call(+, a, call(-, b))),
        (@rule call($(literal(/)), ~a, ~b) => call(*, a, call(inv, b))),

        (@rule call(~f::isinvolution(alg), call(~f, ~a)) => a),
        (@rule call(~f, ~a..., call(~g, ~b), ~c...) => if isdistributive(alg, g, f)
            call(g, call(f, a..., b, c...))
        end),

        (@rule call($(literal(/)), ~a) => call(inv, a)),

        (@rule sieve($(literal(true)), ~a) => a),
        (@rule sieve($(literal(false)), ~a) => sequence()), #TODO should add back skipvisitor

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

"""
    getrules(alg, ctx::LowerJulia, var, tns)

Return a list of constant propagation rules for a tensor stored in variable var.
"""
getrules(alg, ctx, var, val) = base_rules(alg, ctx, var, val)

getrules(alg, ctx, var) = base_rules(alg, ctx, var)

base_rules(alg, ctx::LowerJulia, var, tns) = []

base_rules(alg, ctx::LowerJulia, tns) = []

getrules(ctx::LowerJulia) = getrules(ctx.algebra, ctx)

simplify(node, ctx) = node
function simplify(node::FinchNode, ctx)
    rules = getrules(ctx.algebra, ctx)
    Prewalk((node) -> begin
        if isvar(node)
            append!(rules, getrules(ctx.algebra, ctx, node, resolve(node, ctx)))
        elseif isvirtual(node)
            append!(rules, getrules(ctx.algebra, ctx, node.val))
        end
        nothing
    end)(node)
    Rewrite(Fixpoint(Prewalk(Chain(rules))))(node)
end

function (ctx::LowerJulia)(root, ::SimplifyStyle)
    global rules
    root = Rewrite(Prewalk((x) -> if x.kind === virtual && x.val isa Simplify x.val.body end))(root)
    root = simplify(root, ctx)
    ctx(root)
end

FinchNotation.finch_leaf(x::Simplify) = virtual(x)
