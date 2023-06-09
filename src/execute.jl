execute(ex) = execute(ex, DefaultAlgebra())

@staged function execute(ex, a)
    quote
        @inbounds begin
            $(execute_code(:ex, ex, a()) |> unblock)
        end
    end
end


function execute_code(ex, T, algebra = DefaultAlgebra(); ctx = LowerJulia(algebra = algebra))
    code = contain(ctx) do ctx_2
        prgm = nothing
        prgm = virtualize(ex, T, ctx_2)
        lower_global(prgm, ctx_2)
    end
end

"""
    lower_global(prgm, ctx)

lower the program `prgm` at global scope in the context `ctx`.
"""
function lower_global(prgm, ctx)
    code = contain(ctx) do ctx_2
        quote
            $(begin
                prgm = ScopeVisitor()(prgm)
                prgm = wrapperize(prgm, ctx_2)
                prgm = close_scope(prgm, LifecycleVisitor())
                prgm = dimensionalize!(prgm, ctx_2)
                prgm = simplify(prgm, ctx_2) #appears necessary
                contain(ctx_2) do ctx_3
                    ctx_3(prgm)
                end
            end)
            $(contain(ctx_2) do ctx_3
                :(($(map(getresults(prgm)) do tns
                    @assert tns.kind === variable
                    name = tns.name
                    tns = trim!(ctx_2.bindings[tns], ctx_3)
                    :($name = $(ctx_3(tns)))
                end...), ))
            end)
        end
    end
end

"""
    @finch [algebra] prgm

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

See also: [`@finch_code`](@ref)
"""
macro finch(opts_ex...)
    length(opts_ex) >= 1 || throw(ArgumentError("Expected at least one argument to @finch(opts..., ex)"))
    (opts, ex) = (opts_ex[1:end-1], opts_ex[end])
    results = Set()
    prgm = FinchNotation.finch_parse_instance(ex, results)
    res = esc(:res)
    thunk = quote
        res = $execute($prgm, $(map(esc, opts)...))
    end
    for tns in results
        push!(thunk.args, quote
            $(esc(tns)) = get(res, $(QuoteNode(tns)), $(esc(tns)))
        end)
    end
    push!(thunk.args, quote
        res
    end)
    thunk
end

"""
@finch_code [options...] prgm

Return the code that would be executed in order to run a finch program `prgm`
with the given options.

See also: [`@finch`](@ref)
"""
macro finch_code(opts_ex...)
    length(opts_ex) >= 1 || throw(ArgumentError("Expected at least one argument to @finch(opts..., ex)"))
    (opts, ex) = (opts_ex[1:end-1], opts_ex[end])
    prgm = FinchNotation.finch_parse_instance(ex)
    return quote
        $execute_code(:ex, typeof($prgm), $(map(esc, opts)...)) |> pretty |> dataflow |> unresolve |> unquote_literals
    end
end

"""
    finch_kernel(fname, args, prgm, ctx = LowerJulia())

Return a function definition for which can execute a Finch program of
type `prgm`. Here, `fname` is the name of the function and `args` is a
`iterable` of argument name => type pairs.
"""
function finch_kernel(fname, args, prgm, algebra = DefaultAlgebra(); ctx = LowerJulia(algebra=algebra))
    maybe_typeof(x) = x isa Type ? x : typeof(x)
    code = contain(ctx) do ctx_2
        foreach(args) do (key, val)
            ctx_2.bindings[variable(key)] = virtualize(key, maybe_typeof(val), ctx_2, key)
        end
        execute_code(:TODO, maybe_typeof(prgm), ctx = ctx_2)
    end |> pretty |> dataflow |> unquote_literals
    arg_defs = map(((key, val),) -> :($key::$(maybe_typeof(val))), args)
    striplines(:(function $fname($(arg_defs...))
        @inbounds $(striplines(unblock(code)))
    end))
end

