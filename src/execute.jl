execute(ex) = execute(ex, DefaultAlgebra())
function register(algebra)
    Base.eval(Finch, quote
        @generated function execute(ex, a::$algebra)
            execute_code(:ex, ex, a())
        end
    end)
end

function execute_code(ex, T, algebra = DefaultAlgebra())
    prgm = nothing
    code = contain(LowerJulia(algebra = algebra)) do ctx
        quote
            $(begin
                prgm = virtualize(ex, T, ctx)
                prgm = TransformSSA(Freshen())(prgm)
                prgm = ThunkVisitor(ctx)(prgm) #TODO this is a bit of a hack.
                (prgm, dims) = dimensionalize!(prgm, ctx)
                lctx = LifecycleVisitor()
                prgm = enscope(ctx_2->ctx_2(prgm), lctx)
                display(prgm)
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
                :(($(map(sort(collect(lctx.scope))) do tns
                    @assert acc.tns.kind === variable
                    name = acc.tns.name
                    tns = trim!(ctx.bindings[acc.tns], ctx_2)
                    :($name = $(ctx_2(tns)))
                end...), ))
            end)
        end
    end
    #=
    code = quote
        @inbounds begin
            $code
        end
    end
    =#
    code = code |>
        lower_caches |>
        lower_cleanup
    #quote
    #    println($(QuoteNode(code |>         striplines |>
    #    unblock |>
    #    unquote_literals)))
    #    $code
    #end
end

macro finch(args_ex...)
    @assert length(args_ex) >= 1
    (args, ex) = (args_ex[1:end-1], args_ex[end])
    results = Set()
    prgm = FinchNotation.finch_parse_instance(ex, results)
    thunk = quote
        res = $execute($prgm, $(map(esc, args)...))
    end
    for tns in results
        push!(thunk.args, quote
            $(esc(tns)) = res.$tns
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
        unblock |>
        unquote_literals
    end
end

"""
    declare!(tns, ctx, init)

Declare the read-only virtual tensor `tns` in the context `ctx` with a starting value of `init` and return it.
Afterwards the tensor is update-only.
"""
declare!(tns, ctx, init) = @assert virtual_default(tns) == init

"""
    get_reader(tns, ctx, protos...)
    
Return an object (usually a looplet nest) capable of reading the read-only
virtual tensor `tns`.  As soon as a read-only tensor enters scope, each
subsequent read access will be initialized with a separate call to
`get_reader`. `protos` is the list of protocols in each case.
"""
get_reader(tns, ctx, protos...) = tns

"""
    get_updater(tns, ctx, protos...)
    
Return an object (usually a looplet nest) capable of updating the update-only
virtual tensor `tns`.  As soon as an update only tensor enters scope, each
subsequent update access will be initialized with a separate call to
`get_updater`.  `protos` is the list of protocols in each case.
"""
get_updater(tns, ctx, protos...) = tns

"""
    freeze!(tns, ctx)

Freeze the update-only virtual tensor `tns` in the context `ctx` and return it.
Afterwards, the tensor is read-only.
"""
freeze!(tns, ctx) = tns

"""
    thaw!(tns, ctx)

Thaw the read-only virtual tensor `tns` in the context `ctx` and return it. Afterwards,
the tensor is update-only.
"""
thaw!(tns, ctx) = tns

"""
    trim!(tns, ctx)

Before returning a tensor from the finch program, trim any excess overallocated memory.
"""
trim!(tns, ctx) = tns

@kwdef mutable struct LifecycleVisitor
    modes = Dict()
end

struct LifecycleError
    msg
end

function enscope(prgm, ctx::LifecycleVisitor)
    ctx.modes = ScopeDict(ctx.modes)
    ctx.reqs = ScopeDict(ctx.reqs)
    prgm = ctx(prgm)
    prgm = process_reqs(prgm, ctx)
    ctx.reqs = ctx.reqs.parent
    ctx.modes = ctx.modes.parent
end

function (prgm, ctx::LifecycleVisitor)
    for (tns, mode) in ctx.reqs.data
        if mode.kind == reader && get(ctx.modes, tns, reader()) == updater
            prgm = sequence(freeze(tns), prgm)
            ctx.modes[end][tns] = reader()
        elseif mode.kind == updater && ctx_mode.kind == reader
            prgm = sequence(thaw(tns), prgm)
            ctx.modes[end][tns] = updater(create())
        end
    end
    empty!(ctx.reqs[end])
end

function (ctx::LifecycleVisitor)(node::FinchNode)
    if node.kind === loop
        enscope(ctx) do ctx_2
            loop(node.idx, ctx_2(node.body))
        end
    elseif node.kind === sieve
        enscope(ctx) do ctx_2
            sieve(ctx(node.cond), ctx_2(body))
        end
    elseif node.kind === declare
        tns = node.tns
        ctx.stack[tns] = length(ctx.modes)
        !haskey(ctx.stack, tns) || ctx.modes[ctx.stack[tns]][tns] == reader() || (node = sequence(freeze(tns), node))
        ctx.modes[end] = updater(create())
        push!(ctx.scope, node.tns)
        node
    elseif node.kind === freeze
        haskey(ctx.modes, node.tns) && ctx.modes[node.tns] == reader() && return sequence()
        ctx.modes[node.tns] = reader()
        node
    elseif node.kind === thaw
        haskey(ctx.modes, node.tns) && ctx.modes[node.tns].kind == updater && return sequence()
        ctx.modes[node.tns] = updater(create())
        node
    elseif node.kind === sequence
        res = sequence()
        for body in node.bodies
            body_2 = ctx(body)
            empty!(ctx.reqs)
        end
        res
    if node.kind === assign && node.tns.kind === variable
    elseif node.kind === access && node.tns.kind === variable
        idxs = map(ctx, node.idxs)
        haskey(ctx.reqs, node.tns) && ctx.reqs[node.tns].kind !== node.mode.kind &&
            throw(LifecycleError("combined read and update $(node.tns) used on lhs and rhs"))
        ctx.reqs[node.tns] = node.mode
        println(ctx.reqs)
        access(node.tns, node.mode, idxs...)
    elseif istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end