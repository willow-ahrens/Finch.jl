#using Metatheory
using RewriteTools.Rewriters
using RewriteTools
using AbstractTrees

using Finch

struct Epsilon{T}
    val::T
end

for op in [:+]
    @eval Base.$op(a::Epsilon, b) = Epsilon($op(a.val, b))
    @eval Base.$op(a::Epsilon, b::Epsilon) = Epsilon($op(a.val, b.val))
    @eval Base.$op(a, b::Epsilon) = Epsilon($op(a, b.val))
end

Base.isless(a::Epsilon, b) = a.val < b
Base.isless(a::Epsilon, b::Epsilon) = error("undef")
Base.isless(a, b::Epsilon) = a <= b.val

Base.:<(a::Epsilon, b) = a.val < b
Base.:<(a::Epsilon, b::Epsilon) = error("undef")
Base.:<(a, b::Epsilon) = a <= b.val

Base.:<=(a::Epsilon, b) = a.val < b
Base.:<=(a::Epsilon, b::Epsilon) = error("undef")
Base.:<=(a, b::Epsilon) = a <= b.val

for op in [:isinf]
    @eval Base.$op(a::Epsilon) = $op(a.val)
end

#=
t = @theory a b c d e f x y z begin
    min(x, min(y, z)) == min(min(x, y), z)
    max(x, max(y, z)) == max(max(x, y), z)
    max(x, y) == max(y, x)
    min(x, y) == min(y, x)
    max(a, min(b, max(a, c))) --> max(a, min(b, c))
    min(a, max(b, min(a, c))) --> min(a, max(b, c))
    max(a, min(b, a)) --> a 
    min(a, max(b, a)) --> a
    equiv(a, b) --> a
    equiv(a, b) --> b
    min(a, b) <= a --> true
    a >= min(a, b) --> true
    max(a, b) >= a --> true
    a <= max(a, b) --> true
    (a == a) --> true
    +(x, +(y, z)) == +(+(x, y), z)
    +(x, y) == +(y, x)
    +(x, -(x)) => 0
    -(x, y) --> +(x, -y)
    +(x, 0) => x
    a::Number + b::Number => a + b
    -(a::Number) => -a
end

function query(root::FinchNode, ctx)
    expand(node) = if isvalue(node)
        get(ctx.bindings, node, nothing)
    end
    root = Rewrite(Prewalk(expand))(root)
    root = Rewrite(Prewalk(Fixpoint(Chain([
        RewriteTools.@rule(call(+, ~a, ~b, ~c, ~d...) => call(+, a, call(+, b, c, d...))),
        RewriteTools.@rule(call(min, ~a, ~b, ~c, ~d...) => call(min, a, call(min, b, c, d...))),
        RewriteTools.@rule(call(max, ~a, ~b, ~c, ~d...) => call(max, a, call(min, b, c, d...))),
        RewriteTools.@rule(cached(~a, ~b::isliteral) => b.val),
    ]))))(root)
    names = Dict()
    function rename(node::FinchNode)
        if node.kind == virtual
            get!(names, node, value(Symbol(:virtual_, length(names) + 1)))
        elseif node.kind == index
            value(node.name)
        elseif isvalue(node) && !(node.val isa Symbol)
            get!(names, node, value(Symbol(:value_, length(names) + 1)))
        end
    end
    root = Rewrite(Postwalk(rename))(root)
    niters = treebreadth(root)
    Metatheory.resetbuffers!(Metatheory.DEFAULT_BUFFER_SIZE)
    display(Finch.unresolve(ctx(root)))
    res = areequal(t, ctx(root), true, params = SaturationParams(timeout=treebreadth(root) + length(t)))
    println(res)
    return coalesce(res, false)
end
=#

