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
    Initialize(ctx = ctx_2)(prgm)
    ctx_2(prgm)
    Finalize(ctx = ctx_2)(prgm)
end

function (ctx::Dimensionalize)(node::With, ::ResultStyle) 
    target = map(getname, getresults(root.prod))
    Initialize(ctx, target)(node.prod)
    ctx(node.prod)
    Finalize(ctx, target)(node.prod)
    Initialize(ctx, target)(node.cons)
    ctx(node.cons)
    Finalize(ctx, target)(node.cons)
end

initialize!(tns, ctx::Dimensionalize, mode, idxs...) = access(tns, mode, idxs...)
finalize!(tns, ctx::Dimensionalize, mode, idxs...) = access(tns, mode, idxs...)

function (ctx::Dimensionalize)(node::Loop, ::DefaultStyle) 
    dim = InferDimension(ctx=ctx, idx=node.idx)(node.body)
    ctx.dims[idx] = resolve_dimension(ctx, dim)
    ctx(node.body)
end

@kwdef struct InferDimension{Ctx}
    ctx::Ctx
    idx
end
(ctx::InferDimension)(node, ext) = ctx(node)
(ctx::InferDimension)(node) = MissingExtent()
(ctx::InferDimension)(node::Name, ext) = ctx == getname(node) ? ext : MissingExtent()

function (ctx::InferDimension)(node)
    if istree(node)
        return mapreduce(ctx, result_dimension, arguments(node); init=MissingExtent())
    end
    return MissingExtent()
end

function (ctx::InferDimension)(node::Access)
    dim = mapreduce(ctx, result_dimension, node.idxs, getdims(node.tns); init=MissingExtent())
    return result_dimension(ctx(tns), dim)
end


@kwdef struct EvalDimension{Ctx}
    ctx::Ctx
end
(ctx::EvalDimension)(node) = MissingExtent()
(ctx::EvalDimension)(node::Name) = ctx.dims[getname(node)]

struct UnknownDimension end

resultdim(a, b) = _resultdim(a, b, combinedim(a, b), combinedim(b, a))
_resultdim(a, b, c::UnknownDimension, d::UnknownDimension) = throw(MethodError(combinedim, (ctx, a, b)))
_resultdim(a, b, c, d::UnknownDimension) = c
_resultdim(a, b, c::UnknownDimension, d) = d
_resultdim(a, b, c, d) = c

"""
    combinedim(a, b)

Combine the two dimensions `a` and `b`. Usually, this
involves checking that they are equivalent and returning one of them. To avoid
ambiguity, only define one of

```
combinedim(::Ctx, ::A, ::B)
combinedim(::Ctx, ::B, ::A)
```
"""
combinedim(a, b) = UnknownDimension()

struct UnknownLimit end

resultlim(a, b) = _resultlim(combinelim(a, b), combinelim(b, a))
_resultlim(a::UnknownLimit, b::UnknownLimit) = throw(MethodError(combinelim, ctx, a, b))
_resultlim(a, b::UnknownLimit) = a
_resultlim(a::UnknownLimit, b) = b
#_resultlim(a::T, b::T) where {T} = (a == b) ? a : @assert false "TODO combinelim_ambiguity_error"
#_resultlim(a, b) = (a == b) ? a : @assert false "TODO combinelim_ambiguity_error"
_resultlim(a, b) = a

"""
    combinelim(a, b)

Combine the two dimension extent limits `a` and `b`. Usually, this
involves checking that they are equivalent and returning one of them. To avoid
ambiguity, only define one of

```
combinelim(::Ctx, ::A, ::B)
combinelim(::Ctx, ::B, ::A)
```
"""
combinelim(a, b) = UnknownLimit()

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