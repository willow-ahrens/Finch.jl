mutable struct SingleShift{Tv, Ti} <: AbstractVector{Tv}
    I::Ti
    delta::Ti
    val::Vector{Tv}
end

function SingleShift(I::Ti, delta::Ti, val::Vector{Tv}) where {Ti, Tv}
    SingleShift{Tv, Ti}(I, delta, val)
end

Base.size(vec::SingleShift) = (vec.I,)

function Base.getindex(vec::SingleShift{Tv, Ti}, i) where {Tv, Ti}
    vec.val[i - vec.delta]
end

mutable struct VirtualSingleShift{Tv, Ti}
    ex
    name
end

IndexNotation.isliteral(::VirtualSingleShift) =  false

function Finch.virtualize(ex, ::Type{SingleShift{Tv, Ti}}, ctx, tag=:tns) where {Tv, Ti}
    sym = ctx.freshen(tag)
    push!(ctx.preamble, :($sym = $ex))
    VirtualSingleShift{Tv, Ti}(sym, tag)
end

(ctx::Finch.LowerJulia)(tns::VirtualSingleShift) = tns.ex

function Finch.getsize(arr::VirtualSingleShift{Tv, Ti}, ctx::Finch.LowerJulia, mode) where {Tv, Ti}
    ex = Symbol(arr.name, :_stop)
    push!(ctx.preamble, :($ex = $size($(arr.ex))[1]))
    (Extent(Literal(1), Value{Ti}(ex)),)
end
Finch.setsize!(arr::VirtualSingleShift, ctx::Finch.LowerJulia, mode, dims...) = arr
Finch.getname(arr::VirtualSingleShift) = arr.name
Finch.setname(arr::VirtualSingleShift, name) = (arr_2 = deepcopy(arr); arr_2.name = name; arr_2)
function Finch.stylize_access(node, ctx::Finch.Stylize{LowerJulia}, ::VirtualSingleShift)
    if ctx.root isa Loop && ctx.root.idx == get_furl_root(node.idxs[1])
        Finch.ChunkStyle()
    else
        Finch.DefaultStyle()
    end
end

function Finch.chunkify_access(node, ctx, vec::VirtualSingleShift{Tv, Ti}) where {Tv, Ti}
    if getname(ctx.idx) == getname(node.idxs[1])
        tns = Shift(
            body = Lookup(
                body = (i) -> :($(vec.ex).val[$(ctx.ctx(i))])
            ),
            delta = Value{Ti}(:($(vec.ex).delta))
        )
        Access(tns, node.mode, node.idxs)
    else
        node
    end
end

Finch.register()