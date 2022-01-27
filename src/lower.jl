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
        tag = m.captures[1]
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
    val
end

@kwdef struct LowerJulia <: AbstractVisitor
    preamble::Vector{Any} = []
    bindings::Dict{Any, Any} = Dict()
    epilogue::Vector{Any} = []
    dims::Dimensions = Dimensions()
    freshen::Freshen = Freshen()
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

@kwdef mutable struct Extent
    start
    stop
end

function combinedim(ctx::Finch.LowerJulia, a::Extent, b::Extent)
    push!(ctx.preamble, quote
        $(ctx(a.start)) == $(ctx(b.start)) || throw(DimensionMismatch("mismatched dimension starts"))
        $(ctx(a.stop)) == $(ctx(b.stop)) || throw(DimensionMismatch("mismatched dimension stops"))
    end)
    a #TODO could do some simplify stuff here
end


struct ThunkStyle end

@kwdef struct Thunk
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

function (ctx::LowerJulia)(node, ::ThunkStyle)
    scope(ctx) do ctx2
        node = (ThunkVisitor(ctx2))(node)
        (ctx2)(node)
    end
end

function (ctx::ThunkVisitor)(node::Thunk, ::DefaultStyle)
    push!(ctx.ctx.preamble, node.preamble)
    push!(ctx.ctx.epilogue, node.epilogue)
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
    return quote
        $(initialize_prgm!(root.prod, ctx))
        $(scope(ctx) do ctx2
            (ctx2)(prod)
        end)
        $(scope(ctx) do ctx2
            (ctx2)(cons)
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
        return quote
            for $idx_sym = $(ctx(ext.start)):$(ctx(ext.stop))
                $(bind(ctx, getname(stmt.idxs[1]) => idx_sym) do 
                    scope(ctx) do ctx′
                        body = ForLoopVisitor(ctx′, stmt.idxs[1], idx_sym)(body)
                        (ctx′)(body)
                    end
                end)
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

function (ctx::ForLoopVisitor)(node::Access{Leaf}, ::DefaultStyle)
    node.tns.body(ctx.val)
end