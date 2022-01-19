annihilate_index = @slots a b c i j f g Rewrite(Fixpoint(Prewalk(Chain([
    (@rule @i(f(a...)) => if isliteral(f) && all(isliteral, a) Literal(value(f)(value.(a)...)) end),
    (@rule @i((a..., +(b...), c...)) => @i +(a..., b..., c...)),
    (@rule @i(+(a...)) => if count(isliteral, a) >= 2 @i +($(filter(!isliteral, a)...), $(Literal(+(value.(filter(isliteral, a))...)))) end),
    (@rule @i(+(a..., 0, b...)) => @i +(a..., b...)),

    (@rule @i(*(a..., *(b...), c...)) => @i *(a..., b..., c...)),
    (@rule @i(*(a...)) => if count(isliteral, a) >= 2 @i(*($(filter(!isliteral, a)...), $(Literal(*(value.(filter(isliteral, a))...))))) end),
    (@rule @i(*(a..., 1, b...)) => @i *(a..., b...)),
    (@rule @i(*(a..., 0, b...)) => 0),

    (@rule @i((+)(a)) => a),
    (@rule @i(a - b) => @i a + - b),
    (@rule @i(- (- a)) => a),
    (@rule @i(- +(a, b...)) => @i +(- a, - +(b...))),
    (@rule @i((*)a) => a),
    (@rule @i((*)(a..., - b, c...)) => @i -(*(a..., b, c...))),

    (@rule @i(a[i...] = 0) => pass(a)), #TODO this is only valid when the default of A is 0
    (@rule @i(a[i...] += 0) => pass(a)),
    (@rule @i(a[i...] *= 1) => pass(a)),
    (@rule @i(a = 0) => pass(a)), #TODO this is only valid when the default of A is 0
    (@rule @i(a += 0) => pass(a)),
    (@rule @i(a *= 1) => pass(a)),

    #(@rule @i((~a)[~~i] *= ~b) => if isimplicit(~a) && getdefault(~a) == 0 pass(~a) end),
    #(@rule @i((~a)[~~i] = ~b) => if isimplicit(~a) && getdefault(~a) == ~b pass(~a) end),
    ((a) -> if a isa Literal && isliteral(value(a)) value(a) end), #only quote when necessary

    (@rule @i(@loop i... @pass(a...)) => pass(a...)),
    (@rule @i(@pass(a...) where b) => pass(a...)),
    #(@rule @i(a where @pass(b...)) => a),#can't do this bc produced tensors won't get initialized
]))))

#TODO add simplify as a chunk pass.