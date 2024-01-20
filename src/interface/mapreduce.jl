using Base: Broadcast
using Base.Broadcast: Broadcasted, BroadcastStyle, AbstractArrayStyle
using Base.Broadcast: combine_eltypes
using Base: broadcasted
using LinearAlgebra

"""
    reduce_rep(op, tns, dims)

Return a trait object representing the result of reducing a tensor represented
by `tns` on `dims` by `op`.
"""
function reduce_rep end

#TODO we really shouldn't use Drop like this here.
reduce_rep(op, z, tns, dims) =
    reduce_rep_def(op, z, tns, reverse(map(n -> n in dims ? Drop(n) : n, 1:ndims(tns)))...)

reduce_rep_def(op, z, fbr::HollowData, idxs...) = HollowData(reduce_rep_def(op, z, fbr.lvl, idxs...))
function reduce_rep_def(op, z, lvl::HollowData, idx, idxs...)
    if op(z, default(lvl)) == z
        HollowData(reduce_rep_def(op, z, lvl.lvl, idxs...))
    else
        HollowData(reduce_rep_def(op, z, lvl.lvl, idxs...))
    end
end

reduce_rep_def(op, z, lvl::SparseData, idx::Drop, idxs...) = ExtrudeData(reduce_rep_def(op, z, lvl.lvl, idxs...))
function reduce_rep_def(op, z, lvl::SparseData, idx, idxs...)
    if op(z, default(lvl)) == z
        SparseData(reduce_rep_def(op, z, lvl.lvl, idxs...))
    else
        DenseData(reduce_rep_def(op, z, lvl.lvl, idxs...))
    end
end

reduce_rep_def(op, z, lvl::DenseData, idx::Drop, idxs...) = ExtrudeData(reduce_rep_def(op, z, lvl.lvl, idxs...))
reduce_rep_def(op, z, lvl::DenseData, idx, idxs...) = DenseData(reduce_rep_def(op, z, lvl.lvl, idxs...))

reduce_rep_def(op, z, lvl::ElementData) = ElementData(z, fixpoint_type(op, z, lvl))

reduce_rep_def(op, z, lvl::RepeatData, idx::Drop) = ExtrudeData(reduce_rep_def(op, ElementData(lvl.default, lvl.eltype)))
reduce_rep_def(op, z, lvl::RepeatData, idx) = RepeatData(z, fixpoint_type(op, z))

function Base.reduce(op, src::Tensor; kw...)
    bc = broadcasted(identity, src)
    reduce(op, broadcasted(identity, src); kw...)
end
function Base.mapreduce(f, op, src::Tensor, args::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}...; kw...)
    reduce(op, broadcasted(f, src, args...); kw...)
end
function Base.map(f, src::Tensor, args::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}...)
    f.(src, args...)
end
function Base.map!(dst, f, src::Tensor, args::Union{Tensor, Base.AbstractArrayOrBroadcasted}...)
    copyto!(dst, Base.broadcasted(f, src, args...))
end

Base.:+(
    x::Tensor,
    y::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number},
    z::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}...
) = map(+, x, y, z...)
Base.:+(
    x::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number},
    y::Tensor,
    z::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}...
) = map(+, y, x, z...)
Base.:+(
    x::Tensor,
    y::Tensor,
    z::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}...
) = map(+, x, y, z...)
Base.:*(
    x::Tensor,
    y::Number,
    z::Number...
) = map(*, x, y, z...)
Base.:*(
    x::Number,
    y::Tensor,
    z::Number...
) = map(*, y, x, z...)

Base.:-(x::Tensor) = map(-, x)

Base.:-(x::Tensor, y::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}) = map(-, x, y)
Base.:-(x::Union{Tensor, Base.AbstractArrayOrBroadcasted, Number}, y::Tensor) = map(-, x, y)
Base.:-(x::Tensor, y::Tensor) = map(-, x, y)

Base.:/(x::Tensor, y::Number) = map(/, x, y)
Base.:/(x::Number, y::Tensor) = map(\, y, x)

function Base.reduce(op::Function, bc::Broadcasted{FinchStyle{N}}; dims=:, init = initial_value(op, combine_eltypes(bc.f, bc.args))) where {N}
    reduce_helper(Callable{op}(), lift_broadcast(bc), Val(dims), Val(init))
end

@staged function reduce_helper(op, bc, dims, init)
    reduce_helper_code(op, bc, dims, init)
end

function reduce_helper_code(::Type{Callable{op}}, bc::Type{<:Broadcasted{FinchStyle{N}}}, ::Type{Val{dims}}, ::Type{Val{init}}) where {op, dims, init, N}
    contain(LowerJulia()) do ctx
        idxs = [freshen(ctx.code, :idx, n) for n = 1:N]
        rep = collapse_rep(data_rep(bc))
        dst = freshen(ctx.code, :dst)
        if dims == Colon()
            dst_protos = []
            dst_rep = collapse_rep(reduce_rep(op, init, rep, 1:N))
            dst_ctr = :(Scalar{$(default(dst_rep)), $(eltype(dst_rep))}())
            dst_idxs = []
            res_ex = :($dst[])
        else
            dst_rep = collapse_rep(reduce_rep(op, init, rep, dims))
            dst_protos = [n <= maximum(dims) ? laminate : extrude for n = 1:N]
            dst_ctr = fiber_ctr(dst_rep, dst_protos)
            dst_idxs = [n in dims ? 1 : idxs[n] for n in 1:N]
            res_ex = dst
        end
        pw_ex = pointwise_finch_expr(:bc, bc, ctx, idxs)
        exts = Expr(:block, (:($idx = _) for idx in reverse(idxs))...)
        quote
            $dst = $dst_ctr
            @finch begin
                $dst .= $(init)
                $(Expr(:for, exts, quote
                    $dst[$(dst_idxs...)] <<$op>>= $pw_ex
                end))
            end
            $res_ex
        end
    end
end

const FiberOrBroadcast = Union{<:Tensor, <:Broadcasted{FinchStyle{N}} where N}

Base.sum(arr::FiberOrBroadcast; kwargs...) = reduce(+, arr; kwargs...)
Base.prod(arr::FiberOrBroadcast; kwargs...) = reduce(*, arr; kwargs...)
Base.any(arr::FiberOrBroadcast; kwargs...) = reduce(or, arr; init = false, kwargs...)
Base.all(arr::FiberOrBroadcast; kwargs...) = reduce(and, arr; init = true, kwargs...)
Base.minimum(arr::FiberOrBroadcast; kwargs...) = reduce(min, arr; init = Inf, kwargs...)
Base.maximum(arr::FiberOrBroadcast; kwargs...) = reduce(max, arr; init = -Inf, kwargs...)

Base.extrema(arr::FiberOrBroadcast; kwargs...) = mapreduce(plex, min1max2, arr; init = (Inf, -Inf), kwargs...)

function LinearAlgebra.norm(arr::FiberOrBroadcast, p::Real = 2)
    if p == 2
        return root(sum(broadcasted(square, arr)))
    elseif p == 1
        return sum(broadcasted(abs, arr))
    elseif p == Inf
        return maximum(broadcasted(abs, arr))
    elseif p == 0
        return sum(broadcasted(!, broadcasted(iszero, arr)))
    elseif p == -Inf
        return minimum(broadcasted(abs, arr))
    else
        return root(sum(broadcasted(power, broadcasted(norm, arr, p), p)))
    end
end