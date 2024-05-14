struct PermissiveArray{dims, Body} <: AbstractCombinator
    body::Body
end

PermissiveArray(body, dims) = PermissiveArray{dims}(body)
PermissiveArray{dims}(body::Body) where {dims, Body} = PermissiveArray{dims, Body}(body)

Base.show(io::IO, ex::PermissiveArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::PermissiveArray{dims}) where {dims}
	print(io, "PermissiveArray($(ex.body), $dims)")
end

#Base.getindex(arr::PermissiveArray, i...) = ...

struct VirtualPermissiveArray <: AbstractVirtualCombinator
    body
    dims
end

is_injective(ctx, lvl::VirtualPermissiveArray) = is_injective(ctx, lvl.body)
is_atomic(ctx, lvl::VirtualPermissiveArray) = is_atomic(ctx, lvl.body)
is_concurrent(ctx, lvl::VirtualPermissiveArray) = is_concurrent(ctx, lvl.body)


Base.show(io::IO, ex::VirtualPermissiveArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualPermissiveArray)
	print(io, "VirtualPermissiveArray($(ex.body), $(ex.dims))")
end

Base.summary(io::IO, ex::VirtualPermissiveArray) = print(io, "VPermissive($(summary(ex.body)), $(ex.dims))")

FinchNotation.finch_leaf(x::VirtualPermissiveArray) = virtual(x)

function virtualize(ctx, ex, ::Type{PermissiveArray{dims, Body}}) where {dims, Body}
    VirtualPermissiveArray(virtualize(ctx, :($ex.body), Body), dims)
end

"""
    permissive(tns, dims...)

Create an `PermissiveArray` where `permissive(tns, dims...)[i...]` is `missing`
if `i[n]` is not in the bounds of `tns` when `dims[n]` is `true`.  This wrapper
allows all permissive dimensions to be exempt from dimension checks, and is
useful when we need to access an array out of bounds, or for padding.
More formally,
```
    permissive(tns, dims...)[i...] =
        if any(n -> dims[n] && !(i[n] in axes(tns)[n]))
            missing
        else
            tns[i...]
        end
```
"""
permissive(body, dims...) = PermissiveArray(body, dims)
function virtual_call(ctx, ::typeof(permissive), body, dims...)
    @assert All(isliteral)(dims)
    VirtualPermissiveArray(body, map(dim -> dim.val, dims))
end

unwrap(ctx, arr::VirtualPermissiveArray, var) = call(permissive, unwrap(ctx, arr.body, var), arr.dims...)

lower(ctx::AbstractCompiler, tns::VirtualPermissiveArray, ::DefaultStyle) = :(PermissiveArray($(ctx(tns.body)), $(tns.dims)))

function virtual_size(ctx::AbstractCompiler, arr::VirtualPermissiveArray)
    ifelse.(arr.dims, (dimless,), virtual_size(ctx, arr.body))
end

function virtual_resize!(ctx::AbstractCompiler, arr::VirtualPermissiveArray, dims...)
    virtual_resize!(ctx, arr.body, ifelse.(arr.dims, virtual_size(ctx, arr.body), dim))
end

virtual_fill_value(ctx::AbstractCompiler, arr::VirtualPermissiveArray) = virtual_fill_value(ctx, arr.body)

function instantiate(ctx, arr::VirtualPermissiveArray, mode, protos)
    VirtualPermissiveArray(instantiate(ctx, arr.body, mode, protos), arr.dims)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualPermissiveArray) = ctx(node.body)
function stylize_access(ctx::Stylize{<:AbstractCompiler}, node, tns::VirtualPermissiveArray)
    stylize_access(ctx, node, tns.body)
end

function popdim(node::VirtualPermissiveArray)
    if length(node.dims) == 1
        return node.body
    else
        return VirtualPermissiveArray(node.body, node.dims[1:end-1])
    end
end

truncate(ctx, node::VirtualPermissiveArray, ext, ext_2) = VirtualPermissiveArray(truncate(ctx, node.body, ext, ext_2), node.dims)

function get_point_body(ctx, node::VirtualPermissiveArray, ext, idx)
    body_2 = get_point_body(ctx, node.body, ext, idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualPermissiveArray(body_2, node.dims))
    end