"""
    @finch_kernel [options] fname(args...) = prgm

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
    return quote
        $finch_kernel($(QuoteNode(name)), Any[$(named_args...),], typeof($prgm), $(map(esc, opts)...))
    end
end

@kwdef struct LifecycleVisitor
    uses = OrderedDict()
    scoped_uses = Dict()
    global_uses = uses
    modes = Dict()
end

struct LifecycleError
    msg
end

function open_scope(prgm, ctx::LifecycleVisitor)
    ctx_2 = LifecycleVisitor(;kwfields(ctx)..., uses=Dict())
    close_scope(prgm, ctx_2)
end

function close_scope(prgm, ctx::LifecycleVisitor)
    prgm = ctx(prgm)
    for tns in getresults(prgm)
        if ctx.modes[tns].kind !== reader
            prgm = sequence(prgm, freeze(tns))
        end
    end
    prgm
end

function open_stmt(prgm, ctx::LifecycleVisitor)
    for (tns, mode) in ctx.uses
        cur_mode = get(ctx.modes, tns, reader())
        if mode.kind === reader && cur_mode.kind === updater
            prgm = sequence(freeze(tns), prgm)
        elseif mode.kind === updater && cur_mode.kind === reader
            prgm = sequence(thaw(tns), prgm)
        end
        ctx.modes[tns] = mode
    end
    empty!(ctx.uses)
    prgm
end

function (ctx::LifecycleVisitor)(node::FinchNode)
    if node.kind === loop 
        open_stmt(loop(node.idx, ctx(node.ext), open_scope(node.body, ctx)), ctx)
    elseif node.kind === sieve
        open_stmt(sieve(ctx(node.cond), open_scope(node.body, ctx)), ctx)
    elseif node.kind === declare
        ctx.scoped_uses[node.tns] = ctx.uses
        if get(ctx.modes, node.tns, reader()) === updater 
            node = sequence(freeze(node.tns), node)
        end
        ctx.modes[node.tns] = updater(create())
        node
    elseif node.kind === freeze
        haskey(ctx.modes, node.tns) || throw(LifecycleError("cannot freeze undefined $(node.tns)"))
        ctx.modes[node.tns].kind === reader && return sequence()
        ctx.modes[node.tns] = reader()
        node
    elseif node.kind === thaw
        get(ctx.modes, node.tns, reader()).kind === updater && return sequence()
        ctx.modes[node.tns] = updater(create())
        node
    elseif node.kind === assign
        return open_stmt(assign(ctx(node.lhs), ctx(node.op), ctx(node.rhs)), ctx)
    elseif node.kind === access
        idxs = map(ctx, node.idxs)
        uses = get(ctx.scoped_uses, getroot(node.tns), ctx.global_uses)
        get(uses, getroot(node.tns), node.mode).kind !== node.mode.kind &&
            throw(LifecycleError("cannot mix reads and writes to $(node.tns) outside of defining scope (perhaps missing definition)"))
        uses[getroot(node.tns)] = node.mode
        access(node.tns, node.mode, idxs...)
    elseif istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end

@kwdef struct ScopeVisitor
    freshen = Freshen()
    vars = Dict(index(:(:)) => index(:(:)))
    scope = Set()
    global_scope = scope
end

struct ScopeError
    msg
end

function open_scope(prgm, ctx::ScopeVisitor)
    prgm = ScopeVisitor(;kwfields(ctx)..., vars=copy(ctx.vars), scope = Set())(prgm)
end

function (ctx::ScopeVisitor)(node::FinchNode)
    if @capture node loop(~idx, ~ext, ~body)
        ctx.vars[idx] = index(ctx.freshen(idx.name))
        loop(ctx(idx), ctx(ext), open_scope(body, ctx))
    elseif @capture node sieve(~cond, ~body)
        sieve(ctx(cond), open_scope(body, ctx))
    elseif @capture node declare(~tns, ~init)
        push!(ctx.scope, tns)
        declare(ctx(tns), init)
    elseif @capture node freeze(~tns)
        node.tns in ctx.scope || ctx.scope === ctx.global_scope || throw(ScopeError("cannot freeze $tns not defined in this scope"))
        freeze(ctx(tns))
    elseif @capture node thaw(~tns)
        node.tns in ctx.scope || ctx.scope === ctx.global_scope || throw(ScopeError("cannot thaw $tns not defined in this scope"))
        thaw(ctx(tns))
    elseif node.kind === variable
        if !(node in ctx.scope)
            push!(ctx.global_scope, node)
        end
        node
    elseif node.kind === index
        haskey(ctx.vars, node) || throw(ScopeError("unbound index $node"))
        ctx.vars[node]
    elseif istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end
