@slots a b c d i j f g rules = [
    (@rule @i(f(a...)) => if isliteral(f) && all(isliteral, a) && length(a) >= 1 Literal(getvalue(f)(getvalue.(a)...)) end),

    ((a) -> if a isa Literal && isliteral(getvalue(a)) getvalue(a) end), #only quote when necessary

    (@rule @i(a[i...] = $b) => if b == default(a) pass(a) end), #TODO either default needs to get defined on all chunks, or we need to guard this

    (@rule @i(@loop $i @pass(a...)) => pass(a...)),
    (@rule @i(@chunk $i a @pass(b...)) => pass(b...)),
    (@rule @i(@pass(a...) where $b) => pass(a...)),
    (@rule @i($a where @pass()) => a),
    (@rule @i(@multi(a..., @pass(b...), @pass(c...), d...)) => @i(@multi(a..., @pass(b..., c...), d...))),
    (@rule @i(@multi(@pass(a...))) => @i(@pass(a...))),
    (@rule @i(@multi()) => @i(@pass())),
    (@rule @i((@pass(a...);)) => pass(a...)),
    (@rule @i($a where $b) => begin
        @slots c d i j f g begin
            props = Dict()
            b_2 = Postwalk(Chain([
                (@rule @i(c[i...] = $d) => if isliteral(d)
                    props[getname(c)] = d
                    pass()
                end),
                (@rule @i(@pass(c...)) => begin
                    for d in c
                        props[getname(d)] = default(d) #TODO is this okay?
                    end
                    pass()
                end),
            ]))(b)
            if b_2 != nothing
                a_2 = Rewrite(Postwalk(@rule @i($c[i...]) => get(props, getname(c), nothing)))(a)
                @i $a_2 where $b_2
            end
        end
    end),
    #(@rule @i(a where @pass(b...)) => a),#can't do this bc produced tensors won't get initialized ?

    (@rule @i(max(a...) >= $b) => @i or($(map(x -> @i($x >= $b), a)...))),
    (@rule @i(max(a...) > $b) => @i or($(map(x -> @i($x > $b), a)...))),
    (@rule @i(max(a...) <= $b) => @i and($(map(x -> @i($x <= $b), a)...))),
    (@rule @i(max(a...) < $b) => @i and($(map(x -> @i($x < $b), a)...))),
    (@rule @i(min(a...) <= $b) => @i or($(map(x -> @i($x <= $b), a)...))),
    (@rule @i(min(a...) < $b) => @i or($(map(x -> @i($x < $b), a)...))),
    (@rule @i(min(a...) >= $b) => @i and($(map(x -> @i($x >= $b), a)...))),
    (@rule @i(min(a...) > $b) => @i and($(map(x -> @i($x > $b), a)...))),
    (@rule @i(min(a..., min(b...), c...)) => @i min(a..., b..., c...)),
    (@rule @i(max(a..., max(b...), c...)) => @i max(a..., b..., c...)),
    (@rule @i(min(a...)) => if !(issorted(a, by = Lexicography)) @i min($(sort(a, by = Lexicography)...)) end),
    (@rule @i(max(a...)) => if !(issorted(a, by = Lexicography)) @i max($(sort(a, by = Lexicography)...)) end),
    (@rule @i(min(a...)) => if !(allunique(a)) @i min($(unique(a)...)) end),
    (@rule @i(max(a...)) => if !(allunique(a)) @i max($(unique(a)...)) end),
    (@rule @i(+(a..., +(b...), c...)) => @i +(a..., b..., c...)),
    (@rule @i(+(a...)) => if count(isliteral, a) >= 2 @i +($(filter(!isliteral, a)...), $(Literal(+(getvalue.(filter(isliteral, a))...)))) end),
    (@rule @i(+(a..., 0, b...)) => @i +(a..., b...)),
    (@rule @i(or(a..., false, b...)) => @i or(a..., b...)),
    (@rule @i(or(a..., true, b...)) => true),
    (@rule @i(or()) => false),
    (@rule @i(and(a..., true, b...)) => @i and(a..., b...)),
    (@rule @i(and(a..., false, b...)) => false),
    (@rule @i(and()) => true),
    (@rule @i((+)($a)) => a),
    (@rule @i(- +($a, b...)) => @i +(- $a, - +(b...))),
    (@rule @i(a[i...] += 0) => pass(a)),

    (@rule @i(a[i...] <<f>>= missing) => pass(a)),
    (@rule @i(a[i..., missing, j...] <<f>>= $b) => pass(a)),
    (@rule @i(a[i..., missing, j...]) => missing),
    (@rule @i($f(a..., missing, b...)) => f === coalesce ? (@i $f(a..., b...)) : missing),
    (@rule @i($(coalesce)($a, b...)) => if a isa Virtual && !(Virtual{missing} <: typeof(a)); a end),

    (@rule @i($a - $b) => @i $a + - $b),
    (@rule @i(- (- $a)) => a),

    (@rule @i(*(a..., *(b...), c...)) => @i *(a..., b..., c...)),
    (@rule @i(*(a...)) => if count(isliteral, a) >= 2 @i(*($(filter(!isliteral, a)...), $(Literal(*(getvalue.(filter(isliteral, a))...))))) end),
    (@rule @i(*(a..., 1, b...)) => @i *(a..., b...)),
    (@rule @i(*(a..., 0, b...)) => 0),
    (@rule @i((*)($a)) => a),
    (@rule @i((*)(a..., - $b, c...)) => @i -(*(a..., $b, c...))),
    (@rule @i(a[i...] *= 1) => pass(a)),
    (@rule @i(if true; $a end) => a),
    (@rule @i(if false; $a end) => pass(getresults(a)...)),
]

literalize(x::Symbol) = Virtual{Any}(x)
literalize(x::Expr) = Virtual{Any}(x)
literalize(x::Literal) = x
literalize(x) = isliteral(x) ? Literal(x) : x

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