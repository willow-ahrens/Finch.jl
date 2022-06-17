struct HollowByteLevel{Ti, Tp, Tq, Lvl}
    I::Ti
    P::Ref{Int}
    tbl::Vector{Bool}
    srt::Vector{Tuple{Tp, Ti}}
    srt_stop::Ref{Int}
    pos::Vector{Tq}
    lvl::Lvl
end
const HollowByte = HollowByteLevel
HollowByteLevel(lvl) = HollowByteLevel(0, lvl)
HollowByteLevel{Ti}(lvl) where {Ti} = HollowByteLevel{Ti}(zero(Ti), lvl)
HollowByteLevel(I::Ti, lvl) where {Ti} = HollowByteLevel{Ti}(I, lvl)
HollowByteLevel{Ti}(I::Ti, lvl) where {Ti} = HollowByteLevel{Ti, Int, Int}(I, lvl)
HollowByteLevel{Ti, Tp, Tq}(I::Ti, lvl) where {Ti, Tp, Tq} =
    HollowByteLevel{Ti, Tp, Tq}(I::Ti, Ref(0), [false, false, false, false], Vector{Tuple{Tp, Ti}}(undef, 4), Ref(0), Tq[1, 1, 0, 0, 0], lvl)
HollowByteLevel{Ti, Tp, Tq}(I::Ti, P, tbl, srt, srt_stop, pos, lvl::Lvl) where {Ti, Tp, Tq, Lvl} =
    HollowByteLevel{Ti, Tp, Tq, Lvl}(I, P, tbl, srt, srt_stop, pos, lvl)

@inline arity(fbr::Fiber{<:HollowByteLevel}) = 1 + arity(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline shape(fbr::Fiber{<:HollowByteLevel}) = (fbr.lvl.I, shape(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline domain(fbr::Fiber{<:HollowByteLevel}) = (1:fbr.lvl.I, domain(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline image(fbr::Fiber{<:HollowByteLevel}) = image(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline default(fbr::Fiber{<:HollowByteLevel}) = default(Fiber(fbr.lvl.lvl, Environment(fbr.env)))

function (fbr::Fiber{<:HollowByteLevel{Ti}})(i, tail...) where {D, Tv, Ti}
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
    tbl_alloc
    srt_alloc
    srt_stop
    pos_alloc
    lvl
end
function virtualize(ex, ::Type{HollowByteLevel{Ti, Tp, Tq, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, Tq, Lvl}   
    sym = ctx.freshen(tag)
    I = ctx.freshen(sym, :_I)
    tbl_alloc = ctx.freshen(sym, :_tbl_alloc)
    srt_stop = ctx.freshen(sym, :_srt_stop)
    srt_alloc = ctx.freshen(sym, :_srt_alloc)
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
        $tbl_alloc = length($sym.tbl)
        $srt_alloc = length($sym.srt)
        $srt_stop = $sym.srt_stop[]
        $pos_alloc = length($sym.pos)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualHollowByteLevel(sym, Ti, Tp, Tq, Virtual{Int}(I), tbl_alloc, srt_alloc, srt_stop, pos_alloc, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualHollowByteLevel)
    quote
        $HollowByteLevel{$(lvl.Ti), $(lvl.Tp), $(lvl.Tq)}(
            $(ctx(lvl.I)),
            $(lvl.ex).P,
            $(lvl.ex).tbl,
            $(lvl.ex).srt,
            $(lvl.ex).srt_stop,
            $(lvl.ex).pos,
            $(ctx(lvl.lvl)),
        )
    end
end

function getdims(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode)
    ext = Extent(1, fbr.lvl.I)
    if mode != Read()
        ext = suggest(ext)
    end
    (ext, getdims(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)...)
end

function setdims!(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode, dim, dims...)
    fbr.lvl.I = getstop(dim)
    fbr.lvl.lvl = setdims!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode, dims...).lvl
    fbr
end

@inline default(fbr::VirtualFiber{VirtualHollowByteLevel}) = default(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    r = ctx.freshen(lvl.ex, :_r)
    p = ctx.freshen(lvl.ex, :_p)
    q = ctx.freshen(lvl.ex, :_q)
    i = ctx.freshen(lvl.ex, :_i)
    p_prev = ctx.freshen(lvl.ex, :_p_prev)
    push!(ctx.preamble, quote
        # fill!($(lvl.ex).tbl, 0)
        # empty!($(lvl.ex).srt)
        $(lvl.ex).pos[1] = 1
        $p_prev = 0
        for $r = 1:$(lvl.srt_stop)
            $p = first($(lvl.ex).srt[$r])
            if $p != $p_prev
                $(lvl.ex).pos[$p] = 0
                $(lvl.ex).pos[$p + 1] = 0
            end
            $p_prev = $p
        end
        for $r = 1:$(lvl.srt_stop)
            $(lvl.ex).tbl[$r] = false
            $(if reinitializeable(lvl.lvl)
                push!(ctx.preamble, quote
                    $p = first($(lvl.ex).srt[$r])
                    $i = last($(lvl.ex).srt[$r])
                    $q = ($p - 1) * $(ctx(lvl.I)) + $i
                end)
                reinitialize(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env, position = Virtual{Ti}(q), index = Virtual{Ti}(i))))
            else
                quote end
            end)
        end
        $(lvl.ex).srt_stop[] = $(lvl.srt_stop) = 0
    end)
    lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env, reinitialized = reinitializeable(lvl.lvl))), ctx, mode)
    return lvl
end

interval_assembly_depth(lvl::VirtualHollowByteLevel) = min(Inf, interval_assembly_depth(lvl.lvl) - 1)

#TODO does this actually support reassembly? I think it needs to filter out indices with unset table entries during finalization
function assemble!(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p), getstop(envposition(fbr.env))))
    if extent(envposition(fbr.env)) == 1
        p_start = p_stop
    else
        p_start = ctx(cache!(ctx, freshen(lvl.ex, :_p), getstart(envposition(fbr.env))))
    end
    q_start = ctx.freshen(lvl.ex, :q_start)
    q_stop = ctx.freshen(lvl.ex, :q_stop)
    q = ctx.freshen(lvl.ex, :q)

    push!(ctx.preamble, quote
        $q_start = ($p_start - 1) * $(ctx(lvl.I)) + 1
        $q_stop = $p_stop * $(ctx(lvl.I))
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = Finch.refill!($(lvl.ex).pos, $(zero(lvl.Ti)), $(lvl.pos_alloc), $p_stop + 1))
        $(lvl.tbl_alloc) < $q_stop && ($(lvl.tbl_alloc) = Finch.refill!($(lvl.ex).tbl, false, $(lvl.tbl_alloc), $q_stop))
    end)

    if interval_assembly_depth(lvl.lvl) >= 1
        assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Extent(q_start, q_stop), index = Extent(1, lvl.I), parent=fbr.env)), ctx, mode)
    else
        i = ctx.freshen(lvl.ex, :_i)
        push!(ctx.preamble, quote
            for $q = $q_start:$q_stop
                for $i = 1:$(ctx(lvl.I))
                    $q = ($q - 1) * $(ctx(lvl.I)) + $i
                    assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual(q), index=Virtual(i), parent=fbr.env)), ctx, mode)
                end
            end
        end)
    end
