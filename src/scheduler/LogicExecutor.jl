function simple_map(::Type{T}, f::F, args) where {T, F}
    res = Vector{T}(undef, length(args))
    for i in 1:length(args)
        res[i] = f(args[i])
    end
    res
end

"""
    get_structure(root::LogicNode)

Quickly produce a normalized structure for a logic program. Note: the result
will not be a runnable logic program, but can be hashed and compared for
equality. Two programs will have equal structure if their tensors have the same
type and their program structure is equivalent up to renaming.
"""
function get_structure(
    node::LogicNode,
    fields::Dict{Symbol, LogicNode}=Dict{Symbol, LogicNode}(),
    aliases::Dict{Symbol, LogicNode}=Dict{Symbol, LogicNode}())
    if node.kind === field
        get!(fields, node.name, immediate(length(fields) + length(aliases)))
    elseif node.kind === alias
        get!(aliases, node.name, immediate(length(fields) + length(aliases)))
    elseif node.kind === subquery
        if haskey(aliases, node.lhs.name)
            names[node.lhs]
        else
            subquery(get_structure(node.lhs, fields, aliases), get_structure(node.arg, fields, aliases))
        end
    elseif node.kind === table
        table(immediate(typeof(node.tns.val)), simple_map(LogicNode, idx -> get_structure(idx, fields, aliases), node.idxs))
    elseif istree(node)
        similarterm(node, operation(node), simple_map(LogicNode, arg -> get_structure(arg, fields, aliases), arguments(node)))
    else
        node
    end
end

"""
    LogicExecutor(ctx)

Executes a logic program by compiling it with the given compiler `ctx`. Compiled
codes are cached, and are only compiled once for each 
"""
struct LogicExecutor
    ctx
end

function logic_executor_code(prgm::LogicNode, ctx)
    ctx_2 = JuliaContext()
    freshen(ctx_2, :prgm)
    code = contain(ctx_2) do ctx_3
        prgm = defer_tables(:prgm, prgm)
        prgm = cache_deferred!(ctx_3, prgm)
        ctx.ctx(ctx_3, prgm)
    end
    code = pretty(code)
    fname = gensym(:compute)
    return :(function $fname(prgm)
            $code
        end) |> striplines
end

codes = Dict()
function (ctx::LogicExecutor)(prgm)
    f = get!(codes, get_structure(prgm)) do
        eval(logic_executor_code(prgm), ctx)
    end
    return Base.invokelatest(f, prgm)
end