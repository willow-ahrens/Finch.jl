rules = []
add_rules!(new_rules) = union!(rules, new_rules)

isassociative(f) = false
isassociative(::typeof(right)) = true
isassociative(::typeof(or)) = true
isassociative(::typeof(and)) = true
isassociative(::typeof(coalesce)) = true
isassociative(::typeof(+)) = true
isassociative(::typeof(*)) = true
isassociative(::typeof(min)) = true
isassociative(::typeof(max)) = true

iscommutative(f) = false
iscommutative(::typeof(or)) = true
iscommutative(::typeof(and)) = true
iscommutative(::typeof(+)) = true
iscommutative(::typeof(*)) = true
iscommutative(::typeof(min)) = true
iscommutative(::typeof(max)) = true

isdistributive(f, g) = false
isdistributive(::typeof(+), ::typeof(*)) = true

isidempotent(f) = false
isidempotent(::typeof(right)) = true
isidempotent(::typeof(min)) = true
isidempotent(::typeof(max)) = true

isidentity(f, x) = false
isidentity(::typeof(or), x) = x == false
isidentity(::typeof(and), x) = x == true
isidentity(::typeof(coalesce), x) = ismissing(x)
isidentity(::typeof(+), x) = iszero(x)
isidentity(::typeof(*), x) = isone(x)
isidentity(::typeof(min), x) = isinf(x) && x > 0
isidentity(::typeof(max), x) = isinf(x) && x < 0

isannihilator(f, x) = false
isannihilator(::typeof(+), x) = isinf(x)
isannihilator(::typeof(*), x) = iszero(x)
isannihilator(::typeof(min), x) = isinf(x) && x < 0
isannihilator(::typeof(max), x) = isinf(x) && x > 0
isannihilator(::typeof(or), x) = x == true
isannihilator(::typeof(and), x) = x == false

isinverse(f, g) = false
isinverse(::typeof(+), ::typeof(-)) = true
isinverse(::typeof(*), ::typeof(inv)) = true

getinverse(f) = nothing
getinverse(::typeof(-)) = +
getinverse(::typeof(/)) = *
getinverse(::typeof(inv)) = *

isassociative(f::CINNode) = f.kind === literal && isassociative(f.val)
iscommutative(f::CINNode) = f.kind === literal && iscommutative(f.val)
isidempotent(f::CINNode) = f.kind === literal && isidempotent(f.val)
isdistributive(f::CINNode, x::CINNode) = isliteral(f) && isliteral(x) && isdistributive(f.val, x.val)
isabelian(f) = isassociative(f) && iscommutative(f)
isidentity(f::CINNode, x::CINNode) = isliteral(f) && isliteral(x) && isidentity(f.val, x.val)
isannihilator(f::CINNode, x::CINNode) = isliteral(f) && isliteral(x) && isannihilator(f.val, x.val)

isinverse(f::CINNode, x::CINNode) = isliteral(f) && isliteral(x) && isinverse(f.val, x.val)

hasinverse(f::CINNode) = isliteral(f) && (getinverse(f.val) !== nothing)
getinverse(f::CINNode) = something(getinverse(f.val))

isinplace(f::CINNode) = f.inplace == literal(false)

