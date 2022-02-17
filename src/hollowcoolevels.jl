struct HollowCooLevel{N, Ti<:Tuple, Tp_2, Tbl, Lvl}
    I::Ti
    tbl::Tbl
    pos::Vector{Tp_2}
    lvl::Lvl
end
const HollowCoo = HollowCooLevel
HollowCooLevel{N}(lvl) where {N} = HollowCooLevel{N}((0 for _ in 1:N...), lvl)
HollowCooLevel{N, Ti}(lvl) where {N, Ti} = HollowCooLevel{N, Ti}((map(zero, Ti.parameters)..., ), lvl)
HollowCooLevel{N}(I::Ti, lvl) where {N, Ti} = HollowCooLevel{N, Ti}(I, lvl)
HollowCooLevel{N, Ti}(I::Ti, lvl) where {N, Ti} = HollowCooLevel{N, Ti, Int}(I, lvl)
HollowCooLevel{N, Ti, Tp_2}(I::Ti, lvl) where {N, Ti, Tp_2} = HollowCooLevel{N, Ti}(I, (Vector{T}(undef, 4) for Ti in Ti.parameters), Vector{Tp_2}(undef, 4), lvl)
HollowCooLevel{N, Ti, Tp_2, Tbl}(I::Ti, tbl::Tbl, pos, lvl::Lvl) where {N, Ti, Tp_2, Tbl, Lvl} =
    HollowCooLevel{N, Ti, Tp_2, Tbl, Lvl}(I, tbl, pos, lvl)

@inline arity(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = N + arity(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))
@inline shape(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = (fbr.lvl.I..., shape(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))...)
@inline domain(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = (map(Base.OneTo, fbr.lvl.I)..., domain(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))...)
@inline image(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = image(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))
@inline default(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = default(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))

