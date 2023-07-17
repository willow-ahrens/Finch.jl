struct NoDimension end
const nodim = NoDimension()
FinchNotation.finch_leaf(x::NoDimension) = virtual(x)
virtualize(ex, ::Type{NoDimension}, ctx) = nodim

getstart(::NoDimension) = error("asked for start of dimensionless range")
getstop(::NoDimension) = error("asked for stop of dimensionless range")

@kwdef mutable struct DeclareDimensions
    ctx
    dims = Dict()
    hints = Dict()
end

"""
    dimensionalize!(prgm, ctx)

A program traversal which coordinates dimensions based on shared indices. In
particular, loops and declaration statements have dimensions. Accessing a tensor
with a raw index `hints` that the loop should have a dimension corresponding to
the tensor axis. Accessing a tensor on the left hand side with a raw index also
`hints` that the tensor declaration should have a dimension corresponding to the
loop axis.  All hints inside a loop body are
used to evaluate loop dimensions, and all hints after a declaration until the
first freeze are used to evaluate declaration dimensions.
One may refer to the automatically determined dimension using a
variable named `_` or `:`. Index sharing is transitive, so `A[i] = B[i]` and `B[j]
= C[j]` will induce a gathering of the dimensions of `A`, `B`, and `C` into one.

The dimensions are semantically evaluated just before the corresponding loop or
declaration statement.  The program is assumed to be scoped, so that all loops
have unique index names.

See also: [`virtual_size`](@ref), [`virtual_resize`](@ref), [`combinedim`](@ref)
"""
function dimensionalize!(prgm, ctx) 
    prgm = DeclareDimensions(ctx=ctx)(prgm)
    return prgm
end

struct FinchCompileError msg end

function (ctx::DeclareDimensions)(node::FinchNode)
    if node.kind === access
        @assert @capture node access(~tns::isvirtual, ~mode, ~idxs...)
        tns = tns.val
        if node.mode.kind !== reader && node.tns.kind === virtual && haskey(ctx.hints, getroot(tns))
            shape = map(suggest, virtual_size(tns, ctx.ctx))
            push!(ctx.hints[getroot(tns)], node)
        else
            shape = virtual_size(tns, ctx.ctx)
        end
        length(idxs) > length(shape) && throw(DimensionMismatch("more indices than dimensions in $(sprint(show, MIME("text/plain"), node))"))
        length(idxs) < length(shape) && throw(DimensionMismatch("less indices than dimensions in $(sprint(show, MIME("text/plain"), node))"))
        idxs = map(zip(shape, idxs)) do (dim, idx)
            if isindex(idx)
                ctx.dims[idx] = resultdim(ctx.ctx, dim, get(ctx.dims, idx, nodim))
                idx
            else
                ctx(idx) #Probably not strictly necessary to preserve the result of this, since this expr can't contain a statement and so won't be modified
            end
        end
        access(tns, mode, idxs...)
    elseif node.kind === loop && node.ext == index(:(:))
        body = ctx(node.body)
        haskey(ctx.dims, node.idx) || throw(FinchCompileError("could not resolve dimension of index $(node.idx)"))
        return loop(node.idx, cache_dim!(ctx.ctx, getname(node.idx), resolvedim(ctx.dims[node.idx])), body)
    elseif node.kind === sequence
        sequence(map(ctx, node.bodies)...)
    elseif node.kind === declare
        ctx.hints[node.tns] = []
        node
    elseif node.kind === freeze
        if haskey(ctx.hints, node.tns)
            shape = virtual_size(node.tns, ctx.ctx)
            shape = map(suggest, shape)
            for hint in ctx.hints[node.tns]
                @assert @capture hint access(~tns::isvirtual, updater(), ~idxs...)
                shape = map(zip(shape, idxs)) do (dim, idx)
                    if isindex(idx)
                        resultdim(ctx.ctx, dim, ctx.dims[idx])
                    else
                        resultdim(ctx.ctx, dim, nodim) #TODO I can't think of a case where this doesn't equal `dim`
                    end
                end
            end
            #TODO tns ignored here
            tns = virtual_resize!(node.tns, ctx.ctx, shape...)
            delete!(ctx.hints, node.tns)
        end
        node
    elseif istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end


struct UnknownDimension end

resultdim(ctx, a, b, c, tail...) = resultdim(ctx, a, resultdim(ctx, b, c, tail...))
function resultdim(ctx, a, b)
    c = combinedim(ctx, a, b)
    d = combinedim(ctx, b, a)
    return _resultdim(ctx, a, b, c, d)
