struct ProductArray{dim, Body} <: AbstractCombinator
    body::Body
end

ProductArray(body, dim) = ProductArray{dim}(body)
ProductArray{dim}(body::Body) where {dim, Body} = ProductArray{dim, Body}(body)

Base.show(io::IO, ex::ProductArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::ProductArray{dim}) where {dim}
	print(io, "ProductArray{$dim}($(ex.body))")
end

#Base.getindex(arr::ProductArray, i...) = ...

struct VirtualProductArray <: AbstractVirtualCombinator
    body
    dim
end

function is_injective(ctx, lvl::VirtualProductArray)
    sub = is_injective(ctx, lvl.body)
    return [sub[1:lvl.dim]..., false, sub[lvl.dim + 1:end]...]
end
function is_concurrent(ctx, lvl::VirtualProductArray)
    sub = is_concurrent(ctx, lvl.body)
    return [sub[1:lvl.dim]..., false, sub[lvl.dim + 1:end]...]
end
function is_atomic(ctx, lvl::VirtualProductArray)
    (below, overall) = is_atomic(ctx, lvl.body)
    return ([below[1:lvl.dim]..., below[lvl.dim] && below[lvl.dim+1], below[lvl.dim + 1:end]... ], overall)
end

Base.show(io::IO, ex::VirtualProductArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualProductArray)
	print(io, "VirtualProductArray($(ex.body), $(ex.dim))")
end

Base.summary(io::IO, ex::VirtualProductArray) = print(io, "VProduct($(summary(ex.body)), $(ex.dim))")

FinchNotation.finch_leaf(x::VirtualProductArray) = virtual(x)

function virtualize(ctx, ex, ::Type{ProductArray{dim, Body}}) where {dim, Body}
    VirtualProductArray(virtualize(ctx, :($ex.body), Body), dim)
end

"""
    products(tns, dim)

Create a `ProductArray` such that
```
    products(tns, dim)[i...] == tns[i[1:dim-1]..., i[dim] * i[dim + 1], i[dim + 2:end]...]
```
This is like [`toeplitz`](@ref) but with times instead of plus.
"""
products(body, dim) = ProductArray(body, dim)
function virtual_call(ctx, ::typeof(products), body, dim)
    @assert isliteral(dim)
    VirtualProductArray(body, dim.val)
end

unwrap(ctx, arr::VirtualProductArray, var) = call(products, unwrap(ctx, arr.body, var), arr.dim)

lower(ctx::AbstractCompiler, tns::VirtualProductArray, ::DefaultStyle) = :(ProductArray($(ctx(tns.body)), $(tns.dim)))

#virtual_size(ctx::AbstractCompiler, arr::Fill) = (dimless,) # this is needed for multidimensional convolution..
#virtual_size(ctx::AbstractCompiler, arr::Simplify) = (dimless,)
#virtual_size(ctx::AbstractCompiler, arr::Furlable) = (dimless,)

function virtual_size(ctx::AbstractCompiler, arr::VirtualProductArray)
    dims = virtual_size(ctx, arr.body)
    return (dims[1:arr.dim - 1]..., dimless, dimless, dims[arr.dim + 1:end]...)
end
function virtual_resize!(ctx::AbstractCompiler, arr::VirtualProductArray, dims...)
    virtual_resize!(ctx, arr.body, dims[1:arr.dim - 1]..., dimless, dims[arr.dim + 2:end]...)
end

function instantiate_reader(arr::VirtualProductArray, ctx, protos)
    VirtualProductArray(instantiate_reader(arr.body, ctx, [protos[1:arr.dim]; protos[arr.dim + 2:end]]), arr.dim)
end
function instantiate_updater(arr::VirtualProductArray, ctx, protos)
    VirtualProductArray(instantiate_updater(arr.body, ctx, [protos[1:arr.dim]; protos[arr.dim + 2:end]]), arr.dim)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualProductArray) = ctx(node.body)
function stylize_access(ctx::Stylize{<:AbstractCompiler}, node, tns::VirtualProductArray)
    stylize_access(ctx, node, tns.body)
end

function popdim(node::VirtualProductArray, ctx)
    if length(virtual_size(ctx, node)) == node.dim
        return node.body
    else
        return node
    end
end

truncate(ctx, node::VirtualProductArray, ext, ext_2) = VirtualProductArray(truncate(ctx, node.body, ext, ext_2), node.dim)

function get_point_body(ctx, node::VirtualProductArray, ext, idx)
    body_2 = get_point_body(ctx, node.body, ext, idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualProductArray(body_2, node.dim), ctx)
    end
end

(ctx::ThunkVisitor)(node::VirtualProductArray) = VirtualProductArray(ctx(node.body), node.dim)

function get_run_body(ctx, node::VirtualProductArray, ext)
    body_2 = get_run_body(ctx, node.body, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualProductArray(body_2, node.dim), ctx)
    end
end

function get_acceptrun_body(ctx, node::VirtualProductArray, ext)
    body_2 = get_acceptrun_body(ctx, node.body, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualProductArray(body_2, node.dim), ctx)
    end
end

function (ctx::SequenceVisitor)(node::VirtualProductArray)
    map(ctx(node.body)) do (keys, body)
        return keys => VirtualProductArray(body, node.dim)
    end
end

phase_body(ctx, node::VirtualProductArray, ext, ext_2) = VirtualProductArray(phase_body(ctx, node.body, ext, ext_2), node.dim)
phase_range(ctx, node::VirtualProductArray, ext) = phase_range(ctx, node.body, ext)

get_spike_body(ctx, node::VirtualProductArray, ext, ext_2) = VirtualProductArray(get_spike_body(ctx, node.body, ext, ext_2), node.dim)
get_spike_tail(ctx, node::VirtualProductArray, ext, ext_2) = VirtualProductArray(get_spike_tail(ctx, node.body, ext, ext_2), node.dim)

visit_fill(node, tns::VirtualProductArray) = visit_fill(node, tns.body)
visit_simplify(node::VirtualProductArray) = VirtualProductArray(visit_simplify(node.body), node.dim)

(ctx::SwitchVisitor)(node::VirtualProductArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualProductArray(body, node.dim)
end

jumper_body(ctx, node::VirtualProductArray, ext) = VirtualProductArray(jumper_body(ctx, node.body, ext), node.dim)
stepper_body(ctx, node::VirtualProductArray, ext) = VirtualProductArray(stepper_body(ctx, node.body, ext), node.dim)
stepper_seek(ctx, node::VirtualProductArray, ext) = stepper_seek(ctx, node.body, ext)
jumper_seek(ctx, node::VirtualProductArray, ext) = jumper_seek(ctx, node.body, ext)

getroot(tns::VirtualProductArray) = getroot(tns.body)

function unfurl(ctx, tns::VirtualProductArray, ext, mode, protos...)
    if length(virtual_size(ctx, tns)) == tns.dim + 1
        Unfurled(tns,
            Lookup(
                body = (ctx, idx) -> VirtualPermissiveArray(VirtualScaleArray(tns.body, ([literal(1) for _ in 1:tns.dim - 1]..., idx)), ([false for _ in 1:tns.dim - 1]..., true)), 
            )
        )
    else
        VirtualProductArray(unfurl(ctx, tns.body, ext, mode, protos...), tns.dim)
    end
end
