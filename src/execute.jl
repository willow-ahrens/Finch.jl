abstract type CompileMode end

struct DebugFinch <: CompileMode end
const debugfinch = DebugFinch()
virtualize(ctx, ex, ::Type{DebugFinch}) = DebugFinch()

struct SafeFinch <: CompileMode end
const safefinch = SafeFinch()
virtualize(ctx, ex, ::Type{SafeFinch}) = SafeFinch()

struct FastFinch <: CompileMode end
const fastfinch = FastFinch()
virtualize(ctx, ex, ::Type{FastFinch}) = FastFinch()

issafe(::DebugFinch) = true
issafe(::SafeFinch) = true
issafe(::FastFinch) = false

"""
    instantiate!(ctx, prgm)

A transformation to instantiate readers and updaters before executing an
expression.
"""
function instantiate!(ctx, prgm) 
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
        protos = [(mode.val === reader ? defaultread : defaultupdate) for _ in idxs]
        tns_2 = instantiate(ctx.ctx, tns, mode.val, protos)
        access(tns_2, mode, idxs...)
    elseif istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end

execute(ex) = execute(ex, NamedTuple())

@staged function execute(ex, opts)
    contain(JuliaContext()) do ctx
        code = execute_code(:ex, ex; virtualize(ctx, :opts, opts)...)
        quote
            @inbounds @fastmath begin
                $(code |> unblock)
            end
        end
    end
end

function execute_code(ex, T; algebra = DefaultAlgebra(), mode = safefinch, ctx = LowerJulia(algebra = algebra, mode=mode))
    contain(ctx) do ctx_2
        prgm = virtualize(ctx_2.code, ex, T)
        lower_global(ctx_2, prgm)
    end
end

"""
    lower_global(ctx, prgm)

Lower the program `prgm` at global scope in the context `ctx`.
"""
function lower_global(ctx, prgm)
    prgm = enforce_scopes(prgm)
    prgm = evaluate_partial(ctx, prgm)
    code = contain(ctx) do ctx_2
        quote
            $(ctx.needs_return) = true
            $(ctx.result) = nothing
            $(begin
                prgm = wrapperize(ctx_2, prgm)
                prgm = enforce_lifecycles(prgm)
                prgm = dimensionalize!(prgm, ctx_2)
                prgm = concordize(ctx_2, prgm)
                prgm = evaluate_partial(ctx_2, prgm)
                prgm = simplify(ctx_2, prgm) # Appears necessary
                prgm = instantiate!(ctx_2, prgm)
                contain(ctx_2) do ctx_3
                    ctx_3(prgm)
                end
            end)
            $(ctx.result)
        end
    end
end

macro finch(opts_ex...)
    length(opts_ex) >= 1 || throw(ArgumentError("Expected at least one argument to @finch(opts..., ex)"))
    (opts, ex) = (opts_ex[1:end-1], opts_ex[end])
    prgm = FinchNotation.finch_parse_instance(ex)
    prgm = :(
        $(FinchNotation.block_instance)(
            $prgm,
            $(FinchNotation.yieldbind_instance)(
                $(map(FinchNotation.variable_instance, FinchNotation.finch_parse_default_yieldbind(ex))...)
            )
        )
    )
    res = esc(:res)
    thunk = quote
        res = $execute($prgm, (;$(map(esc, opts)...),))
    end
    for tns in something(FinchNotation.finch_parse_yieldbind(ex), FinchNotation.finch_parse_default_yieldbind(ex))
        push!(thunk.args, quote
            $(esc(tns)) = res[$(QuoteNode(tns))]
        end)
    end
    push!(thunk.args, quote
        res
    end)
    thunk
end

macro finch_code(opts_ex...)
    length(opts_ex) >= 1 || throw(ArgumentError("Expected at least one argument to @finch(opts..., ex)"))
    (opts, ex) = (opts_ex[1:end-1], opts_ex[end])
    prgm = FinchNotation.finch_parse_instance(ex)
    prgm = :(
        $(FinchNotation.block_instance)(
            $prgm,
            $(FinchNotation.yieldbind_instance)(
                $(map(FinchNotation.variable_instance, FinchNotation.finch_parse_default_yieldbind(ex))...)
            )
        )
    )
    return quote
        $execute_code(:ex, typeof($prgm); $(map(esc, opts)...)) |> pretty |> unresolve |> dataflow |> unquote_literals
    end
end

function finch_kernel(fname, args, prgm; algebra = DefaultAlgebra(), mode = safefinch, ctx = LowerJulia(algebra=algebra, mode=mode))
    maybe_typeof(x) = x isa Type ? x : typeof(x)
    code = contain(ctx) do ctx_2
        foreach(args) do (key, val)
            ctx_2.bindings[variable(key)] = finch_leaf(virtualize(ctx_2.code, key, maybe_typeof(val), key))
        end
        execute_code(:UNREACHABLE, prgm, algebra = algebra, mode = mode, ctx = ctx_2)
    end |> pretty |> unresolve |> dataflow |> unquote_literals
    arg_defs = map(((key, val),) -> :($key::$(maybe_typeof(val))), args)
    striplines(:(function $fname($(arg_defs...))
        @inbounds @fastmath $(striplines(unblock(code)))
    end))
end

macro finch_kernel(opts_def...)
    length(opts_def) >= 1 || throw(ArgumentError("expected at least one argument to @finch(opts..., def)"))
    (opts, def) = (opts_def[1:end-1], opts_def[end])
    (@capture def :function(:call(~name, ~args...), ~ex)) ||
    (@capture def :(=)(:
