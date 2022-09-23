struct NoDimension end
const nodim = NoDimension()
IndexNotation.isliteral(::NoDimension) = false
virtualize(ex, ::Type{NoDimension}, ctx) = nodim

struct DeferDimension end
const deferdim = DeferDimension()
IndexNotation.isliteral(::DeferDimension) = false
virtualize(ex, ::Type{DeferDimension}, ctx) = deferdim

getstart(::DeferDimension) = error()
getstop(::DeferDimension) = error()

@kwdef mutable struct DeclareDimensions
    ctx
    dims = Dict()
    shapes = Dict()
end
function (ctx::DeclareDimensions)(node, dim)
    if istree(node)
        similarterm(node, operation(node), map(arg->ctx(arg, nodim), arguments(node)))
    else
        node
    end
end

@kwdef mutable struct InferDimensions
    ctx
    dims = Dict()
    shapes = Dict()
end
function (ctx::InferDimensions)(node)
    if istree(node)
        (similarterm(node, operation(node), map(first, map(ctx, arguments(node)))), nodim)
    else
        (node, nodim)
    end
end

#NOTE TO SELF
#ITS A BIG DEAL THAT WHERE STATEMENTS FORBID TEMP TENSORS WITH INDICES OUTSIDE OF SCOPE

@kwdef struct Dimensionalize
    body
end

IndexNotation.isliteral(::Dimensionalize) =  false

struct DimensionalizeStyle end

Base.show(io, ex::Dimensionalize) = Base.show(io, MIME"text/plain", ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Dimensionalize)
    print(io, "Dimensionalize(")
    print(io, ex.body)
    print(io, ")")
end

(ctx::Stylize{LowerJulia})(node::Dimensionalize) = DimensionalizeStyle()
combine_style(a::DefaultStyle, b::DimensionalizeStyle) = DimensionalizeStyle()
combine_style(a::ThunkStyle, b::DimensionalizeStyle) = ThunkStyle()
combine_style(a::DimensionalizeStyle, b::DimensionalizeStyle) = DimensionalizeStyle()

"""
TODO out of date
    dimensionalize!(prgm, ctx)

A program traversal which gathers dimensions of tensors based on shared indices.
Index sharing is transitive, so `A[i] = B[i]` and `B[j] = C[j]` will induce a
gathering of the dimensions of `A`, `B`, and `C` into one. The resulting
dimensions are gathered into a `Dimensions` object, which can be accesed with an
index name or a `(tensor_name, mode_name)` tuple.

The program is assumed to be in SSA form.

See also: [`getsize`](@ref), [`getsites`](@ref), [`combinedim`](@ref),
[`TransformSSA`](@ref)
"""
function (ctx::LowerJulia)(prgm, ::DimensionalizeStyle) 
    contain(ctx) do ctx_2
        (prgm, dims) = dimensionalize!(prgm, ctx_2)
        ctx_2(prgm)
    end
end

function dimensionalize!(prgm, ctx) 
    prgm = Rewrite(Postwalk(x -> if x isa Dimensionalize x.body end))(prgm)
    dims = filter(((idx, dim),) -> dim !== deferdim, ctx.dims)
    shapes = Dict()
    prgm = DeclareDimensions(ctx=ctx, dims = dims, shapes = shapes)(prgm, nodim)
    (prgm, _) = InferDimensions(ctx=ctx, dims = dims, shapes = shapes)(prgm)
    for k in keys(dims)
        dims[k] = cache!(ctx, k, dims[k])
    end
    ctx.dims = dims
    return (prgm, dims)
end

function (ctx::DeclareDimensions)(node::Dimensionalize, dim)
    ctx(node.body, dim)
end
function (ctx::DeclareDimensions)(node::With, dim)
    prod = ctx(node.prod, nodim)
    (prod, _) = InferDimensions(;kwfields(ctx)...)(prod)
    cons = ctx(node.cons, nodim)
    with(cons, prod)
end
function (ctx::InferDimensions)(node::With)
    (cons, _) = ctx(node.cons)
    (with(cons, node.prod), nodim)
end

function (ctx::DeclareDimensions)(node::Name, ext)
    ctx.dims[getname(node)] = resultdim(get(ctx.dims, getname(node), nodim), ext)
    node
