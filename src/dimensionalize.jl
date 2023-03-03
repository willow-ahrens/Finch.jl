struct NoDimension end
const nodim = NoDimension()
FinchNotation.isliteral(::NoDimension) = false
virtualize(ex, ::Type{NoDimension}, ctx) = nodim

getstart(::NoDimension) = error("asked for start of dimensionless range")
getstop(::NoDimension) = error("asked for stop of dimensionless range")

@kwdef mutable struct DeclareDimensions
    ctx
    dims = Dict()
    hints = Dict()
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

FinchNotation.isliteral(::Dimensionalize) =  false

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

See also: [`virtual_size`](@ref), [`virtual_resize`](@ref), [`combinedim`](@ref),
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
    dims = ctx.dims
    prgm = DeclareDimensions(ctx=ctx, dims = dims)(prgm, nodim)
    for k in keys(dims)
        dims[k] = cache_dim!(ctx, k, dims[k])
    end
    ctx.dims = dims
    return (prgm, dims)
end

function (ctx::DeclareDimensions)(node::Dimensionalize, dim)
    ctx(node.body, dim)
end
(ctx::DeclareDimensions)(node) = ctx(node, nodim)
function (ctx::DeclareDimensions)(node::FinchNode, dim)
    if node.kind === index
        ctx.dims[getname(node)] = resultdim(ctx.ctx, get(ctx.dims, getname(node), nodim), dim)
        return node
    elseif node.kind === access && node.tns.kind === variable
        return declare_dimensions_access(node, ctx, node.tns, dim)
    elseif node.kind === sequence
        sequence(map(ctx, node.bodies)...)
    elseif node.kind === declare
        ctx.hints[node.tns] = []
        node
    elseif node.kind === freeze
        if haskey(ctx.hints, node.tns)
            map(InferDimensions(ctx.ctx, ctx.dims), ctx.hints[node.tns])
            delete!(ctx.hints, node.tns)
        end
        node
    elseif node.kind === protocol
        return protocol(ctx(node.idx, dim), node.mode)
    elseif istree(node)
        return similarterm(node, operation(node), map(arg->ctx(arg, nodim), arguments(node)))
    else
        return node
    end
end
function (ctx::InferDimensions)(node::FinchNode)
    if node.kind === index
        return (node, ctx.dims[getname(node)])
    elseif node.kind === access && node.mode.kind === updater && node.tns.kind === virtual
        return infer_dimensions_access(node, ctx, node.tns.val)
    elseif node.kind === access && node.mode.kind === updater && node.tns.kind === variable #TODO perhaps we can get rid of this
        return infer_dimensions_access(node, ctx, node.tns)
    elseif node.kind === protocol
        (idx, dim) = ctx(node.idx)
        (protocol(idx, node.mode), dim)
    elseif istree(node)
        FinchNotation.isstateful(node) && @assert false
        return (similarterm(node, operation(node), map(first, map(ctx, arguments(node)))), nodim)
    else
        return (node, nodim)
    end
end

declare_dimensions_access(node, ctx, tns::Dimensionalize, dim) = declare_dimensions_access(node, ctx, tns.body, dim)
function declare_dimensions_access(node, ctx, tns, eldim)
    if node.mode.kind !== reader
        shape = map(suggest, virtual_size(tns, ctx.ctx, eldim))
        if node.tns.kind === variable && haskey(ctx.hints, node.tns)
            push!(ctx.hints[node.tns], node)
        end
    else
        shape = virtual_size(tns, ctx.ctx, eldim)
    end
    idxs = map(ctx, node.idxs, shape)
    access(tns, node.mode, idxs...)
end

function infer_dimensions_access(node, ctx, tns)
    res = map(ctx, node.idxs)
    idxs = map(first, res)
    shape = virtual_size(tns, ctx.ctx) #This is an assignment access, so we don't need to add an eldim here
    if node.mode.kind === updater
        shape = map(suggest, shape)
    end
    shape = map(resolvedim, map((a, b) -> resultdim(ctx.ctx, a, b), shape, map(last, res)))
    if node.mode.kind === updater
        eldim = virtual_resize!(tns, ctx.ctx, shape...)
        (access(tns, node.mode, idxs...), eldim)
    else
        (access(tns, node.mode, idxs...), virtual_elaxis(tns, ctx.ctx, shape...))
    end
end

virtual_elaxis(tns, ctx, dims...) = nodim

function virtual_resize!(tns, ctx, dims...)
    for (dim, ref) in zip(dims, virtual_size(tns, ctx))
        if dim !== nodim && ref !== nodim #TODO this should be a function like checkdim or something haha
            push!(ctx.preamble, quote
                $(ctx(getstart(dim))) == $(ctx(getstart(ref))) || throw(DimensionMismatch("mismatched dimension start"))
                $(ctx(getstop(dim))) == $(ctx(getstop(ref))) || throw(DimensionMismatch("mismatched dimension stop"))
            end)
        end
    end
    (tns, nodim)
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
    lower = @f $stop - $start + 1
    upper = @f $stop - $start + 1
end

FinchNotation.isliteral(::Extent) = false

