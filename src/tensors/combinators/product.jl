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

function is_injective(lvl::VirtualProductArray, ctx)
    sub = is_injective(lvl.body, ctx)
    return [sub[1:lvl.dim]..., false, sub[lvl.dim + 1:end]...]
end
function is_concurrent(lvl::VirtualProductArray, ctx)
    sub = is_concurrent(lvl.body, ctx)
    return [sub[1:lvl.dim]..., false, sub[lvl.dim + 1:end]...]
end
is_atomic(lvl::VirtualProductArray, ctx) = is_atomic(lvl.body, ctx)

Base.show(io::IO, ex::VirtualProductArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualProductArray)
	print(io, "VirtualProductArray($(ex.body), $(ex.dim))")
end

Base.summary(io::IO, ex::VirtualProductArray) = print(io, "VProduct($(summary(ex.body)), $(ex.dim))")

FinchNotation.finch_leaf(x::VirtualProductArray) = virtual(x)

function virtualize(ex, ::Type{ProductArray{dim, Body}}, ctx) where {dim, Body}
    VirtualProductArray(virtualize(:($ex.body), Body, ctx), dim)
end

"""
    product(tns, dim)

Create a `ProductArray` such that
```
    product(tns, dim)[i...] == tns[i[1:dim-1]..., i[dim] * i[dim + 1], i[dim + 2:end]...]
```
This is like a [`ToeplitzArray`](@ref) but with times instead of plus.
"""
products(body, dim) = ProductArray(body, dim)
function virtual_call(::typeof(products), ctx, body, dim)
    @assert isliteral(dim)
    VirtualProductArray(body, dim.val)
end

unwrap(ctx, arr::VirtualProductArray, var) = call(products, unwrap(ctx, arr.body, var), arr.dim)

lower(tns::VirtualProductArray, ctx::AbstractCompiler, ::DefaultStyle) = :(ProductArray($(ctx(tns.body)), $(tns.dim)))

#virtual_size(arr::Fill, ctx::AbstractCompiler) = (dimless,) # this is needed for multidimensional convolution..
#virtual_size(arr::Simplify, ctx::AbstractCompiler) = (dimless,)
#virtual_size(arr::Furlable, ctx::AbstractCompiler) = (dimless,)

function virtual_size(arr::VirtualProductArray, ctx::AbstractCompiler)
    dims = virtual_size(arr.body, ctx)
    return (dims[1:arr.dim - 1]..., dimless, dimless, dims[arr.dim + 1:end]...)
end
function virtual_resize!(arr::VirtualProductArray, ctx::AbstractCompiler, dims...)
    virtual_resize!(arr.body, ctx, dims[1:arr.dim - 1]..., dimless, dims[arr.dim + 2:end]...)
end

function instantiate_reader(arr::VirtualProductArray, ctx, protos)
    VirtualProductArray(instantiate_reader(arr.body, ctx, [protos[1:arr.dim]; protos[arr.dim + 2:end]]), arr.dim)
end
function instantiate_updater(arr::VirtualProductArray, ctx, protos)
    VirtualProductArray(instantiate_updater(arr.body, ctx, [protos[1:arr.dim]; protos[arr.dim + 2:end]]), arr.dim)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualProductArray) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::VirtualProductArray)
    stylize_access(node, ctx, tns.body)
end

function popdim(node::VirtualProductArray, ctx)
    if length(virtual_size(node, ctx)) == node.dim
        return node.body
    else
        return node
    end
end

truncate(node::VirtualProductArray, ctx, ext, ext_2) = VirtualProductArray(truncate(node.body, ctx, ext, ext_2), node.dim)

function get_point_body(node::VirtualProductArray, ctx, ext, idx)
    body_2 = get_point_body(node.body, ctx, ext, idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualProductArray(body_2, node.dim), ctx)
    end
end

(ctx::ThunkVisitor)(node::VirtualProductArray) = VirtualProductArray(ctx(node.body), node.dim)

function get_run_body(node::VirtualProductArray, ctx, ext)
    body_2 = get_run_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualProductArray(body_2, node.dim), ctx)
    end
end

function get_acceptrun_body(node::VirtualProductArray, ctx, ext)
    body_2 = get_acceptrun_body(node.body, ctx, ext)
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

phase_body(node::VirtualProductArray, ctx, ext, ext_2) = VirtualProductArray(phase_body(node.body, ctx, ext, ext_2), node.dim)
phase_range(node::VirtualProductArray, ctx, ext) = phase_range(node.body, ctx, ext)

get_spike_body(node::VirtualProductArray, ctx, ext, ext_2) = VirtualProductArray(get_spike_body(node.body, ctx, ext, ext_2), node.dim)
get_spike_tail(node::VirtualProductArray, ctx, ext, ext_2) = VirtualProductArray(get_spike_tail(node.body, ctx, ext, ext_2), node.dim)

visit_fill(node, tns::VirtualProductArray) = visit_fill(node, tns.body)
visit_simplify(node::VirtualProductArray) = VirtualProductArray(visit_simplify(node.body), node.dim)

(ctx::SwitchVisitor)(node::VirtualProductArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualProductArray(body, node.dim)
end

jumper_body(node::VirtualProductArray, ctx, ext) = VirtualProductArray(jumper_body(node.body, ctx, ext), node.dim)
stepper_body(node::VirtualProductArray, ctx, ext) = VirtualProductArray(stepper_body(node.body, ctx, ext), node.dim)
stepper_seek(node::VirtualProductArray, ctx, ext) = stepper_seek(node.body, ctx, ext)
jumper_seek(node::VirtualProductArray, ctx, ext) = jumper_seek(node.body, ctx, ext)

getroot(tns::VirtualProductArray) = getroot(tns.body)

function unfurl(tns::VirtualProductArray, ctx, ext, mode, protos...)
    if length(virtual_size(tns, ctx)) == tns.dim + 1
        Unfurled(tns,
            Lookup(
                body = (ctx, idx) -> VirtualPermissiveArray(VirtualScaleArray(tns.body, ([literal(1) for _ in 1:tns.dim - 1]..., idx)), ([false for _ in 1:tns.dim - 1]..., true)), 
            )
        )
    else
        VirtualProductArray(unfurl(tns.body, ctx, ext, mode, protos...), tns.dim)
    end
end
