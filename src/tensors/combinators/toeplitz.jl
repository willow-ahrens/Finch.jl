struct ToeplitzArray{dim, Body} <: AbstractCombinator
    body::Body
end

ToeplitzArray(body, dim) = ToeplitzArray{dim}(body)
ToeplitzArray{dim}(body::Body) where {dim, Body} = ToeplitzArray{dim, Body}(body)

Base.show(io::IO, ex::ToeplitzArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::ToeplitzArray{dim}) where {dim}
	print(io, "ToeplitzArray{$dim}($(ex.body))")
end

#Base.getindex(arr::ToeplitzArray, i...) = ...

struct VirtualToeplitzArray <: AbstractVirtualCombinator
    body
    dim
end

function is_injective(lvl::VirtualToeplitzArray, ctx)
    sub = is_injective(lvl.body, ctx)
    return [sub[1:lvl.dim]..., false, sub[lvl.dim + 1:end]...]
end
is_atomic(lvl::VirtualToeplitzArray, ctx) = is_atomic(lvl.body, ctx)

Base.show(io::IO, ex::VirtualToeplitzArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualToeplitzArray)
	print(io, "VirtualToeplitzArray($(ex.body), $(ex.dim))")
end

Base.summary(io::IO, ex::VirtualToeplitzArray) = print(io, "VToeplitz($(summary(ex.body)), $(ex.dim))")

FinchNotation.finch_leaf(x::VirtualToeplitzArray) = virtual(x)

function virtualize(ex, ::Type{ToeplitzArray{dim, Body}}, ctx) where {dim, Body}
    VirtualToeplitzArray(virtualize(:($ex.body), Body, ctx), dim)
end

toeplitz(body, dim) = ToeplitzArray(body, dim)
function virtual_call(::typeof(toeplitz), ctx, body, dim)
    @assert isliteral(dim)
    VirtualToeplitzArray(body, dim.val)
end

virtual_uncall(arr::VirtualToeplitzArray) = call(toeplitz, arr.body, arr.dim)

lower(tns::VirtualToeplitzArray, ctx::AbstractCompiler, ::DefaultStyle) = :(ToeplitzArray($(ctx(tns.body)), $(tns.dim)))

function virtual_size(arr::VirtualToeplitzArray, ctx::AbstractCompiler)
    dims = virtual_size(arr.body, ctx)
    return (dims[1:arr.dim - 1]..., dimless, dimless, dims[arr.dim + 1:end]...)
end
function virtual_resize!(arr::VirtualToeplitzArray, ctx::AbstractCompiler, dims...)
    virtual_resize!(arr.body, ctx, dims[1:arr.dim - 1]..., dimless, dims[arr.dim + 2:end]...)
end

function instantiate(arr::VirtualToeplitzArray, ctx, mode, protos)
    VirtualToeplitzArray(instantiate(arr.body, ctx, mode, [protos[1:arr.dim]; protos[arr.dim + 2:end]]), arr.dim)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualToeplitzArray) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::VirtualToeplitzArray)
    stylize_access(node, ctx, tns.body)
end

function popdim(node::VirtualToeplitzArray)
    if length(virtual_size(node)) == node.dim
        return node.body
    else
        return node
    end
end

truncate(node::VirtualToeplitzArray, ctx, ext, ext_2) = VirtualToeplitzArray(truncate(node.body, ctx, ext, ext_2), node.dim)

function get_point_body(node::VirtualToeplitzArray, ctx, ext, idx)
    body_2 = get_point_body(node.body, ctx, ext, idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualToeplitzArray(body_2, node.dim))
    end
end

(ctx::ThunkVisitor)(node::VirtualToeplitzArray) = VirtualToeplitzArray(ctx(node.body), node.dim)

function get_run_body(node::VirtualToeplitzArray, ctx, ext)
    body_2 = get_run_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualToeplitzArray(body_2, node.dim))
    end
end

function get_acceptrun_body(node::VirtualToeplitzArray, ctx, ext)
    body_2 = get_acceptrun_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualToeplitzArray(body_2, node.dim))
    end
end

function (ctx::SequenceVisitor)(node::VirtualToeplitzArray)
    map(ctx(node.body)) do (keys, body)
        return keys => VirtualToeplitzArray(body, node.dim)
    end
end

phase_body(node::VirtualToeplitzArray, ctx, ext, ext_2) = VirtualToeplitzArray(phase_body(node.body, ctx, ext, ext_2), node.dim)
phase_range(node::VirtualToeplitzArray, ctx, ext) = phase_range(node.body, ctx, ext)

get_spike_body(node::VirtualToeplitzArray, ctx, ext, ext_2) = VirtualToeplitzArray(get_spike_body(node.body, ctx, ext, ext_2), node.dim)
get_spike_tail(node::VirtualToeplitzArray, ctx, ext, ext_2) = VirtualToeplitzArray(get_spike_tail(node.body, ctx, ext, ext_2), node.dim)

visit_fill(node, tns::VirtualToeplitzArray) = visit_fill(node, tns.body)
visit_simplify(node::VirtualToeplitzArray) = VirtualToeplitzArray(visit_simplify(node.body), node.dim)

(ctx::SwitchVisitor)(node::VirtualToeplitzArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualToeplitzArray(body, node.dim)
end

stepper_range(node::VirtualToeplitzArray, ctx, ext) = stepper_range(node.body, ctx, ext)
stepper_body(node::VirtualToeplitzArray, ctx, ext, ext_2) = VirtualToeplitzArray(stepper_body(node.body, ctx, ext, ext_2), node.dim)
stepper_seek(node::VirtualToeplitzArray, ctx, ext) = stepper_seek(node.body, ctx, ext)

jumper_range(node::VirtualToeplitzArray, ctx, ext) = jumper_range(node.body, ctx, ext)
jumper_body(node::VirtualToeplitzArray, ctx, ext, ext_2) = VirtualToeplitzArray(jumper_body(node.body, ctx, ext, ext_2), node.dim)
jumper_seek(node::VirtualToeplitzArray, ctx, ext) = jumper_seek(node.body, ctx, ext)

getroot(tns::VirtualToeplitzArray) = getroot(tns.body)

function unfurl(tns::VirtualToeplitzArray, ctx, ext, mode, protos...)
    if length(virtual_size(tns, ctx)) == tns.dim + 1
        Unfurled(tns,
            Lookup(
                body = (ctx, idx) -> VirtualPermissiveArray(VirtualOffsetArray(tns.body, ([literal(0) for _ in 1:tns.dim - 1]..., idx)), ([false for _ in 1:tns.dim - 1]..., true)), 
            )
        )
    else
        VirtualToeplitzArray(unfurl(tns.body, ctx, ext, mode, protos...), tns.dim)
    end
end
