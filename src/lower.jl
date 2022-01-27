Base.@kwdef mutable struct Extent
    start
    stop
end

struct Freshen
    counts
end
Freshen() = Freshen(Dict())
function (spc::Freshen)(tags...)
    name = Symbol(tags...)
    m = match(r"^(.*)_(\d*)$", string(name))
    if m === nothing
        tag = name
        n = 0
    else
        tag = m.captures[1]
        n = parse(BigInt, m.captures[2])
    end
    n = max(get(spc.counts, tag, 0), n) + 1
    spc.counts[tag] = n
    if n == 1
        return Symbol(tag)
    else
        return Symbol(tag, :_, n)
    end
end

struct Scalar
    val
end

Base.@kwdef struct LowerJulia <: AbstractVisitor
    preamble::Vector{Any} = []
    bindings::Dict{Any, Any} = Dict()
    epilogue::Vector{Any} = []
    dims::Dimensions = Dimensions()
    freshen::Freshen = Freshen()
end

getdims(ctx::LowerJulia) = ctx.dims

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

function openscope(ctx::LowerJulia)
    ctx′ = LowerJulia(bindings = ctx.bindings, dims = ctx.dims, freshen = ctx.freshen) #TODO use a mutable pattern here
    return ctx′
end

function closescope(body, ctx)
    thunk = Expr(:block)
    append!(thunk.args, ctx.preamble)
    if isempty(ctx.epilogue)
        push!(thunk.args, body)
    else
        res = ctx.freshen(:res)
        push!(thunk.args, :($res = $body))
        append!(thunk.args, ctx.epilogue)
        push!(thunk.args, res)
    end
    return thunk
end

function scope(f, ctx::LowerJulia)
    ctx′ = openscope(ctx)
    body = f(ctx′)
    return closescope(body, ctx′)
end

struct ThunkStyle end

Base.@kwdef struct Thunk
    preamble = quote end
    body
    epilogue = quote end
end

lower_style(::Thunk, ::LowerJulia) = ThunkStyle()

make_style(root, ctx::LowerJulia, node::Thunk) = ThunkStyle()
combine_style(a::DefaultStyle, b::ThunkStyle) = ThunkStyle()
combine_style(a::ThunkStyle, b::ThunkStyle) = ThunkStyle()

struct ThunkVisitor <: AbstractTransformVisitor
    ctx
end

function visit!(node, ctx::LowerJulia, ::ThunkStyle)
    scope(ctx) do ctx2
        node = visit!(node, ThunkVisitor(ctx2))
        visit!(node, ctx2)
    end
end

function visit!(node::Thunk, ctx::ThunkVisitor, ::DefaultStyle)
    push!(ctx.ctx.preamble, node.preamble)
    push!(ctx.ctx.epilogue, node.epilogue)
    node.body
end

#default lowering

visit!(::Pass, ctx::LowerJulia, ::DefaultStyle) = quote end

function visit!(root::Assign, ctx::LowerJulia, ::DefaultStyle)
    if root.op == nothing
        rhs = visit!(root.rhs, ctx)
    else
        rhs = visit!(call(root.op, root.lhs, root.rhs), ctx)
    end
    lhs = visit!(root.lhs, ctx)
    :($lhs = $rhs)
end

function visit!(root::Call, ctx::LowerJulia, ::DefaultStyle)
    :($(visit!(root.op, ctx))($(map(arg->visit!(arg, ctx), root.args)...)))
end

function visit!(root::Name, ctx::LowerJulia, ::DefaultStyle)
    @assert haskey(ctx.bindings, getname(root)) "variable $(getname(root)) unbound"
    return visit!(ctx.bindings[getname(root)], ctx) #This unwraps indices that are virtuals. Arguably these virtuals should be precomputed, but whatevs.
end

function visit!(root::Literal, ctx::LowerJulia, ::DefaultStyle)
    return root.val
end

function visit!(root, ctx::LowerJulia, ::DefaultStyle)
    if isliteral(root)
        return getvalue(root)
    end
    error("Don't know how to lower $root")
end

function visit!(root::Virtual, ctx::LowerJulia, ::DefaultStyle)
    return root.ex
end

function visit!(root::With, ctx::LowerJulia, ::DefaultStyle)
    return quote
        $(initialize_prgm!(root.prod, ctx))
        $(scope(ctx) do ctx2
            visit!(prod, ctx2)
        end)
        $(scope(ctx) do ctx2
            visit!(cons, ctx2)
        end)
    end
end

function initialize_program!(root, ctx)
    scope(ctx) do ctx2
        thunk = Expr(:block)
        append!(thunk.args, map(tns->virtual_initialize!(tns, ctx2), getresults(root)))
        thunk
    end
end

function visit!(root::Access, ctx::LowerJulia, ::DefaultStyle)
    @assert map(getname, root.idxs) ⊆ keys(ctx.bindings)
    tns = visit!(root.tns, ctx)
    idxs = map(idx->visit!(idx, ctx), root.idxs)
    :($(visit!(tns, ctx))[$(idxs...)])
end

function visit!(root::Access{<:Scalar}, ctx::LowerJulia, ::DefaultStyle)
    return visit!(root.tns.val, ctx)
end

function visit!(root::Access{<:Number, Read}, ctx::LowerJulia, ::DefaultStyle)
    @assert isempty(root.idxs)
    return root.tns
end

function visit!(stmt::Loop, ctx::LowerJulia, ::DefaultStyle)
    if isempty(stmt.idxs)
        return visit!(stmt.body, ctx)
    else
        idx_sym = ctx.freshen(getname(stmt.idxs[1]))
        body = Loop(stmt.idxs[2:end], stmt.body)
        ext = ctx.dims[getname(stmt.idxs[1])]
        return quote
            for $idx_sym = $(visit!(ext.start, ctx)):$(visit!(ext.stop, ctx))
                $(bind(ctx, getname(stmt.idxs[1]) => idx_sym) do 
                    scope(ctx) do ctx′
                        body = visit!(body, ForLoopVisitor(ctx′, stmt.idxs[1], idx_sym))
                        visit!(body, ctx′)
                    end
                end)
            end
        end
    end
end

Base.@kwdef struct ForLoopVisitor <: AbstractTransformVisitor
    ctx
    idx
    val
end

Base.@kwdef struct Leaf
    body
end

function visit!(node::Access{Leaf}, ctx::ForLoopVisitor, ::DefaultStyle)
    node.tns.body(ctx.val)
end