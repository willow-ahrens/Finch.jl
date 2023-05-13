module ExtentOracle

using Metatheory
using RewriteTools.Rewriters
import RewriteTools
using AbstractTrees

using Finch
using Finch.FinchNotation

export query

t = @theory a b c d e f x y z begin
    min(x, min(y, z)) == min(min(x, y), z)
    max(x, max(y, z)) == max(max(x, y), z)
    max(x, y) == max(y, x)
    min(x, y) == min(y, x)
    max(a, min(b, max(a, c))) --> max(a, min(b, c))
    min(a, max(b, min(a, c))) --> min(a, max(b, c))
    max(a, min(b, a)) --> max(a, b)
    min(a, max(b, a)) --> min(a, b)
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
    res = areequal(t, ctx(root), true, params = SaturationParams(timeout=treebreadth(root) + length(t), scheduler=Metatheory.Schedulers.SimpleScheduler))
    res = areequal(t, ctx(root), true, params = SaturationParams(timeout=treebreadth(root) + length(t)))
    println(res)
    return coalesce(res, false)
end

end