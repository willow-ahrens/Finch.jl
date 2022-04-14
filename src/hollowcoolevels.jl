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
HollowCooLevel{N, Ti, Tp_2}(I::Ti, lvl) where {N, Ti, Tp_2} = HollowCooLevel{N, Ti, Tp_2}(I, ((Vector{T}(undef, 4) for T in Ti.parameters)...,), Vector{Tp_2}(undef, 4), lvl)
HollowCooLevel{N, Ti, Tp_2}(I::Ti, tbl::Tbl, pos, lvl) where {N, Ti, Tp_2, Tbl} =
    HollowCooLevel{N, Ti, Tp_2, Tbl}(I, tbl, pos, lvl)
HollowCooLevel{N, Ti, Tp_2, Tbl}(I::Ti, tbl::Tbl, pos, lvl::Lvl) where {N, Ti, Tp_2, Tbl, Lvl} =
    HollowCooLevel{N, Ti, Tp_2, Tbl, Lvl}(I, tbl, pos, lvl)

@inline arity(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = N + arity(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))
@inline shape(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = (fbr.lvl.I..., shape(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))...)
@inline domain(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = (map(Base.OneTo, fbr.lvl.I)..., domain(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))...)
@inline image(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = image(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))
@inline default(fbr::Fiber{<:HollowCooLevel{N}}) where {N} = default(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))

"""
    HollowCooEnvironment(pos, idx, env)

The environment introduced by a HollowCooLevel.

See also: [`envcoordinate`](@ref), [`getparent`](@ref)
"""
struct HollowCooEnvironment{Pos, Idx, Env}
    pos::Pos
    idx::Idx
    env::Env
end
envdepth(env::HollowCooEnvironment) = 1 + envdepth(env.env)
envposition(env::HollowCooEnvironment) = env.pos
envcoordinate(env::HollowCooEnvironment) = env.idx

struct VirtualHollowCooEnvironment
    pos
    idx
    env
end
function virtualize(ex, ::Type{HollowCooEnvironment{Pos, Idx, Env}}, ctx) where {Pos, Idx, Env}
    pos = virtualize(:($ex.pos), Pos, ctx)
    idx = virtualize(:($ex.idx), Idx, ctx)
    env = virtualize(:($ex.env), Env, ctx)
    VirtualHollowCooEnvironment(pos, idx, env)
end
(ctx::Finch.LowerJulia)(env::VirtualHollowCooEnvironment) = :(HollowCooEnvironment($(ctx(env.pos)), $(ctx(env.idx)), $(ctx(env.env))))
isliteral(::VirtualHollowCooEnvironment) = false

envposition(env::VirtualHollowCooEnvironment) = env.pos
envcoordinate(env::VirtualHollowCooEnvironment) = env.idx
envdepth(env::VirtualHollowCooEnvironment) = 1 + envdepth(env.env)

"""
    HollowCooSearchEnvironment(pos, idx, env)

The environment introduced inside a HollowCooLevel.

See also: [`envcoordinate`](@ref), [`getparent`](@ref)
"""
struct HollowCooSearchEnvironment{Start, Stop, Idx, Env}
    start::Start
    stop::Stop
    idx::Idx
    env::Env
end
envdepth(env::HollowCooSearchEnvironment) = 1 + envdepth(env.env)
envcoordinate(env::HollowCooSearchEnvironment) = env.idx
envdeferred(env::HollowCooSearchEnvironment) = (env.idx, envdeferred(env.env)...)

struct VirtualHollowCooSearchEnvironment
    start
    stop
    idx
    env
end
function virtualize(ex, ::Type{HollowCooSearchEnvironment{Pos, Idx, Env}}, ctx) where {Pos, Idx, Env}
    pos = virtualize(:($ex.pos), Pos, ctx)
    idx = virtualize(:($ex.idx), Idx, ctx)
    env = virtualize(:($ex.env), Env, ctx)
    VirtualHollowCooSearchEnvironment(pos, idx, env)
