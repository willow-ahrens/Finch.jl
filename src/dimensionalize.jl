"""
    InferDimensions(ctx)

A program traversal which gathers dimensions of tensors based on shared indices.
Index sharing is transitive, so `A[i] = B[i]` and `B[j] = C[j]` will induce a
gathering of the dimensions of `A`, `B`, and `C` into one. The resulting
dimensions are gathered into a `Dimensions` object, which can be accesed with an
index name or a `(tensor_name, mode_name)` tuple.

The program is assumed to be in SSA form.

See also: [`getdims`](@ref), [`getsites`](@ref), [`combinedim`](@ref),
[`TransformSSA`](@ref)
"""
@enum InferDimensionsMode declare_dims define_dims

@kwdef mutable struct InferDimensions
    ctx
    mode::InferDimensionsMode
    dims = Dict()
    shapes = Dict()
end

#NOTE TO SELF
#ITS A BIG DEAL THAT WHERE STATEMENTS FORBID TEMP TENSORS WITH INDICES OUTSIDE OF SCOPE

function dimensionalize!(prgm, ctx) 
    dims = ctx.dims
    InferDimensions(ctx=ctx, mode=declare_dims, dims = dims)(prgm)
    InferDimensions(ctx=ctx, mode=define_dims, dims = dims)(prgm)
    for k in keys(dims)
        dims[k] = cache!(ctx, :dim, dims[k])
    end
    return (prgm, dims)
end

struct NoDimension end
nodim = NoDimension()

(ctx::InferDimensions)(node, ext) = (ctx(node); nodim)

function (ctx::InferDimensions)(node::With)
    if ctx.mode == declare_dims
        ctx(node.prod)
        InferDimensions(;kwfields(ctx)..., mode=define_dims)(node.prod)
        ctx(node.cons)
    else
        ctx(node.cons)
    end
end

function (ctx::InferDimensions)(node::Name, ext)
    ctx.dims[getname(node)] = resultdim(get(ctx.dims, getname(node), nodim), ext)
end

(ctx::InferDimensions)(node::Protocol, ext) = ctx(node.idx, ext)

function (ctx::InferDimensions)(node::Access)
    if ctx.mode == declare_dims
        exts = get(ctx.shapes, getname(node.tns), getdims(node.tns, ctx.ctx, node.mode))
        exts = map(ctx, node.idxs, exts)
    elseif node.mode != Read() && ctx.mode == define_dims
        ctx.shapes[getname(node.tns)] = map(idx -> resolvedim(ctx(idx, nodim)), node.idxs)
        if getname(node.tns) in ctx.shapes
            setdims!(node.tns, ctx.ctx, node.mode, exts...)
        end
    end
    ctx(node.tns)
    return nodim
end

function setdims!(tns, ctx, mode, dims...)
    for (dim, ref) in zip(dims, getdims(tns, ctx, mode))
        if dim !== nodim && ref !== nodim #TODO this should be a function like checkdim or something haha
            push!(ctx.preamble, quote
                $(ctx(getstart(dim))) == $(ctx(getstart(ref))) || throw(DimensionMismatch("mismatched dimension start"))
                $(ctx(getstop(dim))) == $(ctx(getstop(ref))) || throw(DimensionMismatch("mismatched dimension stop"))
            end)
        end
    end
end

function (ctx::InferDimensions)(node)
    if istree(node)
        foreach(ctx, arguments(node))
    end
    nodim
end


struct UnknownDimension end

resultdim(a, b, c, tail...) = resultdim(a, resultdim(b, c, tail...))
function resultdim(a, b)
    c = combinedim(a, b)
    d = combinedim(b, a)
    return _resultdim(a, b, c, d)
end
_resultdim(a, b, c::UnknownDimension, d::UnknownDimension) = throw(MethodError(combinedim, (a, b)))
_resultdim(a, b, c, d::UnknownDimension) = c
_resultdim(a, b, c::UnknownDimension, d) = d
_resultdim(a, b, c, d) = c #TODO assert same lattice type here.
#_resultdim(a, b, c::T, d::T) where {T} = (c == d) ? c : @assert false "TODO combinedim_ambiguity_error"

"""
    combinedim(a, b)

Combine the two dimensions `a` and `b`.  To avoid ambiguity, only define one of

```
combinedim(::A, ::B)
combinedim(::B, ::A)
```
"""
combinedim(a, b) = UnknownDimension()

combinedim(a::NoDimension, b) = b

@kwdef struct Extent
    start
    stop
    lower = @i $stop - $start + 1
    upper = @i $stop - $start + 1
end

Base.:(==)(a::Extent, b::Extent) =
    a.start == b.start &&
    a.stop == b.stop &&
    a.lower == b.lower &&
    a.upper == b.upper

Extent(start, stop) = Extent(start, stop, (@i $stop - $start + 1), (@i $stop - $start + 1))

cache!(ctx, var, ext::Extent) = Extent(
    start = cache!(ctx, Symbol(var, :_start), ext.start),
    stop = cache!(ctx, Symbol(var, :_stop), ext.stop),
    lower = cache!(ctx, Symbol(var, :_lower), ext.lower),
    upper = cache!(ctx, Symbol(var, :_upper), ext.upper),
)

