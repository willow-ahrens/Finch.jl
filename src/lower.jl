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

struct Scalar
    name
    val
end

@kwdef mutable struct LowerJulia <: AbstractVisitor
    preamble::Vector{Any} = []
    bindings::Dict{Any, Any} = Dict()
    epilogue::Vector{Any} = []
    dims::Dimensions = Dimensions()
    freshen::Freshen = Freshen()
    state::Dict{Any, Any} = Dict()
    defs::Set{Any} = Set()
end

function define!(ctx, var, val)
    if !haskey(ctx.state, var)
        push!(ctx.defs, var)
    end
    ctx.state[var] = val
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

restrict(f, ctx::LowerJulia) = f()
function restrict(f, ctx::LowerJulia, (idx, ext′), tail...)
    @assert haskey(ctx.dims, idx)
    ext = ctx.dims[idx]
    ctx.dims[idx] = ext′
    res = restrict(f, ctx, tail...)
    ctx.dims[idx] = ext
    return res
end

function scope(f, ctx)
    ctx_2 = shallowcopy(ctx)
    ctx_2.defs = Set()
    res = f(ctx_2)
    for var in ctx_2.defs
        delete!(ctx.state, var)
    end
    res
end

function fixpoint(f, ctx)
    res = nothing
    while true
        ctx_2 = diverge(ctx)
        res = contain(f, ctx_2)
        if ctx_2.state == ctx.state
            unify!(ctx, ctx_2)
            break
        else
            unify!(ctx, ctx_2)
        end
    end
    return res
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
        push!(thunk.args, :($res = $body))
        append!(thunk.args, ctx_2.epilogue)
        push!(thunk.args, res)
    end
    return thunk
end

function diverge(ctx::LowerJulia)
    ctx_2 = shallowcopy(ctx)
    ctx_2.state = deepcopy(ctx.state)
    return ctx_2
end

function unify!(ctx::LowerJulia, ctx_2)
    merge!(union, ctx.state, ctx_2.state)
    return ctx
end

@kwdef mutable struct Extent
    start
    stop
end

start(ext::Extent) = ext.start
stop(ext::Extent) = ext.stop
extent(ext::Extent) = @i stop - start + 1

combinedim(ctx, a::Extent, b::Extent) =
    Extent(combinelim(ctx, a.start, b.start), combinelim(ctx, a.stop, b.stop))

@kwdef mutable struct UnitExtent
    val
end

start(ext::UnitExtent) = ext.val
stop(ext::UnitExtent) = ext.val
extent(ext::UnitExtent) = 1

function combinedim(ctx, a::UnitExtent, b::Extent)
    combinelim(ctx, a.val, b.stop)
    UnitExtent(combinelim(ctx, a.val, b.start))
end

combinedim(ctx, a::UnitExtent, b::UnitExtent) =
    UnitExtent(combinelim(ctx, a.val, b.val))

struct MissingExtent end

combinedim(ctx::Finch.LowerJulia, a::MissingExtent, b::Extent) = b

struct SuggestedExtent
    ext
end

combinedim(ctx::Finch.LowerJulia, a::SuggestedExtent, b::Extent) = b

combinedim(ctx::Finch.LowerJulia, a::SuggestedExtent, b::MissingExtent) = a

combinedim(ctx::Finch.LowerJulia, a::SuggestedExtent, b::SuggestedExtent) = a #TODO this is a weird case, because either suggestion could set the dimension for the other.

function combinelim(ctx::Finch.LowerJulia, a::Union{Virtual, Number}, b::Virtual)
    push!(ctx.preamble, quote
        $(ctx(a)) == $(ctx(b)) || throw(DimensionMismatch("mismatched dimension starts"))
    end)
    a #TODO could do some simplify stuff here
end

function combinelim(ctx::Finch.LowerJulia, a::Number, b::Number)
    a == b || throw(DimensionMismatch("mismatched dimension starts ($a != $b)"))
    a #TODO could do some simplify stuff here
end

struct ThunkStyle end

@kwdef struct Thunk
    preamble = quote end
    body
    epilogue = quote end
    binds = ()
end
isliteral(::Thunk) = false

lower_style(::Thunk, ::LowerJulia) = ThunkStyle()

make_style(root, ctx::LowerJulia, node::Thunk) = ThunkStyle()
combine_style(a::DefaultStyle, b::ThunkStyle) = ThunkStyle()
combine_style(a::ThunkStyle, b::ThunkStyle) = ThunkStyle()

struct ThunkVisitor <: AbstractTransformVisitor
    ctx
end

function (ctx::LowerJulia)(node, ::ThunkStyle)
    contain(ctx) do ctx2
        node = (ThunkVisitor(ctx2))(node)
        (ctx2)(node)
    end
end

