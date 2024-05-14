struct ScaleArray{Scale<:Tuple, Body} <: AbstractCombinator
    body::Body
    scale::Scale
end

Base.show(io::IO, ex::ScaleArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::ScaleArray)
	print(io, "ScaleArray($(ex.body), $(ex.scale))")
end

Base.getindex(arr::ScaleArray, i...) = arr.body[(i .* arr.scale)...]

struct VirtualScaleArray <: AbstractVirtualCombinator
    body
    scale
end

is_injective(ctx, lvl::VirtualScaleArray) = is_injective(ctx, lvl.body)
is_atomic(ctx, lvl::VirtualScaleArray) = is_atomic(ctx, lvl.body)
is_concurrent(ctx, lvl::VirtualScaleArray) = is_concurrent(ctx, lvl.body)


Base.show(io::IO, ex::VirtualScaleArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualScaleArray)
	print(io, "VirtualScaleArray($(ex.body), $(ex.scale))")
end

Base.summary(io::IO, ex::VirtualScaleArray) = print(io, "VScale($(summary(ex.body)), $(ex.scale))")

FinchNotation.finch_leaf(x::VirtualScaleArray) = virtual(x)

function virtualize(ctx, ex, ::Type{ScaleArray{Scale, Body}}) where {Scale, Body}
    scale = map(enumerate(Scale.parameters)) do (n, param)
        virtualize(ctx, :($ex.scale[$n]), param)
    end
    VirtualScaleArray(virtualize(ctx, :($ex.body), Body), scale)
end

"""
    scale(tns, delta...)

Create a `ScaleArray` such that `scale(tns, delta...)[i...] == tns[i .*
delta...]`.  The dimensions declared by an OffsetArray are shifted, so that
`size(scale(tns, delta...)) == size(tns) .* delta`.  This is only supported on
tensors with real-valued dimensions.
"""
scale(body, delta...) = ScaleArray(body, delta)
function virtual_call(ctx, ::typeof(scale), body, scale...)
    VirtualScaleArray(body, scale)
end
unwrap(arr::VirtualScaleArray) = call(scale, unwrap(ctx, arr.body, var), arr.scale...)

lower(ctx::AbstractCompiler, tns::VirtualScaleArray, ::DefaultStyle) = :(ScaleArray($(ctx(tns.body)), $(ctx(tns.scale))))

function virtual_size(ctx::AbstractCompiler, arr::VirtualScaleArray)
    map(zip(virtual_size(ctx, arr.body), arr.scale)) do (dim, scale)
        scaledim(dim, call(/, 1.0f0, scale))
    end
end
function virtual_resize!(ctx::AbstractCompiler, arr::VirtualScaleArray, dims...)
    dims_2 = map(zip(dims, arr.scale)) do (dim, scale)
        scaledim(dim, scale)
    end
    virtual_resize!(ctx, arr.body, dims_2...)
end

virtual_default(ctx::AbstractCompiler, arr::VirtualScaleArray) = virtual_default(ctx, arr.body)

function instantiate(ctx, arr::VirtualScaleArray, mode, protos)
    VirtualScaleArray(instantiate(ctx, arr.body, mode, protos), arr.scale)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualScaleArray) = ctx(node.body)
function stylize_access(ctx::Stylize{<:AbstractCompiler}, node, tns::VirtualScaleArray)
    stylize_access(ctx, node, tns.body)
end

function popdim(node::VirtualScaleArray)
    if length(node.scale) == 1
        return node.body
    else
        return VirtualScaleArray(node.body, node.scale[1:end-1])
    end
end

truncate(ctx, node::VirtualScaleArray, ext, ext_2) = VirtualScaleArray(truncate(ctx, node.body, scaledim(ext, node.scale[end]), scaledim(ext_2, node.scale[end])), node.scale)

function get_point_body(ctx, node::VirtualScaleArray, ext, idx)
    body_2 = get_point_body(ctx, node.body, scaledim(ext, node.scale[end]), call(*, idx, node.scale[end]))
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualScaleArray(body_2, node.scale))
    end
end