end
(ctx::Finch.LowerJulia)(env::VirtualHollowCooSearchEnvironment) = :(HollowCooSearchEnvironment($(ctx(env.pos)), $(ctx(env.idx)), $(ctx(env.env))))
isliteral(::VirtualHollowCooSearchEnvironment) = false

envcoordinate(env::VirtualHollowCooEnvironment) = env.idx
envdepth(env::VirtualHollowCooEnvironment) = 1 + envdepth(env.env)
envdeferred(env::VirtualHollowCooSearchEnvironment) = (env.idx, envdeferred(env.env)...)

"""
    HollowCooBufferEnvironment(idx, env)

The environment introduced inside a HollowCooLevel to just buffer up a coordinate to write later.

See also: [`envcoordinate`](@ref), [`getparent`](@ref)
"""
struct HollowCooBufferEnvironment{Idx, Env}
    idx::Idx
    env::Env
end
envdepth(env::HollowCooBufferEnvironment) = 1 + envdepth(env.env)
envcoordinate(env::HollowCooBufferEnvironment) = env.idx
envdeferred(env::HollowCooBufferEnvironment) = (env.idx, envdeferred(env.env)...)

struct VirtualHollowCooBufferEnvironment
    idx
    env
end
function virtualize(ex, ::Type{HollowCooBufferEnvironment{Idx, Env}}, ctx) where {Idx, Env}
    idx = virtualize(:($ex.idx), Idx, ctx)
    env = virtualize(:($ex.env), Env, ctx)
    VirtualHollowCooBufferEnvironment(idx, env)
end
(ctx::Finch.LowerJulia)(env::VirtualHollowCooBufferEnvironment) = :(HollowCooBufferEnvironment($(ctx(env.idx)), $(ctx(env.env))))
isliteral(::VirtualHollowCooBufferEnvironment) = false

envcoordinate(env::VirtualHollowCooEnvironment) = env.idx
envdepth(env::VirtualHollowCooEnvironment) = 1 + envdepth(env.env)
envdeferred(env::VirtualHollowCooBufferEnvironment) = (env.idx, envdeferred(env.env)...)

function (fbr::Fiber{<:HollowCooLevel{N, Ti}})(i, tail...) where {N, Ti}
    lvl = fbr.lvl
    R = length(envdeferred(fbr.env)) + 1
    if R == 1
        q = envposition(fbr.env)
        start = lvl.pos[q]
        stop = lvl.pos[q + 1]
    else
        start = fbr.env.start
        stop = fbr.env.stop
    end
    r = searchsorted(@view(lvl.tbl[R][start:stop - 1]), i)
    p = start + first(r) - 1
    p_2 = start + last(r)
    if R == N
        fbr_2 = Fiber(lvl.lvl, HollowCooEnvironment(p, i, fbr.env))
        length(r) == 0 ? default(fbr_2) : fbr_2(tail...)
    else
        fbr_2 = Fiber(lvl, HollowCooSearchEnvironment(p, p_2, i, fbr.env))
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
    idx_q
    lvl