end
function (ctx::InferDimensions)(node::Name)
    (node, ctx.dims[getname(node)])
end

(ctx::DeclareDimensions)(node::Protocol, ext) = protocol(ctx(node.idx, ext), node.val)
function (ctx::InferDimensions)(node::Protocol)
    (idx, dim) = ctx(node.idx)
    (protocol(idx, node.val), dim)
end

(ctx::DeclareDimensions)(node::Access, dim) = declare_dimensions_access(node, ctx, node.tns, dim)
declare_dimensions_access(node, ctx, tns::Virtual, dim) = declare_dimensions_access(node, ctx, tns.arg, dim)
function declare_dimensions_access(node, ctx, tns, dim)
    if haskey(ctx.shapes, getname(tns))
        dims = ctx.shapes[getname(tns)][getsites(tns)]
        tns = setsize!(tns, ctx.ctx, node.mode, dims...)
    else
        dims = getsize(tns, ctx.ctx, node.mode)
    end
    idxs = map(ctx, node.idxs, dims)
    access(tns, node.mode, idxs...)
end

(ctx::InferDimensions)(node::Access) = infer_dimensions_access(node, ctx, node.tns)
#TODO this would be a good candidate for an index modifier node
infer_dimensions_access(node, ctx, tns::Virtual) = infer_dimensions_access(node, ctx, tns.arg)
function infer_dimensions_access(node, ctx, tns)
    res = map(ctx, node.idxs)
    dims = map(resolvedim, map(last, res))
    idxs = map(first, res)
    if node.mode != Read()
        ctx.shapes[getname(tns)] = dims
        tns = setsize!(tns, ctx.ctx, node.mode, dims...)
    end
    (access(tns, node.mode, idxs...), nodim)
end

function setsize!(tns, ctx, mode, dims...)
    for (dim, ref) in zip(dims, getsize(tns, ctx, mode))
        if dim !== nodim && ref !== nodim #TODO this should be a function like checkdim or something haha
            push!(ctx.preamble, quote
                $(ctx(getstart(dim))) == $(ctx(getstart(ref))) || throw(DimensionMismatch("mismatched dimension start"))
                $(ctx(getstop(dim))) == $(ctx(getstop(ref))) || throw(DimensionMismatch("mismatched dimension stop"))
            end)
        end
    end
    tns
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
combinedim(::DeferDimension, b) = deferdim

@kwdef struct Extent
    start
    stop
    lower = @f $stop - $start + 1
    upper = @f $stop - $start + 1
end

IndexNotation.isliteral(::Extent) = false

Base.:(==)(a::Extent, b::Extent) =
    a.start == b.start &&
    a.stop == b.stop &&
    a.lower == b.lower &&
    a.upper == b.upper

Extent(start, stop) = Extent(start, stop, (@f $stop - $start + 1), (@f $stop - $start + 1))

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
extent(ext::Extent) = @f $(ext.stop) - $(ext.start) + 1

getstart(ext::Virtual) = getstart(ext.arg)
getstop(ext::Virtual) = getstop(ext.arg)
getlower(ext::Virtual) = getlower(ext.arg)
getupper(ext::Virtual) = getupper(ext.arg)

combinedim(a::Extent, b::Extent) =
    Extent(
        start = resultdim(a.start, b.start),
        stop = resultdim(a.stop, b.stop),
        lower = simplify(@f(min($(a.lower), $(b.lower)))),
        upper = simplify(@f(min($(a.upper), $(b.upper))))
    )

combinedim(a::NoDimension, b::Extent) = b

struct SuggestedExtent{Ext}
    ext::Ext
end

IndexNotation.isliteral(::SuggestedExtent) = false

Base.:(==)(a::SuggestedExtent, b::SuggestedExtent) = a.ext == b.ext

suggest(ext) = SuggestedExtent(ext)
suggest(ext::SuggestedExtent) = ext
suggest(ext::NoDimension) = nodim
suggest(ext::DeferDimension) = deferdim

resolvedim(ext::SuggestedExtent) = ext.ext
cache!(ctx, tag, ext::SuggestedExtent) = SuggestedExtent(cache!(ctx, tag, ext.ext))

