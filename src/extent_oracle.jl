module ExtentOracle

using Metatheory
using RewriteTools.Rewriters
import RewriteTools
using AbstractTrees

using Finch
using Finch.FinchNotation
using Finch: equiv

export query

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
    (a == a) --> true
    +(x, +(y, z)) == +(+(x, y), z)
    +(x, y) == +(y, x)
    +(x, -(x)) => 0
    +(x, 0) => x

    #min(a + b, c) --> a + min(a, c + -b) #explodes
    #max(a + b, c) --> a + max(a, c + -b)
    #min(a + b, a + c) --> a + min(b, c)
    #max(a + b, a + c) --> a + max(b, c)
    min(max(a, b), max(a, c)) --> max(a, min(b, c))
    max(min(a, b), min(a, c)) --> min(a, max(b, c))


    a::Number + min(b, c) --> min(a + b, a + c)
    a::Number + max(b, c) --> max(a + b, a + c)
    eps + min(a, b) --> min(a + eps, b + eps)
    eps + max(a, b) --> max(a + eps, b + eps)
    -eps + min(a, b) --> min(a + -eps, b + -eps)
    -eps + max(a, b) --> max(a + -eps, b + -eps)
    a + max(b + -a, c) --> max(b + 0, c + a)
    -a + max(b + a, c) --> max(b + 0, c + -a)
    a + min(b + -a, c) --> min(b + 0, c + a)
    -a + min(b + a, c) --> min(b + 0, c + -a)
    a + max(-a, c) --> max(0, c + a)
    -a + max(a, c) --> max(0, c + -a)
    a + min(-a, c) --> min(0, c + a)
    -a + min(a, c) --> min(0, c + -a)

    a >= b --> max(a, b) == a
    a > b --> max(a, b + eps) == a
    a <= b --> min(a, b) == b
    a < b --> min(a + eps, b) == b

    a::Number + b::Number => a + b
    max(a::Number, b::Number) => max(a, b)
    min(a::Number, b::Number) => min(a, b)
    max(a::Number, b::Number + $eps) => a > b ? a : b + eps
    min(a::Number + eps, b::Number) => a < b ? a + eps : b
    -(a::Number) => -a
end

function query(root::FinchNode, ctx)
    expand(node) = if isvalue(node)
        get(ctx.bindings, node, nothing)
    end
    root = Rewrite(Prewalk(expand))(root)
    root = Rewrite(Prewalk(Fixpoint(Chain([
        RewriteTools.@rule(call(+, ~a, ~b, ~c, ~d...) => call(+, a, call(+, b, c, d...))),
        #RewriteTools.@rule(call(>, ~a, ~b) => call(==, call(max, a, call(+, b, eps)), a)),
        RewriteTools.@rule(call(-, ~a, ~b) => call(+, a, call(-, b))),
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
    res = areequal(t, ctx(root), true, params = SaturationParams(timeout=8))
    g = EGraph(ctx(root))
    saturate!(g, t, SaturationParams(timeout=treebreadth(root) + length(t)))
    println(extract!(g, astsize))
    println(res)
    return coalesce(res, false)
end

end