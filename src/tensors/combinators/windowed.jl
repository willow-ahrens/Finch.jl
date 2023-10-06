struct WindowedArray{Dims<:Tuple, Body} <: AbstractCombinator
    body::Body
    dims::Dims
end

Base.show(io::IO, ex::WindowedArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::WindowedArray)
	print(io, "WindowedArray($(ex.body), $(ex.dims))")
end

Base.getindex(arr::WindowedArray, i...) = arr.body[i...]

struct VirtualWindowedArray <: AbstractVirtualCombinator
    body
    dims
end

is_injective(lvl::VirtualWindowedArray, ctx) = is_injective(lvl.body, ctx)
is_atomic(lvl::VirtualWindowedArray, ctx) = is_atomic(lvl.body, ctx)

Base.show(io::IO, ex::VirtualWindowedArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualWindowedArray)
	print(io, "VirtualWindowedArray($(ex.body), $(ex.dims))")
end

Base.summary(io::IO, ex::VirtualWindowedArray) = print(io, "VWindowed($(summary(ex.body)), $(ex.dims))")

FinchNotation.finch_leaf(x::VirtualWindowedArray) = virtual(x)

function virtualize(ex, ::Type{WindowedArray{Dims, Body}}, ctx) where {Dims, Body}
    dims = map(enumerate(Dims.parameters)) do (n, param)
        if param === Nothing
            nothing
        else
            virtualize(:($ex.dims[$n]), param, ctx)
        end
    end
    VirtualWindowedArray(virtualize(:($ex.body), Body, ctx), dims)
end

window(body, delta...) = WindowArray(body, delta)
function virtual_call(::typeof(window), ctx, body, delta...)
    VirtualWindowedArray(body, delta)
end

virtual_uncall(arr::VirtualWindowedArray) = call(window, arr.body, arr.delta...)

lower(tns::VirtualWindowedArray, ctx::AbstractCompiler, ::DefaultStyle) = :(WindowedArray($(ctx(tns.body)), $(tns.dims)))

function virtual_size(arr::VirtualWindowedArray, ctx::AbstractCompiler)
    something.(arr.dims, virtual_size(arr.body, ctx))
end
function virtual_resize!(arr::VirtualWindowedArray, ctx::AbstractCompiler, dims...)
    virtual_resize!(arr.body, ctx, something.(arr.dims, dims)...)
end

virtual_default(arr::VirtualWindowedArray, ctx::AbstractCompiler) = virtual_default(arr.body, ctx)

function instantiate(arr::VirtualWindowedArray, ctx, mode, protos)
    VirtualWindowedArray(instantiate(arr.body, ctx, mode, protos), arr.dims)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualWindowedArray) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::VirtualWindowedArray)
    stylize_access(node, ctx, tns.body)
end

function popdim(node::VirtualWindowedArray)
    if length(node.dims) == 1
        return node.body
    else
        return VirtualWindowedArray(node.body, node.dims[1:end-1])
    end
end

truncate(node::VirtualWindowedArray, ctx, ext, ext_2) = VirtualWindowedArray(truncate(node.body, ctx, ext, ext_2), node.dims)

function get_point_body(node::VirtualWindowedArray, ctx, ext, idx)
    body_2 = get_point_body(node.body, ctx, ext, idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualWindowedArray(body_2, node.dims))
    end
end

(ctx::ThunkVisitor)(node::VirtualWindowedArray) = VirtualWindowedArray(ctx(node.body), node.dims)

function get_run_body(node::VirtualWindowedArray, ctx, ext)
    body_2 = get_run_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualWindowedArray(body_2, node.dims))
    end
end

function get_acceptrun_body(node::VirtualWindowedArray, ctx, ext)
    body_2 = get_acceptrun_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualWindowedArray(body_2, node.dims))
    end
end

function (ctx::SequenceVisitor)(node::VirtualWindowedArray)
    map(ctx(node.body)) do (keys, body)
        return keys => VirtualWindowedArray(body, node.dims)
    end
end

phase_body(node::VirtualWindowedArray, ctx, ext, ext_2) = VirtualWindowedArray(phase_body(node.body, ctx, ext, ext_2), node.dims)
phase_range(node::VirtualWindowedArray, ctx, ext) = phase_range(node.body, ctx, ext)

get_spike_body(node::VirtualWindowedArray, ctx, ext, ext_2) = VirtualWindowedArray(get_spike_body(node.body, ctx, ext, ext_2), node.dims)
get_spike_tail(node::VirtualWindowedArray, ctx, ext, ext_2) = VirtualWindowedArray(get_spike_tail(node.body, ctx, ext, ext_2), node.dims)

visit_fill(node, tns::VirtualWindowedArray) = visit_fill(node, tns.body)
visit_simplify(node::VirtualWindowedArray) = VirtualWindowedArray(visit_simplify(node.body), node.dims)

(ctx::SwitchVisitor)(node::VirtualWindowedArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualWindowedArray(body, node.dims)
end

stepper_range(node::VirtualWindowedArray, ctx, ext) = stepper_range(node.body, ctx, ext)
stepper_body(node::VirtualWindowedArray, ctx, ext, ext_2) = VirtualWindowedArray(stepper_body(node.body, ctx, ext, ext_2), node.dims)
stepper_seek(node::VirtualWindowedArray, ctx, ext) = stepper_seek(node.body, ctx, ext)

jumper_range(node::VirtualWindowedArray, ctx, ext) = jumper_range(node.body, ctx, ext)
jumper_body(node::VirtualWindowedArray, ctx, ext, ext_2) = VirtualWindowedArray(jumper_body(node.body, ctx, ext, ext_2), node.dims)
jumper_seek(node::VirtualWindowedArray, ctx, ext) = jumper_seek(node.body, ctx, ext)


getroot(tns::VirtualWindowedArray) = getroot(tns.body)

function unfurl(tns::VirtualWindowedArray, ctx, ext, mode, protos...)
    if tns.dims[end] !== nothing
        dims = virtual_size(tns.body, ctx)
        tns_2 = unfurl(tns.body, ctx, dims[end], mode, protos...)
        truncate(tns_2, ctx, dims[end], ext)
    else
        unfurl(tns.body, ctx, ext, mode, protos...)
    end
end
