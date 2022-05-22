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
@kwdef struct InferDimensions
    ctx
    dims = Dict()
    escape = []
    check = false
end

function dimensionalize!(prgm, ctx) 
    dims = Dict()
    while true
        dims_old = Dict(k=>typeof(v) for (k, v) in dims)
        InferDimensions(ctx=ctx, dims = dims)(prgm)
        if Dict(k=>typeof(v) for (k, v) in dims) == dims_old
            break
        end
    end
    InferDimensions(ctx=ctx, dims = dims, check=true)(prgm)
    return (prgm, dims)
end

resolvedim(ctx, ext) = ext

struct MissingDimension end

(ctx::InferDimensions)(node, ext) = (ctx(node); MissingDimension())

function (ctx::InferDimensions)(node::With)
    ctx_2 = InferDimensions(ctx.ctx, ctx.dims, union(ctx.escape, map(getname, getresults(node.prod))), ctx.check)
    With(ctx_2(node.cons), ctx_2(node.prod))
end

function (ctx::InferDimensions)(node::Name, ext)
    ext_2 = get(ctx.dims, getname(node), MissingDimension())
    ctx.dims[getname(node)] = resultdim(ctx.ctx, ext, ext_2)
end

function (ctx::InferDimensions)(node::Union{Gallop, Walk, Follow, Laminate, Extrude}, ext)
    ext_2 = get(ctx.dims, getname(node), MissingDimension())
    ctx.dims[getname(node)] = resultdim(ctx.ctx, ext, ext_2)
end

function (ctx::InferDimensions)(node::Access)
    exts = getdims(node.tns, ctx.ctx, node.mode)
    if node.mode != Read() || getname(node.tns) in ctx.escape
        exts = map(enumerate(exts), node.idxs) do (n, ext), idx
            ext = suggest(ext)
            if getname(node.tns) !== nothing
                site = (getname(node.tns), n)
                ext = resultdim(ctx.ctx, ext, get(ctx.dims, site, MissingDimension()))
                ctx.dims[site] = ctx(idx, ext)
            end
        end
        ctx.check && setdims!(node.tns, ctx.ctx, node.mode, exts...)
    else
        foreach(ctx, node.idxs, exts)
    end
    ctx(node.tns)
    return MissingDimension()
end

setdims!(tns, ctx, mode, dims...) = (map((ext_1, ext_2) -> resultdim(ctx, ext_1, ext_2), dims, getdims(tns, ctx, mode)), tns)

function (ctx::InferDimensions)(node)
    if istree(node)
        foreach(ctx, arguments(node))
    end
    MissingDimension()
end

#=
struct CheckDimension{Dim}
    dim::Dim
end

checkdim(ctx, a, b) = resultdim(ctx, CheckDimension(a), CheckDimension(b))
=#



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

@kwdef mutable struct Extent{Start, Stop}
    start::Start
    stop::Stop
end

start(ext::Extent) = ext.start
stop(ext::Extent) = ext.stop
extent(ext::Extent) = @i stop - start + 1

combinedim(ctx, a::Extent, b::Extent) =
    Extent(resultlim(ctx, a.start, b.start), resultlim(ctx, a.stop, b.stop))

@kwdef mutable struct UnitExtent{Val}
    val::Val
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

struct SuggestedExtent{Ext}
    ext::Ext
end
suggest(ext) = SuggestedExtent(ext)
suggest(ext::SuggestedExtent) = ext
suggest(ext::MissingDimension) = MissingDimension()

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
        $(ctx(a)) == $(ctx(b)) || throw(DimensionMismatch("mismatched dimension limits"))
    end)
    a #TODO could do some simplify stuff here
end

function combinelim(ctx::Finch.LowerJulia, a::Number, b::Number)
    a == b || throw(DimensionMismatch("mismatched dimension limits ($a != $b)"))
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