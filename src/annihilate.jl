annihilate_index = Fixpoint(Prewalk(Chain([
    (@ex@rule @i((~f)(~~a)) => if isliteral(~f) && all(isliteral, ~~a) Literal(value(~f)(value.(~~a)...)) end),
    (@ex@rule @i((~~a, +(~~b), ~~c)) => @i +(~~a, ~~b, ~~c)),
    (@ex@rule @i(+(~~a)) => if count(isliteral, ~~a) >= 2 @i +($(filter(!isliteral, ~~a)), $(Literal(+(value.(filter(isliteral, ~~a))...)))) end),
    (@ex@rule @i(+(~~a, 0, ~~b)) => @i +(~~a, ~~b)),

    (@ex@rule @i(*(~~a, *(~~b), ~~c)) => @i *(~~a, ~~b, ~~c)),
    (@ex@rule @i(*(~~a)) => if count(isliteral, ~~a) >= 2 @i(*($(filter(!isliteral, ~~a)), $(Literal(*(value.(filter(isliteral, ~~a))...))))) end),
    (@ex@rule @i(*(~~a, 1, ~~b)) => @i *(~~a, ~~b)),
    (@ex@rule @i(*(~~a, 0, ~~b)) => 0),

    (@ex@rule @i(+(~a)) => ~a),
    (@ex@rule @i(~a - ~b) => @i ~a + - ~b),
    (@ex@rule @i(- (- ~a)) => ~a),
    (@ex@rule @i(- +(~a, ~~b)) => @i +(- ~a, - +(~~b))),
    (@ex@rule @i(*(~a)) => ~a),
    (@ex@rule @i(*(~~a, - ~b, ~~c)) => @i -(*(~~a, ~b, ~~c))),

    #(@ex@rule @i(+(~~a)) => if !issorted(~~a) @i +($(sort(~~a))) end),
    #(@ex@rule @i(*(~~a)) => if !issorted(~~a) @i *($(sort(~~a))) end),

    (@ex@rule @i((~a)[]) => ~a), 
    (@ex@rule @i((~a)[~~i] = 0) => pass(~a)), #TODO this is only valid when the default of A is 0
    (@ex@rule @i((~a)[~~i] += 0) => pass(~a)),
    (@ex@rule @i((~a)[~~i] *= 1) => pass(~a)),

    #(@ex@rule @i((~a)[~~i] *= ~b) => if isimplicit(~a) && getdefault(~a) == 0 pass(~a) end),
    #(@ex@rule @i((~a)[~~i] = ~b) => if isimplicit(~a) && getdefault(~a) == ~b pass(~a) end),
    ((a) -> if a isa Literal && isliteral(value(a)) value(a) end), #only quote when necessary

    (@ex@rule @i(@loop (~~i) @pass(~~a)) => pass(~~a)),
    (@ex@rule @i(@pass(~~a) where ~x) => pass(~~a)),
    #(@ex@rule @i(~x where @pass(~~a)) => ~x), #can't do this bc produced tensors won't get initialized
])))