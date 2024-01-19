abstract type CompileMode end
struct DebugFinch <: CompileMode end
const debugfinch = DebugFinch()
virtualize(ex, ::Type{DebugFinch}, ctx) = DebugFinch()
struct SafeFinch <: CompileMode end
const safefinch = SafeFinch()
virtualize(ex, ::Type{SafeFinch}, ctx) = SafeFinch()
struct FastFinch <: CompileMode end
const fastfinch = FastFinch()
virtualize(ex, ::Type{FastFinch}, ctx) = FastFinch()

issafe(::DebugFinch) = true
issafe(::SafeFinch) = true
issafe(::FastFinch) = false

"""
    instantiate!(prgm, ctx)

A transformation to instantiate readers and updaters before executing an
expression.
"""
function instantiate!(prgm, ctx) 
    prgm = InstantiateTensors(ctx=ctx)(prgm)
    return prgm
end

@kwdef struct InstantiateTensors{Ctx}
    ctx::Ctx
    escape = Set()
end

function (ctx::InstantiateTensors)(node::FinchNode)
    if node.kind === block
        block(map(ctx, node.bodies)...)
    elseif node.kind === define
        push!(ctx.escape, node.lhs)
        define(node.lhs, ctx(node.rhs), ctx(node.body))
    elseif node.kind === declare
        push!(ctx.escape, node.tns)
        node
    elseif node.kind === freeze
        push!(ctx.escape, node.tns)
        node
    elseif node.kind === thaw
        push!(ctx.escape, node.tns)
        node
    elseif (@capture node access(~tns, ~mode, ~idxs...)) && !(getroot(tns) in ctx.escape)
        #@assert get(ctx.ctx.modes, tns, reader) === node.mode.val
        protos = [(mode.val === reader ? defaultread : defaultupdate) for _ in idxs]
        tns_2 = instantiate(tns, ctx.ctx, mode.val, protos)
        access(tns_2, mode, idxs...)
    elseif istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end

execute(ex) = execute(ex, NamedTuple())

@staged function execute(ex, opts)
    contain(JuliaContext()) do ctx
        code = execute_code(:ex, ex; virtualize(:opts, opts, ctx)...)
        quote
            try
                @inbounds begin
                    $(code |> unblock)
                end
            catch
                println("Error executing code:")
                println($(QuoteNode(code |> unblock |> pretty |> unquote_literals)))
                rethrow()
            end
        end
    end
end

function execute_code(ex, T; algebra = DefaultAlgebra(), mode = safefinch, ctx = LowerJulia(algebra = algebra, mode=mode))
    code = contain(ctx) do ctx_2
        prgm = nothing
        prgm = virtualize(ex, T, ctx_2.code)
        lower_global(prgm, ctx_2)
    end
end

"""
    lower_global(prgm, ctx)

lower the program `prgm` at global scope in the context `ctx`.
"""
function lower_global(prgm, ctx)
    prgm = enforce_scopes(prgm)
    prgm = evaluate_partial(prgm, ctx)
    code = contain(ctx) do ctx_2
        quote
            $(begin
                prgm = wrapperize(prgm, ctx_2)
                prgm = enforce_lifecycles(prgm)
                prgm = dimensionalize!(prgm, ctx_2)
                prgm = concordize(prgm, ctx_2)
                prgm = evaluate_partial(prgm, ctx_2)
                prgm = simplify(prgm, ctx_2) #appears necessary
                prgm = instantiate!(prgm, ctx_2)
                contain(ctx_2) do ctx_3
                    ctx_3(prgm)
                end
            end)
            $(begin
                res = contain(ctx_2) do ctx_3
                    :((; $(map(getresults(prgm)) do tns
                        @assert tns.kind === variable
                        name = tns.name
                        tns = trim!(resolve(tns, ctx_2), ctx_3)
                        Expr(:kw, name, ctx_3(tns))
                    end...), ))
                end
                res
            end)
        end
    end
end

