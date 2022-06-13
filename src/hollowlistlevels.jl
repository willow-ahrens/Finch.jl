struct HollowListLevel{Ti, Lvl}
    I::Ti
    pos::Vector{Ti}
    idx::Vector{Ti}
    lvl::Lvl
end
const HollowList = HollowListLevel
HollowListLevel(lvl) = HollowListLevel(0, lvl)
HollowListLevel{Ti}(lvl) where {Ti} = HollowListLevel(zero{Ti}, lvl)
HollowListLevel(I::Ti, lvl::Lvl) where {Ti, Lvl} = HollowListLevel{Ti, Lvl}(I, lvl)
HollowListLevel{Ti}(I::Ti, lvl::Lvl) where {Ti, Lvl} = HollowListLevel{Ti, Lvl}(I, lvl)
HollowListLevel{Ti}(I::Ti, pos, idx, lvl::Lvl) where {Ti, Lvl} = HollowListLevel{Ti, Lvl}(I, pos, idx, lvl)
HollowListLevel{Ti, Lvl}(I::Ti, lvl::Lvl) where {Ti, Lvl} = HollowListLevel{Ti, Lvl}(I, Ti[1, fill(0, 16)...], Vector{Ti}(undef, 16), lvl)

@inline arity(fbr::Fiber{<:HollowListLevel}) = 1 + arity(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline shape(fbr::Fiber{<:HollowListLevel}) = (fbr.lvl.I, shape(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline domain(fbr::Fiber{<:HollowListLevel}) = (1:fbr.lvl.I, domain(Fiber(fbr.lvl.lvl, Environment(fbr.env)))...)
@inline image(fbr::Fiber{<:HollowListLevel}) = image(Fiber(fbr.lvl.lvl, Environment(fbr.env)))
@inline default(fbr::Fiber{<:HollowListLevel}) = default(Fiber(fbr.lvl.lvl, Environment(fbr.env)))

function (fbr::Fiber{<:HollowListLevel{Ti}})(i, tail...) where {D, Tv, Ti, N, R}
    lvl = fbr.lvl
    p = envposition(fbr.env)
    r = searchsorted(@view(lvl.idx[lvl.pos[p]:lvl.pos[p + 1] - 1]), i)
    q = lvl.pos[p] + first(r) - 1
    fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
    length(r) == 0 ? default(fbr_2) : fbr_2(tail...)
end

mutable struct VirtualHollowListLevel
    ex
    Ti
    I
    pos_alloc
    idx_alloc
    lvl
end
function virtualize(ex, ::Type{HollowListLevel{Ti, Lvl}}, ctx, tag=:lvl) where {Ti, Lvl}
    sym = ctx.freshen(tag)
    I = ctx.freshen(sym, :_I)
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    idx_alloc = ctx.freshen(sym, :_idx_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
        $pos_alloc = length($sym.pos)
        $idx_alloc = length($sym.idx)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualHollowListLevel(sym, Ti, I, pos_alloc, idx_alloc, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualHollowListLevel)
    quote
        $HollowListLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(lvl.ex).pos,
            $(lvl.ex).idx,
            $(ctx(lvl.lvl)),
        )
    end
end

function getdims(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode)
    ext = Extent(1, Virtual{Int}(fbr.lvl.I))
    (ext, getdims(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)...)
end

function setdims!(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode, dim, dims...)
    push!(ctx.preamble, :($(fbr.lvl.I) = $(ctx(getstop(dim)))))
    fbr.lvl.lvl = setdims!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode, dims...).lvl
    fbr
end

@inline default(fbr::VirtualFiber{<:VirtualHollowListLevel}) = default(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualHollowListLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    lvl = fbr.lvl
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = length($(lvl.ex).pos)
        $(lvl.ex).pos[1] = 1
        $(lvl.idx_alloc) = length($(lvl.ex).idx)
    end)
    lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, Environment(fbr.env)), ctx, mode)
    return lvl
end

interval_assembly_depth(lvl::VirtualHollowListLevel) = Inf

