struct Freshen
    seen
    counts
end
Freshen() = Freshen(Set(), Dict())
function (spc::Freshen)(tags...)
    name = Symbol(tags...)
    m = match(r"^(.*)_(\d*)$", string(name))
    if m === nothing
        tag = name
        n = 1
    else
        tag = Symbol(m.captures[1])
        n = parse(BigInt, m.captures[2])
    end
    if (tag, n) in spc.seen
        n = max(get(spc.counts, tag, 0), n) + 1
        spc.counts[tag] = n
    end
    push!(spc.seen, (tag, n))
    if n == 1
        return Symbol(tag)
    else
        return Symbol(tag, :_, n)
    end
end

@kwdef mutable struct LowerJulia
    algebra = DefaultAlgebra()
    preamble::Vector{Any} = []
    bindings::Dict{Any, Any} = Dict()
    epilogue::Vector{Any} = []
    dims::Dict = Dict()
    freshen::Freshen = Freshen()
    shash = StaticHash()
end

struct StaticHash
    counts::Dict{Any, Int}
end
StaticHash() = StaticHash(Dict{Any, Int}())

function (h::StaticHash)(x)
    if haskey(h.counts, x)
        return h.counts[x]
    else
        return (h.counts[x] = UInt(length(h.counts)))
    end
end

(ctx::LowerJulia)(root) = ctx(root, Stylize(root, ctx)(root))
#function(ctx::LowerJulia)(root)
#    style = Stylize(root, ctx)(root)
#    @info :lower root style
#    ctx(root, style)
#end

function cache!(ctx, var, val)
    if isliteral(val)
        return val
    end
    body = contain(ctx) do ctx_2
        ctx(val)
    end
    if body isa Symbol
        return body
    else
        var = ctx.freshen(var)
        push!(ctx.preamble, Expr(:cache, var,
        quote
            $var = $body
        end))
        return value(var, Any) #TODO could we do better here?
    end
end

bind(f, ctx::LowerJulia) = f()
function bind(f, ctx::LowerJulia, (var, val′), tail...)
    if haskey(ctx.bindings, var)
        val = ctx.bindings[var]
        ctx.bindings[var] = val′
        res = bind(f, ctx, tail...)
        ctx.bindings[var] = val
        return res
    else
        ctx.bindings[var] = val′
        res = bind(f, ctx, tail...)
        pop!(ctx.bindings, var)
        return res
    end
end

function contain(f, ctx::LowerJulia)
    ctx_2 = shallowcopy(ctx)
    ctx_2.preamble = []
    ctx_2.epilogue = []
    body = f(ctx_2)
    thunk = Expr(:block)
    append!(thunk.args, ctx_2.preamble)
    if isempty(ctx_2.epilogue)
        push!(thunk.args, body)
    else
        res = ctx_2.freshen(:res)
        push!(thunk.args, Expr(:cleanup, res, body, Expr(:block, ctx_2.epilogue...)))
    end
    return thunk
end

struct ThunkStyle end

@kwdef struct Thunk
    preamble = quote end
    body
    epilogue = quote end
    binds = ()
end
IndexNotation.isliteral(::Thunk) =  false

Base.show(io::IO, ex::Thunk) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Thunk)
    print(io, "Thunk()")
end

(ctx::Stylize{LowerJulia})(node::Thunk) = ThunkStyle()
combine_style(a::DefaultStyle, b::ThunkStyle) = ThunkStyle()
combine_style(a::ThunkStyle, b::ThunkStyle) = ThunkStyle()

struct ThunkVisitor
    ctx
end

function (ctx::ThunkVisitor)(node)
    if istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end

function (ctx::LowerJulia)(node, ::ThunkStyle)
    contain(ctx) do ctx2
        node = (ThunkVisitor(ctx2))(node)
        contain(ctx2) do ctx3
            (ctx3)(node)
        end
    end
end

function (ctx::ThunkVisitor)(node::IndexNode)
    if node.kind === virtual
        ctx(node.val)
    elseif node.kind === access && node.tns isa IndexNode && node.tns.kind === virtual
        #TODO this case morally shouldn't exist
        thunk_access(node, ctx, node.tns.val)
    elseif istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end

thunk_access(node, ctx, tns) = similarterm(node, operation(node), map(ctx, arguments(node)))

function (ctx::ThunkVisitor)(node::Thunk)
    push!(ctx.ctx.preamble, node.preamble)
    push!(ctx.ctx.epilogue, node.epilogue)
    for (var, val) in node.binds
        define!(ctx.ctx, var, val)
    end
    node.body
end

IndexNotation.isliteral(::Union{Symbol, Expr, Missing}) =  false
(ctx::LowerJulia)(root::Union{Symbol, Expr}, ::DefaultStyle) = root

function (ctx::LowerJulia)(root, ::DefaultStyle)
    if isliteral(root)
        return getvalue(root)
    end
    error("Don't know how to lower $root")
end

