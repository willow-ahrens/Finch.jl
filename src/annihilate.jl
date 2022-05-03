@kwdef struct SkipVisitor <: AbstractTransformVisitor
    ctx
end

@kwdef struct Skip
    ignores
    body
end
isliteral(::Skip) = false

make_style(root, ctx::LowerJulia, node::Skip) = ThunkStyle()

function (ctx::ThunkVisitor)(node::Skip, ::DefaultStyle)
    map(SkipVisitor(ctx.ctx), node.ignores)
    node.body
end

@slots a b c d i j f g rules = [
    (@rule @i(f(a...)) => if isliteral(f) && all(isliteral, a) Literal(getvalue(f)(getvalue.(a)...)) end),

    ((a) -> if a isa Literal && isliteral(getvalue(a)) getvalue(a) end), #only quote when necessary

    (@rule @i(a[i...] = $b) => if b == default(a) pass(a) end),

    (@rule @i(@loop i... @pass(a...)) => pass(a...)),
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

    (@rule @i(+(a..., +(b...), c...)) => @i +(a..., b..., c...)),
    (@rule @i(+(a...)) => if count(isliteral, a) >= 2 @i +($(filter(!isliteral, a)...), $(Literal(+(getvalue.(filter(isliteral, a))...)))) end),
    (@rule @i(+(a..., 0, b...)) => @i +(a..., b...)),
    (@rule @i((+)($a)) => a),
    (@rule @i(- +($a, b...)) => @i +(- $a, - +(b...))),
    (@rule @i(a[i...] += 0) => pass(a)),

    (@rule @i($a - $b) => @i $a + - $b),
    (@rule @i(- (- $a)) => a),

    (@rule @i(*(a..., *(b...), c...)) => @i *(a..., b..., c...)),
    (@rule @i(*(a...)) => if count(isliteral, a) >= 2 @i(*($(filter(!isliteral, a)...), $(Literal(*(getvalue.(filter(isliteral, a))...))))) end),
    (@rule @i(*(a..., 1, b...)) => @i *(a..., b...)),
    (@rule @i(*(a..., 0, b...)) => Skip(ignores = [a; b], body = Simplify(0))), #TODO this is lazy, but not sure yet if I want the rules to have access to context.
    (@rule @i((*)($a)) => a),
    (@rule @i((*)(a..., - $b, c...)) => @i -(*(a..., $b, c...))),
    (@rule @i(a[i...] *= 1) => pass(a)),
]

@kwdef mutable struct Simplify
    body
end

struct SimplifyStyle end

make_style(root, ctx::LowerJulia, node::Simplify) = SimplifyStyle()
combine_style(a::DefaultStyle, b::SimplifyStyle) = SimplifyStyle()
combine_style(a::ThunkStyle, b::SimplifyStyle) = ThunkStyle() #Not sure about this, but we gotta get rid of thunks to match, so...
combine_style(a::SimplifyStyle, b::SimplifyStyle) = SimplifyStyle()

@kwdef struct SimplifyContext{Ctx} <: AbstractTransformVisitor
    ctx::Ctx
end

function postvisit!(node::Simplify, ctx::SimplifyContext)
    node.body
end

function (ctx::LowerJulia)(root, ::SimplifyStyle)
    global rules
    root = SimplifyContext(ctx)(root)
    root = Rewrite(Fixpoint(Prewalk(Chain(rules))))(root)
    ctx(root)
end

add_rules!(new_rules) = union!(rules, new_rules)

isliteral(::Simplify) = false