function (ctx::ThunkVisitor)(node::Thunk, ::DefaultStyle)
    push!(ctx.ctx.preamble, node.preamble)
    push!(ctx.ctx.epilogue, node.epilogue)
    for (var, val) in node.binds
        define!(ctx.ctx, var, val)
    end
    node.body
end

#default lowering

(ctx::LowerJulia)(::Pass, ::DefaultStyle) = quote end

function (ctx::LowerJulia)(root::Assign, ::DefaultStyle)
    if root.op == nothing
        rhs = ctx(root.rhs)
    else
        rhs = ctx(call(root.op, root.lhs, root.rhs))
    end
    lhs = ctx(root.lhs)
    :($lhs = $rhs)
end

function (ctx::LowerJulia)(root::Call, ::DefaultStyle)
    :($(ctx(root.op))($(map(ctx, root.args)...)))
end

function (ctx::LowerJulia)(root::Name, ::DefaultStyle)
    @assert haskey(ctx.bindings, getname(root)) "variable $(getname(root)) unbound"
    return ctx(ctx.bindings[getname(root)]) #This unwraps indices that are virtuals. Arguably these virtuals should be precomputed, but whatevs.
end

function (ctx::LowerJulia)(root::Literal, ::DefaultStyle)
    return root.val
end

function (ctx::LowerJulia)(root, ::DefaultStyle)
    if isliteral(root)
        return getvalue(root)
    end
    error("Don't know how to lower $root")
end

function (ctx::LowerJulia)(root::Virtual, ::DefaultStyle)
    return root.ex
end

function (ctx::LowerJulia)(root::With, ::DefaultStyle)
    prod = nothing
    return quote
        $(contain(ctx) do ctx_2
            prod = Initialize(ctx_2)(root.prod)
            (ctx_2)(prod)
        end)
        $(contain(ctx) do ctx_2
            Finalize(ctx_2)(prod)
            (ctx_2)(root.cons)
        end)
    end
end

function (ctx::LowerJulia)(root::Multi, ::DefaultStyle)
    thunk = Expr(:block)
    for body in root.bodies
        println(body)
        push!(thunk.args, quote
            $(contain(ctx) do ctx_2
                (ctx_2)(body)
            end)
        end)
    end
    thunk
end

function initialize_program!(root, ctx)
    contain(ctx) do ctx_2
        thunk = Expr(:block)
        append!(thunk.args, map(tns->virtual_initialize!(tns, ctx_2), getresults(root)))
        thunk
    end
end

function (ctx::LowerJulia)(root::Access, ::DefaultStyle)
    @assert map(getname, root.idxs) ⊆ keys(ctx.bindings)
    tns = ctx(root.tns)
    idxs = map(ctx, root.idxs)
    :($(ctx(tns))[$(idxs...)])
end

function (ctx::LowerJulia)(root::Access{<:Scalar}, ::DefaultStyle)
    return ctx(root.tns.val)
end

function (ctx::LowerJulia)(root::Access{<:Number, Read}, ::DefaultStyle)
    @assert isempty(root.idxs)
    return root.tns
end

function (ctx::LowerJulia)(stmt::Loop, ::DefaultStyle)
    if isempty(stmt.idxs)
        return ctx(stmt.body)
    else
        idx_sym = ctx.freshen(getname(stmt.idxs[1]))
        body = Loop(stmt.idxs[2:end], stmt.body)
        ext = ctx.dims[getname(stmt.idxs[1])]
        if extent(ext) == 1
            return quote
                $idx_sym = $(ctx(start(ext)))
                $(bind(ctx, getname(stmt.idxs[1]) => idx_sym) do 
                    contain(ctx) do ctx_2
                        body_3 = ForLoopVisitor(ctx_2, stmt.idxs[1], idx_sym)(body)
                        (ctx_2)(body_3)
                    end
                end)
            end
        else
            return quote
                for $idx_sym = $(ctx(start(ext))):$(ctx(stop(ext)))
                    $(fixpoint(ctx) do ctx_2
                        scope(ctx_2) do ctx_3
                            bind(ctx_3, getname(stmt.idxs[1]) => idx_sym) do 
                                contain(ctx_3) do ctx_4
                                    body_3 = ForLoopVisitor(ctx_4, stmt.idxs[1], idx_sym)(body)
                                    (ctx_4)(body_3)
                                end
                            end
                        end
                    end)
                end
            end
        end
    end
end

@kwdef struct ForLoopVisitor <: AbstractTransformVisitor
    ctx
    idx
    val
end

@kwdef struct Leaf
    body
end

isliteral(node::Leaf) = false

function (ctx::ForLoopVisitor)(node::Access{Leaf}, ::DefaultStyle)
    node.tns.body(ctx.val)
end

function (ctx::ForLoopVisitor)(node::Leaf, ::DefaultStyle)
    node.body(ctx.val)
end