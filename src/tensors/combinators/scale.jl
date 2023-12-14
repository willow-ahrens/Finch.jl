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

is_injective(lvl::VirtualScaleArray, ctx) = is_injective(lvl.body, ctx)
is_atomic(lvl::VirtualScaleArray, ctx) = is_atomic(lvl.body, ctx)

Base.show(io::IO, ex::VirtualScaleArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualScaleArray)
	print(io, "VirtualScaleArray($(ex.body), $(ex.scale))")
end

Base.summary(io::IO, ex::VirtualScaleArray) = print(io, "VScale($(summary(ex.body)), $(ex.scale))")

FinchNotation.finch_leaf(x::VirtualScaleArray) = virtual(x)

function virtualize(ex, ::Type{ScaleArray{Scale, Body}}, ctx) where {Scale, Body}
    scale = map(enumerate(Scale.parameters)) do (n, param)
        virtualize(:($ex.scale[$n]), param, ctx)
    end
    VirtualScaleArray(virtualize(:($ex.body), Body, ctx), scale)
end

scale(body, scale...) = ScaleArray(body, scale)
function virtual_call(::typeof(scale), ctx, body, scale...)
    VirtualScaleArray(body, scale)
end
virtual_uncall(arr::VirtualScaleArray) = call(scale, arr.body, arr.scale...)

lower(tns::VirtualScaleArray, ctx::AbstractCompiler, ::DefaultStyle) = :(ScaleArray($(ctx(tns.body)), $(ctx(tns.scale))))

function virtual_size(arr::VirtualScaleArray, ctx::AbstractCompiler)
    map(zip(virtual_size(arr.body, ctx), arr.scale)) do (dim, scale)
        scaledim(dim, call(/, 1.0f0, scale))
    end
end
function virtual_resize!(arr::VirtualScaleArray, ctx::AbstractCompiler, dims...)
    dims_2 = map(zip(dims, arr.scale)) do (dim, scale)
        scaledim(dim, scale)
    end
    virtual_resize!(arr.body, ctx, dims_2...)
end

virtual_default(arr::VirtualScaleArray, ctx::AbstractCompiler) = virtual_default(arr.body, ctx)

function instantiate(arr::VirtualScaleArray, ctx, mode, protos)
    VirtualScaleArray(instantiate(arr.body, ctx, mode, protos), arr.scale)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualScaleArray) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::VirtualScaleArray)
    stylize_access(node, ctx, tns.body)
end

function popdim(node::VirtualScaleArray)
    if length(node.scale) == 1
        return node.body
    else
        return VirtualScaleArray(node.body, node.scale[1:end-1])
    end
end

truncate(node::VirtualScaleArray, ctx, ext, ext_2) = VirtualScaleArray(truncate(node.body, ctx, scaledim(ext, node.scale[end]), scaledim(ext_2, node.scale[end])), node.scale)

function get_point_body(node::VirtualScaleArray, ctx, ext, idx)
    body_2 = get_point_body(node.body, ctx, scaledim(ext, node.scale[end]), call(*, idx, node.scale[end]))
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualScaleArray(body_2, node.scale))
    end
end

(ctx::ThunkVisitor)(node::VirtualScaleArray) = VirtualScaleArray(ctx(node.body), node.scale)

function get_run_body(node::VirtualScaleArray, ctx, ext)
    body_2 = get_run_body(node.body, ctx, scaledim(ext, node.scale[end]))
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualScaleArray(body_2, node.scale))
    end
end

function get_acceptrun_body(node::VirtualScaleArray, ctx, ext)
    body_2 = get_acceptrun_body(node.body, ctx, scaledim(ext, node.scale[end]))
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

phase_body(node::VirtualScaleArray, ctx, ext, ext_2) = VirtualScaleArray(phase_body(node.body, ctx, scaledim(ext, node.scale[end]), scaledim(ext_2, node.scale[end])), node.scale)
phase_range(node::VirtualScaleArray, ctx, ext) = scaledim(phase_range(node.body, ctx, scaledim(ext, node.scale[end])), call(/, 1.0f0, node.scale[end]))

get_spike_body(node::VirtualScaleArray, ctx, ext, ext_2) = VirtualScaleArray(get_spike_body(node.body, ctx, scaledim(ext, node.scale[end]), scaledim(ext_2, node.scale[end])), node.scale)
get_spike_tail(node::VirtualScaleArray, ctx, ext, ext_2) = VirtualScaleArray(get_spike_tail(node.body, ctx, scaledim(ext, node.scale[end]), scaledim(ext_2, node.scale[end])), node.scale)

visit_fill(node, tns::VirtualScaleArray) = visit_fill(node, tns.body)
visit_simplify(node::VirtualScaleArray) = VirtualScaleArray(visit_simplify(node.body), node.scale)

(ctx::SwitchVisitor)(node::VirtualScaleArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualScaleArray(body, node.scale)
end

stepper_range(node::VirtualScaleArray, ctx, ext) = scaledim(stepper_range(node.body, ctx, scaledim(ext, node.scale[end])), call(/, 1.0f0, node.scale[end]))
stepper_body(node::VirtualScaleArray, ctx, ext, ext_2) = VirtualScaleArray(stepper_body(node.body, ctx, scaledim(ext, node.scale[end]), scaledim(ext_2, node.scale[end])), node.scale)
stepper_seek(node::VirtualScaleArray, ctx, ext) = stepper_seek(node.body, ctx, scaledim(ext, node.scale[end]))

jumper_range(node::VirtualScaleArray, ctx, ext) = scaledim(jumper_range(node.body, ctx, scaledim(ext, node.scale[end])), call(/, 1.0f0, node.scale[end]))
jumper_body(node::VirtualScaleArray, ctx, ext, ext_2) = VirtualScaleArray(jumper_body(node.body, ctx, scaledim(ext, node.scale[end]), scaledim(ext_2, node.scale[end])), node.scale)
jumper_seek(node::VirtualScaleArray, ctx, ext) = jumper_seek(node.body, ctx, scaledim(ext, node.scale[end]))

function short_circuit_cases(node::VirtualScaleArray, ctx, op)
    map(short_circuit_cases(node.body, ctx, op)) do (guard, body)
        guard => VirtualScaleArray(body, node.scale)
    end
end

getroot(tns::VirtualScaleArray) = getroot(tns.body)

function unfurl(tns::VirtualScaleArray, ctx, ext, mode, protos...)
    VirtualScaleArray(unfurl(tns.body, ctx, scaledim(ext, tns.scale[end]), mode, protos...), tns.scale)
end

function lower_access(ctx::AbstractCompiler, node, tns::VirtualScaleArray)
    if !isempty(node.idxs)
        error("oh no!")
    end
    lower_access(ctx, node, tns.body)
end