#This function is quite simple, since HollowListLevels don't support reassembly.
function assemble!(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = $Finch.regrow!($(lvl.ex).pos, $(lvl.pos_alloc), $p_stop + 1))
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualHollowListLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    fbr.lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)
    return fbr.lvl
end

unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Read, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, walk))

function unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Read, idx::Protocol{Name, Walk}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)

    Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_q < $my_q_stop
                $my_i = $(lvl.ex).idx[$my_q]
                $my_i1 = $(lvl.ex).idx[$my_q_stop - 1]
            else
                $my_i = 1
                $my_i1 = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (start) -> my_i1,
                body = (start, step) -> Stepper(
                    seek = (ctx, ext) -> quote
                        #$my_q = searchsortedfirst($(lvl.ex).idx, $start, $my_q, $my_q_stop, Base.Forward)
                        while $my_q < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                            $my_q += 1
                        end
                    end,
                    body = Thunk(
                        preamble = :(
                            $my_i = $(lvl.ex).idx[$my_q]
                        ),
                        body = Step(
                            stride = (ctx, idx, ext) -> my_i,
                            chunk = Spike(
                                body = Simplify(default(fbr)),
                                tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                            ),
                            next = (ctx, idx, ext) -> quote
                                $my_q += 1
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

function unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Read, idx::Protocol{Name, Gallop}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)

    Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_q < $my_q_stop
                $my_i = $(lvl.ex).idx[$my_q]
                $my_i1 = $(lvl.ex).idx[$my_q_stop - 1]
            else
                $my_i = 1
                $my_i1 = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (start) -> my_i1,
                body = (start, step) -> Jumper(
                    body = Thunk(
                        body = Jump(
                            seek = (ctx, ext) -> quote
                                #$my_q = searchsortedfirst($(lvl.ex).idx, $start, $my_q, $my_q_stop, Base.Forward)
                                while $my_q < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                                    $my_q += 1
                                end
                                $my_i = $(lvl.ex).idx[$my_q]
                            end,
                            stride = (ctx, ext) -> my_i,
                            body = (ctx, ext, ext_2) -> Cases([
                                :($(ctx(getstop(ext_2))) == $my_i) => Thunk(
                                    body = Spike(
                                        body = Simplify(default(fbr)),
                                        tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                                    ),
                                    epilogue = quote
                                        $my_q += 1
                                    end
                                ),
                                true => Stepper(
                                    seek = (ctx, ext) -> quote
                                        #$my_q = searchsortedfirst($(lvl.ex).idx, $start, $my_q, $my_q_stop, Base.Forward)
                                        while $my_q < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                                            $my_q += 1
                                        end
                                    end,
                                    body = Thunk(
                                        preamble = :(
                                            $my_i = $(lvl.ex).idx[$my_q]
                                        ),
                                        body = Step(
                                            stride = (ctx, idx, ext) -> my_i,
                                            chunk = Spike(
                                                body = Simplify(default(fbr)),
                                                tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=Virtual{lvl.Ti}(my_i), parent=fbr.env)), ctx, mode, idxs...),
                                            ),
                                            next = (ctx, idx, ext) -> quote
                                                $my_q += 1
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

unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Union{Write, Update}, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, extrude), idxs...)

function unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Union{Write, Update}, idx::Protocol{Name, Extrude}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)
    my_guard = if hasdefaultcheck(lvl.lvl)
        ctx.freshen(tag, :_isdefault)
    end

    Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
        end,
        body = AcceptSpike(
            val = default(fbr),
            tail = (ctx, idx) -> Thunk(
                preamble = quote
                    $(begin
                        assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=my_q, parent=fbr.env)), ctx, mode)
                        quote end
                    end)
                    $(
                        if hasdefaultcheck(lvl.lvl)
                            :($my_guard = true)
                        else
                            quote end
                        end
                    )
                end,
                body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode, idxs...),
                epilogue = begin
                    #We should be careful here. Presumably, we haven't modified the subfiber because it is still default. Is this always true? Should strict assembly happen every time?
                    body = quote
                        $(lvl.idx_alloc) < $my_q && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q))
                        $(lvl.ex).idx[$my_q] = $(ctx(idx))
                        $my_q += 1
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
        ),
        epilogue = quote
            $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1] = $my_q
        end
    )
end