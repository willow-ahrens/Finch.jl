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

is_injective(lvl::VirtualPermissiveArray, ctx) = is_injective(lvl.body, ctx)
is_atomic(lvl::VirtualPermissiveArray, ctx) = is_atomic(lvl.body, ctx)

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
function virtual_call(::typeof(permissive), ctx, body, dims...)
    @assert All(isliteral)(dims)
    VirtualPermissiveArray(body, map(dim -> dim.val, dims))
end

unwrap(ctx, arr::VirtualPermissiveArray, var) = call(permissive, unwrap(ctx, arr.body, var), arr.dims...)

lower(tns::VirtualPermissiveArray, ctx::AbstractCompiler, ::DefaultStyle) = :(PermissiveArray($(ctx(tns.body)), $(tns.dims)))

function virtual_size(ctx::AbstractCompiler, arr::VirtualPermissiveArray)
    ifelse.(arr.dims, (dimless,), virtual_size(ctx, arr.body))
end

function virtual_resize!(ctx::AbstractCompiler, arr::VirtualPermissiveArray, dims...)
    virtual_resize!(ctx, arr.body, ifelse.(arr.dims, virtual_size(ctx, arr.body), dim))
end

virtual_default(ctx::AbstractCompiler, arr::VirtualPermissiveArray) = virtual_default(ctx, arr.body)

function instantiate(arr::VirtualPermissiveArray, ctx, mode, protos)
    VirtualPermissiveArray(instantiate(arr.body, ctx, mode, protos), arr.dims)
end

(ctx::Stylize{<:AbstractCompiler})(node::VirtualPermissiveArray) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::VirtualPermissiveArray)
    stylize_access(node, ctx, tns.body)
end

function popdim(node::VirtualPermissiveArray)
    if length(node.dims) == 1
        return node.body
    else
        return VirtualPermissiveArray(node.body, node.dims[1:end-1])
    end
end

truncate(node::VirtualPermissiveArray, ctx, ext, ext_2) = VirtualPermissiveArray(truncate(node.body, ctx, ext, ext_2), node.dims)

function get_point_body(node::VirtualPermissiveArray, ctx, ext, idx)
    body_2 = get_point_body(node.body, ctx, ext, idx)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualPermissiveArray(body_2, node.dims))
    end
end

(ctx::ThunkVisitor)(node::VirtualPermissiveArray) = VirtualPermissiveArray(ctx(node.body), node.dims)

function get_run_body(node::VirtualPermissiveArray, ctx, ext)
    body_2 = get_run_body(node.body, ctx, ext)
    if body_2 === nothing
        return nothing
    else
        return popdim(VirtualPermissiveArray(body_2, node.dims))
    end
end

function get_acceptrun_body(node::VirtualPermissiveArray, ctx, ext)
    body_2 = get_acceptrun_body(node.body, ctx, ext)
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

phase_body(node::VirtualPermissiveArray, ctx, ext, ext_2) = VirtualPermissiveArray(phase_body(node.body, ctx, ext, ext_2), node.dims)
phase_range(node::VirtualPermissiveArray, ctx, ext) = phase_range(node.body, ctx, ext)

get_spike_body(node::VirtualPermissiveArray, ctx, ext, ext_2) = VirtualPermissiveArray(get_spike_body(node.body, ctx, ext, ext_2), node.dims)
get_spike_tail(node::VirtualPermissiveArray, ctx, ext, ext_2) = VirtualPermissiveArray(get_spike_tail(node.body, ctx, ext, ext_2), node.dims)

visit_fill(node, tns::VirtualPermissiveArray) = visit_fill(node, tns.body)
visit_simplify(node::VirtualPermissiveArray) = VirtualPermissiveArray(visit_simplify(node.body), node.dims)

(ctx::SwitchVisitor)(node::VirtualPermissiveArray) = map(ctx(node.body)) do (guard, body)
    guard => VirtualPermissiveArray(body, node.dims)
end

stepper_range(node::VirtualPermissiveArray, ctx, ext) = stepper_range(node.body, ctx, ext)
stepper_body(node::VirtualPermissiveArray, ctx, ext, ext_2) = VirtualPermissiveArray(stepper_body(node.body, ctx, ext, ext_2), node.dims)
stepper_seek(node::VirtualPermissiveArray, ctx, ext) = stepper_seek(node.body, ctx, ext)

jumper_range(node::VirtualPermissiveArray, ctx, ext) = jumper_range(node.body, ctx, ext)
jumper_body(node::VirtualPermissiveArray, ctx, ext, ext_2) = VirtualPermissiveArray(jumper_body(node.body, ctx, ext, ext_2), node.dims)
jumper_seek(node::VirtualPermissiveArray, ctx, ext) = jumper_seek(node.body, ctx, ext)

function short_circuit_cases(node::VirtualPermissiveArray, ctx, op)
    map(short_circuit_cases(node.body, ctx, op)) do (guard, body)
        guard => VirtualPermissiveArray(body, node.dims)
    end
end

getroot(tns::VirtualPermissiveArray) = getroot(tns.body)

function unfurl(tns::VirtualPermissiveArray, ctx, ext, mode, protos...)
    tns_2 = unfurl(tns.body, ctx, ext, mode, protos...)
    dims = virtual_size(ctx, tns.body)
    garb = (mode === reader) ? Fill(literal(missing)) : Fill(Null())
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
                        body = (ctx, ext_2) -> truncate(tns_2, ctx, dims[end], ext_2)
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
