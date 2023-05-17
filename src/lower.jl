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

abstract type AbstractCompiler end

@kwdef mutable struct LowerJulia <: AbstractCompiler
    algebra = DefaultAlgebra()
    preamble::Vector{Any} = []
    bindings::Dict{Any, Any} = Dict()
    modes::Dict{Any, Any} = Dict()
    scope = Set()
    epilogue::Vector{Any} = []
    dims::Dict = Dict()
    freshen::Freshen = Freshen()
    shash = StaticHash()
    program_rules = get_program_rules(algebra, shash)
    bounds_rules = get_bounds_rules(algebra, shash)
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

function open_scope(prgm, ctx::LowerJulia)
    ctx_2 = shallowcopy(ctx)
    ctx_2.scope = Set()
    res = ctx_2(prgm)
    for tns in ctx_2.scope
        pop!(ctx_2.modes, tns, nothing)
    end
    res
end

function cache!(ctx, var, val)
    val = finch_leaf(val)
    isconstant(val) && return val
    var = ctx.freshen(var)
    val = simplify(val, ctx)
    push!(ctx.preamble, quote
        $var = $(contain(ctx_2 -> ctx_2(val), ctx))
    end)
    return cached(value(var, Any), literal(val))
end

function resolve(var, ctx::LowerJulia)
    if var isa FinchNode && (var.kind === variable || var.kind === index)
        return ctx.bindings[var]
    end
    return var
end

"""
    contain(f, ctx)

Call f on a subcontext of `ctx` and return the result. Variable bindings,
preambles, and epilogues defined in the subcontext will not escape the call to
contain.
"""
function contain(f, ctx::LowerJulia)
    ctx_2 = shallowcopy(ctx)
    preamble = Expr(:block)
    ctx_2.preamble = preamble.args
    epilogue = Expr(:block)
    ctx_2.epilogue = epilogue.args
    ctx_2.bindings = copy(ctx.bindings)
    body = f(ctx_2)
    if epilogue == Expr(:block)
        return quote
            $preamble
            $body
        end
    else
        res = ctx_2.freshen(:res)
        return quote
            $preamble
            $res = $body
            $epilogue
            $res
        end
    end

end

struct ThunkStyle end

@kwdef struct Thunk
    preamble = quote end
    body
    epilogue = quote end
end
FinchNotation.finch_leaf(x::Thunk) = virtual(x)

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

function (ctx::ThunkVisitor)(node::FinchNode)
    if node.kind === virtual
        ctx(node.val)
    elseif node.kind === access && node.tns.kind === virtual
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
    node.body(ctx.ctx)
end

"""
    InstantiateTensors(ctx)

A transformation to instantiate readers and updaters before executing an
expression

See also: [`declare!`](@ref)
"""
@kwdef struct InstantiateTensors{Ctx}
    ctx::Ctx
    escape = Set()
end

function (ctx::InstantiateTensors)(node)
    if istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end

function (ctx::InstantiateTensors)(node::FinchNode)
    if node.kind === sequence
        sequence(map(ctx, node.bodies)...)
    elseif node.kind === declare
        push!(ctx.escape, node.tns)
        node
    elseif node.kind === access && node.tns.kind === variable && !(node.tns in ctx.escape)
        tns = ctx.ctx.bindings[node.tns]
        protos = map(idx -> idx.kind === protocol ? idx.mode.val : nothing, node.idxs)
        idxs = map(idx -> idx.kind === protocol ? ctx(idx.idx) : ctx(idx), node.idxs)
        if node.mode.kind === reader
            get(ctx.ctx.modes, node.tns, reader()).kind === reader || throw(LifecycleError("Cannot read update-only $(node.tns) (perhaps same tensor on both lhs and rhs?)"))
            return access(get_reader(tns, ctx.ctx, protos...), node.mode, idxs...)
        else
            ctx.ctx.modes[node.tns].kind === updater || throw(LifecycleError("Cannot update read-only $(node.tns) (perhaps same tensor on both lhs and rhs?)"))
            return access(get_updater(tns, ctx.ctx, protos...), node.mode, idxs...)
        end
    elseif istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end

(ctx::LowerJulia)(root::Union{Symbol, Expr}, ::DefaultStyle) = root

function (ctx::LowerJulia)(root, ::DefaultStyle)
    node = finch_leaf(root)
    if node.kind === virtual
        error("don't know how to lower $root")
    end
    ctx(node)
