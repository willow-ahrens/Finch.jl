"""
    Dimensionalize(ctx)

A program traversal which gathers dimensions of tensors based on shared indices.
Index sharing is transitive, so `A[i] = B[i]` and `B[j] = C[j]` will induce a
gathering of the dimensions of `A`, `B`, and `C` into one. The resulting
dimensions are gathered into a `Dimensions` object, which can be accesed with an
index name or a `(tensor_name, mode_name)` tuple.

The program is assumed to be in SSA form.

See also: [`getdims`](@ref), [`getsites`](@ref), [`combinedim`](@ref),
[`TransformSSA`](@ref)
"""
@kwdef struct Dimensionalize <: AbstractTransformVisitor
    ctx
    dims = Dict()
end

function dimensionalize!(prgm, ctx) 
    ctx_2 = Dimensionalize(ctx=ctx)
    prgm = Initialize(ctx = ctx_2)(prgm)
    prgm = ctx_2(prgm)
    prgm = Finalize(ctx = ctx_2)(prgm)
    return (prgm, ctx_2.dims)
end

function (ctx::Dimensionalize)(node::With, ::DefaultStyle) 
    target = map(getname, getresults(node.prod))
    prod = Initialize(ctx=ctx, target=target)(node.prod)
    prod = ctx(prod)
    prod = Finalize(ctx=ctx, target=target)(prod)
    cons = Initialize(ctx=ctx, target=target)(node.cons)
    cons = ctx(cons)
    cons = Finalize(ctx=ctx, target=target)(cons)
    return with(cons, prod)
end

function (ctx::Dimensionalize)(node::Loop, ::DefaultStyle)
    if get(ctx.dims, getname(node.idx), MissingDimension()) == MissingDimension()
        error("could not dimensionalize")
    end
    loop(node.idx, ctx(node.body))
end

resolvedim(ctx, ext) = ext

struct MissingDimension end


(ctx::LowerJulia)(root::MissingDimension) = error()

@kwdef struct InferDimension{Ctx}
    ctx::Ctx
    dims
end
(ctx::InferDimension)(node, ext) = ctx(node)
(ctx::InferDimension)(node::Name, ext) = 
    ctx.dims[getname(node)] = resultdim(ctx.ctx, get(ctx.dims, getname(node), MissingDimension()), ext)

(ctx::InferDimension)(node::Union{Gallop, Walk, Follow, Laminate, Extrude}, ext) =
    ctx.dims[getname(node)] = resultdim(ctx.ctx, get(ctx.dims, getname(node), MissingDimension()), ext) #TODO

function (ctx::InferDimension)(node)
    if istree(node)
        foreach(ctx, arguments(node))
    end
end

function (ctx::InferDimension)(node::Access)
    foreach(ctx, node.idxs, getdims(node.tns, ctx.ctx, node.mode))
end

function initialize!(tns, ctx::Dimensionalize, mode, idxs...)
    foreach(InferDimension(ctx.ctx, ctx.dims), idxs, getdims(tns, ctx.ctx, mode))
    access(tns, mode, idxs...)
end

@kwdef struct EvalDimension{Ctx}
    ctx::Ctx
    dims
end
(ctx::EvalDimension)(node) = MissingDimension()
(ctx::EvalDimension)(node::Name) = ctx.dims[getname(node)]
(ctx::InferDimension)(node::Union{Gallop, Walk, Follow, Laminate, Extrude}, ext) = ctx.dims[getname(node)] # TODO

finalize!(tns, ctx::Dimensionalize, mode::Union{Write, Update}, idxs...) = setdims!(tns, ctx.ctx, mode, map(EvalDimension(ctx = ctx.ctx, dims = ctx.dims), idxs)...)



struct UnknownDimension end

resultdim(ctx, a, b) = _resultdim(ctx, a, b, combinedim(ctx, a, b), combinedim(ctx, b, a))
_resultdim(ctx, a, b, c::UnknownDimension, d::UnknownDimension) = throw(MethodError(combinedim, (ctx, a, b)))
_resultdim(ctx, a, b, c, d::UnknownDimension) = c
_resultdim(ctx, a, b, c::UnknownDimension, d) = d
_resultdim(ctx, a, b, c, d) = c
#_resultdim(ctx, a, b, c::T, d::T) where {T} = (c == d) ? c : @assert false "TODO combinedim_ambiguity_error"