"""
    @finch [options...] prgm

Run a finch program `prgm`. The syntax for a finch program is a set of nested
loops, statements, and branches over pointwise array assignments. For example,
the following program computes the sum of two arrays `A = B + C`:

```julia   
A .= 0
@finch for i = _
    A[i] = B[i] + C[i]
end
```

Finch programs are composed using the following syntax:

 - `arr .= 0`: an array declaration initializing arr to zero.
 - `arr[inds...]`: an array access, the array must be a variable and each index may be another finch expression.
 - `x + y`, `f(x, y)`: function calls, where `x` and `y` are finch expressions.
 - `arr[inds...] = ex`: an array assignment expression, setting `arr[inds]` to the value of `ex`.
 - `arr[inds...] += ex`: an incrementing array expression, adding `ex` to `arr[inds]`. `*, &, |`, are supported.
 - `arr[inds...] <<min>>= ex`: a incrementing array expression with a custom operator, e.g. `<<min>>` is the minimum operator.
 - `for i = _ body end`: a loop over the index `i`, where `_` is computed from array access with `i` in `body`.
 - `if cond body end`: a conditional branch that executes only iterations where `cond` is true.

Symbols are used to represent variables, and their values are taken from the environment. Loops introduce
index variables into the scope of their bodies.

Finch uses the types of the arrays and symbolic analysis to discover program
optimizations. If `B` and `C` are sparse array types, the program will only run
over the nonzeros of either. 

Semantically, Finch programs execute every iteration. However, Finch can use
sparsity information to reliably skip iterations when possible.

`options` are optional keyword arguments:

 - `algebra`: the algebra to use for the program. The default is `DefaultAlgebra()`.
 - `mode`: the optimization mode to use for the program. The default is `fastfinch`.
 - `ctx`: the context to use for the program. The default is a `LowerJulia` context with the given options.

See also: [`@finch_code`](@ref)
"""
macro finch(opts_ex...)
    length(opts_ex) >= 1 || throw(ArgumentError("Expected at least one argument to @finch(opts..., ex)"))
    (opts, ex) = (opts_ex[1:end-1], opts_ex[end])
    results = Set()
    prgm = FinchNotation.finch_parse_instance(ex, results)
    res = esc(:res)
    thunk = quote
        res = $execute($prgm, (;$(map(esc, opts)...),))
    end
    for tns in results
        push!(thunk.args, quote
            if haskey(res, $(QuoteNode(tns)))
                $(esc(tns)) = res[$(QuoteNode(tns))]
            end
        end)
    end
    push!(thunk.args, quote
        res
    end)
    thunk
end

"""
@finch_code [options...] prgm

Return the code that would be executed in order to run a finch program `prgm`.

See also: [`@finch`](@ref)
"""
macro finch_code(opts_ex...)
    length(opts_ex) >= 1 || throw(ArgumentError("Expected at least one argument to @finch(opts..., ex)"))
    (opts, ex) = (opts_ex[1:end-1], opts_ex[end])
    prgm = FinchNotation.finch_parse_instance(ex)
    return quote
        $execute_code(:ex, typeof($prgm); $(map(esc, opts)...)) |> pretty |> dataflow |> unresolve |> unquote_literals
    end
end

"""
    finch_kernel(fname, args, prgm; options...)

Return a function definition for which can execute a Finch program of
type `prgm`. Here, `fname` is the name of the function and `args` is a
`iterable` of argument name => type pairs.

See also: [`@finch`](@ref)
"""
function finch_kernel(fname, args, prgm; algebra = DefaultAlgebra(), mode = safefinch, ctx = LowerJulia(algebra=algebra, mode=mode))
    maybe_typeof(x) = x isa Type ? x : typeof(x)
    code = contain(ctx) do ctx_2
        foreach(args) do (key, val)
            ctx_2.bindings[variable(key)] = virtualize(key, maybe_typeof(val), ctx_2.code, key)
        end
        execute_code(:UNREACHABLE, prgm, algebra = algebra, mode = mode, ctx = ctx_2)
    end |> pretty |> dataflow |> unquote_literals
    arg_defs = map(((key, val),) -> :($key::$(maybe_typeof(val))), args)
    striplines(:(function $fname($(arg_defs...))
        @inbounds $(striplines(unblock(code)))
    end))
end

"""
    @finch_kernel [options...] fname(args...) = prgm

Return a definition for a function named `fname` which executes `@finch prgm` on
the arguments `args`. `args` should be a list of variables holding
representative argument instances or types.

See also: [`@finch`](@ref)
"""
macro finch_kernel(opts_def...)
    length(opts_def) >= 1 || throw(ArgumentError("expected at least one argument to @finch(opts..., def)"))
    (opts, def) = (opts_def[1:end-1], opts_def[end])
    (@capture def :function(:call(~name, ~args...), ~ex)) ||
    (@capture def :(=)(:call(~name, ~args...), ~ex)) ||
    throw(ArgumentError("unrecognized function definition in @finch_kernel"))
    named_args = map(arg -> :($(QuoteNode(arg)) => $(esc(arg))), args)
    prgm = FinchNotation.finch_parse_instance(ex)
    for arg in args
        prgm = quote    
            let $(esc(arg)) = $(FinchNotation.variable_instance(arg))
                $prgm
            end
        end
    end
    return quote
        $finch_kernel($(QuoteNode(name)), Any[$(named_args...),], typeof($prgm); $(map(esc, opts)...))
    end
end