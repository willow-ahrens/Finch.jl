struct Virtual{T}
    ex
end
TermInterface.istree(::Type{<:Virtual}) = false

virtual_typeof(x) = typeof(x)
virtual_typeof(::Virtual{T}) where {T} = T
virtual_expr(x) = x
virtual_expr(ex::Virtual) = ex.ex

Base.@kwdef struct Extent
    start
    stop
end

struct Scalar
    val
end

Base.@kwdef struct LowerJuliaContext
    preamble::Vector{Any} = []
    bindings::Dict{Name, Any} = Dict()
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

function scope(f, ctx::LowerJuliaContext)
    thunk = Expr(:block)
    ctx′ = LowerJuliaContext(bindings = ctx.bindings, dims = ctx.dims)
    body = f(ctx′)
    append!(thunk.args, ctx′.preamble)
    push!(thunk.args, body)
    append!(thunk.args, ctx′.epilogue)
    return thunk
end

#default lowering

function lower_julia(prgm)
    ex = scope(LowerJuliaContext()) do ctx
        dimensionalize!(prgm, ctx)
        Pigeon.visit!(prgm, ctx)
    end
    MacroTools.prettify(ex, alias=false)
end

Pigeon.visit!(::Pass, ctx::LowerJuliaContext, ::DefaultStyle) = :()

function Pigeon.visit!(root::Assign, ctx::LowerJuliaContext, ::DefaultStyle)
    @assert root.lhs isa Access && root.lhs.idxs ⊆ keys(ctx.bindings)
    if root.op == nothing
        rhs = visit!(root.rhs, ctx)
    else
        rhs = visit!(call(root.op, root.lhs, root.rhs), ctx)
    end
    tns = visit!(root.lhs.tns, ctx)
    idxs = map(idx->visit!(idx, ctx), root.lhs.idxs)
    :($(virtual_expr(tns))[$(idxs...)] = $rhs)
end

function Pigeon.visit!(root::Call, ctx::LowerJuliaContext, ::DefaultStyle)
    :($(visit!(root.op, ctx))($(map(arg->visit!(arg, ctx), root.args)...)))
end

function Pigeon.visit!(root::Name, ctx::LowerJuliaContext, ::DefaultStyle)
    @assert haskey(ctx.bindings, root) "TODO unbound variable error or something"
    return visit!(ctx.bindings[root], ctx) #This unwraps indices that are virtuals. Arguably these virtuals should be precomputed, but whatevs.
end

function Pigeon.visit!(root::Literal, ctx::LowerJuliaContext, ::DefaultStyle)
    return root.val
end

function Pigeon.visit!(root, ctx::LowerJuliaContext, ::DefaultStyle)
    if Pigeon.isliteral(root) return Pigeon.value(root) end
    error()
end

function Pigeon.visit!(root::Virtual, ctx::LowerJuliaContext, ::DefaultStyle)
    return root.ex
end

function Pigeon.visit!(root::Access, ctx::LowerJuliaContext, ::DefaultStyle)
    @assert root.idxs ⊆ keys(ctx.bindings)
    tns = visit!(root.tns, ctx)
    idxs = map(idx->visit!(idx, ctx), root.idxs)
    :($(virtual_expr(tns))[$(idxs...)])
end

function Pigeon.visit!(root::Access{<:Scalar, Read}, ctx::LowerJuliaContext, ::DefaultStyle)
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
        stmt′ = Loop(stmt.idxs[2:end], stmt.body)
        ext = ctx.dims[getname(stmt.idxs[1])]
        return bind(ctx, stmt.idxs[1] => idx_sym) do 
            scope(ctx, ) do ctx′
                quote
                    for $idx_sym = $(virtual_expr(ext.start)):$(virtual_expr(ext.stop))
                        $(visit!(stmt′, ctx′))
                    end
                end
            end
        end
    end
end