function interval_rules(alg, shash)
    return [
        (@rule call(~f::isliteral, ~a::isliteral, ~b::(All(isliteral))...) => literal(getval(f)(getval(a), getval.(b)...))),

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

        (@rule(cached(~a, ~b::isliteral) => b.val)),
        (@rule cached(cached(~a, ~b), ~c) => cached(a, c)),

        (@rule call(==, ~a, ~a) => literal(true)),
        (@rule call(>=, ~a, ~b) => call(==, call(max, a, b), a)),
        (@rule call(>, ~a, ~b) => call(==, call(max, a, call(+, b, Epsilon(0))), a)),
        (@rule call(<=, ~a, ~b) => call(==, a, call(max, a, b))),
        (@rule call(<, ~a, ~b) => call(==, a, call(max, call(+, a, Epsilon(0)), b))),

        (@rule call(identity, ~a) => a),
        (@rule call(overwrite, ~a, ~b) => b),
        (@rule call(ifelse, true, ~a, ~b) => a),
        (@rule call(ifelse, false, ~a, ~b) => b),
        (@rule call(ifelse, ~a, ~b, ~b) => b),
        (@rule $(literal(-0.0)) => literal(0.0)),

        (@rule call(-, ~a, ~b) => call(+, a, call(-, b))),
        (@rule call(-, call(+, ~a...)) =>
            call(+, map(x -> call(-, x), a)...)),
        (@rule call(+, ~a..., ~b, ~c..., call(-, ~b), ~d...) =>
            call(+, 0, a..., c..., d...)),
        (@rule call(+, ~a..., call(-, ~b), ~c..., ~b, ~d...) =>
            call(+, 0, a..., c..., d...)),

        (@rule call(~f, ~a..., call(equiv, ~b...), ~c...) => call(equiv, map(x -> call(f, a..., x, c...), b)...)),
        (@rule call(+, ~a..., call(min, ~b...), ~c...) => call(min, map(x -> call(+, a..., x, c...), b)...)),
        (@rule call(+, ~a..., call(max, ~b...), ~c...) => call(max, map(x -> call(+, a..., x, c...), b)...)),

        (@rule call(max, ~a1..., call(min, ~a2..., call(max, ~a3...), ~a4...), ~a5...) => if !(isdisjoint(a3, a1) && isdisjoint(a3, a5))
            call(max, a1..., call(min, a2..., call(max, setdiff(setdiff(a3, a1), a5)...), a4...), a5...)
        end),
        (@rule call(min, ~a1..., call(max, ~a2..., call(min, ~a3...), ~a4...), ~a5...) => if !(isdisjoint(a3, a1) && isdisjoint(a3, a5))
            call(min, a1..., call(max, a2..., call(min, setdiff(setdiff(a3, a1), a5)...), a4...), a5...)
        end),

        (@rule call(max, ~a1..., call(min, ~a2...), ~a3...) => if !(isdisjoint(a1, a2) && isdisjoint(a2, a3))
            call(max, a1..., a3...)
        end),
        (@rule call(min, ~a1..., call(max, ~a2...), ~a3...) => if !(isdisjoint(a1, a2) && isdisjoint(a2, a3))
            call(min, a1..., a3...)
        end),

        (@rule call(max, ~a1..., call(min, ~a2...), ~a3..., call(min, ~a4...), ~a5...) => if !(isdisjoint(a2, a4))
            call(max, a1..., call(min, union(a2, a4)..., call(max, call(min, setdiff(a2, a4)...), call(min, setdiff(a4, a2)...)), a3..., a5...))
        end),

        (@rule call(min, ~a1..., call(max, ~a2...), ~a3..., call(max, ~a4...), ~a5...) => if !(isdisjoint(a2, a4))
            call(min, a1..., call(max, union(a2, a4)..., call(min, call(max, setdiff(a2, a4)...), call(max, setdiff(a4, a2)...)), a3..., a5...))
        end),

        (@rule call(min, ~a1..., call(max), ~a2...) => call(min, a1..., a2...)),
        (@rule call(max, ~a1..., call(min), ~a2...) => call(min, a1..., a2...)),

        (@rule call(~f::isinvolution(alg), call(~f, ~a)) => a),

        #(@rule call(~f, ~a..., call(~g, ~b), ~c...) => if isdistributive(alg, g, f)
        #    call(g, call(f, a..., b, c...))
        #end),
    ]
end

function query(root0::FinchNode, ctx)
    root = Rewrite(Prewalk(Fixpoint(Chain([
        @rule(cached(~a, ~b::isliteral) => b.val),
    ]))))(root0)
    names = Dict()
    function rename(node::FinchNode)
        if node.kind == virtual
            get!(names, node, value(Symbol(:virtual_, length(names) + 1)))
        elseif node.kind == index
            value(node.name)
        elseif isvalue(node) && !(node.val isa Symbol)
            get!(names, node, value(Symbol(:value_, length(names) + 1)))
        end
    end
    root = Rewrite(Postwalk(rename))(root)
    res = Fixpoint(Prewalk(Fixpoint(Chain(interval_rules(ctx.algebra, ctx.shash)))))(root)
    if isliteral(res) && res.val
        #display(Finch.unresolve(ctx(root0)))
        #display(Finch.unresolve(ctx(root)))
        #display(Finch.unresolve(ctx(res)))
        #println()
        return res.val
    else
        return false
    end
end