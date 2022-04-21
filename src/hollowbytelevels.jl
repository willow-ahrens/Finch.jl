struct HollowByteLevel{Ti, Tp, Tp_2, Lvl}
    I::Ti
    tbl::Vector{Bool}
    srt::Vector{Tuple{Tp, Ti}}
    pos::Vector{Tp_2}
    lvl::Lvl
end
const HollowByte = HollowByteLevel
HollowByteLevel(lvl) = HollowByteLevel(0, lvl)
HollowByteLevel{Ti}(lvl) where {Ti} = HollowByteLevel{Ti}(zero(Ti), lvl)
HollowByteLevel(I::Ti, lvl) where {Ti} = HollowByteLevel{Ti}(I, lvl)
HollowByteLevel{Ti}(I::Ti, lvl) where {Ti} = HollowByteLevel{Ti, Int, Int}(I, lvl)
HollowByteLevel{Ti, Tp, Tp_2}(I::Ti, lvl) where {Ti, Tp, Tp_2} =
    HollowByteLevel{Ti, Tp, Tp_2}(I::Ti, Vector{Bool}(undef, 4), Vector{Tuple{Tp, Ti}}(undef, 4), Vector{Tp_2}(undef, 4), lvl)
HollowByteLevel{Ti, Tp, Tp_2}(I::Ti, tbl, srt, pos, lvl::Lvl) where {Ti, Tp, Tp_2, Lvl} =
    HollowByteLevel{Ti, Tp, Tp_2, Lvl}(I, tbl, srt, pos, lvl)

