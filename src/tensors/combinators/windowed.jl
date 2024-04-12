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

is_injective(ctx, lvl::VirtualWindowedArray) = is_injective(ctx, lvl.body)
is_atomic(ctx, lvl::VirtualWindowedArray) = is_atomic(ctx, lvl.body)

Base.show(io::IO, ex::VirtualWindowedArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualWindowedArray)
	print(io, "VirtualWindowedArray($(ex.body), $(ex.dims))")
end

Base.summary(io::IO, ex::VirtualWindowedArray) = print(io, "VWindowed($(summary(ex.body)), $(ex.dims))")

FinchNotation.finch_leaf(x::VirtualWindowedArray) = virtual(x)

function virtualize(ctx, ex, ::Type{WindowedArray{Dims, Body}}) where {Dims, Body}
    dims = map(enumerate(Dims.parameters)) do (n, param)
        if param === Nothing
            nothing
        else
            virtualize(ctx, :($ex.dims[$n]), param)
        end
    end
    VirtualWindowedArray(virtualize(ctx, :($ex.body), Body), dims)
end

"""
    window(tns, dims)

Create a `WindowedArray` which represents a view into another tensor
```
    window(tns, dims)[i...] == tns[dim[1][i], dim[2][i], ...]
```
The windowed array restricts the new dimension to the dimension of valid indices
of each `dim`. The `dims` may also be `nothing` to represent a full view of the
underlying dimension.
"""
window(body, delta...) = WindowArray(body, delta)
function virtual_call(ctx, ::typeof(window), body, delta...)
    VirtualWindowedArray(body, delta)
end

unwrap(ctx, arr::VirtualWindowedArray, var) = call(window, unwrap(ctx, arr.body, var), arr.delta...)

lower(ctx::AbstractCompiler, tns::VirtualWindowedArray, ::DefaultStyle) = :(WindowedArray($(ctx(tns.body)), $(tns.dims)))

function virtual_size(ctx::AbstractCompiler, arr::VirtualWindowedArray)
    something.(arr.dims, virtual_size(ctx, arr.body))
end
function virtual_resize!(ctx::AbstractCompiler, arr::VirtualWindowedArray, dims...)
    virtual_resize!(ctx, arr.body, something.(arr.dims, dims)...)
end

virtual_default(ctx::AbstractCompiler, arr::VirtualWindowedArray) = virtual_default(ctx, arr.body)

function instantiate(ctx, arr::VirtualWindowedArray, mode, protos)
    VirtualWindowedArray(instantiate(ctx, arr.body, mode, protos), arr.dims)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualWindowedArray) = ctx(node.body)
function stylize_access(ctx::Stylize{<:AbstractCompiler}, node, tns::VirtualWindowedArray)
    stylize_access(ctx, node, tns.body)
end

function popdim(node::VirtualWindowedArray)
    if length(node.dims) == 1
        return node.body
    else
        return VirtualWindowedArray(node.body, node.dims[1:end-1])
    end
end

truncate(ctx, node::VirtualWindowedArray, ext, ext_2) = VirtualWindowedArray(truncate(ctx, node.body, ext, ext_2), node.dims)

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

function get_acceptrun_body(ctx, node::VirtualWindowedArray, ext)
    body_2 = get_acceptrun_body(ctx, node.body, ext)
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

phase_body(ctx, node::VirtualWindowedArray, ext, ext_2) = VirtualWindowedArray(phase_body(ctx, node.body, ext, ext_2), node.dims)
phase_range(ctx, node::VirtualWindowedArray, ext) = phase_range(ctx, node.body, ext)

get_spike_body(ctx, node::VirtualWindowedArray, ext, ext_2) = VirtualWindowedArray(get_spike_body(ctx, node.body, ext, ext_2), node.dims)
get_spike_tail(ctx, node::VirtualWindowedArray, ext, ext_2) = VirtualWindowedArray(get_spike_tail(ctx, node.body, ext, ext_2), node.dims)

visit_fill(node, tns::VirtualWindowedArray) = visit_fill(node, tns.body)
visit_simplify(node::VirtualWindowedArray) = VirtualWindowedArray(visit_simplify(node.body), node.dims)

(ctx::SwitchVisitor)(node::VirtualWindowedArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualWindowedArray(body, node.dims)
end

stepper_range(ctx, node::VirtualWindowedArray, ext) = stepper_range(ctx, node.body, ext)
stepper_body(ctx, node::VirtualWindowedArray, ext, ext_2) = VirtualWindowedArray(stepper_body(ctx, node.body, ext, ext_2), node.dims)
stepper_seek(ctx, node::VirtualWindowedArray, ext) = stepper_seek(ctx, node.body, ext)

jumper_range(ctx, node::VirtualWindowedArray, ext) = jumper_range(ctx, node.body, ext)
jumper_body(ctx, node::VirtualWindowedArray, ext, ext_2) = VirtualWindowedArray(jumper_body(ctx, node.body, ext, ext_2), node.dims)
jumper_seek(ctx, node::VirtualWindowedArray, ext) = jumper_seek(ctx, node.body, ext)

function short_circuit_cases(ctx, node::VirtualWindowedArray, op)
    map(short_circuit_cases(ctx, node.body, op)) do (guard, body)
        guard => VirtualWindowedArray(body, node.dims)
    end
end

getroot(tns::VirtualWindowedArray) = getroot(tns.body)

function unfurl(ctx, tns::VirtualWindowedArray, ext, mode, protos...)
    if tns.dims[end] !== nothing
        dims = virtual_size(ctx, tns.body)
        tns_2 = unfurl(ctx, tns.body, dims[end], mode, protos...)
        truncate(ctx, tns_2, dims[end], ext)
    else
        unfurl(ctx, tns.body, ext, mode, protos...)
    end
end