end

function (ctx::LowerJulia)(root::FinchNode, ::DefaultStyle)
    if root.kind === value
        return root.val
    elseif root.kind === index
        @assert haskey(ctx.bindings, root) "index $(root) unbound"
        return ctx(ctx.bindings[root]) #This unwraps indices that are virtuals. Arguably these virtuals should be precomputed, but whatevs.
    elseif root.kind === literal
        if typeof(root.val) === Symbol ||
          typeof(root.val) === Expr ||
          typeof(root.val) === Missing
            return QuoteNode(root.val)
        else
            return root.val
        end
    elseif root.kind === sequence
        if isempty(root.bodies)
            return quote end
        else
            quote
                $(ctx(InstantiateTensors(ctx=ctx)(root.bodies[1])))
                $(contain(ctx) do ctx_2
                    (ctx_2)(sequence(root.bodies[2:end]...))
                end)
            end
        end
    elseif root.kind === declare
        @assert root.tns.kind === variable
        @assert get(ctx.modes, root.tns, reader()).kind === reader
        ctx.bindings[root.tns] = declare!(ctx.bindings[root.tns], ctx, root.init) #TODO should ctx.bindings be scoped?
        push!(ctx.scope, root.tns)
        ctx.modes[root.tns] = updater(create())
        quote end
    elseif root.kind === freeze
        @assert ctx.modes[root.tns].kind === updater
        ctx.bindings[root.tns] = freeze!(ctx.bindings[root.tns], ctx)
        ctx.modes[root.tns] = reader()
        quote end
    elseif root.kind === thaw
        @assert get(ctx.modes, root.tns, reader()).kind === reader
        ctx.bindings[root.tns] = thaw!(ctx.bindings[root.tns], ctx)
        ctx.modes[root.tns] = updater(modify())
        quote end
    elseif root.kind === forget
        @assert get(ctx.modes, root.tns, reader()).kind === reader
        delete!(ctx.modes, root.tns)
        quote end
    elseif root.kind === access
        if root.tns.kind === virtual
            return lowerjulia_access(ctx, root, root.tns.val)
        elseif root.tns.kind === variable
            return lowerjulia_access(ctx, root, resolve(root.tns, ctx))
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
    elseif root.kind === cached
        return ctx(root.arg)
    elseif root.kind === loop
        idx_sym = ctx.freshen(getname(root.idx))
        body = contain(ctx) do ctx_2
            ctx_2.bindings[root.idx] = value(idx_sym)
            body_3 = Rewrite(Postwalk(
                @rule access(~a::isvirtual, ~m, ~i..., ~j) => begin
                    a_2 = get_point_body(a.val, ctx_2, value(idx_sym))
                    if a_2 != nothing
                        access(a_2, m, i...)
                    else
                        access(a, m, i..., j)
                    end
                end
            ))(root.body)
            open_scope(body_3, ctx_2)
        end
        @assert isvirtual(root.ext)
        if query(call(==, measure(root.ext.val), 1), ctx)
            return quote
                $idx_sym = $(ctx(getstart(root.ext)))
                $body
            end
        else
            return quote
                for $idx_sym = $(ctx(getstart(root.ext))):$(ctx(getstop(root.ext)))
                    $body
                end
            end
        end
    elseif root.kind === sieve
        cond = ctx.freshen(:cond)
        push!(ctx.preamble, :($cond = $(ctx(root.cond))))
    
        return quote
            if $cond
                $(contain(ctx) do ctx_2
                    open_scope(root.body, ctx_2)
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
    elseif root.kind === variable
        error()
        return ctx(ctx.bindings[root])
    else
        error("unimplemented ($root)")
    end
end

function lowerjulia_access(ctx, node, tns)
    idxs = map(ctx, node.idxs)
    :($(ctx(tns))[$(idxs...)])
end

function lowerjulia_access(ctx, node, tns::Number)
    @assert node.mode.kind === reader
    tns
end

@kwdef struct Lookup
    body
end

Base.show(io::IO, ex::Lookup) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Lookup)
    print(io, "Lookup()")
end

FinchNotation.finch_leaf(x::Lookup) = virtual(x)

get_point_body(node, ctx, idx) = nothing
get_point_body(node::Lookup, ctx, idx) = node.body(ctx, idx)