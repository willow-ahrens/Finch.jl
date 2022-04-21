struct HollowByteLevel{Ti, Tp, Tq, Lvl}
    I::Ti
    P::Ref{Int}
    tbl::Vector{Bool}
    srt::Vector{Tuple{Tp, Ti}}
    pos::Vector{Tq}
    lvl::Lvl
end
const HollowByte = HollowByteLevel
HollowByteLevel(lvl) = HollowByteLevel(0, lvl)
HollowByteLevel{Ti}(lvl) where {Ti} = HollowByteLevel{Ti}(zero(Ti), lvl)
HollowByteLevel(I::Ti, lvl) where {Ti} = HollowByteLevel{Ti}(I, lvl)
HollowByteLevel{Ti}(I::Ti, lvl) where {Ti} = HollowByteLevel{Ti, Int, Int}(I, lvl)
HollowByteLevel{Ti, Tp, Tq}(I::Ti, lvl) where {Ti, Tp, Tq} =
    HollowByteLevel{Ti, Tp, Tq}(I::Ti, Ref(0), [false, false, false, false], Vector{Tuple{Tp, Ti}}(undef, 4), Tq[1, 1, 0, 0, 0], lvl)
HollowByteLevel{Ti, Tp, Tq}(I::Ti, P, tbl, srt, pos, lvl::Lvl) where {Ti, Tp, Tq, Lvl} =
    HollowByteLevel{Ti, Tp, Tq, Lvl}(I, P, tbl, srt, pos, lvl)

@inline arity(fbr::Fiber{<:HollowByteLevel}) = 1 + arity(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline shape(fbr::Fiber{<:HollowByteLevel}) = (fbr.lvl.I, shape(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline domain(fbr::Fiber{<:HollowByteLevel}) = (1:fbr.lvl.I, domain(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline image(fbr::Fiber{<:HollowByteLevel}) = image(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline default(fbr::Fiber{<:HollowByteLevel}) = default(Fiber(fbr.lvl.lvl, Environment(fbr.env)))

function (fbr::Fiber{<:HollowByteLevel{Ti}})(i, tail...) where {D, Tv, Ti, R}
    lvl = fbr.lvl
    p = envposition(fbr.env)
    q = (p - 1) * lvl.I + i
    if lvl.tbl[q]
        fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
        fbr_2(tail...)
    else
        default(fbr_2)
    end
end

mutable struct VirtualHollowByteLevel
    ex
    Ti
    Tp
    Tq
    I
    pos_alloc
    Q
    idx_alloc
    tbl_alloc
    lvl
end
function virtualize(ex, ::Type{HollowByteLevel{Ti, Tp, Tq, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, Tq, Lvl}   
    sym = ctx.freshen(tag)
    I = ctx.freshen(sym, :_I)
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    Q = ctx.freshen(sym, :_Q)
    idx_alloc = ctx.freshen(sym, :_idx_alloc)
    tbl_alloc = ctx.freshen(sym, :_tbl_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
        $pos_alloc = length($sym.pos)
        $Q = length($sym.srt)
        $idx_alloc = length($sym.srt)
        $tbl_alloc = length($sym.tbl)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualHollowByteLevel(sym, Ti, Tp, Tq, I, pos_alloc, Q, idx_alloc, tbl_alloc, lvl_2)
end
(ctx::Finch.LowerJulia)(lvl::VirtualHollowByteLevel) = lvl.ex

function reconstruct!(lvl::VirtualHollowByteLevel, ctx)
    push!(ctx.preamble, quote
        $(lvl.ex) = $HollowByteLevel{$(lvl.Ti), $(lvl.Tp), $(lvl.Tq)}(
            $(ctx(lvl.I)),
            $(lvl.ex).P,
            $(lvl.ex).tbl,
            $(lvl.ex).srt,
            $(lvl.ex).pos,
            $(ctx(lvl.lvl)),
        )
    end)
end

function getsites(fbr::VirtualFiber{VirtualHollowByteLevel})
    return (envdepth(fbr.env) + 1, getsites(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))...)
end

function getdims(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode)
    ext = Extent(1, Virtual{Int}(:($(fbr.lvl.I))))
    dim = mode isa Read ? ext : SuggestedExtent(ext)
    (dim, getdims(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)...)
end

@inline default(fbr::VirtualFiber{VirtualHollowByteLevel}) = default(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Union{Write, Update})
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    my_p = ctx.freshen(lvl.ex, :_p)
    push!(ctx.preamble, quote
        $(lvl.I) = $(lvl.Ti)($(ctx(stop(ctx.dims[(getname(fbr), envdepth(fbr.env) + 1)]))))
        $(lvl.Q) = 0
        # fill!($(lvl.ex).tbl, 0)
        # empty!($(lvl.ex).srt)
        $(lvl.pos_alloc) = $Finch.refill!($(lvl.ex).pos, $(zero(lvl.Ti)), 0, 5) - 1
        $(lvl.tbl_alloc) = $Finch.refill!($(lvl.ex).tbl, false, 0, 4)
        $(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).srt, 0, 4)
        $(lvl.ex).pos[1] = 1
    end)
    if (lvl_2 = initialize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)) !== nothing
        lvl = shallowcopy(lvl)
        lvl.lvl = lvl_2
    end
    reconstruct!(lvl, ctx)
    return lvl
end

interval_assembly_depth(lvl::VirtualHollowByteLevel) = min(Inf, interval_assembly_depth(lvl.lvl) - 1)

#TODO does this actually support reassembly? I think it needs to filter out indices with unset table entries during finalization
function assemble!(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p), stop(envposition(fbr.env))))
    if extent(envposition(fbr.env)) == 1
        p_start = p_stop
    else
        p_start = ctx(cache!(ctx, freshen(lvl.ex, :_p), start(envposition(fbr.env))))
    end
    p_start_2 = ctx.freshen(lvl.ex, :p_start_2)
    p_stop_2 = ctx.freshen(lvl.ex, :p_stop_2)
    p_2 = ctx.freshen(lvl.ex, :p_2)

    push!(ctx.preamble, quote
        $p_start_2 = ($p_start - 1) * $(lvl.I) + 1
        $p_stop_2 = $p_stop * $(lvl.I)
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = Finch.refill!($(lvl.ex).pos, $(zero(lvl.Ti)), $(lvl.pos_alloc), $p_stop + 1))
        $(lvl.tbl_alloc) < $p_stop_2 && ($(lvl.tbl_alloc) = Finch.refill!($(lvl.ex).tbl, false, $(lvl.tbl_alloc), $p_stop_2))
    end)

    if interval_assembly_depth(lvl.lvl) >= 1
        assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Extent(p_start_2, p_stop_2), index = Extent(1, lvl.I), parent=fbr.env)), ctx, mode)
    else
        i_2 = ctx.freshen(lvl.ex, :_i)
        p = ctx.freshen(lvl.ex, :_p)
        push!(ctx.preamble, quote
            for $p = $p_start:$p_stop
                for $i_2 = 1:$(lvl.I)
                    $p_2 = ($p - 1) * $(lvl.I) + $i_2
                    assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual(p_2), index=Virtual(i_2), parent=fbr.env)), ctx, mode)
                end
            end
        end)
    end