Base.:(==)(a::Extent, b::Extent) =
    a.start == b.start &&
    a.stop == b.stop &&
    a.lower == b.lower &&
    a.upper == b.upper

Extent(start, stop) = Extent(start, stop, (@f $stop - $start + 1), (@f $stop - $start + 1))

cache_dim!(ctx, var, ext::Extent) = Extent(
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
function getlower(ext::FinchNode)
    if ext.kind === virtual
        getlower(ext.val)
    else
        1
    end
end
function getupper(ext::FinchNode)
    if ext.kind === virtual
        getupper(ext.val)
    else
        1
    end
end
#TODO I don't like this def
function extent(ext::FinchNode)
    if ext.kind === virtual
        extent(ext.val)
    elseif ext.kind === value
        return 1
    elseif ext.kind === literal
        return 1
    else
        error("unimplemented")
    end
end
extent(ext::Integer) = 1

combinedim(ctx, a::Extent, b::Extent) =
    Extent(
        start = checklim(ctx, a.start, b.start),
        stop = checklim(ctx, a.stop, b.stop),
        lower = simplify(@f(min($(a.lower), $(b.lower))), ctx),
        upper = simplify(@f(min($(a.upper), $(b.upper))), ctx)
    )

combinedim(ctx, a::NoDimension, b::Extent) = b

struct SuggestedExtent{Ext}
    ext::Ext
end

FinchNotation.isliteral(::SuggestedExtent) = false

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
extent(ext::SuggestedExtent) = extent(ext.ext)

combinedim(ctx, a::SuggestedExtent, b::Extent) = b

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

"""
    virtual_size(tns, ctx)

Return a tuple of the dimensions of `tns` in the context `ctx` with access
mode `mode`. This is a function similar in spirit to `Base.axes`.
"""
function getsize end

virtual_size(tns, ctx, eldim) = virtual_size(tns, ctx)
function virtual_size(tns::FinchNode, ctx, eldim = nodim)
    if tns.kind === variable
        return virtual_size(ctx.bindings[tns], ctx, eldim)
    else
        return error("unimplemented")
    end
end

function virtual_elaxis(tns::FinchNode, ctx, dims...)
    if tns.kind === variable
        return virtual_elaxis(ctx.bindings[tns], ctx, dims...)
    else
        return error("unimplemented")
    end
end

function virtual_resize!(tns::FinchNode, ctx, dims...)
    if tns.kind === variable
        return (ctx.bindings[tns], eldim) = virtual_resize!(ctx.bindings[tns], ctx, dims...)
    else
        error("unimplemented")
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

FinchNotation.isliteral(::Narrow) = false

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

FinchNotation.isliteral(::Widen) = false

widendim(dim) = Widen(dim)
widendim(::NoDimension) = nodim

Base.:(==)(a::Widen, b::Widen) = a.ext == b.ext

getstart(ext::Widen) = getstart(ext.ext)
getstop(ext::Widen) = getstop(ext.ext)


combinedim(ctx, a::Narrow, b::Extent) = resultdim(ctx, a, Narrow(b))
combinedim(ctx, a::Narrow, b::SuggestedExtent) = a
combinedim(ctx, a::Narrow, b::NoDimension) = a

function combinedim(ctx, a::Narrow{<:Extent}, b::Narrow{<:Extent})
    Narrow(Extent(
        start = simplify(@f(max($(getstart(a)), $(getstart(b)))), ctx),
        stop = simplify(@f(min($(getstop(a)), $(getstop(b)))), ctx),
        lower = if getstart(a) == getstart(b) || getstop(a) == getstop(b)
            simplify(@f(min($(a.ext.lower), $(b.ext.lower))), ctx)
        else
            literal(0)
        end,
        upper = simplify(@f(min($(a.ext.upper), $(b.ext.upper))), ctx)
    ))
end

combinedim(ctx, a::Widen, b::Extent) = b
combinedim(ctx, a::Widen, b::NoDimension) = a
combinedim(ctx, a::Widen, b::SuggestedExtent) = a

function combinedim(ctx, a::Widen{<:Extent}, b::Widen{<:Extent})
    Widen(Extent(
        start = simplify(@f(min($(getstart(a)), $(getstart(b)))), ctx),
        stop = simplify(@f(max($(getstop(a)), $(getstop(b)))), ctx),
        lower = simplify(@f(max($(a.ext.lower), $(b.ext.lower))), ctx),
        upper = if getstart(a) == getstart(b) || getstop(a) == getstop(b)
            simplify(@f(max($(a.ext.upper), $(b.ext.upper))), ctx)
        else
            simplify(@f($(a.ext.upper) + $(b.ext.upper)), ctx)
        end,
    ))
end

resolvedim(ext) = ext
resolvedim(ext::Narrow) = resolvedim(ext.ext)
resolvedim(ext::Widen) = resolvedim(ext.ext)
cache_dim!(ctx, tag, ext::Narrow) = Narrow(cache_dim!(ctx, tag, ext.ext))
cache_dim!(ctx, tag, ext::Widen) = Widen(cache_dim!(ctx, tag, ext.ext))