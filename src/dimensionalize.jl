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
    dims
    escape=[]
end

#=
function (ctx::Dimensionalize)(node::Loop, ::DefaultStyle) 
    isempty(node.idxs) || error("Inference Error: no declared extent for $(node.idxs[1])")
    return ctx(node.body)
end

function (ctx::Dimensionalize)(node::Loop, style::ExtentStyle) 
    idx = node.idxs[1]
    ext = resolve_extent(ctx.ctx, style.ext)
    ctx.dims[idx] = ext
    loop(idx, ctx(loop(node.idxs[2:end], node.body)))
end

combine_style(a::ExtentStyle, ::DefaultStyle) = a
combine_style(ctx::Dimensionalize, a::ExtentStyle, b::ExtentStyle) = ExtentStyle(resultdim(ctx.ctx, a.ext, b.ext))
function make_style(root::Loop, ctx::Dimensionalize, node::Access)
    getdims(ctx, node.tns)[findall(isequal(idx), node.idxs)]
end

=#

function (ctx::Dimensionalize)(node::With, ::DefaultStyle) 
    ctx_2 = Dimensionalize(ctx.ctx, ctx.dims, union(ctx.escape, map(getname, getresults(node.prod))))
    With(ctx_2(node.cons), ctx(node.prod))
end

function redimensionalize!(node::Access{<:Any, Read}, ctx::Dimensionalize)
    if getname(node.tns) !== nothing && getname(node.tns) in ctx.escape
        return [MissingExtent() for ext in 1:length(getsites(node.tns))]
    else
        return getdims(node.tns, ctx.ctx, node.mode)
    end
end

function redimensionalize!(node::Access{<:Any, <:Union{Write, Update}}, ctx::Dimensionalize)
    return [SuggestedExtent(ext) for ext in getdims(node.tns, ctx.ctx, node.mode)]
end

function previsit!(node::Access, ctx::Dimensionalize)
    if !istree(node.tns)
        for (idx, dim, n) in zip(getname.(node.idxs), redimensionalize!(node, ctx), getsites(node.tns))
            site = (getname(node.tns), n)
            mergewith!((a, b) -> resultdim(ctx.ctx, a, b), ctx.dims, DisjointDict((idx, site)=>dim))
        end
    end
    node
end

struct UnknownDimension end

resultdim(ctx, a, b) = _resultdim(ctx, a, b, combinedim(ctx, a, b), combinedim(ctx, b, a))
_resultdim(ctx, a, b, c::UnknownDimension, d::UnknownDimension) = throw(MethodError(combinedim, (ctx, a, b)))
_resultdim(ctx, a, b, c, d::UnknownDimension) = c
_resultdim(ctx, a, b, c::UnknownDimension, d) = d
_resultdim(ctx, a, b, c, d) = c

"""
    combinedim(ctx, a, b)

Combine the two dimensions `a` and `b` in the context ctx. Usually, this
involves checking that they are equivalent and returning one of them. To avoid
ambiguity, only define one of

```
combinedim(::Ctx, ::A, ::B)
combinedim(::Ctx, ::B, ::A)
```
"""
combinedim(ctx, a, b) = UnknownDimension()

struct UnknownLimit end

resultlim(ctx, a, b) = _resultlim(ctx, combinelim(ctx, a, b), combinelim(ctx, b, a))
_resultlim(ctx, a::UnknownLimit, b::UnknownLimit) = throw(MethodError(combinelim, ctx, a, b))
_resultlim(ctx, a, b::UnknownLimit) = a
_resultlim(ctx, a::UnknownLimit, b) = b
#_resultlim(ctx, a::T, b::T) where {T} = (a == b) ? a : @assert false "TODO combinelim_ambiguity_error"
#_resultlim(ctx, a, b) = (a == b) ? a : @assert false "TODO combinelim_ambiguity_error"
_resultlim(ctx, a, b) = a

"""
    combinelim(ctx, a, b)

Combine the two dimension extent limits `a` and `b` in the context ctx. Usually, this
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