end
_resultdim(ctx, a, b, c::UnknownDimension, d::UnknownDimension) = throw(MethodError(combinedim, (ctx, a, b)))
_resultdim(ctx, a, b, c, d::UnknownDimension) = c
_resultdim(ctx, a, b, c::UnknownDimension, d) = d
_resultdim(ctx, a, b, c, d) = c #TODO assert same lattice type here.
#_resultdim(a, b, c::T, d::T) where {T} = (c == d) ? c : @assert false "TODO combinedim_ambiguity_error"

"""
    combinedim(ctx, a, b)

Combine the two dimensions `a` and `b`.  To avoid ambiguity, only define one of

```
combinedim(ctx, ::A, ::B)
combinedim(ctx, ::B, ::A)
```
"""
combinedim(ctx, a, b) = UnknownDimension()

combinedim(ctx, a::NoDimension, b) = b

@kwdef struct Extent
    start
    stop
end

@kwdef struct ContinuousExtent
    start
    stop
end

FinchNotation.finch_leaf(x::Extent) = virtual(x)
FinchNotation.finch_leaf(x::ContinuousExtent) = virtual(x)

Base.:(==)(a::Extent, b::Extent) = a.start == b.start && a.stop == b.stop
Base.:(==)(a::ContinuousExtent, b::ContinuousExtent) = a.start == b.start && a.stop == b.stop
Base.:(==)(a::Extent, b::ContinuousExtent) = throw(ArgumentError("Extent and ContinuousExtent cannot interact"))

bound_below!(val, below) = cached(val, literal(call(max, val, below)))
bound_above!(val, above) = cached(val, literal(call(min, val, above)))
bound_measure_below!(ext::Extent, m) = Extent(ext.start, bound_below!(ext.stop, call(+, ext.start, m)))
bound_measure_below!(ext::ContinuousExtent, m) = ContinuousExtent(ext.start, bound_below!(ext.stop, call(+, ext.start, m)))
bound_measure_above!(ext::Extent, m) = Extent(ext.start, bound_above!(ext.stop, call(+, ext.start, m)))
bound_measure_above!(ext::ContinuousExtent, m) = ContinuousExtent(ext.start, bound_above!(ext.stop, call(+, ext.start, m)))


cache_dim!(ctx, var, ext::Extent) = Extent(
    start = cache!(ctx, Symbol(var, :_start), ext.start),
    stop = cache!(ctx, Symbol(var, :_stop), ext.stop)
)
cache_dim!(ctx, var, ext::ContinuousExtent) = ContinuousExtent(
    start = cache!(ctx, Symbol(var, :_start), ext.start),
    stop = cache!(ctx, Symbol(var, :_stop), ext.stop)
)

getstart(ext::Extent) = ext.start
getstart(ext::ContinuousExtent) = ext.start
getstart(ext::FinchNode) = ext.kind === virtual ? getstart(ext.val) : ext

getstop(ext::Extent) = ext.stop
getstop(ext::ContinuousExtent) = ext.stop
getstop(ext::FinchNode) = ext.kind === virtual ? getstop(ext.val) : ext

measure(ext::Extent) = call(+, call(-, ext.stop, ext.start), 1)
measure(ext::ContinuousExtent) = call(-, ext.stop, ext.start) # TODO: Think carefully, Not quite sure!



combinedim(ctx, a::Extent, b::Extent) = Extent(checklim(ctx, a.start, b.start), checklim(ctx, a.stop, b.stop))
combinedim(ctx, a::ContinuousExtent, b::ContinuousExtent) = ContinuousExtent(checklim(ctx, a.start, b.start), checklim(ctx, a.stop, b.stop))
combinedim(ctx, a::NoDimension, b::Extent) = b
combinedim(ctx, a::NoDimension, b::ContinuousExtent) = b
combinedim(ctx, a::Extent, b::ContinuousExtent) = throw(ArgumentError("Extent and ContinuousExtent cannot interact"))

struct SuggestedExtent{Ext}
    ext::Ext
end

FinchNotation.finch_leaf(x::SuggestedExtent) = virtual(x)

Base.:(==)(a::SuggestedExtent, b::SuggestedExtent) = a.ext == b.ext

suggest(ext) = SuggestedExtent(ext)
suggest(ext::SuggestedExtent) = ext
suggest(ext::NoDimension) = nodim

resolvedim(ext::Symbol) = error()
resolvedim(ext::SuggestedExtent) = ext.ext
cache_dim!(ctx, tag, ext::SuggestedExtent) = SuggestedExtent(cache_dim!(ctx, tag, ext.ext))

#TODO maybe just call something like resolve_extent to unwrap?
getstart(ext::SuggestedExtent) = getstart(ext.ext)
getstop(ext::SuggestedExtent) = getstop(ext.ext)
measure(ext::SuggestedExtent) = measure(ext.ext)

combinedim(ctx, a::SuggestedExtent, b::Extent) = b
combinedim(ctx, a::SuggestedExtent, b::ContinuousExtent) = b

