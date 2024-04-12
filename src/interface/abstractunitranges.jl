@kwdef mutable struct VirtualAbstractUnitRange
    ex
    target
    arrtype
    eltype
end

function lower(arr::VirtualAbstractUnitRange, ctx::AbstractCompiler,  ::DefaultStyle)
    return arr.ex
end

function virtualize(ctx, ex, arrtype::Type{<:AbstractUnitRange{T}}, tag=:tns) where {T}
    sym = freshen(ctx, tag)
    push!(ctx.preamble, :($sym = $ex))
    target = Extent(value(:(first($sym)), T), value(:(last($sym)), T))
    VirtualAbstractUnitRange(sym, target, arrtype, T)
end

function virtual_size(ctx::AbstractCompiler, arr::VirtualAbstractUnitRange)
    return [Extent(literal(1), value(:(length($(arr.ex))), Int)),]
end

virtual_resize!(ctx::AbstractCompiler, arr::VirtualAbstractUnitRange, idx_dim) = arr

function instantiate(arr::VirtualAbstractUnitRange, ctx, mode::Reader, subprotos, proto::typeof(defaultread))
    Unfurled(
        arr = arr,
        body = Furlable(
            body = (ctx, ext) -> Lookup(
                body = (ctx, i) -> Fill(value(:($(arr.ex)[$(ctx(i))])))
            )
        )
    )
end

function declare!(ctx::AbstractCompiler, arr::VirtualAbstractUnitRange, init)
    throw(FinchProtocolError("$(arr.arrtype) is not writeable"))
end

instantiate(arr::VirtualAbstractUnitRange, ctx::AbstractCompiler, mode::Updater, protos...) = 
    throw(FinchProtocolError("$(arr.arrtype) is not writeable"))

FinchNotation.finch_leaf(x::VirtualAbstractUnitRange) = virtual(x)

virtual_default(ctx, ::VirtualAbstractUnitRange) = 0
virtual_eltype(ctx, tns::VirtualAbstractUnitRange) = tns.eltype