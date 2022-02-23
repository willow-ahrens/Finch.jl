"""
    GatherDimensions(ctx, dims)

A program traversal which gathers the dimensions of tensors based on shared
indices. Index sharing is transitive, so `A[i] = B[i]` and `B[j] = C[j]` will
induce a gathering of the dimensions of `A`, `B`, and `C` into one. The
resulting dimensions are gathered into a `Dimensions` object, which can be
accesed with an index name or a `(tensor_name, mode_name)` tuple.

The program is assumed to be in SSA form.

See also: [`getdims`](@ref), [`getsites`](@ref), [`combinedim`](@ref),
[`TransformSSA`](@ref)
"""
@kwdef struct GatherDimensions <: AbstractTransformVisitor
    ctx
    dims
end

function previsit!(node::Access, ctx::GatherDimensions)
    if !istree(node.tns)
        for (idx, dim, n) in zip(getname.(node.idxs), getdims(node.tns, ctx.ctx, node.mode), getsites(node.tns))
            site = (getname(node.tns), n)
            if !haskey(ctx.dims, site)
                push!(ctx.dims.labels, site)
                ctx.dims.dims[site] = dim
            end
            site_axis = ctx.dims[site]
            if !haskey(ctx.dims, idx)
                push!(ctx.dims.labels, idx)
                ctx.dims.dims[union!(ctx.dims.labels, site, idx)] = site_axis
            elseif !in_same_set(ctx.dims.labels, idx, site)
                idx_axis = ctx.dims[idx]
                ctx.dims.dims[union!(ctx.dims.labels, site, idx)] =
                    site_axis === nothing ? idx_axis :
                    idx_axis === nothing ? site_axis :
                    resultdim(ctx.ctx, idx_axis, site_axis)
            end
        end
    end
    node
end

mutable struct Dimensions
    labels
    dims
end

Dimensions() = Dimensions(DisjointSets{Any}(), Dict())

#there is a wacky julia bug that is fixed on 70cc57cb36. It causes find_root! to sometimes
#return the right index into dims.labels.revmap, but reinterprets the access as the wrong type.
#not sure which commit actually fixed this, but I need to move on with my life.
Base.getindex(dims::Dimensions, idx) = dims.dims[find_root!(dims.labels, idx)]
Base.setindex!(dims::Dimensions, ext, idx) = dims.dims[find_root!(dims.labels, idx)] = ext
Base.haskey(dims::Dimensions, idx) = idx in dims.labels

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