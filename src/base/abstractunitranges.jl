@kwdef mutable struct VirtualAbstractUnitRange
    ex
    target
    arrtype
    eltype
end

function lower(arr::VirtualAbstractUnitRange, ctx::AbstractCompiler,  ::DefaultStyle)
    return arr.ex
end

function virtualize(ex, arrtype::Type{<:AbstractUnitRange{T}}, ctx, tag=:tns) where {T}
    sym = freshen(ctx, tag)
    push!(ctx.preamble, :($sym = $ex))
    target = Extent(value(:(first($sym)), T), value(:(last($sym)), T))
    VirtualAbstractUnitRange(sym, target, arrtype, T)
end

function virtual_size(arr::VirtualAbstractUnitRange, ctx::AbstractCompiler)
    return [Extent(literal(1), value(:(length($(arr.ex))), Int)),]
end

virtual_resize!(arr::VirtualAbstractUnitRange, ctx::AbstractCompiler, idx_dim) = arr

function instantiate_reader(arr::VirtualAbstractUnitRange, ctx, subprotos, proto::typeof(defaultread))
    Unfurled(
        arr = arr,
        body = Furlable(
            body = (ctx, ext) -> Lookup(
                body = (ctx, i) -> Fill(value(:($(arr.ex)[$(ctx(i))])))
            )
        )
    )
end

function declare!(arr::VirtualAbstractUnitRange, ctx::AbstractCompiler, init)
    throw(FormatLimitation("$(arr.arrtype) is not writeable"))
end

instantiate_updater(arr::VirtualAbstractUnitRange, ctx::AbstractCompiler, protos...) = 
    throw(FormatLimitation("$(arr.arrtype) is not writeable"))

FinchNotation.finch_leaf(x::VirtualAbstractUnitRange) = virtual(x)

virtual_default(::VirtualAbstractUnitRange, ctx) = 0
virtual_eltype(tns::VirtualAbstractUnitRange, ctx) = tns.eltype