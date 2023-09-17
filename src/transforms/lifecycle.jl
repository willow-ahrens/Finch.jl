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
            prgm = block(prgm, freeze(tns))
        end
    end
    prgm
end

"""
    enforce_lifecycles(prgm)

A transformation which adds `freeze` and `thaw` statements automatically to
tensor roots, depending on whether they appear on the left or right hand side.
"""
function enforce_lifecycles(prgm)
    close_scope(prgm, LifecycleVisitor())
end

function open_stmt(prgm, ctx::LifecycleVisitor)
    for (tns, mode) in ctx.uses
        cur_mode = get(ctx.modes, tns, reader())
        if mode.kind === reader && cur_mode.kind === updater
            prgm = block(freeze(tns), prgm)
        elseif mode.kind === updater && cur_mode.kind === reader
            prgm = block(thaw(tns), prgm)
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
            node = block(freeze(node.tns), node)
        end
        ctx.modes[node.tns] = updater()
        node
    elseif node.kind === freeze
        haskey(ctx.modes, node.tns) || throw(LifecycleError("cannot freeze undefined $(node.tns)"))
        ctx.modes[node.tns].kind === reader && return block()
        ctx.modes[node.tns] = reader()
        node
    elseif node.kind === thaw
        get(ctx.modes, node.tns, reader()).kind === updater && return block()
        ctx.modes[node.tns] = updater()
        node
    elseif node.kind === assign
        return open_stmt(assign(ctx(node.lhs), ctx(node.op), ctx(node.rhs)), ctx)
    elseif node.kind === access
        idxs = map(ctx, node.idxs)
        uses = get(ctx.scoped_uses, getroot(node.tns), ctx.global_uses)
        get(uses, getroot(node.tns), node.mode).kind !== node.mode.kind &&
            throw(LifecycleError("cannot mix reads and writes to $(node.tns) outside of defining scope (hint: perhaps add a declaration like `var .= 0` or use an updating operator like `var += 1`)"))
        uses[getroot(node.tns)] = node.mode
        access(node.tns, node.mode, idxs...)
    elseif istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end
