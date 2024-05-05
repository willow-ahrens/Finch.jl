"""
    defer_tables(root::LogicNode)

Replace immediate tensors with deferred expressions assuming the original program structure
is given as input to the program.
"""
function defer_tables(ex, node::LogicNode)
    if @capture node table(~tns::isimmediate, ~idxs...)
        table(deferred(:($ex.tns.val), typeof(tns.val)), map(enumerate(node.idxs)) do (i, idx)
            defer_tables(:($ex.idxs[$i]), idx)
        end)
    elseif istree(node)
        similarterm(node, operation(node), map(enumerate(node.children)) do (i, child)
            defer_tables(:($ex.children[$i]), child)
        end)
    else
        node
    end
end

"""
    cache_deferred(ctx, root::LogicNode, seen)

Replace deferred expressions with simpler expressions, and cache their evaluation in the preamble.
"""
function cache_deferred!(ctx, root::LogicNode)
    seen::Dict{Any, LogicNode} = Dict{Any, LogicNode}()
    return Rewrite(Postwalk(node -> if isdeferred(node)
        get!(seen, node.val) do
            var = freshen(ctx, :V)
            push!(ctx.preamble, :($var = $(node.ex)::$(node.type)))
            deferred(var, node.type)
        end
    end))(root)
end

function logic_executor_code(ctx, prgm)
    ctx_2 = JuliaContext()
    freshen(ctx_2, :prgm)
    code = contain(ctx_2) do ctx_3
        prgm = defer_tables(:prgm, prgm)
        prgm = cache_deferred!(ctx_3, prgm)
        ctx(prgm)
    end
    code = pretty(code)
    fname = gensym(:compute)
    return :(function $fname(prgm)
            $code
        end) |> striplines
end

"""
    LogicExecutor(ctx)

Executes a logic program by compiling it with the given compiler `ctx`. Compiled
codes are cached, and are only compiled once for each program with the same
structure.
"""
struct LogicExecutor end

codes = Dict()
function (ctx::LogicExecutor)(prgm)
    f = get!(codes, get_structure(prgm)) do
        eval(logic_executor_code(ctx.ctx, prgm))
    end
    return Base.invokelatest(f, prgm)
end

"""
    LogicExecutorCode(ctx)

Return the code that would normally be used by the LogicExecutor to run a program.
"""
struct LogicExecutorCode end

function (ctx::LogicExecutorCode)(prgm)
    return logic_executor_code(ctx.ctx, prgm)
end