add_rules!([
    (@rule call(~f, ~a...) => if isliteral(f) && all(isliteral, a) && length(a) >= 1 literal(getvalue(f)(getvalue.(a)...)) end),

    #TODO default needs to get defined on all writable chunks
    (@rule assign(access(~a, ~m, ~i...), $(literal(right)), ~b) => if b == literal(default(a)) pass(access(a, m)) end),

    #TODO we probably can just drop modes from pass
    (@rule pass(~a..., access(~b, updater($(literal(true)))), ~c...) => pass(a..., c...)),


    (@rule loop(~i, pass(~a...)) => pass(a...)),
    (@rule chunk(~i, ~a, pass(~b...)) => pass(b...)),
    (@rule with(pass(~a...), ~b) => pass(a...)),
    (@rule with(~a, pass()) => a),
    (@rule multi(~a..., pass(~b...), pass(~c...)) => multi(a..., pass(b..., c...))),
    (@rule multi(pass(~a...)) => pass(a...)),
    (@rule multi() => pass()),

    (@rule loop(~i, assign(access(~a, updater(~m), ~j...), ~f::isidempotent, ~b)) => begin
        if i ∉ j && getname(i) ∉ getunbound(b) #=TODO this doesn't work because chunkify temporarily drops indicies so we add =# && isliteral(b)
            assign(access(a, updater(m), j...), f, b)
        end
    end),
    (@rule loop(~i, multi(~a..., assign(access(~b, updater(~m), ~j...), ~c), ~f::isidempotent, ~d...)) => begin
        if i ∉ j && getname(i) ∉ getunbound(c) #=TODO this doesn't work because chunkify temporarily drops indicies so we add =# && isliteral(c)
            multi(assign(access(b, updater(m), j...), c), f, loop(i, multi(a..., d...)))
        end
    end),

    (@rule with(~a, assign(access(~b, updater($(literal(false)))), ~f, ~c::isliteral)) => begin
        Rewrite(Postwalk(@rule access(~x, reader()) => if getname(x) === getname(b) call(f, default(b), c) end))(a)
    end),
    (@rule with(~a, multi(~b..., assign(access(~c, updater($(literal(false)))), ~f, ~d::isliteral), ~e...)) => begin
        with(Rewrite(Postwalk(@rule access(~x, reader()) => if getname(x) === getname(c) call(f, default(c), d) end))(a), multi(b..., e...))
    end),
    (@rule with(~a, pass(~b..., access(~c, ~m::isinplace), ~d...)) => begin
        with(Rewrite(Postwalk(@rule access(~x, reader(), ~i...) => if getname(x) === getname(c) default(c) end))(a), pass(b..., d...))
    end),
    (@rule with(~a, multi(~b..., pass(~c..., access(~d, ~m::isinplace), ~e...), ~f...)) => begin
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
    (@rule call(~f::isassociative, ~a..., call(~f, ~b...), ~c...) => call(f, a..., b..., c...)),
    (@rule call(~f::iscommutative, ~a...) => if !(issorted(a, by = Lexicography))
        call(f, sort(a, by = Lexicography)...)
    end),
    (@rule call(~f::isidempotent, ~a...) => if !allunique(a)
        call(f, unique(a)...)
    end),
    (@rule call(~f::isassociative, ~a..., ~b::isliteral, ~c::isliteral, ~d...) => call(f, a..., f.val(b.val, c.val), d...)),
    (@rule call(~f::isabelian, ~a..., ~b::isliteral, ~c..., ~d::isliteral, ~e...) => call(f, a..., f.val(b.val, d.val), c..., e...)),
    (@rule call(~f, ~a..., ~b, ~c...) => if isannihilator(f, b) b end),
    (@rule call(~f, ~a..., ~b, ~c, ~d...) => if isidentity(f, b)
        call(f, a..., c, d...)
    end),
    (@rule call(~f, ~a..., ~b, ~c, ~d...) => if isidentity(f, c)
        call(f, a..., b, d...)
    end),
    (@rule call(~f, ~a) => if isassociative(f) a end), #TODO

    (@rule assign(access(~a, updater(~m), ~i...), ~f, ~b) => if isidentity(f, b) pass(access(a, updater(m))) end),
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


    (@rule call(~f::hasinverse, call(~g::isliteral, ~a, ~b...)) => if g.val == getinverse(f) && isassociative(g)
        call(g, call(f, a), call(f, call(g, b...)))
    end),

    (@rule call(~f::hasinverse, ~a, ~b) => call(getinverse(f), a, call(f, b))),
    (@rule call(~f::hasinverse, call(~f, ~a)) => a),
    (@rule call(~f::isliteral, ~a..., call(~g::hasinverse, ~b), ~c...) => if isdistributive(getinverse(g), f.val)
        call(g, call(f, a..., b, c...))
    end),

    (@rule call($(literal(/)), ~a) => call(inv, a)),

    (@rule sieve($(literal(true)), ~a) => a),
    (@rule sieve($(literal(false)), ~a) => pass(getresults(a)...)),

    (@rule chunk(~i, ~a, assign(access(~b, updater(~m), ~j...), ~f::isidempotent, ~c)) => begin
        if i ∉ j && getname(i) ∉ getunbound(c)
            assign(access(b, updater(m), j...), f, c)
        end
    end),
    (@rule chunk(~i, ~a, multi(~b..., assign(access(~c, updater(~m), ~j...), ~d), ~f::isidempotent, ~e...)) => begin
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
])

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

function simplify(node)
    global rules
    Rewrite(Fixpoint(Prewalk(Chain(rules))))(node)
end

function (ctx::LowerJulia)(root, ::SimplifyStyle)
    global rules
    root = SimplifyVisitor(ctx)(root)
    root = simplify(root)
    ctx(root)
end


IndexNotation.isliteral(::Simplify) =  false

struct Lexicography
    arg
end

function Base.isless(a::Lexicography, b::Lexicography)
    (a, b) = a.arg, b.arg
    #@assert which(priority, Tuple{typeof(a)}) == which(priority, Tuple{typeof(b)}) || priority(a) != priority(b)
    if a != b
        a_key = (priority(a), comparators(a)...)
        b_key = (priority(b), comparators(b)...)
        @assert a_key < b_key || b_key < a_key "a = $a b = $b a_key = $a_key b_key = $b_key"
        return a_key < b_key
    end
    return false
end

function Base.:(==)(a::Lexicography, b::Lexicography)
    (a, b) = a.arg, b.arg
    #@assert which(priority, Tuple{typeof(a)}) == which(priority, Tuple{typeof(b)}) || priority(a) != priority(b)
    a_key = (priority(a), comparators(a)...)
    b_key = (priority(b), comparators(b)...)
    return a_key == b_key
end

#=
priority(::Type) = (0, 5)
comparators(x::Type) = (string(x),)

priority(::Missing) = (0, 4)
comparators(::Missing) = (1,)

priority(::Number) = (1, 1)
comparators(x::Number) = (x, sizeof(x), typeof(x))

priority(::Function) = (1, 2)
comparators(x::Function) = (string(x),)

priority(::Symbol) = (2, 0)
comparators(x::Symbol) = (x,)

priority(::Expr) = (2, 1)
comparators(x::Expr) = (x.head, map(Lexicography, x.args)...)

#priority(::Workspace) = (3,3)
#comparators(x::Workspace) = (x.n,)

#TODO this works for now, but reconsider this later
priority(node::IndexNode) = (3, 4)
function comparators(node::IndexNode)
    if node.kind === value
        return (node.kind, Lexicography(node.val), Lexicography(node.type))
    elseif node.kind === literal
        return (node.kind, Lexicography(node.val))
    elseif node.kind === virtual
        return (node.kind, Lexicography(node.val))
    elseif node.kind === index
        return (node.kind, Lexicography(node.val))
    elseif istree(node)
        return (node.kind, map(Lexicography, node.children))
    else
        error("unimplemented")
    end
end
=#
#TODO these are nice defaults if we want to allow nondeterminism
priority(::Any) = (Inf,)
comparators(x::Any) = hash(x)