"""
    combinedim(ctx, a, b)

Combine the two dimensions `a` and `b`. Usually, this
involves checking that they are equivalent and returning one of them. To avoid
ambiguity, only define one of

```
combinedim(::Ctx, ::A, ::B)
combinedim(::Ctx, ::B, ::A)
```
"""
combinedim(ctx, a, b) = UnknownDimension()

combinedim(ctx, a::MissingDimension, b) = b

@kwdef mutable struct Extent
    start
    stop
end

start(ext::Extent) = ext.start
stop(ext::Extent) = ext.stop
extent(ext::Extent) = @i stop - start + 1

combinedim(ctx, a::Extent, b::Extent) =
    Extent(resultlim(ctx, a.start, b.start), resultlim(ctx, a.stop, b.stop))

@kwdef mutable struct UnitExtent
    val
end

start(ext::UnitExtent) = ext.val
stop(ext::UnitExtent) = ext.val
extent(ext::UnitExtent) = 1

function combinedim(ctx, a::UnitExtent, b::Extent)
    resultlim(ctx, a.val, b.stop)
    UnitExtent(resultlim(ctx, a.val, b.start))
end

combinedim(ctx, a::UnitExtent, b::UnitExtent) =
    UnitExtent(resultlim(ctx, a.val, b.val))

combinedim(ctx, a::MissingDimension, b::Extent) = b

struct SuggestedExtent
    ext
end

#TODO maybe just call something like resolve_extent to unwrap?
start(ext::SuggestedExtent) = start(ext.ext)
stop(ext::SuggestedExtent) = stop(ext.ext)
extent(ext::SuggestedExtent) = extent(ext.ext)

resolvedim(ctx, ext::SuggestedExtent) = resolvedim(ctx, ext.ext)

combinedim(ctx::Finch.LowerJulia, a::SuggestedExtent, b::Extent) = b

combinedim(ctx::Finch.LowerJulia, a::SuggestedExtent, b::MissingDimension) = a

combinedim(ctx::Finch.LowerJulia, a::SuggestedExtent, b::SuggestedExtent) = a #TODO this is a weird case, because either suggestion could set the dimension for the other.

function combinelim(ctx::Finch.LowerJulia, a::Union{Virtual, Number}, b::Virtual)
    push!(ctx.preamble, quote
        $(ctx(a)) == $(ctx(b)) || throw(DimensionMismatch("mismatched dimension starts"))
    end)
    a #TODO could do some simplify stuff here
end

function combinelim(ctx::Finch.LowerJulia, a::Number, b::Number)
    a == b || throw(DimensionMismatch("mismatched dimension starts ($a != $b)"))
    a #TODO could do some simplify stuff here
end

struct UnknownLimit end

resultlim(ctx, a, b) = _resultlim(ctx, a, b, combinelim(ctx, a, b), combinelim(ctx, b, a))
_resultlim(ctx, a, b, c::UnknownLimit, d::UnknownLimit) = throw(MethodError(combinelim, (ctx, a, b)))
_resultlim(ctx, a, b, c, d::UnknownLimit) = c
_resultlim(ctx, a, b, c::UnknownLimit, d) = d
_resultlim(ctx, a, b, c, d) = c
#_resultlim(ctx, a, b, c::T, d::T) where {T} = (c == d) ? c : @assert false "TODO combinelim_ambiguity_error"

"""
    combinelim(ctx, a, b)

Combine the two dimension extent limits `a` and `b`. Usually, this
involves checking that they are equivalent and returning one of them. To avoid
ambiguity, only define one of

```
combinelim(::Ctx, ::A, ::B)
combinelim(::Ctx, ::B, ::A)
```
"""
combinelim(ctx, a, b) = UnknownLimit()

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


start(val) = val
stop(val) = val
extent(val) = 1