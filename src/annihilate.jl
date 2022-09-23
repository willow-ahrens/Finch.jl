
@slots a b c d e i j f g rules = [
    (@rule @_f($f(a...)) => if isliteral(f) && all(isliteral, a) && length(a) >= 1 Literal(getvalue(f)(getvalue.(a)...)) end),

    #((a) -> if a isa Literal && isliteral(getvalue(a)) getvalue(a) end), #only quote when necessary

    (@rule @_f($a[i...] = $b) => if b == Literal(default(a)) pass(a) end), #TODO either default needs to get defined on all chunks, or we need to guard this

    (@rule @_f(@loop $i @pass(a...)) => pass(a...)),
    (@rule @_f(@chunk $i $a @pass(b...)) => pass(b...)),
    (@rule @_f(@pass(a...) where $b) => pass(a...)),
    (@rule @_f($a where @pass()) => a),
    (@rule @_f(@multi(a..., @pass(b...), @pass(c...), d...)) => @f(@multi(a..., @pass(b..., c...), d...))),
    (@rule @_f(@multi(@pass(a...))) => @f(@pass(a...))),
    (@rule @_f(@multi()) => @f(@pass())),
    (@rule @_f((@pass(a...);)) => pass(a...)),

    (@rule @_f($a where $b) => begin
        @slots c d i j f g begin
            props = Dict()
            b_2 = Postwalk(Chain([
                (@rule @_f($c[i...] = $d) => if isliteral(d)
                    props[getname(c)] = d
                    pass()
                end),
                (@rule @_f(@pass(c...)) => begin
                    for d in c
                        props[getname(d)] = Literal(default(d)) #TODO is this okay?
                    end
                    pass()
                end),
            ]))(b)
            if b_2 != nothing
                a_2 = Rewrite(Postwalk(@rule @_f($c[i...]) => get(props, getname(c), nothing)))(a)
                @f $a_2 where $b_2
            end
        end
    end),
    #(@rule @_f(a where @pass(b...)) => a),#can't do this bc produced tensors won't get initialized ?

    (@rule @_f(max(a...) >= $b) => @f or($(map(x -> @f($x >= $b), a)...))),
    (@rule @_f(max(a...) > $b) => @f or($(map(x -> @f($x > $b), a)...))),
    (@rule @_f(max(a...) <= $b) => @f and($(map(x -> @f($x <= $b), a)...))),
    (@rule @_f(max(a...) < $b) => @f and($(map(x -> @f($x < $b), a)...))),
    (@rule @_f(min(a...) <= $b) => @f or($(map(x -> @f($x <= $b), a)...))),
    (@rule @_f(min(a...) < $b) => @f or($(map(x -> @f($x < $b), a)...))),
    (@rule @_f(min(a...) >= $b) => @f and($(map(x -> @f($x >= $b), a)...))),
    (@rule @_f(min(a...) > $b) => @f and($(map(x -> @f($x > $b), a)...))),
    (@rule @_f(min(a..., min(b...), c...)) => @f min(a..., b..., c...)),
    (@rule @_f(max(a..., max(b...), c...)) => @f max(a..., b..., c...)),
    (@rule @_f(min(a...)) => if !(issorted(a, by = Lexicography)) @f min($(sort(a, by = Lexicography)...)) end),
    (@rule @_f(max(a...)) => if !(issorted(a, by = Lexicography)) @f max($(sort(a, by = Lexicography)...)) end),
    (@rule @_f(min(a...)) => if !(allunique(a)) @f min($(unique(a)...)) end),
    (@rule @_f(max(a...)) => if !(allunique(a)) @f max($(unique(a)...)) end),
    (@rule @_f(+(a..., +(b...), c...)) => @f +(a..., b..., c...)),
    (@rule @_f(+(a...)) => if count(isliteral, a) >= 2 @f +($(filter(!isliteral, a)...), $(Literal(+(getvalue.(filter(isliteral, a))...)))) end),
    (@rule @_f(+(a..., 0, b...)) => @f +(a..., b...)),
    (@rule @_f(or(a..., false, b...)) => @f or(a..., b...)),
    (@rule @_f(or(a..., true, b...)) => @f true),
    (@rule @_f(or($a)) => a),
    (@rule @_f(or()) => @f false),
    (@rule @_f(and(a..., true, b...)) => @f and(a..., b...)),
    (@rule @_f(and(a..., false, b...)) => @f false),
    (@rule @_f(and($a)) => a),
    (@rule @_f(and()) => @f true),
    (@rule @_f((+)($a)) => a),
    (@rule @_f(- +($a, b...)) => @f +(- $a, - +(b...))),
    (@rule @_f($a[i...] += 0) => pass(a)),

    (@rule @_f($a[i...] <<$f>>= $($(Literal(missing)))) => pass(a)),
    (@rule @_f($a[i..., $($(Literal(missing))), j...] <<$f>>= $b) => pass(a)),
    (@rule @_f($a[i..., $($(Literal(missing))), j...]) => Literal(missing)),
    (@rule @_f(coalesce(a..., $($(Literal(missing))), b...)) => @f coalesce(a..., b...)),
    (@rule @_f(coalesce(a..., $b, c...)) => if b isa Value && !(Value{Missing} <: typeof(b)); @f(coalesce(a..., $b)) end),
    (@rule @_f(coalesce(a..., $b, c...)) => if b isa Literal && b != Literal(missing); @f(coalesce(a..., $b)) end),
    (@rule @_f(coalesce($a)) => a),

    (@rule @_f($a - $b) => @f $a + - $b),
    (@rule @_f(- (- $a)) => a),

    (@rule @_f(*(a..., *(b...), c...)) => @f *(a..., b..., c...)),
    (@rule @_f(*(a...)) => if count(isliteral, a) >= 2 @f(*($(filter(!isliteral, a)...), $(Literal(*(getvalue.(filter(isliteral, a))...))))) end),
    (@rule @_f(*(a..., 1, b...)) => @f *(a..., b...)),
    (@rule @_f(*(a..., 0, b...)) => @f 0),
    (@rule @_f((*)($a)) => a),
    (@rule @_f((*)(a..., - $b, c...)) => @f -(*(a..., $b, c...))),
    (@rule @_f($a[i...] *= 1) => pass(a)),
    (@rule @_f(@sieve true $a) => a),
    (@rule @_f(@sieve false $a) => pass(getresults(a)...)),

    (@rule @_f(@chunk $i $a ($b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<min>>= $d)
    end),
    (@rule @_f(@chunk $i $a @multi b... ($c[j...] <<min>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @f @multi (c[j...] <<min>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),
    (@rule @_f(@chunk $i $a ($b[j...] <<max>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<max>>= $d)
    end),
    (@rule @_f(@chunk $i $a @multi b... ($c[j...] <<max>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            println(@f @multi (c[j...] <<max>>= $d) @chunk $i a @f(@multi b... e...))
            @f @multi (c[j...] <<max>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),
    (@rule @_f(@chunk $i $a ($b[j...] += $d)) => begin
        if getname(i) ∉ getunbound(d) && i ∉ j
            @f (b[j...] += $(extent(a)) * $d)
        end
    end),
    (@rule @_f(@chunk $i $a @multi b... ($c[j...] += $d) e...) => begin
        if getname(i) ∉ getunbound(d) && i ∉ j
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

add_rules!(new_rules) = union!(rules, new_rules)

IndexNotation.isliteral(::Simplify) =  false

struct Lexicography{T}
    arg::T
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

priority(::Name) = (3,0)
comparators(x::Name) = (x.name,)

priority(::Literal) = (3,1)
comparators(x::Literal) = (Lexicography(x.val),)

priority(::Read) = (3,2,1)
comparators(x::Read) = ()

priority(::Write) = (3,2,2)
comparators(x::Write) = ()

priority(::Update) = (3,2,3)
comparators(x::Update) = ()

priority(::Workspace) = (3,3)
comparators(x::Workspace) = (x.n,)

priority(::Value) = (3,4)
comparators(x::Value) = (string(typeof(x)), Lexicography(x.ex))

priority(::IndexNode) = (3,Inf)
comparators(x::IndexNode) = (@assert istree(x); (string(operation(x)), map(Lexicography, arguments(x))...))

#TODO these are nice defaults if we want to allow nondeterminism
#priority(::Any) = (Inf,)
#comparators(x::Any) = hash(x)