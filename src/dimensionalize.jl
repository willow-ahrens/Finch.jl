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
@kwdef mutable struct InferDimensions
    ctx
    prev_dims = Dict()
    dims = Dict()
    escape = []
    check = false
end

function dimensionalize!(prgm, ctx) 
    dims = Dict()
    while true
        prev_dims = dims
        dims = Dict()
        InferDimensions(ctx=ctx, prev_dims = prev_dims, dims = dims)(prgm)
        if Dict(k=>typeof(v) for (k, v) in prev_dims) == Dict(k=>typeof(v) for (k, v) in dims)
            break
        end
    end
    InferDimensions(ctx=ctx, prev_dims = dims, check=true)(prgm)
    return (prgm, dims)
end

struct NoDimension end
nodim = NoDimension()

(ctx::InferDimensions)(node, ext) = (ctx(node); nodim)

function (ctx::InferDimensions)(node::With)
    ctx_2 = shallowcopy(ctx)
    ctx_2.escape = union(ctx.escape, map(getname, getresults(node.prod)))
    With(ctx_2(node.cons), ctx_2(node.prod))
end

function (ctx::InferDimensions)(node::Name, ext)
    ctx.dims[getname(node)] = resultdim(ctx.ctx, ctx.check, get(ctx.dims, getname(node), nodim), ext)
    get(ctx.prev_dims, getname(node), nodim)
end

(ctx::InferDimensions)(node::Protocol, ext) = ctx(node.idx, ext)

function (ctx::InferDimensions)(node::Access)
    exts = getdims(node.tns, ctx.ctx, node.mode)
    if node.mode != Read() || getname(node.tns) in ctx.escape
        exts = map(enumerate(exts), node.idxs) do (n, ext), idx
            ext = suggest(ext)
            if getname(node.tns) !== nothing
                site = (getname(node.tns), n)
                ext = resultdim(ctx.ctx, false, get(ctx.prev_dims, site, nodim), ext)
                ctx.dims[site] = resultdim(ctx.ctx, false, get(ctx.dims, site, nodim), ctx(idx, ext))
                ext
            end
        end
        ctx.check && setdims!(node.tns, ctx.ctx, node.mode, exts...)
    else
        foreach(ctx, node.idxs, exts)
    end
    ctx(node.tns)
    return nodim
end

setdims!(tns, ctx, mode, dims...) = (map((ext_1, ext_2) -> resultdim(ctx, true, ext_1, ext_2), dims, getdims(tns, ctx, mode)), tns)

function (ctx::InferDimensions)(node)
    if istree(node)
        foreach(ctx, arguments(node))
    end
    nodim
end

#=
struct CheckDimension{Dim}
    dim::Dim
end

checkdim(ctx, a, b) = resultdim(ctx, CheckDimension(a), CheckDimension(b))
=#



struct UnknownDimension end

resultdim(ctx, check, a, b, c, tail...) = resultdim(ctx, check, a, resultdim(ctx, check, b, c, tail...))
function resultdim(ctx, check, a, b)
    c = combinedim(ctx, check, a, b)
    d = combinedim(ctx, check && (c isa UnknownDimension), b, a)
    return _resultdim(ctx, a, b, c, d)
end
_resultdim(ctx, a, b, c::UnknownDimension, d::UnknownDimension) = throw(MethodError(combinedim, (ctx, false, a, b)))
_resultdim(ctx, a, b, c, d::UnknownDimension) = c
_resultdim(ctx, a, b, c::UnknownDimension, d) = d
_resultdim(ctx, a, b, c, d) = c #TODO assert same lattice type here.
#_resultdim(ctx, a, b, c::T, d::T) where {T} = (c == d) ? c : @assert false "TODO combinedim_ambiguity_error"

"""
    combinedim(ctx, check, a, b)

Combine the two dimensions `a` and `b`. If `check`, also 
check that they are equivalent. To avoid
ambiguity, only define one of

```
combinedim(::Ctx, ::Bool, ::A, ::B)
combinedim(::Ctx, ::Bool, ::B, ::A)
```
"""
combinedim(ctx, check, a, b) = UnknownDimension()

combinedim(ctx, check, a::NoDimension, b) = b

@kwdef struct Extent
    start
    stop
    lower = @i $stop - $start + 1
    upper = @i $stop - $start + 1
end

Extent(start, stop) = Extent(start, stop, (@i $stop - $start + 1), (@i $stop - $start + 1))