#TODO maybe just call something like resolve_extent to unwrap?
getstart(ext::SuggestedExtent) = getstart(ext.ext)
getstop(ext::SuggestedExtent) = getstop(ext.ext)
extent(ext::SuggestedExtent) = extent(ext.ext)

combinedim(a::SuggestedExtent, b::Extent) = b

combinedim(a::SuggestedExtent, b::NoDimension) = a

combinedim(a::SuggestedExtent, b::SuggestedExtent) = SuggestedExtent(combinedim(a.ext, b.ext))

function combinedim(a::Value, b::Value)
    a
end

combinedim(a::Union{<:Value, <:Number}, b::IndexExpression) = a

combinedim(a::IndexExpression, b::IndexExpression) = min(string(a), string(b)) #TODO

combinedim(a::Number, b::Value) = a

function combinedim(a::T, b::T) where {T <: Number}
    a == b || throw(DimensionMismatch("mismatched dimension limits ($a != $b)"))
    a
end

"""
    getsize(tns, ctx, mode)

Return an iterable over the dimensions of `tns` in the context `ctx` with access
mode `mode`. This is a function similar in spirit to `Base.axes`.
"""
function getsize end

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

Narrow(ex::Virtual) = Narrow(ex.arg)

IndexNotation.isliteral(::Narrow) = false

narrowdim(dim) = Narrow(dim)
narrowdim(::NoDimension) = nodim
narrowdim(::DeferDimension) = deferdim

Base.:(==)(a::Narrow, b::Narrow) = a.ext == b.ext

getstart(ext::Narrow) = getstart(ext.ext)
getstop(ext::Narrow) = getstop(ext.ext)

struct Widen{Ext}
    ext::Ext
end

Widen(ex::Virtual) = Widen(ex.arg)

IndexNotation.isliteral(::Widen) = false

widendim(dim) = Widen(dim)
widendim(::NoDimension) = nodim
widendim(::DeferDimension) = deferdim

Base.:(==)(a::Widen, b::Widen) = a.ext == b.ext

getstart(ext::Widen) = getstart(ext.ext)
getstop(ext::Widen) = getstop(ext.ext)


combinedim(a::Narrow, b::Extent) = resultdim(a, Narrow(b))
combinedim(a::Narrow, b::SuggestedExtent) = a
combinedim(a::Narrow, b::NoDimension) = a
combinedim(a::Narrow, ::DeferDimension) = deferdim

function combinedim(a::Narrow{<:Extent}, b::Narrow{<:Extent})
    Narrow(Extent(
        start = simplify(@f max($(getstart(a)), $(getstart(b)))),
        stop = simplify(@f min($(getstop(a)), $(getstop(b)))),
        lower = if getstart(a) == getstart(b) || getstop(a) == getstop(b)
            simplify(@f(min($(a.ext.lower), $(b.ext.lower))))
        else
            0
        end,
        upper = simplify(@f(min($(a.ext.upper), $(b.ext.upper))))
    ))
end

combinedim(a::Widen, b::Extent) = b
combinedim(a::Widen, b::NoDimension) = a
combinedim(a::Widen, b::SuggestedExtent) = a
combinedim(a::Widen, ::DeferDimension) = deferdim

function combinedim(a::Widen{<:Extent}, b::Widen{<:Extent})
    Widen(Extent(
        start = simplify(@f min($(getstart(a)), $(getstart(b)))),
        stop = simplify(@f max($(getstop(a)), $(getstop(b)))),
        lower = simplify(@f(max($(a.ext.lower), $(b.ext.lower)))),
        upper = if getstart(a) == getstart(b) || getstop(a) == getstop(b)
            simplify(@f(max($(a.ext.upper), $(b.ext.upper))))
        else
            simplify(@f($(a.ext.upper) + $(b.ext.upper)))
        end,
    ))
end

resolvedim(ext) = ext
resolvedim(ext::Narrow) = resolvedim(ext.ext)
resolvedim(ext::Widen) = resolvedim(ext.ext)
cache!(ctx, tag, ext::Narrow) = Narrow(cache!(ctx, tag, ext.ext))
cache!(ctx, tag, ext::Widen) = Widen(cache!(ctx, tag, ext.ext))