end

function finalize_level!(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Union{Write, Update})
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    my_p = ctx.freshen(lvl.ex, :_p)
    push!(ctx.preamble, quote
        sort!(@view $(lvl.ex).srt[1:$(lvl.Q)])
        for $my_p = 1:$(lvl.pos_alloc)
            $(lvl.ex).pos[$my_p + 1] += $(lvl.ex).pos[$my_p]
        end
        #resize!($(lvl.ex).pos, $(lvl.pos_alloc) + 1)
    end)
    if (lvl_2 = finalize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)) !== nothing
        lvl = shallowcopy(lvl)
        lvl.lvl = lvl_2
        reconstruct!(lvl, ctx)
        return lvl
    else
        return nothing
    end
end

unfurl(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Read, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, walk(idx))

function unfurl(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Read, idx::Walk, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_p)
    my_q_stop = ctx.freshen(tag, :_p1)
    my_i_stop = ctx.freshen(tag, :_i_stop)

    Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_q < $my_p1
                $my_i = last($(lvl.ex).srt[$my_q])
                $my_i_stop = last($(lvl.ex).srt[$my_q_stop - 1])
            else
                $my_i = 1
                $my_i_stop = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (start) -> my_i_stop,
                body = (start, step) -> Stepper(
                    seek = (ctx, start) -> quote
                        #$my_q = searchsortedfirst($(lvl.ex).idx, $start, $my_p, $my_p1, Base.Forward)
                        while $my_q < $my_p1 && last($(lvl.ex).srt[$my_p]) < $start
                            $my_q += 1
                        end
                    end,
                    body = Thunk(
                        preamble = :(
                            $my_i = last($(lvl.ex).srt[$my_q])
                        ),
                        body = Phase(
                            guard = (start) -> :($my_q < $my_p1),
                            stride = (start) -> my_i,
                            body = (start, step) -> Thunk(
                                body = Cases([
                                    :($step == $my_i) => Thunk(
                                        body = Spike(
                                            body = Simplify(default(fbr)),
                                            tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                                        ),
                                        epilogue = quote
                                            $my_q += 1
                                        end
                                    ),
                                    true => Run(
                                        body = Simplify(default(fbr)),
                                    ),
                                ])
                            )
                        )
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(default(fbr)))
            )
        ])
    )
end

