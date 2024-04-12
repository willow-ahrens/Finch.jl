struct OffsetArray{Delta<:Tuple, Body} <: AbstractCombinator
    body::Body
    delta::Delta
end

Base.show(io::IO, ex::OffsetArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::OffsetArray)
	print(io, "OffsetArray($(ex.body), $(ex.delta))")
end

Base.getindex(arr::OffsetArray, i...) = arr.body[(i .+ arr.delta)...]

struct VirtualOffsetArray <: AbstractVirtualCombinator
    body
    delta
end

is_injective(lvl::VirtualOffsetArray, ctx) = is_injective(lvl.body, ctx)
is_atomic(lvl::VirtualOffsetArray, ctx) = is_atomic(lvl.body, ctx)

Base.show(io::IO, ex::VirtualOffsetArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualOffsetArray)
	print(io, "VirtualOffsetArray($(ex.body), $(ex.delta))")
end

Base.summary(io::IO, ex::VirtualOffsetArray) = print(io, "VOffset($(summary(ex.body)), $(ex.delta))")

FinchNotation.finch_leaf(x::VirtualOffsetArray) = virtual(x)

function virtualize(ctx, ex, ::Type{OffsetArray{Delta, Body}}) where {Delta, Body}
    delta = map(enumerate(Delta.parameters)) do (n, param)
        virtualize(ctx, :($ex.delta[$n]), param)
    end
    VirtualOffsetArray(virtualize(ctx, :($ex.body), Body), delta)
end

"""
    offset(tns, delta...)

Create an `OffsetArray` such that `offset(tns, delta...)[i...] == tns[i .+ delta...]`.
The dimensions declared by an OffsetArray are shifted, so that `size(offset(tns, delta...)) == size(tns) .+ delta`.
"""
offset(body, delta...) = OffsetArray(body, delta)
function virtual_call(::typeof(offset), ctx, body, delta...)
    VirtualOffsetArray(body, delta)
end

unwrap(ctx, arr::VirtualOffsetArray, var) = call(offset, unwrap(ctx, arr.body, var), arr.delta...)

lower(tns::VirtualOffsetArray, ctx::AbstractCompiler, ::DefaultStyle) = :(OffsetArray($(ctx(tns.body)), $(ctx(tns.delta))))

function virtual_size(ctx::AbstractCompiler, arr::VirtualOffsetArray)
    map(zip(virtual_size(ctx, arr.body), arr.delta)) do (dim, delta)
        shiftdim(dim, call(-, delta))
    end
end
function virtual_resize!(ctx::AbstractCompiler, arr::VirtualOffsetArray, dims...)
    dims_2 = map(zip(dims, arr.delta)) do (dim, delta)
        shiftdim(dim, delta)
    end
    virtual_resize!(ctx, arr.body, dims_2...)
end

virtual_default(ctx::AbstractCompiler, arr::VirtualOffsetArray) = virtual_default(ctx, arr.body)

function instantiate(arr::VirtualOffsetArray, ctx, mode, protos)
    VirtualOffsetArray(instantiate(arr.body, ctx, mode, protos), arr.delta)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualOffsetArray) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::VirtualOffsetArray)
    stylize_access(node, ctx, tns.body)
end

function popdim(node::VirtualOffsetArray)
    if length(node.delta) == 1
        return node.body
    else
        return VirtualOffsetArray(node.body, node.delta[1:end-1])
    end
end

truncate(node::VirtualOffsetArray, ctx, ext, ext_2) = VirtualOffsetArray(truncate(node.body, ctx, shiftdim(ext, node.delta[end]), shiftdim(ext_2, node.delta[end])), node.delta)

function get_point_body(node::VirtualOffsetArray, ctx, ext, idx)
    body_2 = get_point_body(node.body, ctx, shiftdim(ext, node.delta[end]), call(+, idx, node.delta[end]))
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualOffsetArray(body_2, node.delta))
    end
end

(ctx::ThunkVisitor)(node::VirtualOffsetArray) = VirtualOffsetArray(ctx(node.body), node.delta)