end

function finalize_level!(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    r = ctx.freshen(lvl.ex, :_r)
    p = ctx.freshen(lvl.ex, :_p)
    p_prev = ctx.freshen(lvl.ex, :_p_prev)
    push!(ctx.preamble, quote
        sort!(@view $(lvl.ex).srt[1:$(lvl.srt_stop)])
        $p_prev = 0
        for $r = 1:$(lvl.srt_stop)
            $p = first($(lvl.ex).srt[$r])
            if $p != $p_prev
                $(lvl.ex).pos[$p_prev + 1] = $r
                $(lvl.ex).pos[$p] = $r
            end
            $p_prev = $p
        end
        $(lvl.ex).pos[$p_prev + 1] = $(lvl.srt_stop) + 1
        $(lvl.ex).srt_stop[] = $(lvl.srt_stop)
    end)
    lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)
    return lvl
end

unfurl(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Read, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, walk))

function unfurl(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Read, idx::Protocol{Name, Walk}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_r = ctx.freshen(tag, :_r)
    my_r_stop = ctx.freshen(tag, :_r_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)

    Thunk(
        preamble = quote
            $my_r = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_r_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_r != 0 && $my_r < $my_r_stop
                $my_i = last($(lvl.ex).srt[$my_r])
                $my_i_stop = last($(lvl.ex).srt[$my_r_stop - 1])
            else
                $my_i = 1
                $my_i_stop = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (start) -> my_i_stop,
                body = (start, step) -> Stepper(
                    seek = (ctx, ext) -> quote
                        #$my_r = searchsortedfirst($(lvl.ex).idx, $start, $my_r, $my_r_stop, Base.Forward)
                        while $my_r < $my_r_stop && last($(lvl.ex).srt[$my_r]) < $(ctx(getstart(ext)))
                            $my_r += 1
                        end
                    end,
                    body = Thunk(
                        preamble = :(
                            $my_i = last($(lvl.ex).srt[$my_r])
                        ),
                        body = Step(
                            stride = (ctx, idx, ext) -> my_i,
                            chunk = Spike(
                                body = Simplify(default(fbr)),
                                tail = Thunk(
                                    preamble = quote
                                        $my_q = ($(ctx(envposition(fbr.env))) - 1) * $(ctx(lvl.I)) + $my_i
                                    end,
                                    body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                                ),
                            ),
                            next = (ctx, idx, ext) -> quote
                                $my_r += 1
                            end
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

function unfurl(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Read, idx::Protocol{Name, Gallop}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_r = ctx.freshen(tag, :_r)
    my_r_stop = ctx.freshen(tag, :_r_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)

    Thunk(
        preamble = quote
            $my_r = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_r_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_r != 0 && $my_r < $my_r_stop
                $my_i = last($(lvl.ex).srt[$my_r])
                $my_i_stop = last($(lvl.ex).srt[$my_r_stop - 1])
            else
                $my_i = 1
                $my_i_stop = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (start) -> my_i_stop,
                body = (start, step) -> Jumper(
                    body = Thunk(
                        body = Jump(
                            seek = (ctx, ext) -> quote
                                #$my_r = searchsortedfirst($(lvl.ex).idx, $start, $my_r, $my_r_stop, Base.Forward)
                                while $my_r < $my_r_stop && last($(lvl.ex).srt[$my_r]) < $(ctx(getstart(ext_2)))
                                    $my_r += 1
                                end
                                $my_i = last($(lvl.ex).srt[$my_r])
                            end,
                            stride = (ctx, ext) -> my_i,
                            body = (ctx, ext, ext_2) -> Cases([
                                :($(ctx(getstop(ext_2))) == $my_i) => Thunk(
                                    body = Spike(
                                        body = Simplify(default(fbr)),
                                        tail = Thunk(
                                            preamble = quote
                                                $my_q = ($(ctx(envposition(fbr.env))) - 1) * $(ctx(lvl.I)) + $my_i
                                            end,
                                            body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                                        ),
                                    ),
                                    epilogue = quote
                                        $my_r += 1
                                    end
                                ),
                                true => Stepper(
                                    seek = (ctx, ext) -> quote
                                        #$my_r = searchsortedfirst($(lvl.ex).idx, $start, $my_r, $my_r_stop, Base.Forward)
                                        while $my_r < $my_r_stop && last($(lvl.ex).srt[$my_r]) < $(ctx(getstart(ext)))
                                            $my_r += 1
                                        end
                                    end,
                                    body = Thunk(
                                        preamble = :(
                                            $my_i = last($(lvl.ex).srt[$my_r])
                                        ),
                                        body = Step(
                                            stride = (ctx, idx, ext) -> my_i,
                                            chunk = Spike(
                                                body = Simplify(default(fbr)),
                                                tail = Thunk(
                                                    preamble = quote
                                                        $my_q = ($(ctx(envposition(fbr.env))) - 1) * $(ctx(lvl.I)) + $my_i
                                                    end,
                                                    body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                                                ),
                                            ),
                                            next = (ctx, idx, ext) -> quote
                                                $my_r += 1
                                            end
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

function unfurl(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Read, idx::Protocol{Name, Follow}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    R = length(envdeferred(fbr.env)) + 1
    my_key = cgx.freshen(tag, :_key)
    my_q = cgx.freshen(tag, :_q)
    q = envposition(fbr.env)

    Leaf(
        body = (i) -> Thunk(
            preamble = quote
                $my_q = $(ctx(q)) * $(ctx(lvl.I)) + $i
            end,
            body = Cases([
                :($tbl[$my_q]) => refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Tq}(my_q), index=i, parent=fbr.env)), ctx, mode, idxs...),
                true => Simplify(default(fbr))
            ])
        )
    )
end

unfurl(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Union{Write, Update}, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, laminate), idxs...)

hasdefaultcheck(lvl::VirtualHollowByteLevel) = true

function unfurl(fbr::VirtualFiber{VirtualHollowByteLevel}, ctx, mode::Union{Write, Update}, idx::Union{Name, Protocol{Name, <:Union{Extrude, Laminate}}}, idxs...)
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
                    $my_q = ($(ctx(envposition(fbr.env))) - 1) * $(ctx(lvl.I)) + $idx
                end,
                body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode, idxs...),
                epilogue = begin
                    body = quote
                        if !$(lvl.ex).tbl[$my_q]
                            $(lvl.ex).tbl[$my_q] = true
                            $(lvl.srt_stop) += 1
                            $(lvl.srt_alloc) < $(lvl.srt_stop) && ($(lvl.srt_alloc) = $Finch.regrow!($(lvl.ex).srt, $(lvl.srt_alloc), $(lvl.srt_stop)))
                            $(lvl.ex).srt[$(lvl.srt_stop)] = ($(ctx(envposition(fbr.env))), $idx)
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