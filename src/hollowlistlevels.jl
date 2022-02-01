struct HollowListLevel{D, Tv, Ti}
    I::Ti
    pos::Vector{Ti}
    idx::Vector{Ti}
end
const HollowList = HollowListLevel

HollowListLevel{D}(args...) where {D} = HollowListLevel{D, typeof(D)}(args...)
HollowListLevel{D, Tv}() where {D, Tv} = HollowListLevel{D, Tv}(0)
HollowListLevel{D, Tv}(I::Ti) where {D, Tv, Ti} = HollowListLevel{D, Tv, Ti}(I)
HollowListLevel{D, Tv}(I::Ti, pos, idx) where {D, Tv, Ti} = HollowListLevel{D, Tv, Ti}(I, pos, idx)
HollowListLevel{D, Tv, Ti}() where {D, Tv, Ti} = HollowListLevel{D, Tv, Ti}(zero(Ti))
HollowListLevel{D, Tv, Ti}(I::Ti) where {D, Tv, Ti} = HollowListLevel{D, Tv, Ti}(I, Vector{Ti}(undef, 4), Vector{Ti}(undef, 4))

dimension(lvl::HollowListLevel) = lvl.I

function unfurl(lvl::HollowListLevel{D, Tv, Ti}, fbr::Fiber{Tv, N, R}, i, tail...) where {D, Tv, Ti, N, R}
    q = fbr.poss[R]
    r = searchsorted(@view(lvl.idx[lvl.pos[q]:lvl.pos[q + 1] - 1]), i)
    p = lvl.pos[q] + first(r) - 1
    length(r) == 0 ? D : readindex(refurl(fbr, p, i), tail...)
end



struct VirtualHollowListLevel
    ex
    D
    Tv
    Ti
    I
    pos_q
    idx_q
end

(ctx::Finch.LowerJulia)(lvl::VirtualHollowListLevel) = lvl.ex

function virtualize(ex, ::Type{HollowListLevel{D, Tv, Ti}}, ctx, tag=:lvl) where {D, Tv, Ti}
    sym = ctx.freshen(tag)
    I = ctx.freshen(tag, :_I)
    pos_q = ctx.freshen(tag, :_pos_q)
    idx_q = ctx.freshen(tag, :_idx_q)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
        $pos_q = length($sym.pos)
        $idx_q = length($sym.idx)
    end)
    VirtualHollowListLevel(sym, D, Tv, Ti, I, pos_q, idx_q)
end

function getdims_level!(lvl::VirtualHollowListLevel, arr, R, ctx, mode)
    ext = Extent(1, Virtual{Int}(lvl.I))
    return mode isa Read ? ext : SuggestedExtent(ext)
end

function initialize_level!(lvl::VirtualHollowListLevel, tns, R, ctx, mode)
    push!(ctx.preamble, quote
        if $(lvl.pos_q) < 4
            resize!($(lvl.ex).pos, 4)
        end
        $(lvl.pos_q) = 4
        $(lvl.ex).pos[1] = 1
        if $(lvl.idx_q) < 4
            resize!($(lvl.ex).idx, 4)
        end
        $(lvl.idx_q) = 4
    end)
    if mode isa Union{Write, Update}
        push!(ctx.preamble, quote
            $(lvl.I) = $(ctx(ctx.dims[(getname(tns), R)].stop))
            $(lvl.ex) = HollowListLevel{$(lvl.D), $(lvl.Tv), $(lvl.Ti)}(
                $(lvl.Ti)($(lvl.I)),
                $(lvl.ex).pos,
                $(lvl.ex).idx,
            )
        end)
        lvl
    else
        return nothing
    end
end

function virtual_assemble(lvl::VirtualHollowListLevel, tns, ctx, qoss, q)
    if q == nothing
        return quote end
    else
        return quote
            if $(lvl.pos_q) < $(ctx(q))
                resize!($(lvl.ex).pos, $(lvl.pos_q) * 4)
                $(lvl.pos_q) *= 4
            end
            $(virtual_assemble(tns, ctx, qoss, nothing))
        end
    end
end

virtual_unfurl(lvl::VirtualHollowListLevel, tns, ctx, mode::Read, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, walk(idx), tail...)

function virtual_unfurl(lvl::VirtualHollowListLevel, tns, ctx, mode::Read, idx::Walk, tail...)
    R = tns.R
    tag = Symbol(getname(tns), :_lvl, R)
    my_i = ctx.freshen(tag, :_i)
    my_p = ctx.freshen(tag, :_p)
    my_p1 = ctx.freshen(tag, :_p1)
    my_i1 = ctx.freshen(tag, :_i1)

    Thunk(
        preamble = quote
            $my_p = $(lvl.ex).pos[$(ctx(tns.poss[R]))]
            $my_p1 = $(lvl.ex).pos[$(ctx(tns.poss[R])) + 1]
            if $my_p < $my_p1
                $my_i = $(lvl.ex).idx[$my_p]
                $my_i1 = $(lvl.ex).idx[$my_p1 - 1]
            else
                $my_i = 1
                $my_i1 = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (start) -> my_i1,
                body = (start, step) -> Stepper(
                    preamble = :(
                        $my_i = $(lvl.ex).idx[$my_p]
                    ),
                    guard = (start) -> :($my_p < $my_p1),
                    stride = (start) -> my_i,
                    body = (start, step) -> Thunk(
                        body = Cases([
                            :($step < $my_i) =>
                                Run(
                                    body = lvl.D,
                                ),
                            true =>
                                Thunk(
                                    body = Spike(
                                        body = lvl.D,
                                        tail = virtual_refurl(tns, Virtual{lvl.Tv}(my_p), Virtual{lvl.Ti}(my_i), mode, tail...),
                                    ),
                                    epilogue = quote
                                        $my_p += 1
                                    end
                                ),
                        ])
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(0)
            )
        ])
    )
end

virtual_unfurl(lvl::VirtualHollowListLevel, tns, ctx, mode::Union{Write, Update}, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, extrude(idx), tail...)

function virtual_unfurl(lvl::VirtualHollowListLevel, tns, ctx, mode::Union{Write, Update}, idx::Extrude, tail...)
    R = tns.R
    tag = Symbol(getname(tns), :_lvl, R)
    my_i = ctx.freshen(tag, :_i)
    my_p = ctx.freshen(tag, :_p)
    my_p1 = ctx.freshen(tag, :_p1)
    my_i1 = ctx.freshen(tag, :_i1)

    Thunk(
        preamble = quote
            $my_p = $(lvl.ex).pos[$(ctx(tns.poss[R]))]
        end,
        body = AcceptSpike(
            val = lvl.D,
            tail = (ctx, idx) -> Thunk(
                preamble = quote
                    $(scope(ctx) do ctx2 
                        virtual_assemble(tns, ctx2, my_p)
                    end)
                end,
                body = virtual_refurl(tns, Virtual{lvl.Tv}(my_p), idx, mode, tail...),
                epilogue = quote
                    if $(lvl.idx_q) < $my_p
                        resize!($(lvl.ex).idx, $(lvl.idx_q) * 4)
                        $(lvl.idx_q) *= 4
                    end
                    $(lvl.ex).idx[$my_p] = $(ctx(idx))
                    $my_p += 1
                end
            )
        ),
        epilogue = quote
            $(lvl.ex).pos[$(ctx(tns.poss[R])) + 1] = $my_p
        end
    )
end