combinedim(ctx, a::SuggestedExtent, b::NoDimension) = a

combinedim(ctx, a::SuggestedExtent, b::SuggestedExtent) = SuggestedExtent(combinedim(ctx, a.ext, b.ext))

function checklim(ctx, a::FinchNode, b::FinchNode)
    if isliteral(a) && isliteral(b)
        a == b || throw(DimensionMismatch("mismatched dimension limits ($a != $b)"))
    end
    if ctx.shash(a) < ctx.shash(b) #TODO instead of this, we should introduce a lazy operator to assert equality
        push!(ctx.preamble, quote
            $(ctx(a)) == $(ctx(b)) || throw(DimensionMismatch("mismatched dimension limits ($($(ctx(a))) != $($(ctx(b))))"))
        end)
        a
    else
        b
    end
end

getstart(val) = val #TODO avoid generic definition here
getstop(val) = val #TODO avoid generic herer

struct Narrow{Ext}
    ext::Ext
end

function Narrow(ext::FinchNode)
    if ext.kind === virtual
        Narrow(ext.val)
    else
        error("unimplemented")
    end
end

FinchNotation.finch_leaf(x::Narrow) = virtual(x)

narrowdim(dim) = Narrow(dim)
narrowdim(::NoDimension) = nodim

Base.:(==)(a::Narrow, b::Narrow) = a.ext == b.ext

getstart(ext::Narrow) = getstart(ext.ext)
getstop(ext::Narrow) = getstop(ext.ext)

struct Widen{Ext}
    ext::Ext
end

function Widen(ext::FinchNode)
    if ext.kind === virtual
        Widen(ext.val)
    else
        error("unimplemented")
    end
end

FinchNotation.finch_leaf(x::Widen) = virtual(x)

widendim(dim) = Widen(dim)
widendim(::NoDimension) = nodim

Base.:(==)(a::Widen, b::Widen) = a.ext == b.ext

getstart(ext::Widen) = getstart(ext.ext)
getstop(ext::Widen) = getstop(ext.ext)

combinedim(ctx, a::Narrow, b::Extent) = resultdim(ctx, a, Narrow(b))
combinedim(ctx, a::Narrow, b::ContinuousExtent) = resultdim(ctx, a, Narrow(b))
combinedim(ctx, a::Narrow, b::SuggestedExtent) = a
combinedim(ctx, a::Narrow, b::NoDimension) = a

function combinedim(ctx, a::Narrow{<:Extent}, b::Narrow{<:Extent})
    Narrow(Extent(
        start = @f(max($(getstart(a)), $(getstart(b)))),
        stop = @f(min($(getstop(a)), $(getstop(b))))
    ))
end
function combinedim(ctx, a::Narrow{<:ContinuousExtent}, b::Narrow{<:ContinuousExtent})
    Narrow(ContinuousExtent(
        start = @f(max($(getstart(a)), $(getstart(b)))),
        stop = @f(min($(getstop(a)), $(getstop(b))))
    ))
end
combinedim(ctx, a::Narrow{<:Extent}, b::Narrow{<:ContinuousExtent}) = throw(ArgumentError("Extent and ContinuousExtent cannot interact"))


combinedim(ctx, a::Widen, b::Extent) = resultdim(ctx, a, Widen(b))
combinedim(ctx, a::Widen, b::ContinuousExtent) = resultdim(ctx, a, Widen(b))
combinedim(ctx, a::Widen, b::NoDimension) = a
combinedim(ctx, a::Widen, b::SuggestedExtent) = a

function combinedim(ctx, a::Widen{<:Extent}, b::Widen{<:Extent})
    Widen(Extent(
        start = @f(min($(getstart(a)), $(getstart(b)))),
        stop = @f(max($(getstop(a)), $(getstop(b))))
    ))
end
function combinedim(ctx, a::Widen{<:ContinuousExtent}, b::Widen{<:ContinuousExtent})
    Widen(ContinuousExtent(
        start = @f(min($(getstart(a)), $(getstart(b)))),
        stop = @f(max($(getstop(a)), $(getstop(b))))
    ))
end
combinedim(ctx, a::Widen{<:Extent}, b::Widen{<:ContinuousExtent}) = throw(ArgumentError("Extent and ContinuousExtent cannot interact"))

resolvedim(ext) = ext
resolvedim(ext::Narrow) = resolvedim(ext.ext)
resolvedim(ext::Widen) = resolvedim(ext.ext)
cache_dim!(ctx, tag, ext::Narrow) = Narrow(cache_dim!(ctx, tag, ext.ext))
cache_dim!(ctx, tag, ext::Widen) = Widen(cache_dim!(ctx, tag, ext.ext))