function unfurl(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Read, idx::Gallop, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)

    Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_q < $my_q_stop
                $my_i = last($(lvl.ex).srt[$my_q])
                $my_i_stop = last($(lvl.ex).srt[$my_q_stop - 1])
            else
                $my_i = 1
                $my_i_stop = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (start) -> my_i_stop,
                body = (start, step) -> Jumper(
                    seek = (ctx, start) -> quote
                        #$my_q = searchsortedfirst($(lvl.ex).idx, $start, $my_q, $my_q_stop, Base.Forward)
                        while $my_q < $my_q_stop && last($(lvl.ex).srt[$my_q]) < $start
                            $my_q += 1
                        end
                    end,
                    body = Thunk(
                        preamble = :(
                            $my_i = last($(lvl.ex).srt[$my_q])
                        ),
                        body = Phase(
                            guard = (start) -> :($my_q < $my_q_stop),
                            stride = (start) -> my_i,
                            body = (start, step) -> Cases([
                                :($step == $my_i) => Thunk(
                                    body = Spike(
                                        body = Simplify(default(fbr)),
                                        tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                                    ),
                                    epilogue = quote
                                        $my_q += 1
                                    end
                                ),
                                true => Stepper(
                                    seek = (ctx, start) -> quote
                                        #$my_q = searchsortedfirst($(lvl.ex).idx, $start, $my_q, $my_q_stop, Base.Forward)
                                        while $my_q < $my_q_stop && last($(lvl.ex).srt[$my_q]) < $start
                                            $my_q += 1
                                        end
                                    end,
                                    body = Thunk(
                                        preamble = :(
                                            $my_i = last($(lvl.ex).srt[$my_q])
                                        ),
                                        body = Phase(
                                            stride = (start) -> my_i,
                                            body = (start, step) -> Thunk(
                                                body = Cases([
                                                    :($step == $my_i) => Thunk(
                                                        body = Spike(
                                                            body = Simplify(default(fbr)),
                                                            tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                                                        ),
                                                        epilogue = quote
                                                            $my_q += 1
                                                        end
                                                    ),
                                                    true => Run(
                                                        body = Simplify(default(fbr)),
                                                    ),
                                                ])
                                            )
                                        )
                                    )
                                ),
                            ])
                        )
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(default(fbr)))
            )
        ])
    )
end

function unfurl(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Read, idx::Union{Follow}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    R = length(envdeferred(fbr.env)) + 1
    my_key = cgx.freshen(tag, :_key)
    my_q = cgx.freshen(tag, :_q)
    q = envposition(fbr.env)

    Leaf(
        body = (i) -> Thunk(
            preamble = quote
                $my_q = $(ctx(q)) * $(lvl.I) + $i
            end,
            body = Cases([
                :($tbl[$my_q]) => refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Tq}(my_q), index=i, parent=fbr.env)), ctx, mode, idxs...),
                true => Simplify(default(fbr))
            ])
        )
    )
end

unfurl(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Union{Write, Update}, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, laminate(idx), idxs...)

hasdefaultcheck(lvl::VirtualHollowByteLevel) = true

function unfurl(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Union{Write, Update}, idx::Union{Name, Extrude, Laminate}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_key = ctx.freshen(tag, :_key)
    my_q = ctx.freshen(tag, :_q)
    my_guard = ctx.freshen(tag, :_guard)
    my_seen = ctx.freshen(tag, :_seen)

    Thunk(
        preamble = quote
        end,
        body = AcceptSpike(
            val = default(fbr),
            tail = (ctx, idx) -> Thunk(
                preamble = quote
                    $my_guard = true
                    $my_q = ($(ctx(envposition(fbr.env))) - 1) * $(lvl.I) + $idx
                    $my_seen = $(lvl.ex).tbl[$my_q]
                    if !$my_seen
                        $(contain(ctx) do ctx_2 
                            #TODO This code reassembles every time. Maybe that's okay?
                            assemble!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(position=my_q, parent=VirtualEnvironment(fbr.env))), ctx_2, mode)
                            quote end
                        end)
                    end
                end,
                body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode, idxs...),
                epilogue = begin
                    body = quote
                        if !$my_seen
                            $(lvl.ex).tbl[$my_q] = true
                            $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1] += 1
                            $(lvl.Q) += 1
                            $(lvl.idx_alloc) < $(lvl.Q) && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).srt, $(lvl.idx_alloc), $(lvl.Q)))
                            $(lvl.ex).srt[$(lvl.Q)] = ($(ctx(envposition(fbr.env))), $idx)
                        end
                    end
                    if envdefaultcheck(fbr.env) !== nothing
                        body = quote
                            $body
                            $(envdefaultcheck(fbr.env)) = false
                        end
                    end
                    if hasdefaultcheck(lvl.lvl)
                        body = quote
                            if !$(my_guard)
                                $body
                            end
                        end
                    end
                    body
                end
            )
        )
    )
end