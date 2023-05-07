module ExtentOracle

using Metatheory
using RewriteTools.Rewriters

#=
using Finch
using Finch.FinchNotation

export query

t = @theory a b c d e f x y z begin
    min(a, b, c, d...) --> min(min(a, b), c, d...)
    max(a, b, c, d...) --> max(max(a, b), c, d...)
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
    +(x, -(x)) => (println("hi $x"); 0)
    -(x, y) --> +(x, -y)
    +(x, 0) => (println("bye $x"); x)
    a::Number + b::Number => a + b
    #-(a::Number) => -a
end

function query(root::FinchNode, ctx)
    expand(node) = if isvalue(node)
        get(ctx.bindings, node, nothing)
    end
    root = Rewrite(Prewalk(expand))(root)
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
    root = ctx(root)
    println(root)
    res = areequal(t, root, true; params = SaturationParams(printiter=true, timeout=100))
    println(res)
    return res
end
=#

#println(@rule x y +(x, y) --> +(x, -y))
#println(areequal(t, :((==)((+)((-)(src_mode1_stop, 1), 1), 1)), true; params = SaturationParams(printiter=true, timeout=100)))
#exit()

t = @theory a b c d e f x y z begin
    +(x, +(y, z)) == +(+(x, y), z)
    +(x, y) == +(y, x)
    +(1, -1) => 0
    x + 0 --> x
end

println(areequal(t, :(a + (b + -b)), true; params = SaturationParams(printiter=true, timeout=100)))

t = @theory a b c begin
    a + 0 --> a
    a + b --> b + a
    a + inv(a) --> 0 # inverse
    a + (b + c) --> (a + b) + c
	a * (b + c) --> (a * b) + (a * c)
	(a * b) + (a * c) --> a * (b + c)
	a * a --> a^2
	a --> a^1
	a^b * a^c --> a^(b+c)
	log(a^b) --> b * log(a)
	log(a * b) --> log(a) + log(b)
	log(1) --> 0
	log(:e) --> 1
	:e^(log(a)) --> a
	a::Number + b::Number => a + b
	a::Number * b::Number => a * b
end

println(areequal(t, :(a + (b + -b)), true; params = SaturationParams(printiter=true, timeout=100)))



end