function (fbr::Fiber{<:HollowCooLevel{N, Ti}})(i, tail...) where {N, Ti}
    lvl = fbr.lvl
    R = length(envdeferred(fbr.env))
    if R == 0
        start = lvl.pos[q]
        stop = lvl.pos[q + 1]
    else
        start = envstart(lvl.pos[q])
        stop = envstop(lvl.pos[q + 1])
    end
    r = searchsorted(@view(lvl.tbl[[start:stop - 1]), i)
    p = lvl.pos[q] + first(r) - 1
    p_2 = lvl.pos[q] + last(r)
    if R == N - 1
        @assert p_2 - p == 1
        fbr_2 = Fiber(lvl.lvl, PositionEnvironment(p, i, fbr.env))
        length(r) == 0 ? default(fbr_2) : fbr_2(tail...)
    else
        fbr_2 = Fiber(lvl.lvl, PosRangeEnvironment(p, p_2, i, fbr.env))
        length(r) == 0 ? default(fbr_2) : fbr_2(tail...)
    end
end



mutable struct VirtualHollowCooLevel
    ex
    N
    Ti
    Tp_2
    Tbl
    I
    pos_q
    pos_q_alloc
    idx_q
    lvl
end
function virtualize(ex, ::Type{HollowCooLevel{N, Ti, Tp_2, Tbl, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tp_2, Tbl, Lvl}   
    sym = ctx.freshen(tag)
    I = ctx.freshen(sym, :_I)
    pos_q = ctx.freshen(sym, :_pos_q)
    pos_q_alloc = ctx.freshen(sym, :_pos_q_alloc)
    idx_q = ctx.freshen(sym, :_idx_q)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
        $pos_q = length($sym.pos)
        $pos_q_alloc = $pos_q
        $idx_q = length($sym.tbl)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualHollowCooLevel(sym, N, Ti, Tp_2, Tbl, I, pos_q, pos_q_alloc, idx_q, lvl_2)
end
(ctx::Finch.LowerJulia)(lvl::VirtualHollowCooLevel) = lvl.ex

function reconstruct!(lvl::VirtualHollowCooLevel, ctx)
    push!(ctx.preamble, quote
        $(lvl.ex) = $HollowCooLevel{$(lvl.N), $(lvl.Ti), $(lvl.Tp_2), $(lvl.Tbl)}(
            $(ctx(lvl.I)),
            $(lvl.ex).tbl,
            $(lvl.ex).pos,
            $(ctx(lvl.lvl)),
        )
    end)
end

function getsites(fbr::VirtualFiber{VirtualHollowCooLevel})
    return (map(n-> envdepth(fbr.env) + n, 1:fbr.lvl.N)..., getsites(VirtualFiber(fbr.lvl.lvl, ∘(repeated(VirtualArbitraryEnvironment, fbr.lvl.N)...)(fbr.env)))...)
end

function getdims(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode)
    ext = map(n->Extent(1, Virtual{Int}(:($(fbr.lvl.I)[$n]))), 1:fbr.lvl.N)
    dim = mode isa Read ? ext : map(SuggestedExtent, ext)
    (dim..., getdims(VirtualFiber(fbr.lvl.lvl, VirtualArbitraryEnvironment(fbr.env)), ctx, mode)...)
end

@inline default(fbr::VirtualFiber{VirtualHollowCooLevel}) = default(VirtualFiber(fbr.lvl.lvl, ∘(repeated(VirtualArbitraryEnvironment, fbr.lvl.N)...)(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode)
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    my_p = ctx.freshen(lvl.ex, :_p)
    push!(ctx.preamble, quote
        $(lvl.I) = $(lvl.Ti)(($(map(n->ctx(ctx.dims[(getname(fbr), envdepth(fbr.env) + n)].stop), 1:lvl.N)...),))
        $(lvl.idx_q) = 0
        $(lvl.pos_q_alloc) = 4
        resize!($(lvl.ex).pos, 5)
        $(lvl.ex).pos[1] = 1
        $(lvl.pos_q) = 0
    end)
    for n = 1:lvl.N
        push!(ctx.preamble, quote
            empty!($(lvl.ex).tbl[$n])
        end)
    end

    if (lvl_2 = initialize_level!(VirtualFiber(fbr.lvl.lvl, ∘(repeated(VirtualArbitraryEnvironment, lvl.N)...)(fbr.env)), ctx, mode)) !== nothing
        lvl = shallowcopy(lvl)
        lvl.lvl = lvl_2
    end
    reconstruct!(lvl, ctx)
    return lvl
end

function assemble!(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode)
    q = envmaxposition(fbr.env)
    lvl = fbr.lvl
    push!(ctx.preamble, quote
        $(lvl.pos_q) = $(ctx(q))
        if $(lvl.pos_q_alloc) < $(lvl.pos_q)
            $(lvl.pos_q_alloc) *= 4
            resize!($(lvl.ex).pos, $(lvl.pos_q_alloc) + 1)
        end
        $(lvl.ex).pos[$(lvl.pos_q) + 1] = 0
    end)
end

struct CooLT{Tbl}
    tbl::Tbl
end

@generated function(lt::CooLT{Tbl})(i, j) where {Tbl}
    R = length(Tbl.parameters)
    thunk = :(lt.tbl[$R][i] < lt.tbl[$R][j])
    while R > 1
        R -= 1
        thunk = :(lt.tbl[$R][i] < lt.tbl[$R][j] || ((lt.tbl[$R][i] == lt.tbl[$R][j]) && $thunk))
    end
    thunk
end

function finalize_level!(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode)
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    my_p = ctx.freshen(lvl.ex, :_p)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).srt, length($(lvl.ex).tbl))
        copyto!($(lvl.ex).srt, pairs($(lvl.ex).tbl))
        σ = collect($(lvl.Tp_2(1)):$pos_q)
        sortperm!(σ, lt=CooLT($lvl.tbl))
        for $my_p = 1:$(lvl.pos_q)
            $(lvl.ex).pos[$my_p + 1] += $(lvl.ex).pos[$my_p]
        end
    end)
    for n = 1:lvl.N
        push!(ctx.preamble, quote
            permute!($(lvl.ex).tbl[$n], prm)
        end)
    end


    if (lvl_2 = finalize_level!(VirtualFiber(fbr.lvl.lvl, ∘(repeated(VirtualArbitraryEnvironment, lvl.N)...)(fbr.env)), ctx, mode)) !== nothing
        lvl = shallowcopy(lvl)
        lvl.lvl = lvl_2
        reconstruct!(lvl, ctx)
        return lvl
    else
        return nothing
    end
end

unfurl(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode::Read, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, walk(idx))

function unfurl(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode::Read, idx::Walk, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_p = ctx.freshen(tag, :_p)
    my_p_step = ctx.freshen(tag, :_p_step)
    my_p_stop = ctx.freshen(tag, :_p_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)
    R = length(envdeferred(fbr.env)) + 1
    @assert R == 1 || (envstart(fbr.env) !== nothing && envstop(fbr.env) !== nothing)
    if R == 1
        p_start = Virtual{lvl.Tp}(:($(lvl.ex).pos[$(ctx(envposition(fbr.env)))]))
        p_stop = Virtual{lvl.Tp}(:($(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]))
    else
        p_start = envstart(fbr.env)
        p_stop = envstop(fbr.env)
    end

    Thunk(
        preamble = quote
            $my_p = $(ctx(p_start))
            $my_p_stop = $(ctx(p_stop))
            if $my_p < $my_p_stop
                $my_i = $(lvl.ex).tbl[$R][$my_p]
                $my_i_stop = $(lvl.ex).tbl[$R][$my_p_stop - 1]
            else
                $my_i = 1
                $my_i_stop = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (start) -> my_i_stop,
                body = (start, step) -> Stepper(
                    preamble = :(
                        $my_i = $(lvl.ex).tbl[$R][$my_p]
                    ),
                    guard = (start) -> :($my_p < $my_p_stop),
                    stride = (start) -> my_i,
                    body = (start, step) -> Thunk(
                        body = Cases([
                            :($step < $my_i) =>
                                Run(
                                    body = default(fbr),
                                ),
                            true => begin
                                if R == lvl.N
                                    Thunk(
                                        body = Spike(
                                            body = default(fbr),
                                            tail = access(VirtualFiber(lvl.lvl, PositionEnvironment(Virtual{lvl.Ti}(:($(lvl.ex).tbl[$R][$my_p])), Virtual{lvl.Ti}(my_i), fbr.env)), mode, idxs...),
                                        ),
                                        epilogue = quote
                                            $my_p += 1
                                        end
                                    )
                                else
                                    Thunk(
                                        preamble = quote
                                            $my_p_step = $my_p + 1
                                            while $my_p_step < $my_p_stop && $(lvl.ex).tbl[$R][$my_p_step] == $my_i
                                                $my_p_step += 1
                                            end
                                        end,
                                        body = Spike(
                                            body = default(fbr),
                                            tail = access(VirtualFiber(lvl, PosRangeEnvironment(Virtual{lvl.Ti}(my_i), Virtual{lvl.Ti}(my_p), Virtual{lvl.Ti}(my_p_step), fbr.env)), mode, idxs...),
                                        ),
                                        epilogue = quote
                                            $my_p = $my_p_step
                                        end
                                    )
                                end
                            end,
                        ])
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(default(fbr))
            )
        ])
    )
end

function unfurl(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode::Read, idx::Union{Follow}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    R = length(envdeferred(fbr.env)) + 1
    my_key = cgx.freshen(tag, :_key)
    my_p = cgx.freshen(tag, :_p)

    if R == lvl.N
        Leaf(
            body = (i) -> Thunk(
                preamble = quote
                    $my_key = ($(ctx(envposition(fbr.env))), ($(map(ctx, envdeferred(fbr.env))...), $(ctx(i))))
                    $my_p = get($(lvl.ex).tbl, $my_key, 0)
                end,
                body = Cases([
                    :($my_p != 0) => access(VirtualFiber(lvl.lvl, PositionEnvironment(Virtual{lvl.Tp_2}(my_p), i, fbr.env)), mode, idxs...),
                    true => default(fbr)
                ])
            )
        )
    else
        Leaf(
            body = (i) -> access(VirtualFiber(lvl, DeferredEnvironment(i, fbr.env)), mode, idxs...)
        )
    end
end

unfurl(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode::Union{Write, Update}, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, laminate(idx), idxs...)

function unfurl(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode::Union{Write, Update}, idx::Union{Name, Extrude, Laminate}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    R = length(envdeferred(fbr.env)) + 1
    my_key = ctx.freshen(tag, :_key)
    my_p = ctx.freshen(tag, :_p)

    if R == lvl.N
        Thunk(
            preamble = quote
                $my_p = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            end,
            body = AcceptSpike(
                val = default(fbr),
                tail = (ctx, idx) -> Thunk(
                    preamble = quote
                        $my_key = ($(ctx(envposition(fbr.env))), ($(map(ctx, envdeferred(fbr.env))...), $(ctx(idx))))
                        $my_p = get!($(lvl.ex).tbl, $my_key, $(lvl.idx_q) + 1)
                        if $my_p > $(lvl.idx_q)
                            $(lvl.idx_q) = $my_p
                            $(scope(ctx) do ctx_2 
                                assemble!(VirtualFiber(fbr.lvl.lvl, VirtualMaxPositionEnvironment(my_p, ∘(repeated(VirtualArbitraryEnvironment, lvl.N - 1)..., identity)(fbr.env))), ctx_2, mode)
                                quote end
                            end)
                            $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1] += 1
                        end
                    end,
                    body = access(VirtualFiber(lvl.lvl, PositionEnvironment(Virtual{lvl.Ti}(my_p), idx, fbr.env)), mode, idxs...)
                )
            )
        )
    else
        Leaf(
            body = (i) -> access(VirtualFiber(lvl, DeferredEnvironment(i, fbr.env)), mode, idxs...)
        )
    end
end