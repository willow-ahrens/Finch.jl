execute(ex) = execute(ex, DefaultAlgebra())

@staged_function execute ex a quote
    @inbounds begin
        $(execute_code(:ex, ex, a()) |> unblock)
    end
end

function execute_code(ex, T, algebra = DefaultAlgebra())
    prgm = nothing
    code = contain(LowerJulia(algebra = algebra)) do ctx
        quote
            $(begin
                prgm = virtualize(ex, T, ctx)
                prgm = ScopeVisitor()(prgm)
                prgm = ThunkVisitor(ctx)(prgm) #TODO this is a bit of a hack.
                prgm = close_scope(prgm, LifecycleVisitor())
                prgm = dimensionalize!(prgm, ctx)
                prgm = simplify(prgm, ctx)
                #The following call separates tensor and index names from environment symbols.
                #TODO we might want to keep the namespace around, and/or further stratify index
                #names from tensor names
                contain(ctx) do ctx_2
                    prgm2 = prgm
                    if prgm.kind !== sequence
                        prgm2 = InstantiateTensors(ctx = ctx_2)(prgm2)
                    end
                    prgm2 = ThunkVisitor(ctx_2)(prgm2) #TODO this is a bit of a hack.
                    prgm2 = simplify(prgm2, ctx_2)
                    ctx_2(prgm2)
                end
            end)
            $(contain(ctx) do ctx_2
                :(($(map(getresults(prgm)) do tns
                    @assert tns.kind === variable
                    name = tns.name
                    tns = trim!(ctx.bindings[tns], ctx_2)
                    :($name = $(ctx_2(tns)))
                end...), ))
            end)
        end
    end
end

macro finch(args_ex...)
    @assert length(args_ex) >= 1
    (args, ex) = (args_ex[1:end-1], args_ex[end])
    results = Set()
    prgm = FinchNotation.finch_parse_instance(ex, results)
    res = esc(:res)
    thunk = quote
        res = $execute($prgm, $(map(esc, args)...))
    end
    for tns in results
        push!(thunk.args, quote
            $(esc(tns)) = get(res, $(QuoteNode(tns)), $(esc(tns))) #TODO can we do this better?
        end)
    end
    push!(thunk.args, quote
        res
    end)
    thunk
end

macro finch_code(args_ex...)
    @assert length(args_ex) >= 1
    (args, ex) = (args_ex[1:end-1], args_ex[end])
    prgm = FinchNotation.finch_parse_instance(ex)
    return quote
        $execute_code(:ex, typeof($prgm), $(map(esc, args)...)) |>
        striplines |>
        desugar |>
        propagate |>
        mark_dead |>
        prune_dead |>
        resugar |>
        unblock |>
        unquote_literals |>
        unresolve
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
    elseif node.kind === access && node.tns.kind === variable
        idxs = map(ctx, node.idxs)
        uses = get(ctx.scoped_uses, node.tns, ctx.global_uses)
        get(uses, node.tns, node.mode).kind !== node.mode.kind &&
            throw(LifecycleError("cannot mix reads and writes to $(node.tns) outside of defining scope (perhaps missing definition)"))
        uses[node.tns] = node.mode
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
