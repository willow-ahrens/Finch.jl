
Base.@kwdef mutable struct Extent
    start
    stop
end

struct Scalar
    val
end

Base.@kwdef struct LowerJuliaContext
    preamble::Vector{Any} = []
    bindings::Dict{Any, Any} = Dict()
    epilogue::Vector{Any} = []
    dims::Dimensions = Dimensions()
end

Pigeon.getdims(ctx::LowerJuliaContext) = ctx.dims

bind(f, ctx::LowerJuliaContext) = f()
function bind(f, ctx::LowerJuliaContext, (var, val′), tail...)
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

restrict(f, ctx::LowerJuliaContext) = f()
function restrict(f, ctx::LowerJuliaContext, (idx, ext′), tail...)
    @assert haskey(ctx.dims, idx)
    ext = ctx.dims[idx]
    ctx.dims[idx] = ext′
    res = restrict(f, ctx, tail...)
    ctx.dims[idx] = ext
    return res
end

function openscope(ctx::LowerJuliaContext)
    ctx′ = LowerJuliaContext(bindings = ctx.bindings, dims = ctx.dims)
    return ctx′
end

function closescope(body, ctx)
    thunk = Expr(:block)
    append!(thunk.args, ctx.preamble)
    push!(thunk.args, body)
    append!(thunk.args, ctx.epilogue)
    return thunk
end

function scope(f, ctx::LowerJuliaContext)
    ctx′ = openscope(ctx)
    body = f(ctx′)
    return closescope(body, ctx′)
end

function cache!(ex, ctx::LowerJuliaContext, name = gensym())
    push!(ctx.preamble, "$name = $ex")
    return name
end

struct ThunkStyle end

Base.@kwdef struct Thunk
    preamble = quote end
    body
    epilogue = quote end
end

lower_style(::Thunk, ::LowerJuliaContext) = ThunkStyle()

Pigeon.make_style(root, ctx::LowerJuliaContext, node::Thunk) = ThunkStyle()
Pigeon.combine_style(a::DefaultStyle, b::ThunkStyle) = ThunkStyle()
Pigeon.combine_style(a::ThunkStyle, b::ThunkStyle) = ThunkStyle()

struct ThunkContext <: Pigeon.AbstractTransformContext
    ctx
end

function Pigeon.visit!(node, ctx::LowerJuliaContext, ::ThunkStyle)
    node = visit!(node, ThunkContext(ctx))
    visit!(node, ctx)
    #scope(ctx) do ctx′ #TODO this should probably be the only way to do preambles, etc.
    #    node = visit!(node, ThunkContext(ctx′))
    #    visit!(node, ctx′)
    #end
end

function Pigeon.visit!(node::Thunk, ctx::ThunkContext, ::DefaultStyle)
    push!(ctx.ctx.preamble, node.preamble)
    push!(ctx.ctx.epilogue, node.epilogue)
    node.body
end

#default lowering

Pigeon.visit!(::Pass, ctx::LowerJuliaContext, ::DefaultStyle) = quote end

function Pigeon.visit!(root::Assign, ctx::LowerJuliaContext, ::DefaultStyle)
    @assert root.lhs isa Access && map(getname, root.lhs.idxs) ⊆ keys(ctx.bindings)
    if root.op == nothing
        rhs = visit!(root.rhs, ctx)
    else
        rhs = visit!(call(root.op, root.lhs, root.rhs), ctx)
    end
    lhs = visit!(root.lhs, ctx)
    :($lhs = $rhs)
end

function Pigeon.visit!(root::Call, ctx::LowerJuliaContext, ::DefaultStyle)
    :($(visit!(root.op, ctx))($(map(arg->visit!(arg, ctx), root.args)...)))
end

function Pigeon.visit!(root::Name, ctx::LowerJuliaContext, ::DefaultStyle)
    @assert haskey(ctx.bindings, getname(root)) "variable $(getname(root)) unbound"
    return visit!(ctx.bindings[getname(root)], ctx) #This unwraps indices that are virtuals. Arguably these virtuals should be precomputed, but whatevs.
end

function Pigeon.visit!(root::Literal, ctx::LowerJuliaContext, ::DefaultStyle)
    return root.val
end

function Pigeon.visit!(root, ctx::LowerJuliaContext, ::DefaultStyle)
    if Pigeon.isliteral(root)
        return Pigeon.value(root)
    end
    error("Don't know how to lower $root")
end

function Pigeon.visit!(root::Virtual, ctx::LowerJuliaContext, ::DefaultStyle)
    return root.ex
end

function Pigeon.visit!(root::Access, ctx::LowerJuliaContext, ::DefaultStyle)
    @assert map(getname, root.idxs) ⊆ keys(ctx.bindings)
    tns = visit!(root.tns, ctx)
    idxs = map(idx->visit!(idx, ctx), root.idxs)
    :($(visit!(tns, ctx))[$(idxs...)])
end

function Pigeon.visit!(root::Access{<:Scalar}, ctx::LowerJuliaContext, ::DefaultStyle)
    return visit!(root.tns.val, ctx)
end

function Pigeon.visit!(root::Access{<:Number, Read}, ctx::LowerJuliaContext, ::DefaultStyle)
    @assert isempty(root.idxs)
    return root.tns
end

function Pigeon.visit!(stmt::Loop, ctx::LowerJuliaContext, ::DefaultStyle)
    if isempty(stmt.idxs)
        return visit!(stmt.body, ctx)
    else
        idx_sym = gensym(Pigeon.getname(stmt.idxs[1]))
        body = Loop(stmt.idxs[2:end], stmt.body)
        ext = ctx.dims[getname(stmt.idxs[1])]
        return quote
            for $idx_sym = $(visit!(ext.start, ctx)):$(visit!(ext.stop, ctx))
                $(bind(ctx, getname(stmt.idxs[1]) => idx_sym) do 
                    scope(ctx) do ctx′
                        body = visit!(body, ForLoopContext(ctx′, stmt.idxs[1], idx_sym))
                        visit!(body, ctx′)
                    end
                end)
            end
        end
    end
end

Base.@kwdef struct ForLoopContext <: Pigeon.AbstractTransformContext
    ctx
    idx
    val
end

Base.@kwdef struct Leaf
    body
end

function Pigeon.visit!(node::Access{Leaf}, ctx::ForLoopContext, ::DefaultStyle)
    node.tns.body(ctx.val)
end