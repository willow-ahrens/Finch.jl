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

@kwdef struct Dimensionalize
    body
end

FinchNotation.finch_leaf(x::Dimensionalize) = virtual(x)

struct DimensionalizeStyle end

Base.show(io, ex::Dimensionalize) = Base.show(io, MIME"text/plain", ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Dimensionalize)
    print(io, "Dimensionalize(")
    print(io, ex.body)
    print(io, ")")
end

(ctx::Stylize{<:AbstractCompiler})(node::Dimensionalize) = DimensionalizeStyle()
combine_style(a::DefaultStyle, b::DimensionalizeStyle) = DimensionalizeStyle()
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
function lower(prgm, ctx::AbstractCompiler,  ::DimensionalizeStyle) 
    contain(ctx) do ctx_2
        prgm = dimensionalize!(prgm, ctx_2)
        ctx_2(prgm)
    end
end

function dimensionalize!(prgm, ctx) 
    prgm = Rewrite(Postwalk(x -> if x isa Dimensionalize x.body end))(prgm)
    prgm = DeclareDimensions(ctx=ctx)(prgm, nodim)
    return prgm
end

function (ctx::DeclareDimensions)(node::Dimensionalize, dim)
    ctx(node.body, dim)
end
(ctx::DeclareDimensions)(node) = ctx(node, nodim)
function (ctx::DeclareDimensions)(node::FinchNode, dim)
    if node.kind === index
        ctx.dims[node] = resultdim(ctx.ctx, get(ctx.dims, node, nodim), dim)
        return node
    elseif node.kind === access && node.tns.kind === virtual
        return declare_dimensions_access(node, ctx, node.tns.val, dim)
    elseif node.kind === loop && node.ext == index(:(:))
        body = ctx(node.body)
        return loop(node.idx, cache_dim!(ctx.ctx, getname(node.idx), resolvedim(ctx.dims[node.idx])), body)
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
    elseif istree(node)
        return similarterm(node, operation(node), map(arg->ctx(arg, nodim), arguments(node)))
    else
        return node
    end
end
function (ctx::InferDimensions)(node::FinchNode)
    if node.kind === index
        return (node, ctx.dims[node])
    elseif node.kind === access && node.mode.kind === updater && node.tns.kind === virtual
        return infer_dimensions_access(node, ctx, node.tns.val)
    elseif istree(node)
        FinchNotation.isstateful(node) && @assert false
        return (similarterm(node, operation(node), map(first, map(ctx, arguments(node)))), nodim)
    else
        return (node, nodim)
    end
end

declare_dimensions_access(node, ctx, tns::Dimensionalize, dim) = declare_dimensions_access(node, ctx, tns.body, dim)
function declare_dimensions_access(node, ctx, tns, eldim)
    if node.mode.kind !== reader && node.tns.kind === virtual && haskey(ctx.hints, getroot(node.tns))
        shape = map(suggest, virtual_size(tns, ctx.ctx))
        push!(ctx.hints[getroot(tns)], node)
    else
        shape = virtual_size(tns, ctx.ctx)
    end
    length(node.idxs) > length(shape) && throw(DimensionMismatch("more indices than dimensions in $(sprint(show, MIME("text/plain"), node))"))
    length(node.idxs) < length(shape) && throw(DimensionMismatch("less indices than dimensions in $(sprint(show, MIME("text/plain"), node))"))
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

combinedim(ctx, a::NoDimension, b::Extent) = b

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
combinedim(ctx, a::Narrow, b::SuggestedExtent) = a
combinedim(ctx, a::Narrow, b::NoDimension) = a

function combinedim(ctx, a::Narrow{<:Extent}, b::Narrow{<:Extent})
    Narrow(Extent(
        start = @f(max($(getstart(a)), $(getstart(b)))),
        stop = @f(min($(getstop(a)), $(getstop(b))))
    ))
end

combinedim(ctx, a::Widen, b::Extent) = b
combinedim(ctx, a::Widen, b::NoDimension) = a
combinedim(ctx, a::Widen, b::SuggestedExtent) = a

function combinedim(ctx, a::Widen{<:Extent}, b::Widen{<:Extent})
    Widen(Extent(
        start = @f(min($(getstart(a)), $(getstart(b)))),
        stop = @f(max($(getstop(a)), $(getstop(b))))
    ))
end

resolvedim(ext) = ext
resolvedim(ext::Narrow) = resolvedim(ext.ext)
resolvedim(ext::Widen) = resolvedim(ext.ext)
cache_dim!(ctx, tag, ext::Narrow) = Narrow(cache_dim!(ctx, tag, ext.ext))
cache_dim!(ctx, tag, ext::Widen) = Widen(cache_dim!(ctx, tag, ext.ext))