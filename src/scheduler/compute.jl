struct DefaultOptimizer
    ctx
end

default_optimizer = DefaultOptimizer(FinchCompiler())

"""
    compute(args..., ctx=default_optimizer) -> Any

Compute the value of a lazy tensor. The result is the argument itself, or a
tuple of arguments if multiple arguments are passed.
"""
compute(args...; ctx=default_optimizer) = compute_parse(args, ctx)
compute(arg; ctx=default_optimizer) = compute_parse((arg,), ctx)[1]
compute(args::Tuple; ctx=default_optimizer) = compute_parse(args, ctx)
function compute_parse(args::Tuple, ctx)
    args = collect(args)
    vars = map(arg -> alias(gensym(:A)), args)
    bodies = map((arg, var) -> query(var, arg.data), args, vars)
    prgm = plan(bodies, produces(vars))

    return compute_impl(prgm, ctx)
end

function compute_impl(prgm, ctx::DefaultOptimizer)
    compute_impl(prgm, ctx.ctx)
end

function compute_impl(prgm, ctx::FinchInterpreter)
    prgm = optimize(prgm)
    prgm = format_queries(prgm)
    ctx(prgm)
end
