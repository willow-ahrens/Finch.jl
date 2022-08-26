@slots a b c d e i j f g rules = [
    (@rule @f(f(a...)) => if isliteral(f) && all(isliteral, a) && length(a) >= 1 Literal(getvalue(f)(getvalue.(a)...)) end),

    ((a) -> if a isa Literal && isliteral(getvalue(a)) getvalue(a) end), #only quote when necessary

    (@rule @f(a[i...] = $b) => if b == default(a) pass(a) end), #TODO either default needs to get defined on all chunks, or we need to guard this

    (@rule @f(@loop $i @pass(a...)) => pass(a...)),
    (@rule @f(@chunk $i a @pass(b...)) => pass(b...)),
    (@rule @f(@pass(a...) where $b) => pass(a...)),
    (@rule @f($a where @pass()) => a),
    (@rule @f(@multi(a..., @pass(b...), @pass(c...), d...)) => @f(@multi(a..., @pass(b..., c...), d...))),
    (@rule @f(@multi(@pass(a...))) => @f(@pass(a...))),
    (@rule @f(@multi()) => @f(@pass())),
    (@rule @f((@pass(a...);)) => pass(a...)),
    (@rule @f($a where $b) => begin
        @slots c d i j f g begin
            props = Dict()
            b_2 = Postwalk(Chain([
                (@rule @f(c[i...] = $d) => if isliteral(d)
                    props[getname(c)] = d
                    pass()
                end),
                (@rule @f(@pass(c...)) => begin
                    for d in c
                        props[getname(d)] = default(d) #TODO is this okay?
                    end
                    pass()
                end),
            ]))(b)
            if b_2 != nothing
                a_2 = Rewrite(Postwalk(@rule @f($c[i...]) => get(props, getname(c), nothing)))(a)
                @f $a_2 where $b_2
            end
        end
    end),
    #(@rule @f(a where @pass(b...)) => a),#can't do this bc produced tensors won't get initialized ?

    (@rule @f(max(a...) >= $b) => @f or($(map(x -> @f($x >= $b), a)...))),
    (@rule @f(max(a...) > $b) => @f or($(map(x -> @f($x > $b), a)...))),
    (@rule @f(max(a...) <= $b) => @f and($(map(x -> @f($x <= $b), a)...))),
    (@rule @f(max(a...) < $b) => @f and($(map(x -> @f($x < $b), a)...))),
    (@rule @f(min(a...) <= $b) => @f or($(map(x -> @f($x <= $b), a)...))),
    (@rule @f(min(a...) < $b) => @f or($(map(x -> @f($x < $b), a)...))),
    (@rule @f(min(a...) >= $b) => @f and($(map(x -> @f($x >= $b), a)...))),
    (@rule @f(min(a...) > $b) => @f and($(map(x -> @f($x > $b), a)...))),
    (@rule @f(min(a..., min(b...), c...)) => @f min(a..., b..., c...)),
    (@rule @f(max(a..., max(b...), c...)) => @f max(a..., b..., c...)),
    (@rule @f(min(a...)) => if !(issorted(a, by = Lexicography)) @f min($(sort(a, by = Lexicography)...)) end),
    (@rule @f(max(a...)) => if !(issorted(a, by = Lexicography)) @f max($(sort(a, by = Lexicography)...)) end),
    (@rule @f(min(a...)) => if !(allunique(a)) @f min($(unique(a)...)) end),
    (@rule @f(max(a...)) => if !(allunique(a)) @f max($(unique(a)...)) end),
    (@rule @f(+(a..., +(b...), c...)) => @f +(a..., b..., c...)),
    (@rule @f(+(a...)) => if count(isliteral, a) >= 2 @f +($(filter(!isliteral, a)...), $(Literal(+(getvalue.(filter(isliteral, a))...)))) end),
    (@rule @f(+(a..., 0, b...)) => @f +(a..., b...)),
    (@rule @f(+(a..., -0.0, b...)) => @f +(a..., b...)),
    (@rule @f(or(a..., false, b...)) => @f or(a..., b...)),
    (@rule @f(or(a..., true, b...)) => true),
    (@rule @f(or()) => false),
    (@rule @f(and(a..., true, b...)) => @f and(a..., b...)),
    (@rule @f(and(a..., false, b...)) => false),
    (@rule @f(and()) => true),
    (@rule @f((+)($a)) => a),
    (@rule @f((-$a)^2) => @f $a^2),
    (@rule @f(- +($a, b...)) => @f +(- $a, - +(b...))),
    (@rule @f(a[i...] += 0) => pass(a)),
    (@rule @f(a[i...] += -0.0) => pass(a)),

    (@rule @f(a[i...] <<f>>= $($(Literal(missing)))) => pass(a)),
    (@rule @f(a[i..., $($(Literal(missing))), j...] <<f>>= $b) => pass(a)),
    (@rule @f(a[i..., $($(Literal(missing))), j...]) => Literal(missing)),
    (@rule @f(coalesce(a..., $($(Literal(missing))), b...)) => @f coalesce(a..., b...)),
    (@rule @f(coalesce(a..., $b, c...)) => if b isa Virtual && !(Virtual{missing} <: typeof(b)); @f(coalesce(a..., $b)) end),
    (@rule @f(coalesce(a..., $b, c...)) => if b isa Literal && b != Literal(missing); @f(coalesce(a..., $b)) end),
    (@rule @f(coalesce($a)) => a),

    (@rule @f($a - $b) => @f $a + - $b),
    (@rule @f(- (- $a)) => a),

    (@rule @f(*(a..., *(b...), c...)) => @f *(a..., b..., c...)),
    (@rule @f(*(a...)) => if count(isliteral, a) >= 2 @f(*($(filter(!isliteral, a)...), $(Literal(*(getvalue.(filter(isliteral, a))...))))) end),
    (@rule @f(*(a..., 1, b...)) => @f *(a..., b...)),
    (@rule @f(*(a..., 0, b...)) => 0),
    (@rule @f(*(a..., -0.0, b...)) => 0),
    (@rule @f((*)($a)) => a),
    (@rule @f((*)(a..., - $b, c...)) => @f -(*(a..., $b, c...))),
    (@rule @f(a[i...] *= 1) => pass(a)),
    (@rule @f(@sieve true $a) => a),
    (@rule @f(@sieve false $a) => pass(getresults(a)...)),

    (@rule @f(@chunk $i a (b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<min>>= $d)
    end),
    (@rule @f(@chunk $i a @multi b... (c[j...] <<min>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @f @multi (c[j...] <<min>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),
    (@rule @f(@chunk $i a (b[j...] <<max>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<max>>= $d)
    end),
    (@rule @f(@chunk $i a @multi b... (c[j...] <<max>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            println(@f @multi (c[j...] <<max>>= $d) @chunk $i a @f(@multi b... e...))
            @f @multi (c[j...] <<max>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),
    (@rule @f(@chunk $i $a (b[j...] += $d)) => begin
        if i ∉ getunbound(d) && i ∉ j
            @f (b[j...] += $(extent(a)) * $d)
        end
    end),
    (@rule @f(@chunk $i a @multi b... (c[j...] += $d) e...) => begin
        if i ∉ getunbound(d) && i ∉ j
            @f @multi (c[j...] += $(extent(a)) * $d) @chunk $i a @f(@multi b... e...)
        end
    end),
]

@kwdef mutable struct Simplify
    body
end

struct SimplifyStyle end

(ctx::Stylize{LowerJulia})(::Simplify) = SimplifyStyle()
combine_style(a::DefaultStyle, b::SimplifyStyle) = SimplifyStyle()
combine_style(a::ThunkStyle, b::SimplifyStyle) = ThunkStyle()
combine_style(a::SimplifyStyle, b::SimplifyStyle) = SimplifyStyle()

@kwdef struct SimplifyContext{Ctx} <: AbstractTransformVisitor
    ctx::Ctx
end

function postvisit!(node::Simplify, ctx::SimplifyContext)
    node.body
end

function simplify(node)
    global rules
    Rewrite(Fixpoint(Prewalk(Chain(rules))))(node)
end

function (ctx::LowerJulia)(root, ::SimplifyStyle)
    global rules
    root = SimplifyContext(ctx)(root)
    root = simplify(root)
    ctx(root)
end

add_rules!(new_rules) = union!(rules, new_rules)

isliteral(::Simplify) = false