@kwdef struct ScopeVisitor
    freshen = Freshen()
    vars = Dict(index(:(:)) => index(:(:)))
    scope = Set()
    global_scope = scope
end

"""
    enforce_scopes(prgm)

A transformation which gives all loops unique index names and enforces that
tensor roots are declared in a containing scope. Note that `loop` and `sieve`
both introduce new scopes.
"""
enforce_scopes(prgm) = ScopeVisitor()(prgm)

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
    elseif @capture node declare(~tns, ~init, ~fiber, ~shape...)
        push!(ctx.scope, tns)
        declare(ctx(tns), init, fiber, ctx(shape...))
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
