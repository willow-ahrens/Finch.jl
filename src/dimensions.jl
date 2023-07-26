FinchNotation.finch_leaf(x::MakeDimension) = virtual(x)
FinchNotation.finch_leaf_instance(x::MakeDimension) = value_instance(x)
virtualize(ex, ::Type{MakeDimension}, ctx) = mkdim

getstart(::MakeDimension) = error("asked for start of dimensionless range")
getstop(::MakeDimension) = error("asked for stop of dimensionless range")

struct UnknownDimension end

resolvedim(ext) = ext

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

combinedim(ctx, a::MakeDimension, b) = b

@kwdef struct Extent
    start
    stop
end

FinchNotation.finch_leaf(x::Extent) = virtual(x)

Base.:(==)(a::Extent, b::Extent) =
    a.start == b.start &&
    a.stop == b.stop

bound_below!(val, below) = cached(val, literal(call(max, val, below)))

bound_above!(val, above) = cached(val, literal(call(min, val, above)))

bound_measure_below!(ext::Extent, m) = Extent(ext.start, bound_below!(ext.stop, call(+, ext.start, m)))
bound_measure_above!(ext::Extent, m) = Extent(ext.start, bound_above!(ext.stop, call(+, ext.start, m)))

cache_dim!(ctx, var, ext::Extent) = Extent(
    start = cache!(ctx, Symbol(var, :_start), ext.start),
    stop = cache!(ctx, Symbol(var, :_stop), ext.stop)
)

getstart(ext::Extent) = ext.start
getstop(ext::Extent) = ext.stop
measure(ext::Extent) = call(+, call(-, ext.stop, ext.start), 1)

function getstop(ext::FinchNode)
    if ext.kind === virtual
        getstop(ext.val)
    else
        ext
    end
end
function getstart(ext::FinchNode)
    if ext.kind === virtual
        getstart(ext.val)
    else
        ext
    end
end

combinedim(ctx, a::Extent, b::Extent) =
    Extent(
        start = checklim(ctx, a.start, b.start),
        stop = checklim(ctx, a.stop, b.stop)
    )

combinedim(ctx, a::MakeDimension, b::Extent) = b

struct SuggestedExtent
    ext
end

FinchNotation.finch_leaf(x::SuggestedExtent) = virtual(x)

Base.:(==)(a::SuggestedExtent, b::SuggestedExtent) = a.ext == b.ext

suggest(ext) = SuggestedExtent(ext)
suggest(ext::SuggestedExtent) = ext
suggest(ext::MakeDimension) = mkdim

resolvedim(ext::Symbol) = error()
resolvedim(ext::SuggestedExtent) = resolvedim(ext.ext)
cache_dim!(ctx, tag, ext::SuggestedExtent) = SuggestedExtent(cache_dim!(ctx, tag, ext.ext))

combinedim(ctx, a::SuggestedExtent, b::Extent) = b

combinedim(ctx, a::SuggestedExtent, b::MakeDimension) = a

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

struct ParallelDimension
    ext
end

parallel(dim) = ParallelDimension(dim)

function virtual_call(::typeof(parallel), ctx, arg)
    if arg.kind === virtual
        ParallelDimension(arg.val)
    end
end

FinchNotation.finch_leaf(x::ParallelDimension) = virtual(x)

Base.:(==)(a::ParallelDimension, b::ParallelDimension) = a.ext == b.ext

getstart(ext::ParallelDimension) = getstart(ext.ext)
getstop(ext::ParallelDimension) = getstop(ext.ext)

combinedim(ctx, a::ParallelDimension, b::Extent) = ParallelDimension(resultdim(ctx, a.ext, b))
combinedim(ctx, a::ParallelDimension, b::SuggestedExtent) = a
combinedim(ctx, a::ParallelDimension, b::ParallelDimension) = ParallelDimension(combinedim(ctx, a.ext, b.ext))

resolvedim(ext::ParallelDimension) = ParallelDimension(resolvedim(ext.ext))
cache_dim!(ctx, tag, ext::ParallelDimension) = ParallelDimension(cache_dim!(ctx, tag, ext.ext))

promote_rule(::Type{Extent}, ::Type{Extent}) = Extent

function shiftdim(ext::Extent, delta)
    Extent(
        start = call(+, ext.start, delta),
        stop = call(+, ext.stop, delta)
    )
end

shiftdim(ext::MakeDimension, delta) = mkdim
shiftdim(ext::ParallelDimension, delta) = ParallelDimension(ext, shiftdim(ext.ext, delta))

function shiftdim(ext::FinchNode, body)
    if ext.kind === virtual
        shiftdim(ext.val, body)
    else
        error("unimplemented")
    end
end

#virtual_intersect(ctx, a, b) = virtual_intersect(ctx, promote(a, b)...)
function virtual_intersect(ctx, a, b)
    println(a, b)
    println("problem!")
    error()
end

virtual_intersect(ctx, a::MakeDimension, b) = b
virtual_intersect(ctx, a, b::MakeDimension) = a
virtual_intersect(ctx, a::MakeDimension, b::MakeDimension) = b

function virtual_intersect(ctx, a::Extent, b::Extent)
    Extent(
        start = @f(max($(getstart(a)), $(getstart(b)))),
        stop = @f(min($(getstop(a)), $(getstop(b))))
    )
end

virtual_union(ctx, a::MakeDimension, b) = b
virtual_union(ctx, a, b::MakeDimension) = a
virtual_union(ctx, a::MakeDimension, b::MakeDimension) = b

#virtual_union(ctx, a, b) = virtual_union(ctx, promote(a, b)...)
function virtual_union(ctx, a::Extent, b::Extent)
    Extent(
        start = @f(min($(getstart(a)), $(getstart(b)))),
        stop = @f(max($(getstop(a)), $(getstop(b))))
    )
end