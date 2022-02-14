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
HollowListLevel{Ti, Lvl}(I::Ti, lvl::Lvl) where {Ti, Lvl} = HollowListLevel{Ti, Lvl}(I, Vector{Ti}(undef, 4), Vector{Ti}(undef, 4), lvl)

@inline arity(fbr::Fiber{<:HollowListLevel}) = 1 + arity(Fiber(fbr.lvl.lvl, ArbitraryEnvironment(fbr.env)))
@inline shape(fbr::Fiber{<:HollowListLevel}) = (fbr.lvl.I, shape(Fiber(fbr.lvl.lvl, ArbitraryEnvironment(fbr.env)))...)
@inline domain(fbr::Fiber{<:HollowListLevel}) = (1:fbr.lvl.I, domain(Fiber(fbr.lvl.lvl, ArbitraryEnvironment(fbr.env)))...)
@inline image(fbr::Fiber{<:HollowListLevel}) = image(Fiber(fbr.lvl.lvl, ArbitraryEnvironment(fbr.env)))
@inline default(fbr::Fiber{<:HollowListLevel}) = default(Fiber(fbr.lvl.lvl, ArbitraryEnvironment(fbr.env)))

function (fbr::Fiber{<:HollowListLevel{Ti}})(i, tail...) where {D, Tv, Ti, N, R}
    lvl = fbr.lvl
    q = envposition(fbr.env)
    r = searchsorted(@view(lvl.idx[lvl.pos[q]:lvl.pos[q + 1] - 1]), i)
    p = lvl.pos[q] + first(r) - 1
    fbr_2 = Fiber(lvl.lvl, PositionEnvironment(p, i, fbr.env))
    length(r) == 0 ? default(fbr_2) : fbr_2(tail...)
end



mutable struct VirtualHollowListLevel
    ex
    Ti
    I
    pos_q
    idx_q
    lvl
end
function virtualize(ex, ::Type{HollowListLevel{Ti, Lvl}}, ctx, tag=:lvl) where {Ti, Lvl}
    sym = ctx.freshen(tag)
    I = ctx.freshen(sym, :_I)
    pos_q = ctx.freshen(sym, :_pos_q)
    idx_q = ctx.freshen(sym, :_idx_q)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
        $pos_q = length($sym.pos)
        $idx_q = length($sym.idx)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualHollowListLevel(sym, Ti, I, pos_q, idx_q, lvl_2)
end
(ctx::Finch.LowerJulia)(lvl::VirtualHollowListLevel) = lvl.ex

function reconstruct!(lvl::VirtualHollowListLevel, ctx)
    push!(ctx.preamble, quote
        $(lvl.ex) = $HollowListLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(lvl.ex).pos,
            $(lvl.ex).idx,
            $(ctx(lvl.lvl)),
        )
    end)
end

function getsites(fbr::VirtualFiber{VirtualHollowListLevel})
    return (envdepth(fbr.env) + 1, getsites(VirtualFiber(fbr.lvl.lvl, VirtualArbitraryEnvironment(fbr.env)))...)
end

function getdims(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode)
    ext = Extent(1, Virtual{Int}(fbr.lvl.I))
    dim = mode isa Read ? ext : SuggestedExtent(ext)
    (dim, getdims(VirtualFiber(fbr.lvl.lvl, VirtualArbitraryEnvironment(fbr.env)), ctx, mode)...)
end

@inline default(fbr::VirtualFiber{<:VirtualHollowListLevel}) = default(VirtualFiber(fbr.lvl.lvl, VirtualArbitraryEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode)
    lvl = fbr.lvl
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
        $(lvl.I) = $(ctx(ctx.dims[(getname(fbr), envdepth(fbr.env) + 1)].stop))
    end)
    if (lvl_2 = initialize_level!(VirtualFiber(fbr.lvl.lvl, ArbitraryEnvironment(fbr.env)), ctx, mode)) !== nothing
        lvl = shallowcopy(lvl)
        lvl.lvl = lvl_2
    end
    reconstruct!(lvl, ctx)
    return lvl
end

function assemble!(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode)
    q = envmaxposition(fbr.env)
    lvl = fbr.lvl
    push!(ctx.preamble, quote
        if $(lvl.pos_q) < $(ctx(q)) + 1
            resize!($(lvl.ex).pos, $(lvl.pos_q) * 4)
            $(lvl.pos_q) *= 4
        end
    end)
    assemble!(VirtualFiber(fbr.lvl.lvl, VirtualMaxPositionEnvironment(q, fbr.env)), ctx, mode)
end

function finalize_level!(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode)
    lvl = fbr.lvl
    if (lvl_2 = initialize_level!(VirtualFiber(fbr.lvl.lvl, ArbitraryEnvironment(fbr.env)), ctx, mode)) !== nothing
        lvl = shallowcopy(lvl)
        lvl.lvl = lvl_2
        reconstruct!(lvl, ctx)
    end
    return lvl
end

unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Read, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, walk(idx))

function unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Read, idx::Walk, idxs...)
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
                                    body = default(fbr),
                                ),
                            true =>
                                Thunk(
                                    body = Spike(
                                        body = default(fbr),
                                        tail = access(VirtualFiber(lvl.lvl, PositionEnvironment(Virtual{lvl.Ti}(my_p), Virtual{lvl.Ti}(my_i), fbr.env)), mode, idxs...),
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

unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Union{Write, Update}, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, extrude(idx), idxs...)

function unfurl(fbr::VirtualFiber{VirtualHollowListLevel}, ctx, mode::Union{Write, Update}, idx::Extrude, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_p = ctx.freshen(tag, :_p)
    my_p1 = ctx.freshen(tag, :_p1)
    my_i1 = ctx.freshen(tag, :_i1)
    lvl_2 = nothing

    Thunk(
        preamble = quote
            $my_p = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
        end,
        body = AcceptSpike(
            val = default(fbr),
            tail = (ctx, idx) -> Thunk(
                preamble = quote
                    $(scope(ctx) do ctx2 
                        if (lvl_2 = assemble!(VirtualFiber(lvl.lvl, VirtualMaxPositionEnvironment(my_p, fbr.env)), ctx2, mode)) === nothing
                            lvl_2 = lvl.lvl
                        end
                        quote end
                    end)
                end,
                body = access(VirtualFiber(lvl_2, PositionEnvironment(Virtual{lvl.Ti}(my_p), idx, fbr.env)), mode, idxs...),
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
            $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1] = $my_p
        end
    )
end