@inline arity(fbr::Fiber{<:HollowByteLevel}) = 1 + arity(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline shape(fbr::Fiber{<:HollowByteLevel}) = (fbr.lvl.I, shape(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline domain(fbr::Fiber{<:HollowByteLevel}) = (1:fbr.lvl.I, domain(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline image(fbr::Fiber{<:HollowByteLevel}) = image(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline default(fbr::Fiber{<:HollowByteLevel}) = default(Fiber(fbr.lvl.lvl, Environment(fbr.env)))

function (fbr::Fiber{<:HollowByteLevel{Ti}})(i, tail...) where {D, Tv, Ti, R}
    lvl = fbr.lvl
    q = envposition(fbr.env)
    p = (q - 1) * lvl.I + i
    if lvl.tbl[p]
        fbr_2 = Fiber(lvl.lvl, Environment(position=p, index=i, parent=fbr.env))
        fbr_2(tail...)
    else
        default(fbr_2)
    end
end

mutable struct VirtualHollowByteLevel
    ex
    Ti
    Tp
    Tp_2
    I
    pos_q
    idx_q
    idx_q_alloc
    tbl_q
    lvl
end
function virtualize(ex, ::Type{HollowByteLevel{Ti, Tp, Tp_2, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, Tp_2, Lvl}   
    sym = ctx.freshen(tag)
    I = ctx.freshen(sym, :_I)
    pos_q = ctx.freshen(sym, :_pos_q)
    idx_q = ctx.freshen(sym, :_idx_q)
    idx_q_alloc = ctx.freshen(sym, :_idx_q_alloc)
    tbl_q = ctx.freshen(sym, :_tbl_q)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
        $pos_q = length($sym.pos)
        $idx_q = length($sym.srt)
        $idx_q_alloc = length($sym.srt)
        $tbl_q = length($sym.tbl)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualHollowByteLevel(sym, Ti, Tp, Tp_2, I, pos_q, idx_q, idx_q_alloc, tbl_q, lvl_2)
end
(ctx::Finch.LowerJulia)(lvl::VirtualHollowByteLevel) = lvl.ex

function reconstruct!(lvl::VirtualHollowByteLevel, ctx)
    push!(ctx.preamble, quote
        $(lvl.ex) = $HollowByteLevel{$(lvl.Ti), $(lvl.Tp), $(lvl.Tp_2)}(
            $(ctx(lvl.I)),
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
        $(lvl.idx_q) = 0
        # fill!($(lvl.ex).tbl, 0)
        # empty!($(lvl.ex).srt)
        $(lvl.pos_q) = $Finch.refill!($(lvl.ex).pos, $(zero(lvl.Ti)), 0, 5) - 1
        $(lvl.tbl_q) = $Finch.refill!($(lvl.ex).tbl, false, 0, 4)
        $(lvl.idx_q_alloc) = $Finch.regrow!($(lvl.ex).srt, 0, 4)
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

function assemble!(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode)
    q = envposition(fbr.env)
    lvl = fbr.lvl
    q_2 = ctx.freshen(lvl.ex, :_q_2)
    push!(ctx.preamble, quote
        $(lvl.pos_q) < $(ctx(q)) && ($(lvl.pos_q) = Finch.refill!($(lvl.ex).pos, $(zero(lvl.Ti)), $(lvl.pos_q) + 1, $(ctx(q)) + 1) - 1)
        $q_2 = $(ctx(q)) * $(lvl.I)
        $(lvl.tbl_q) < $q_2 && ($(lvl.tbl_q) = Finch.refill!($(lvl.ex).tbl, false, $(lvl.tbl_q), $q_2))
    end)
    assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=q_2, parent=fbr.env)), ctx, mode)
    #This bad boy needs to initialize sublevels like a dense level
end

function finalize_level!(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Union{Write, Update})
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    my_p = ctx.freshen(lvl.ex, :_p)
    push!(ctx.preamble, quote
        sort!(@view $(lvl.ex).srt[1:$(lvl.idx_q)])
        for $my_p = 1:$(lvl.pos_q)
            $(lvl.ex).pos[$my_p + 1] += $(lvl.ex).pos[$my_p]
        end
        #resize!($(lvl.ex).pos, $(lvl.pos_q) + 1)
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
    my_p = ctx.freshen(tag, :_p)
    my_p1 = ctx.freshen(tag, :_p1)
    my_i1 = ctx.freshen(tag, :_i1)

    Thunk(
        preamble = quote
            $my_p = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_p1 = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_p < $my_p1
                $my_i = last($(lvl.ex).srt[$my_p])
                $my_i1 = last($(lvl.ex).srt[$my_p1 - 1])
            else
                $my_i = 1
                $my_i1 = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (start) -> my_i1,
                body = (start, step) -> Stepper(
                    seek = (ctx, start) -> quote
                        #$my_p = searchsortedfirst($(lvl.ex).idx, $start, $my_p, $my_p1, Base.Forward)
                        while $my_p < $my_p1 && last($(lvl.ex).srt[$my_p]) < $start
                            $my_p += 1
                        end
                    end,
                    body = Thunk(
                        preamble = :(
                            $my_i = last($(lvl.ex).srt[$my_p])
                        ),
                        body = Phase(
                            guard = (start) -> :($my_p < $my_p1),
                            stride = (start) -> my_i,
                            body = (start, step) -> Thunk(
                                body = Cases([
                                    :($step == $my_i) => Thunk(
                                        body = Spike(
                                            body = Simplify(default(fbr)),
                                            tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_p), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                                        ),
                                        epilogue = quote
                                            $my_p += 1
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
    my_p = ctx.freshen(tag, :_p)
    my_p1 = ctx.freshen(tag, :_p1)
    my_i1 = ctx.freshen(tag, :_i1)

    Thunk(
        preamble = quote
            $my_p = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_p1 = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_p < $my_p1
                $my_i = last($(lvl.ex).srt[$my_p])
                $my_i1 = last($(lvl.ex).srt[$my_p1 - 1])
            else
                $my_i = 1
                $my_i1 = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (start) -> my_i1,
                body = (start, step) -> Jumper(
                    seek = (ctx, start) -> quote
                        #$my_p = searchsortedfirst($(lvl.ex).idx, $start, $my_p, $my_p1, Base.Forward)
                        while $my_p < $my_p1 && last($(lvl.ex).srt[$my_p]) < $start
                            $my_p += 1
                        end
                    end,
                    body = Thunk(
                        preamble = :(
                            $my_i = last($(lvl.ex).srt[$my_p])
                        ),
                        body = Phase(
                            guard = (start) -> :($my_p < $my_p1),
                            stride = (start) -> my_i,
                            body = (start, step) -> Cases([
                                :($step == $my_i) => Thunk(
                                    body = Spike(
                                        body = Simplify(default(fbr)),
                                        tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_p), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                                    ),
                                    epilogue = quote
                                        $my_p += 1
                                    end
                                ),
                                true => Stepper(
                                    seek = (ctx, start) -> quote
                                        #$my_p = searchsortedfirst($(lvl.ex).idx, $start, $my_p, $my_p1, Base.Forward)
                                        while $my_p < $my_p1 && last($(lvl.ex).srt[$my_p]) < $start
                                            $my_p += 1
                                        end
                                    end,
                                    body = Thunk(
                                        preamble = :(
                                            $my_i = last($(lvl.ex).srt[$my_p])
                                        ),
                                        body = Phase(
                                            stride = (start) -> my_i,
                                            body = (start, step) -> Thunk(
                                                body = Cases([
                                                    :($step == $my_i) => Thunk(
                                                        body = Spike(
                                                            body = Simplify(default(fbr)),
                                                            tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_p), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                                                        ),
                                                        epilogue = quote
                                                            $my_p += 1
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
    my_p = cgx.freshen(tag, :_p)
    q = envposition(fbr.env)

    Leaf(
        body = (i) -> Thunk(
            preamble = quote
                $my_p = $(ctx(q)) * $(lvl.I) + $i
            end,
            body = Cases([
                :($tbl[$my_p]) => refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Tp_2}(my_p), index=i, parent=fbr.env)), ctx, mode, idxs...),
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
    my_p = ctx.freshen(tag, :_p)
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
                    $my_p = ($(ctx(envposition(fbr.env))) - 1) * $(lvl.I) + $idx
                    $my_seen = $(lvl.ex).tbl[$my_p]
                    if !$my_seen
                        $(contain(ctx) do ctx_2 
                            #THIS code reassembles every time. TODO
                            assemble!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(position=my_p, parent=VirtualEnvironment(fbr.env))), ctx_2, mode)
                            quote end
                        end)
                    end
                end,
                body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_p), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode, idxs...),
                epilogue = begin
                    body = quote
                        if !$my_seen
                            $(lvl.ex).tbl[$my_p] = true
                            $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1] += 1
                            $(lvl.idx_q) += 1
                            $(lvl.idx_q_alloc) < $(lvl.idx_q) && ($(lvl.idx_q_alloc) = $Finch.regrow!($(lvl.ex).srt, $(lvl.idx_q_alloc), $(lvl.idx_q)))
                            $(lvl.ex).srt[$(lvl.idx_q)] = ($(ctx(envposition(fbr.env))), $idx)
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