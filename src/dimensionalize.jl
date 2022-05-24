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
    println(dims)
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

function (ctx::InferDimensions)(node::Union{Gallop, Walk, Follow, Laminate, Extrude}, ext)
    ctx.dims[getname(node)] = resultdim(ctx.ctx, ctx.check, get(ctx.dims, getname(node), nodim), ext)
    get(ctx.prev_dims, getname(node), nodim)
end

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

@kwdef mutable struct Extent{Start, Stop}
    start::Start
    stop::Stop
end

start(ext::Extent) = ext.start
stop(ext::Extent) = ext.stop
extent(ext::Extent) = @i stop - start + 1

combinedim(ctx, check, a::Extent, b::Extent) =
    Extent(resultdim(ctx, check, a.start, b.start), resultdim(ctx, check, a.stop, b.stop))

@kwdef mutable struct UnitExtent{Val}
    val::Val
end

start(ext::UnitExtent) = ext.val
stop(ext::UnitExtent) = ext.val
extent(ext::UnitExtent) = 1

function combinedim(ctx, check, a::UnitExtent, b::Extent)
    resultdim(ctx, check, a.val, b.stop)
    UnitExtent(resultdim(ctx, check, a.val, b.start))
end

combinedim(ctx, check, a::UnitExtent, b::UnitExtent) =
    UnitExtent(resultdim(ctx, check, a.val, b.val))

combinedim(ctx, check, a::NoDimension, b::Extent) = b

struct SuggestedExtent{Ext}
    ext::Ext
end
suggest(ext) = SuggestedExtent(ext)
suggest(ext::SuggestedExtent) = ext
suggest(ext::NoDimension) = nodim

#TODO maybe just call something like resolve_extent to unwrap?
start(ext::SuggestedExtent) = start(ext.ext)
stop(ext::SuggestedExtent) = stop(ext.ext)
extent(ext::SuggestedExtent) = extent(ext.ext)

combinedim(ctx::Finch.LowerJulia, check, a::SuggestedExtent, b::Extent) = b

combinedim(ctx::Finch.LowerJulia, check, a::SuggestedExtent, b::NoDimension) = a

combinedim(ctx::Finch.LowerJulia, check, a::SuggestedExtent, b::SuggestedExtent) = a #TODO this is a weird case, because either suggestion could set the dimension for the other.

function combinedim(ctx::Finch.LowerJulia, check, a::Union{Virtual, Number}, b::Virtual)
    if check && a != b
        push!(ctx.preamble, quote
            $(ctx(a)) == $(ctx(b)) || throw(DimensionMismatch("mismatched dimension limits"))
        end)
    end
    a #TODO could do some simplify stuff here
end

function combinedim(ctx::Finch.LowerJulia, check, a::Number, b::Number)
    a == b || throw(DimensionMismatch("mismatched dimension limits ($a != $b)"))
    a #TODO could do some simplify stuff here
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


start(val) = val
stop(val) = val
extent(val) = 1