(ctx::ThunkVisitor)(node::VirtualScaleArray) = VirtualScaleArray(ctx(node.body), node.scale)

function get_run_body(ctx, node::VirtualScaleArray, ext)
    body_2 = get_run_body(ctx, node.body, scaledim(ext, node.scale[end]))
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualScaleArray(body_2, node.scale))
    end
end

function get_acceptrun_body(ctx, node::VirtualScaleArray, ext)
    body_2 = get_acceptrun_body(ctx, node.body, scaledim(ext, node.scale[end]))
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualScaleArray(body_2, node.scale))
    end
end

function (ctx::SequenceVisitor)(node::VirtualScaleArray)
    map(SequenceVisitor(; kwfields(ctx)..., ext = scaledim(ctx.ext, node.scale[end]))(node.body)) do (keys, body)
        return keys => VirtualScaleArray(body, node.scale)
    end
end

phase_body(ctx, node::VirtualScaleArray, ext, ext_2) = VirtualScaleArray(phase_body(ctx, node.body, scaledim(ext, node.scale[end]), scaledim(ext_2, node.scale[end])), node.scale)
phase_range(ctx, node::VirtualScaleArray, ext) = scaledim(phase_range(ctx, node.body, scaledim(ext, node.scale[end])), call(/, 1.0f0, node.scale[end]))

get_spike_body(ctx, node::VirtualScaleArray, ext, ext_2) = VirtualScaleArray(get_spike_body(ctx, node.body, scaledim(ext, node.scale[end]), scaledim(ext_2, node.scale[end])), node.scale)
get_spike_tail(ctx, node::VirtualScaleArray, ext, ext_2) = VirtualScaleArray(get_spike_tail(ctx, node.body, scaledim(ext, node.scale[end]), scaledim(ext_2, node.scale[end])), node.scale)

visit_fill_leaf_leaf(node, tns::VirtualScaleArray) = visit_fill_leaf_leaf(node, tns.body)
visit_simplify(node::VirtualScaleArray) = VirtualScaleArray(visit_simplify(node.body), node.scale)

(ctx::SwitchVisitor)(node::VirtualScaleArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualScaleArray(body, node.scale)
end

stepper_range(ctx, node::VirtualScaleArray, ext) = scaledim(stepper_range(ctx, node.body, scaledim(ext, node.scale[end])), call(/, 1.0f0, node.scale[end]))
stepper_body(ctx, node::VirtualScaleArray, ext, ext_2) = VirtualScaleArray(stepper_body(ctx, node.body, scaledim(ext, node.scale[end]), scaledim(ext_2, node.scale[end])), node.scale)
stepper_seek(ctx, node::VirtualScaleArray, ext) = stepper_seek(ctx, node.body, scaledim(ext, node.scale[end]))

jumper_range(ctx, node::VirtualScaleArray, ext) = scaledim(jumper_range(ctx, node.body, scaledim(ext, node.scale[end])), call(/, 1.0f0, node.scale[end]))
jumper_body(ctx, node::VirtualScaleArray, ext, ext_2) = VirtualScaleArray(jumper_body(ctx, node.body, scaledim(ext, node.scale[end]), scaledim(ext_2, node.scale[end])), node.scale)
jumper_seek(ctx, node::VirtualScaleArray, ext) = jumper_seek(ctx, node.body, scaledim(ext, node.scale[end]))

function short_circuit_cases(ctx, node::VirtualScaleArray, op)
    map(short_circuit_cases(ctx, node.body, op)) do (guard, body)
        guard => VirtualScaleArray(body, node.scale)
    end
end

getroot(tns::VirtualScaleArray) = getroot(tns.body)

function unfurl(ctx, tns::VirtualScaleArray, ext, mode, protos...)
    VirtualScaleArray(unfurl(ctx, tns.body, scaledim(ext, tns.scale[end]), mode, protos...), tns.scale)
end

function lower_access(ctx::AbstractCompiler, node, tns::VirtualScaleArray)
    if !isempty(node.idxs)
        error("oh no!")
    end
    lower_access(ctx, node, tns.body)
end