getstart(ext::Extent) = ext.start
getstop(ext::Extent) = ext.stop
getlower(ext::Extent) = ext.lower
getupper(ext::Extent) = ext.upper
extent(ext::Extent) = @i $(ext.stop) - $(ext.start) + 1

combinedim(a::Extent, b::Extent) =
    Extent(
        start = resultdim(a.start, b.start),
        stop = resultdim(a.stop, b.stop),
        lower = simplify(@i(min($(a.lower), $(b.lower)))),
        upper = simplify(@i(min($(a.upper), $(b.upper))))
    )

combinedim(a::NoDimension, b::Extent) = b

struct SuggestedExtent{Ext}
    ext::Ext
end

Base.:(==)(a::SuggestedExtent, b::SuggestedExtent) = a.ext == b.ext

suggest(ext) = SuggestedExtent(ext)
suggest(ext::SuggestedExtent) = ext
suggest(ext::NoDimension) = nodim

resolvedim(ext::SuggestedExtent) = ext.ext
cache!(ctx, tag, ext::SuggestedExtent) = SuggestedExtent(cache!(ctx, tag, ext.ext))

#TODO maybe just call something like resolve_extent to unwrap?
getstart(ext::SuggestedExtent) = getstart(ext.ext)
getstop(ext::SuggestedExtent) = getstop(ext.ext)
extent(ext::SuggestedExtent) = extent(ext.ext)

combinedim(a::SuggestedExtent, b::Extent) = b

combinedim(a::SuggestedExtent, b::NoDimension) = a

combinedim(a::SuggestedExtent, b::SuggestedExtent) = SuggestedExtent(combinedim(a.ext, b.ext))

function combinedim(a::Virtual, b::Virtual)
    a
end

combinedim(a::Union{<:Virtual, <:Number}, b::IndexExpression) = a

combinedim(a::IndexExpression, b::IndexExpression) = min(string(a), string(b)) #TODO

combinedim(a::Number, b::Virtual) = a

function combinedim(a::T, b::T) where {T <: Number}
    a == b || throw(DimensionMismatch("mismatched dimension limits ($a != $b)"))
    a
end

"""
    getdims(tns, ctx, mode)

Return an iterable over the dimensions of `tns` in the context `ctx` with access
mode `mode`. This is a function similar in spirit to `Base.axes`.
"""
function getdims end

"""
    getsites(tns)

Return an iterable over the identities of the modes of `tns`. If `tns_2` is a
transpose of `tns`, then `getsites(tns_2)` should be a permutation of
`getsites(tns)` corresponding to the order in which modes have been permuted.
"""
function getsites end


getstart(val) = val
getstop(val) = val
extent(val) = 1

struct Narrow{Ext}
    ext::Ext
end

Base.:(==)(a::Narrow, b::Narrow) = a.ext == b.ext

getstart(ext::Narrow) = getstart(ext.ext)
getstop(ext::Narrow) = getstop(ext.ext)

struct Widen{Ext}
    ext::Ext
end

Base.:(==)(a::Widen, b::Widen) = a.ext == b.ext

getstart(ext::Widen) = getstart(ext.ext)
getstop(ext::Widen) = getstop(ext.ext)


combinedim(a::Narrow, b::Extent) = resultdim(a, Narrow(b))
combinedim(a::Narrow, b::NoDimension) = a

function combinedim(a::Narrow{<:Extent}, b::Narrow{<:Extent})
    Narrow(Extent(
        start = simplify(@i max($(getstart(a)), $(getstart(b)))),
        stop = simplify(@i min($(getstop(a)), $(getstop(b)))),
        lower = if getstart(a) == getstart(b) || getstop(a) == getstop(b)
            simplify(@i(min($(a.ext.lower), $(b.ext.lower))))
        else
            0
        end,
        upper = simplify(@i(min($(a.ext.upper), $(b.ext.upper))))
    ))
end

combinedim(a::Widen, b::Extent) = resultdim(a, Widen(b))
combinedim(a::Widen, b::NoDimension) = a

function combinedim(a::Widen{<:Extent}, b::Widen{<:Extent})
    Widen(Extent(
        start = simplify(@i min($(getstart(a)), $(getstart(b)))),
        stop = simplify(@i max($(getstop(a)), $(getstop(b)))),
        lower = simplify(@i(max($(a.ext.lower), $(b.ext.lower)))),
        upper = if getstart(a) == getstart(b) || getstop(a) == getstop(b)
            simplify(@i(max($(a.ext.upper), $(b.ext.upper))))
        else
            simplify(@i($(a.ext.upper) + $(b.ext.upper)))
        end,
    ))
end

resolvedim(ext) = ext
resolvedim(ext::Narrow) = resolvedim(ext.ext)
resolvedim(ext::Widen) = resolvedim(ext.ext)
cache!(ctx, tag, ext::Narrow) = Narrow(cache!(ctx, tag, ext.ext))
cache!(ctx, tag, ext::Widen) = Widen(cache!(ctx, tag, ext.ext))