function get_run_body(node::VirtualOffsetArray, ctx, ext)
    body_2 = get_run_body(node.body, ctx, shiftdim(ext, node.delta[end]))
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualOffsetArray(body_2, node.delta))
    end
end

function get_acceptrun_body(node::VirtualOffsetArray, ctx, ext)
    body_2 = get_acceptrun_body(node.body, ctx, shiftdim(ext, node.delta[end]))
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualOffsetArray(body_2, node.delta))
    end
end

function (ctx::SequenceVisitor)(node::VirtualOffsetArray)
    map(SequenceVisitor(; kwfields(ctx)..., ext = shiftdim(ctx.ext, node.delta[end]))(node.body)) do (keys, body)
        return keys => VirtualOffsetArray(body, node.delta)
    end
end

phase_body(node::VirtualOffsetArray, ctx, ext, ext_2) = VirtualOffsetArray(phase_body(node.body, ctx, shiftdim(ext, node.delta[end]), shiftdim(ext_2, node.delta[end])), node.delta)
phase_range(node::VirtualOffsetArray, ctx, ext) = shiftdim(phase_range(node.body, ctx, shiftdim(ext, node.delta[end])), call(-, node.delta[end]))

get_spike_body(node::VirtualOffsetArray, ctx, ext, ext_2) = VirtualOffsetArray(get_spike_body(node.body, ctx, shiftdim(ext, node.delta[end]), shiftdim(ext_2, node.delta[end])), node.delta)
get_spike_tail(node::VirtualOffsetArray, ctx, ext, ext_2) = VirtualOffsetArray(get_spike_tail(node.body, ctx, shiftdim(ext, node.delta[end]), shiftdim(ext_2, node.delta[end])), node.delta)

visit_fill(node, tns::VirtualOffsetArray) = visit_fill(node, tns.body)
visit_simplify(node::VirtualOffsetArray) = VirtualOffsetArray(visit_simplify(node.body), node.delta)

(ctx::SwitchVisitor)(node::VirtualOffsetArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualOffsetArray(body, node.delta)
end

stepper_range(node::VirtualOffsetArray, ctx, ext) = shiftdim(stepper_range(node.body, ctx, shiftdim(ext, node.delta[end])), call(-, node.delta[end]))
stepper_body(node::VirtualOffsetArray, ctx, ext, ext_2) = VirtualOffsetArray(stepper_body(node.body, ctx, shiftdim(ext, node.delta[end]), shiftdim(ext_2, node.delta[end])), node.delta)
stepper_seek(node::VirtualOffsetArray, ctx, ext) = stepper_seek(node.body, ctx, shiftdim(ext, node.delta[end]))

jumper_range(node::VirtualOffsetArray, ctx, ext) = shiftdim(jumper_range(node.body, ctx, shiftdim(ext, node.delta[end])), call(-, node.delta[end]))
jumper_body(node::VirtualOffsetArray, ctx, ext, ext_2) = VirtualOffsetArray(jumper_body(node.body, ctx, shiftdim(ext, node.delta[end]), shiftdim(ext_2, node.delta[end])), node.delta)
jumper_seek(node::VirtualOffsetArray, ctx, ext) = jumper_seek(node.body, ctx, shiftdim(ext, node.delta[end]))

function short_circuit_cases(node::VirtualOffsetArray, ctx, op)
    map(short_circuit_cases(node.body, ctx, op)) do (guard, body)
        guard => VirtualOffsetArray(body, node.delta)
    end
end

getroot(tns::VirtualOffsetArray) = getroot(tns.body)

function unfurl(tns::VirtualOffsetArray, ctx, ext, mode, protos...)
    VirtualOffsetArray(unfurl(tns.body, ctx, shiftdim(ext, tns.delta[end]), mode, protos...), tns.delta)
end

function lower_access(ctx::AbstractCompiler, node, tns::VirtualOffsetArray)
    if !isempty(node.idxs)
        error("OffsetArray not lowered completely")
    end
    lower_access(ctx, node, tns.body)
end
