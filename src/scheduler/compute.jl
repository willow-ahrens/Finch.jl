
default_scheduler = DefaultLogicOptimizer(FinchCompiler())

"""
    compute(args..., ctx=default_scheduler) -> Any

Compute the value of a lazy tensor. The result is the argument itself, or a
tuple of arguments if multiple arguments are passed.
"""
compute(args...; ctx=default_scheduler) = compute_parse(ctx, args)
compute(arg; ctx=default_scheduler) = compute_parse(ctx, (arg,))[1]
compute(args::Tuple; ctx=default_scheduler) = compute_parse(ctx, args)
function compute_parse(ctx, args::Tuple)
    args = collect(args)
    vars = map(arg -> alias(gensym(:A)), args)
    bodies = map((arg, var) -> query(var, arg.data), args, vars)
    prgm = plan(bodies, produces(vars))

    return ctx(prgm)
end