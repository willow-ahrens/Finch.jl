struct RaggedLevel{Ti, Tp, Lvl}
    lvl::Lvl
    I::Ti
    ptr::Vector{Tp}
end
const Ragged = RaggedLevel
RaggedLevel(lvl) = RaggedLevel{Int}(lvl)
RaggedLevel(lvl, I::Ti, args...) where {Ti} = RaggedLevel{Ti}(lvl, I, args...)
RaggedLevel{Ti}(lvl, args...) where {Ti} = RaggedLevel{Ti, typeof(lvl)}(lvl, args...)
RaggedLevel{Ti, Tp}(lvl, args...) where {Ti, Tp} = RaggedLevel{Ti, Tp, typeof(lvl)}(lvl, args...)


RaggedLevel{Ti, Tp, Lvl}(lvl) where {Ti, Tp, Lvl} = RaggedLevel{Ti, Tp, Lvl}(lvl, zero(Ti))
RaggedLevel{Ti, Tp, Lvl}(lvl, I) where {Ti, Tp, Lvl} =
RaggedLevel{Ti, Tp, Lvl}(lvl, Ti(I), Tp[1])


mutable struct VirtualRaggedLevel
    lvl
    ex
    Ti
    Tp
    I
    qos_fill
    qos_stop
end
function virtualize(ex, ::Type{RaggedLevel{Ti, Tp, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, Lvl}
    sym = ctx.freshen(tag)
    I = value(:($sym.I), Int)
    qos_fill = ctx.freshen(sym, :_qos_fill)
    qos_stop = ctx.freshen(sym, :_qos_stop)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualRaggedLevel(lvl_2, sym, Ti, Tp, I, qos_fill, qos_stop)
end