end
function virtualize(ex, ::Type{HollowCooLevel{N, Ti, Tp_2, Tbl, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tp_2, Tbl, Lvl}   
    sym = ctx.freshen(tag)
    I = ctx.freshen(sym, :_I)
    pos_q = ctx.freshen(sym, :_pos_q)
    idx_q = ctx.freshen(sym, :_idx_q)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
        $pos_q = length($sym.pos)
        $idx_q = length($sym.tbl)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualHollowCooLevel(sym, N, Ti, Tp_2, Tbl, I, pos_q, idx_q, lvl_2)
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

function initialize_level!(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode::Union{Write, Update})
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    my_p = ctx.freshen(lvl.ex, :_p)
    push!(ctx.preamble, quote
        $(lvl.I) = $(lvl.Ti)(($(map(n->ctx(stop(ctx.dims[(getname(fbr), envdepth(fbr.env) + n)])), 1:lvl.N)...),))
        $(lvl.idx_q) = 4
        $(lvl.pos_q) = 4
        resize!($(lvl.ex).pos, 5)
        $(lvl.ex).pos[1] = 1
    end)
    for n = 1:lvl.N
        push!(ctx.preamble, quote
            resize!($(lvl.ex).tbl[$n], 4)
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
        if $(lvl.pos_q) < $(ctx(q)) + 1
            $(lvl.pos_q) *= 4
            resize!($(lvl.ex).pos, $(lvl.pos_q))
        end
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode::Union{Write, Update})
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl

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
    if R == 1
        p_start = Virtual{lvl.Tp_2}(:($(lvl.ex).pos[$(ctx(envposition(fbr.env)))]))
        p_stop = Virtual{lvl.Tp_2}(:($(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]))
    else
        p_start = fbr.env.start
        p_stop = fbr.env.stop
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
                    body = Thunk(
                        preamble = quote
                            $my_i = $(lvl.ex).tbl[$R][$my_p]
                        end,
                        body = Phase(
                            guard = (start) -> :($my_p < $my_p_stop),
                            stride = (start) -> my_i,
                            body = (start, step) -> Thunk(
                                body = Cases([
                                    :($step == $my_i) => if R == lvl.N
                                        Thunk(
                                            body = Spike(
                                                body = Simplify(default(fbr)),
                                                tail = refurl(VirtualFiber(lvl.lvl, VirtualHollowCooEnvironment(Virtual{lvl.Tp_2}(:($my_p)), Virtual{lvl.Ti}(my_i), fbr.env)), ctx, mode, idxs...),
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
                                                body = Simplify(default(fbr)),
                                                tail = refurl(VirtualFiber(lvl, VirtualHollowCooSearchEnvironment(Virtual{lvl.Ti}(my_p), Virtual{lvl.Ti}(my_p_step), Virtual{lvl.Ti}(my_i), fbr.env)), ctx, mode, idxs...),
                                            ),
                                            epilogue = quote
                                                $my_p = $my_p_step
                                            end
                                        )
                                    end,
                                    true => Run(
                                        body = default(fbr),
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

function unfurl(fbr::VirtualFiber{VirtualHollowCooLevel}, ctx, mode::Union{Write, Update}, idx::Union{Name, Extrude}, idxs...)
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
                        $(contain(ctx) do ctx_2 
                            assemble!(VirtualFiber(lvl.lvl, VirtualMaxPositionEnvironment(my_p, fbr.env)), ctx_2, mode)
                            quote end
                        end)
                    end,
                    body = refurl(VirtualFiber(lvl.lvl, VirtualHollowCooEnvironment(Virtual{lvl.Ti}(my_p), idx, fbr.env)), ctx, mode, idxs...),
                    epilogue = begin
                        resize_body = quote end
                        write_body = quote end
                        idxs = map(ctx, (envdeferred(fbr.env)..., idx))
                        for n = 1:lvl.N
                            resize_body = quote
                                $resize_body
                                resize!($(lvl.ex).tbl[$n], $(lvl.idx_q))
                            end
                            write_body = quote
                                $write_body
                                $(lvl.ex).tbl[$n][$my_p] = $(idxs[n])
                            end
                        end
                        quote
                            if $(lvl.idx_q) < $my_p
                                $(lvl.idx_q) *= 4
                                $resize_body
                            end
                            $write_body
                            $my_p += 1
                        end
                    end
                )
            ),
            epilogue = quote
                $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1] = $my_p
            end
        )
    else
        Leaf(
            body = (i) -> refurl(VirtualFiber(lvl, VirtualHollowCooBufferEnvironment(i, fbr.env)), ctx, mode, idxs...)
        )
    end
end