function (ctx::LowerJulia)(root::IndexNode, ::DefaultStyle)
    if root.kind === value
        return root.val
    elseif root.kind === index
        @assert haskey(ctx.bindings, getname(root)) "variable $(getname(root)) unbound"
        return ctx(ctx.bindings[getname(root)]) #This unwraps indices that are virtuals. Arguably these virtuals should be precomputed, but whatevs.
    elseif root.kind === literal
        if typeof(root.val) === Symbol ||
          typeof(root.val) === Expr ||
          typeof(root.val) === Missing
            return QuoteNode(root.val)
        else
            return root.val
        end
    elseif root.kind === with
        prod = nothing
        target = map(getname, getresults(root.prod))
        return quote
            $(contain(ctx) do ctx_2
                prod = Initialize(ctx = ctx_2, target=target)(root.prod)
                (ctx_2)(prod)
            end)
            $(contain(ctx) do ctx_2
                Finalize(ctx = ctx_2, target=target)(prod)
                cons = Initialize(ctx = ctx_2, target=target)(root.cons)
                res = (ctx_2)(cons)
                Finalize(ctx = ctx_2, target=target)(cons)
                res
            end)
        end
    elseif root.kind === multi
        thunk = Expr(:block)
        for body in root.bodies
            push!(thunk.args, quote
                $(contain(ctx) do ctx_2
                    (ctx_2)(body)
                end)
            end)
        end
        thunk
    elseif root.kind === access
        if root.tns isa IndexNode && root.tns.kind === virtual
            return lowerjulia_access(ctx, root, root.tns.val)
        else
            tns = ctx(root.tns)
            idxs = map(ctx, root.idxs)
            return :($(ctx(tns))[$(idxs...)])
        end
    elseif root.kind === protocol
        :($(ctx(root.idx)))
    elseif root.kind === call
        if root.op == literal(and)
            if isempty(root.args)
                return true
            else
                reduce((x, y) -> :($x && $y), map(ctx, root.args)) #TODO This could be better. should be able to handle empty case
            end
        elseif root.op == literal(or)
            if isempty(root.args)
                return false
            else
                reduce((x, y) -> :($x || $y), map(ctx, root.args))
            end
        else
            :($(ctx(root.op))($(map(ctx, root.args)...)))
        end
    elseif root.kind === loop
        return ctx(simplify(chunk(
            root.idx,
            resolvedim(ctx.dims[getname(root.idx)]),
            root.body),
            ctx))
    elseif root.kind === chunk
        idx_sym = ctx.freshen(getname(root.idx))
        if simplify((@f $(getlower(root.ext)) >= 1), ctx) == (@f true)  && simplify((@f $(getupper(root.ext)) <= 1), ctx) == (@f true)
            return quote
                $idx_sym = $(ctx(getstart(root.ext)))
                $(bind(ctx, getname(root.idx) => idx_sym) do 
                    contain(ctx) do ctx_2
                        body_3 = ForLoopVisitor(ctx_2, root.idx, value(idx_sym))(root.body)
                        (ctx_2)(body_3)
                    end
                end)
            end
        else
            return quote
                for $idx_sym = $(ctx(getstart(root.ext))):$(ctx(getstop(root.ext)))
                    $(bind(ctx, getname(root.idx) => idx_sym) do 
                        contain(ctx) do ctx_2
                            body_3 = ForLoopVisitor(ctx_2, root.idx, value(idx_sym))(root.body)
                            (ctx_2)(body_3)
                        end
                    end)
                end
            end
        end
    elseif root.kind === sieve
        cond = ctx.freshen(:cond)
        push!(ctx.preamble, :($cond = $(ctx(root.cond))))
    
        return quote
            if $cond
                $(contain(ctx) do ctx_2
                    ctx_2(root.body)
                end)
            end
        end
    elseif root.kind === virtual
        ctx(root.val)
    elseif root.kind === assign
        if root.lhs.kind === access
            @assert root.lhs.mode.kind == updater
            rhs = ctx(simplify(call(root.op, root.lhs, root.rhs), ctx))
        else
            rhs = ctx(root.rhs)
        end
        lhs = ctx(root.lhs)
        return :($lhs = $rhs)
    elseif root.kind === pass
        return quote end
    else
        error("unimplemented")
    end
end

function lowerjulia_access(ctx, node, tns)
    tns = ctx(tns)
    idxs = map(ctx, node.idxs)
    :($(ctx(tns))[$(idxs...)])
end

function lowerjulia_access(ctx, node, tns::Number)
    @assert node.mode.kind === reader
    tns
end

@kwdef struct ForLoopVisitor
    ctx
    idx
    val
end

function (ctx::ForLoopVisitor)(node)
    if istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end

function (ctx::ForLoopVisitor)(node::IndexNode)
    if node.kind === access && node.tns isa IndexNode && node.tns.kind === virtual
        tns_2 = unchunk(node.tns.val, ctx)
        if tns_2 === nothing
            access(node.tns, node.mode, map(ctx, node.idxs)...)
        else
            access(tns_2, node.mode, map(ctx, node.idxs[2:end])...)
        end
    elseif istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end

@kwdef struct Lookup
    val = nothing
    body
end

default(ex::Lookup) = something(ex.val)

Base.show(io::IO, ex::Lookup) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Lookup)
    print(io, "Lookup()")
end

IndexNotation.isliteral(node::Lookup) =  false

function (ctx::ForLoopVisitor)(node::Lookup)
    node.body(ctx.val)
end

unchunk(node, ctx) = nothing
unchunk(node::Lookup, ctx::ForLoopVisitor) = node.body(ctx.val)