getstart(ext::Extent) = ext.start
getstop(ext::Extent) = ext.stop
getlower(ext::Extent) = ext.lower
getupper(ext::Extent) = ext.upper
extent(ext::Extent) = @i $(ext.stop) - $(ext.start) + 1

combinedim(ctx, check, a::Extent, b::Extent) =
    Extent(resultdim(ctx, check, a.start, b.start), resultdim(ctx, check, a.stop, b.stop), resultdim(ctx, false, a.lower, b.lower), resultdim(ctx, false, a.upper, b.upper))

combinedim(ctx, check, a::NoDimension, b::Extent) = b

struct SuggestedExtent{Ext}
    ext::Ext
end
suggest(ext) = SuggestedExtent(ext)
suggest(ext::SuggestedExtent) = ext
suggest(ext::NoDimension) = nodim

#TODO maybe just call something like resolve_extent to unwrap?
getstart(ext::SuggestedExtent) = getstart(ext.ext)
getstop(ext::SuggestedExtent) = getstop(ext.ext)
extent(ext::SuggestedExtent) = extent(ext.ext)

combinedim(ctx::Finch.LowerJulia, check, a::SuggestedExtent, b::Extent) = b

combinedim(ctx::Finch.LowerJulia, check, a::SuggestedExtent, b::NoDimension) = a

combinedim(ctx::Finch.LowerJulia, check, a::SuggestedExtent, b::SuggestedExtent) = a #TODO this is a weird case, because either suggestion could set the dimension for the other.

function combinedim(ctx::Finch.LowerJulia, check, a::Virtual, b::Virtual)
    if check && a.ex != b.ex
        push!(ctx.preamble, quote
            $(ctx(a)) == $(ctx(b)) || throw(DimensionMismatch("mismatched dimension limits"))
        end)
    end
    a
end

combinedim(ctx::Finch.LowerJulia, check, a::IndexExpression, b::Union{<:IndexExpression, <:Virtual, <:Number}) = b

function combinedim(ctx::Finch.LowerJulia, check, a::Number, b::Virtual)
    if check
        push!(ctx.preamble, quote
            $a == $(ctx(b)) || throw(DimensionMismatch("mismatched dimension limits"))
        end)
    end
    a
end

function combinedim(ctx::Finch.LowerJulia, check, a::Number, b::Number)
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

getstart(ext::Narrow) = getstart(ext.ext)
getstop(ext::Narrow) = getstop(ext.ext)

struct Widen{Ext}
    ext::Ext
end

getstart(ext::Widen) = getstart(ext.ext)
getstop(ext::Widen) = getstop(ext.ext)

combinedim(ctx, check, a::Narrow, b::Extent) = resultdim(ctx, check, a, Narrow(b))
combinedim(ctx, check, a::Narrow, b::NoDimension) = a

function combinedim(ctx, check, a::Narrow{<:Extent}, b::Narrow{<:Extent})
    Narrow(Extent(
        start = cache!(ctx, :start, simplify(@i max($(getstart(a)), $(getstart(b))))),
        stop = cache!(ctx, :stop, simplify(@i min($(getstop(a)), $(getstop(b))))),
        lower = if getstart(a) == getstart(b) || getstop(a) == getstop(b)
            simplify(@i(min($(a.ext.lower), $(b.ext.lower))))
        else
            0
        end,
        upper = simplify(@i(min($(a.ext.upper), $(b.ext.upper))))
    ))
end

combinedim(ctx, check, a::Widen, b::Extent) = resultdim(ctx, check, a, Widen(b))
combinedim(ctx, check, a::Widen, b::NoDimension) = a

function combinedim(ctx, check, a::Widen{<:Extent}, b::Widen{<:Extent})
    Widen(Extent(
        start = cache!(ctx, :start, simplify(@i min($(getstart(a)), $(getstart(b))))),
        stop = cache!(ctx, :stop, simplify(@i max($(getstop(a)), $(getstop(b))))),
        lower = simplify(@i(max($(a.ext.lower), $(b.ext.lower)))),
        upper = if getstart(a) == getstart(b) || getstop(a) == getstop(b)
            simplify(@i(max($(a.ext.upper), $(b.ext.upper))))
        else
            simplify(@i($(a.ext.upper) + $(b.ext.upper)))
        end,
    ))
end

resolvedim(ctx, ext) = ext
resolvedim(ctx, ext::Narrow) = resolvedim(ctx, ext.ext)
resolvedim(ctx, ext::Widen) = resolvedim(ctx, ext.ext)