end

(ctx::ThunkVisitor)(node::VirtualPermissiveArray) = VirtualPermissiveArray(ctx(node.body), node.dims)

function get_run_body(ctx, node::VirtualPermissiveArray, ext)
    body_2 = get_run_body(ctx, node.body, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualPermissiveArray(body_2, node.dims))
    end
end

function get_acceptrun_body(ctx, node::VirtualPermissiveArray, ext)
    body_2 = get_acceptrun_body(ctx, node.body, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualPermissiveArray(body_2, node.dims))
    end
end

function (ctx::SequenceVisitor)(node::VirtualPermissiveArray)
    map(ctx(node.body)) do (keys, body)
        return keys => VirtualPermissiveArray(body, node.dims)
    end
end

phase_body(ctx, node::VirtualPermissiveArray, ext, ext_2) = VirtualPermissiveArray(phase_body(ctx, node.body, ext, ext_2), node.dims)
phase_range(ctx, node::VirtualPermissiveArray, ext) = phase_range(ctx, node.body, ext)

get_spike_body(ctx, node::VirtualPermissiveArray, ext, ext_2) = VirtualPermissiveArray(get_spike_body(ctx, node.body, ext, ext_2), node.dims)
get_spike_tail(ctx, node::VirtualPermissiveArray, ext, ext_2) = VirtualPermissiveArray(get_spike_tail(ctx, node.body, ext, ext_2), node.dims)

visit_fill_leaf_leaf(node, tns::VirtualPermissiveArray) = visit_fill_leaf_leaf(node, tns.body)
visit_simplify(node::VirtualPermissiveArray) = VirtualPermissiveArray(visit_simplify(node.body), node.dims)

(ctx::SwitchVisitor)(node::VirtualPermissiveArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualPermissiveArray(body, node.dims)
end

stepper_range(ctx, node::VirtualPermissiveArray, ext) = stepper_range(ctx, node.body, ext)
stepper_body(ctx, node::VirtualPermissiveArray, ext, ext_2) = VirtualPermissiveArray(stepper_body(ctx, node.body, ext, ext_2), node.dims)
stepper_seek(ctx, node::VirtualPermissiveArray, ext) = stepper_seek(ctx, node.body, ext)

jumper_range(ctx, node::VirtualPermissiveArray, ext) = jumper_range(ctx, node.body, ext)
jumper_body(ctx, node::VirtualPermissiveArray, ext, ext_2) = VirtualPermissiveArray(jumper_body(ctx, node.body, ext, ext_2), node.dims)
jumper_seek(ctx, node::VirtualPermissiveArray, ext) = jumper_seek(ctx, node.body, ext)

function short_circuit_cases(ctx, node::VirtualPermissiveArray, op)
    map(short_circuit_cases(ctx, node.body, op)) do (guard, body)
        guard => VirtualPermissiveArray(body, node.dims)
    end
end

getroot(tns::VirtualPermissiveArray) = getroot(tns.body)

function unfurl(ctx, tns::VirtualPermissiveArray, ext, mode, protos...)
    tns_2 = unfurl(ctx, tns.body, ext, mode, protos...)
    dims = virtual_size(ctx, tns.body)
    garb = (mode === reader) ? FillLeaf(literal(missing)) : FillLeaf(Null())
    if tns.dims[end] && dims[end] != dimless
        VirtualPermissiveArray(
            Unfurled(
                tns,
                Sequence([
                    Phase(
                        stop = (ctx, ext_2) -> call(-, getstart(dims[end]), 1),
                        body = (ctx, ext) -> Run(garb),
                    ),
                    Phase(
                        stop = (ctx, ext_2) -> getstop(dims[end]),
                        body = (ctx, ext_2) -> truncate(ctx, tns_2, dims[end], ext_2)
                    ),
                    Phase(
                        body = (ctx, ext_2) -> Run(garb),
                    )
                ]),
            ),
            tns.dims
        )
    else
        VirtualPermissiveArray(tns_2, tns.dims)
    end
end

function lower_access(ctx::AbstractCompiler, node, tns::VirtualPermissiveArray)
    if !isempty(node.idxs)
        error("PermissiveArray not lowered completely")
    end
    lower_access(ctx, node, tns.body)
end
