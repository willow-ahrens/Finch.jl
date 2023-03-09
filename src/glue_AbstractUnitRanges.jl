@kwdef mutable struct VirtualAbstractUnitRange
    ex
    target
    arrtype
    eltype
end

function (ctx::LowerJulia)(arr::VirtualAbstractUnitRange, ::DefaultStyle)
    return arr.ex
end

function virtualize(ex, arrtype::Type{<:AbstractUnitRange{T}}, ctx, tag=:tns) where {T}
    sym = ctx.freshen(tag)
    push!(ctx.preamble, :($sym = $ex))
    target = Extent(value(:(first($sym)), T), value(:(last($sym)), T))
    VirtualAbstractUnitRange(sym, target, arrtype, T)
end

function virtual_size(arr::VirtualAbstractUnitRange, ctx::LowerJulia, ::NoDimension) #TODO I'm sure this has unintended consequences
    return [Extent(literal(1), value(:(length($(arr.ex))), Int)),]
end

virtual_size(arr::VirtualAbstractUnitRange, ctx::LowerJulia, dim) = (shiftdim(arr.target, call(-, getstart(dim), getstart(arr.target))),)
virtual_resize!(arr::VirtualAbstractUnitRange, ctx::LowerJulia, idx_dim) = (arr, arr.target)
virtual_eldim(arr::VirtualAbstractUnitRange, ctx::LowerJulia, idx_dim) = arr.target

function get_reader(arr::VirtualAbstractUnitRange, ctx, proto_idx)
    Furlable(
        size = (nodim,),
        body = (ctx, idx, ext) -> Lookup(
            body = (i) -> Fill(value(:($(arr.ex)[$(ctx(i))])))
        ),
        fuse = (tns, ctx, idx, ext) ->
            Shift(truncate(tns, ctx, ext, arr.target), call(-, getstart(ext), getstart(arr.target)))
    )
end

function initialize!(arr::VirtualAbstractUnitRange, ctx::LowerJulia)
    throw(FormatLimitation("$(arr.arrtype) is not writeable"))
end

get_updater(arr::VirtualAbstractUnitRange, ctx::LowerJulia, protos...) = 
    throw(FormatLimitation("$(arr.arrtype) is not writeable"))

FinchNotation.isliteral(::VirtualAbstractUnitRange) =  false

virtual_default(::VirtualAbstractUnitRange) = 0
virtual_eltype(tns::VirtualAbstractUnitRange) = tns.eltype