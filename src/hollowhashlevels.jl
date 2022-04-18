struct HollowHashLevel{N, Ti<:Tuple, Tp, Tp_2, Tbl, Lvl}
    I::Ti
    tbl::Tbl
    srt::Vector{Pair{Tuple{Tp, Ti}, Tp_2}}
    pos::Vector{Tp_2}
    lvl::Lvl
end
const HollowHash = HollowHashLevel
HollowHashLevel{N}(lvl) where {N} = HollowHashLevel{N}((0 for _ in 1:N...), lvl)
HollowHashLevel{N, Ti}(lvl) where {N, Ti} = HollowHashLevel{N, Ti}((map(zero, Ti.parameters)..., ), lvl)
HollowHashLevel{N}(I::Ti, lvl) where {N, Ti} = HollowHashLevel{N, Ti}(I, lvl)
HollowHashLevel{N, Ti}(I::Ti, lvl) where {N, Ti} = HollowHashLevel{N, Ti, Int, Int}(I, lvl)
HollowHashLevel{N, Ti, Tp, Tp_2}(I::Ti, lvl) where {N, Ti, Tp, Tp_2} =
    HollowHashLevel{N, Ti, Tp, Tp_2}(I, Dict{Tuple{Tp, Ti}, Tp_2}(), lvl)
HollowHashLevel{N, Ti, Tp, Tp_2}(I::Ti, tbl::Tbl, lvl) where {N, Ti, Tp, Tp_2, Tbl} =
    HollowHashLevel{N, Ti, Tp, Tp_2, Tbl}(I, tbl, lvl)
HollowHashLevel{N, Ti}(I::Ti, tbl::Tbl, lvl) where {N, Ti, Tp, Tp_2, Tbl <: AbstractDict{Tuple{Tp, Ti}, Tp_2}} =
    HollowHashLevel{N, Ti, Tp, Tp_2, Tbl}(I, tbl, lvl)
HollowHashLevel{N, Ti, Tp, Tp_2, Tbl}(I::Ti, tbl::Tbl, lvl) where {N, Ti, Tp, Tp_2, Tbl} =
    HollowHashLevel{N, Ti, Tp, Tp_2, Tbl}(I::Ti, tbl, Vector{Pair{Tuple{Tp, Ti}, Tp_2}}(undef, 0), Vector{Tp_2}(undef, 4), lvl)
HollowHashLevel{N, Ti, Tp, Tp_2, Tbl}(I::Ti, tbl::Tbl, srt, pos, lvl::Lvl) where {N, Ti, Tp, Tp_2, Tbl, Lvl} =
    HollowHashLevel{N, Ti, Tp, Tp_2, Tbl, Lvl}(I, tbl, srt, pos, lvl)

@inline arity(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = N + arity(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))
@inline shape(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = (fbr.lvl.I..., shape(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))...)
@inline domain(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = (map(Base.OneTo, fbr.lvl.I)..., domain(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))...)
@inline image(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = image(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))
@inline default(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = default(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))

function (fbr::Fiber{<:HollowHashLevel{N, Ti}})(i, tail...) where {N, Ti}
    lvl = fbr.lvl
    if length(envdeferred(fbr.env)) == N - 1
        q = (envposition(fbr.env), (envdeferred(fbr.env)..., i))

        if !haskey(lvl.tbl, q)
            return default(fbr)
        else
            p = lvl.tbl[q]
            fbr_2 = Fiber(lvl.lvl, PositionEnvironment(p, i, fbr.env))
            return fbr_2(tail...)
        end
    else
        fbr_2 = Fiber(lvl, DeferredEnvironment(i, fbr.env))
        fbr_2(tail...)
    end
end



mutable struct VirtualHollowHashLevel
    ex
    N
    Ti
    Tp
    Tp_2
    Tbl
    I
    pos_q
    pos_q_alloc
    idx_q
    lvl
end
function virtualize(ex, ::Type{HollowHashLevel{N, Ti, Tp, Tp_2, Tbl, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tp, Tp_2, Tbl, Lvl}   
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
    VirtualHollowHashLevel(sym, N, Ti, Tp, Tp_2, Tbl, I, pos_q, pos_q_alloc, idx_q, lvl_2)
end
(ctx::Finch.LowerJulia)(lvl::VirtualHollowHashLevel) = lvl.ex

function reconstruct!(lvl::VirtualHollowHashLevel, ctx)
    push!(ctx.preamble, quote
        $(lvl.ex) = $HollowHashLevel{$(lvl.N), $(lvl.Ti), $(lvl.Tp), $(lvl.Tp_2), $(lvl.Tbl)}(
            $(ctx(lvl.I)),
            $(lvl.ex).tbl,
            $(lvl.ex).srt,
            $(lvl.ex).pos,
            $(ctx(lvl.lvl)),
        )
    end)
end

function getsites(fbr::VirtualFiber{VirtualHollowHashLevel})
    return (map(n-> envdepth(fbr.env) + n, 1:fbr.lvl.N)..., getsites(VirtualFiber(fbr.lvl.lvl, ∘(repeated(VirtualArbitraryEnvironment, fbr.lvl.N)...)(fbr.env)))...)
end

function getdims(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode)
    ext = map(n->Extent(1, Virtual{Int}(:($(fbr.lvl.I)[$n]))), 1:fbr.lvl.N)
    dim = mode isa Read ? ext : map(SuggestedExtent, ext)
    (dim..., getdims(VirtualFiber(fbr.lvl.lvl, VirtualArbitraryEnvironment(fbr.env)), ctx, mode)...)
end

@inline default(fbr::VirtualFiber{VirtualHollowHashLevel}) = default(VirtualFiber(fbr.lvl.lvl, ∘(repeated(VirtualArbitraryEnvironment, fbr.lvl.N)...)(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Union{Write, Update})
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    my_p = ctx.freshen(lvl.ex, :_p)
    push!(ctx.preamble, quote
        $(lvl.I) = $(lvl.Ti)(($(map(n->ctx(stop(ctx.dims[(getname(fbr), envdepth(fbr.env) + n)])), 1:lvl.N)...),))
        $(lvl.idx_q) = 0
        empty!($(lvl.ex).tbl)
        empty!($(lvl.ex).srt)
        $(lvl.pos_q_alloc) = 4
        resize!($(lvl.ex).pos, 5)
        $(lvl.ex).pos[1] = 1
        $(lvl.pos_q) = 0
    end)
    if (lvl_2 = initialize_level!(VirtualFiber(fbr.lvl.lvl, ∘(repeated(VirtualArbitraryEnvironment, lvl.N)...)(fbr.env)), ctx, mode)) !== nothing
        lvl = shallowcopy(lvl)
        lvl.lvl = lvl_2
    end
    reconstruct!(lvl, ctx)
    return lvl
end

function assemble!(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode)
    q = envposition(fbr.env)
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

function finalize_level!(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Union{Write, Update})
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    my_p = ctx.freshen(lvl.ex, :_p)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).srt, length($(lvl.ex).tbl))
        copyto!($(lvl.ex).srt, pairs($(lvl.ex).tbl))
        sort!($(lvl.ex).srt)
        #resize!($(lvl.ex).pos, $(lvl.pos_q) + 1)
        for $my_p = 1:$(lvl.pos_q)
            $(lvl.ex).pos[$my_p + 1] += $(lvl.ex).pos[$my_p]
        end
    end)
    if (lvl_2 = finalize_level!(VirtualFiber(fbr.lvl.lvl, ∘(repeated(VirtualArbitraryEnvironment, lvl.N)...)(fbr.env)), ctx, mode)) !== nothing
        lvl = shallowcopy(lvl)
        lvl.lvl = lvl_2
        reconstruct!(lvl, ctx)
        return lvl
    else
        return nothing
    end
end



"""
    HollowHashEnvironment(pos, idx, env)

The environment introduced by a HollowHashLevel.
"""
struct HollowHashEnvironment{Pos, Idx, Env}
    pos::Pos
    idx::Idx
    env::Env
end
envdepth(env::HollowHashEnvironment) = 1 + envdepth(env.env)
envposition(env::HollowHashEnvironment) = env.pos
envcoordinate(env::HollowHashEnvironment) = env.idx

struct VirtualHollowHashEnvironment
    pos
    idx
    env
end
function virtualize(ex, ::Type{HollowHashEnvironment{Pos, Idx, Env}}, ctx) where {Pos, Idx, Env}
    pos = virtualize(:($ex.pos), Pos, ctx)
    idx = virtualize(:($ex.idx), Idx, ctx)
    env = virtualize(:($ex.env), Env, ctx)
    VirtualHollowHashEnvironment(pos, idx, env)
end
(ctx::Finch.LowerJulia)(env::VirtualHollowHashEnvironment) = :(HollowHashEnvironment($(ctx(env.pos)), $(ctx(env.idx)), $(ctx(env.env))))
isliteral(::VirtualHollowHashEnvironment) = false

envposition(env::VirtualHollowHashEnvironment) = env.pos
envcoordinate(env::VirtualHollowHashEnvironment) = env.idx
envdepth(env::VirtualHollowHashEnvironment) = 1 + envdepth(env.env)

"""
    HollowHashSearchEnvironment(pos, idx, env)

The environment introduced inside a HollowHashLevel.
"""
struct HollowHashSearchEnvironment{Start, Stop, Idx, Env}
    start::Start
    stop::Stop
    idx::Idx
    env::Env
end
envdepth(env::HollowHashSearchEnvironment) = 1 + envdepth(env.env)
envcoordinate(env::HollowHashSearchEnvironment) = env.idx
envdeferred(env::HollowHashSearchEnvironment) = (env.idx, envdeferred(env.env)...)
envparent(env::HollowHashSearchEnvironment) = env.env

struct VirtualHollowHashSearchEnvironment
    start
    stop
    idx
    env
end
function virtualize(ex, ::Type{HollowHashSearchEnvironment{Pos, Idx, Env}}, ctx) where {Pos, Idx, Env}
    pos = virtualize(:($ex.pos), Pos, ctx)
    idx = virtualize(:($ex.idx), Idx, ctx)
    env = virtualize(:($ex.env), Env, ctx)
    VirtualHollowHashSearchEnvironment(pos, idx, env)
end
(ctx::Finch.LowerJulia)(env::VirtualHollowHashSearchEnvironment) = :(HollowHashSearchEnvironment($(ctx(env.pos)), $(ctx(env.idx)), $(ctx(env.env))))
isliteral(::VirtualHollowHashSearchEnvironment) = false

envcoordinate(env::VirtualHollowHashSearchEnvironment) = env.idx
envdepth(env::VirtualHollowHashSearchEnvironment) = 1 + envdepth(env.env)
envdeferred(env::VirtualHollowHashSearchEnvironment) = (env.idx, envdeferred(env.env)...)
envparent(env::VirtualHollowHashSearchEnvironment) = env.env

"""
    HollowHashBufferEnvironment(idx, env)

The environment introduced inside a HollowHashLevel to just buffer up a coordinate to write later.
"""
struct HollowHashBufferEnvironment{Idx, Env}
    idx::Idx
    env::Env
end
envdepth(env::HollowHashBufferEnvironment) = 1 + envdepth(env.env)
envcoordinate(env::HollowHashBufferEnvironment) = env.idx
envdeferred(env::HollowHashBufferEnvironment) = (env.idx, envdeferred(env.env)...)
envparent(env::HollowHashBufferEnvironment) = env.env

struct VirtualHollowHashBufferEnvironment
    idx
    env
end
function virtualize(ex, ::Type{HollowHashBufferEnvironment{Idx, Env}}, ctx) where {Idx, Env}
    idx = virtualize(:($ex.idx), Idx, ctx)
    env = virtualize(:($ex.env), Env, ctx)
    VirtualHollowHashBufferEnvironment(idx, env)
end
(ctx::Finch.LowerJulia)(env::VirtualHollowHashBufferEnvironment) = :(HollowHashBufferEnvironment($(ctx(env.idx)), $(ctx(env.env))))
isliteral(::VirtualHollowHashBufferEnvironment) = false

envcoordinate(env::VirtualHollowHashBufferEnvironment) = env.idx
envdepth(env::VirtualHollowHashBufferEnvironment) = 1 + envdepth(env.env)
envdeferred(env::VirtualHollowHashBufferEnvironment) = (env.idx, envdeferred(env.env)...)
envparent(env::VirtualHollowHashBufferEnvironment) = env.env



unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Read, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, walk(idx))

function unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Read, idx::Walk, idxs...)
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
                $my_i = last(first($(lvl.ex).srt[$my_p]))[$R]
                $my_i_stop = last(first($(lvl.ex).srt[$my_p_stop - 1]))[$R]
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
                        preamble = :(
                            $my_i = last(first($(lvl.ex).srt[$my_p]))[$R]
                        ),
                        body = Phase(
                            guard = (start) -> :($my_p < $my_p_stop),
                            stride = (start) -> my_i,
                            body = (start, step) -> Thunk(
                                body = Cases([
                                    :($step == $my_i) => if R == lvl.N
                                        Thunk(
                                            body = Spike(
                                                body = Simplify(default(fbr)),
                                                tail = refurl(VirtualFiber(lvl.lvl, VirtualHollowHashEnvironment(Virtual{lvl.Ti}(:(last($(lvl.ex).srt[$my_p])[$R])), Virtual{lvl.Ti}(my_i), fbr.env)), ctx, mode, idxs...),
                                            ),
                                            epilogue = quote
                                                $my_p += 1
                                            end
                                        )
                                    else
                                        Thunk(
                                            preamble = quote
                                                $my_p_step = $my_p + 1
                                                while $my_p_step < $my_p_stop && last(first($(lvl.ex).srt[$my_p_step]))[$R] == $my_i
                                                    $my_p_step += 1
                                                end
                                            end,
                                            body = Spike(
                                                body = Simplify(default(fbr)),
                                                tail = refurl(VirtualFiber(lvl, VirtualHollowHashSearchEnvironment(Virtual{lvl.Ti}(my_p), Virtual{lvl.Ti}(my_p_step), Virtual{lvl.Ti}(my_i), fbr.env)), ctx, mode, idxs...),
                                            ),
                                            epilogue = quote
                                                $my_p = $my_p_step
                                            end
                                        )
                                    end,
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

function unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Read, idx::Union{Follow}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    R = length(envdeferred(fbr.env)) + 1
    my_key = cgx.freshen(tag, :_key)
    my_p = cgx.freshen(tag, :_p)

    if R == lvl.N
        Leaf(
            body = (i) -> Thunk(
                preamble = quote
                    $my_key = ($(ctx(envposition(envparent(fbr.env)))), ($(map(ctx, envdeferred(fbr.env))...), $(ctx(i))))
                    $my_p = get($(lvl.ex).tbl, $my_key, 0)
                end,
                body = Cases([
                    :($my_p != 0) => refurl(VirtualFiber(lvl.lvl, HollowHashEnvironment(Virtual{lvl.Tp_2}(my_p), i, fbr.env)), ctx, mode, idxs...),
                    true => Simplify(default(fbr))
                ])
            )
        )
    else
        Leaf(
            body = (i) -> refurl(VirtualFiber(lvl, HollowHashBufferEnvironment(i, fbr.env)), ctx, mode, idxs...)
        )
    end
end

unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Union{Write, Update}, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, laminate(idx), idxs...)

function unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Union{Write, Update}, idx::Union{Name, Extrude, Laminate}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    R = length(envdeferred(fbr.env)) + 1
    my_key = ctx.freshen(tag, :_key)
    my_p = ctx.freshen(tag, :_p)

    if R == lvl.N
        Thunk(
            preamble = quote
                $my_p = $(lvl.ex).pos[$(ctx(envposition(envparent(fbr.env))))]
            end,
            body = AcceptSpike(
                val = default(fbr),
                tail = (ctx, idx) -> Thunk(
                    preamble = quote
                        $my_key = ($(ctx(envposition(envparent(fbr.env)))), ($(map(ctx, envdeferred(fbr.env))...), $(ctx(idx))))
                        $my_p = get!($(lvl.ex).tbl, $my_key, $(lvl.idx_q) + 1)
                        if $(lvl.idx_q) < $my_p 
                            $(lvl.idx_q) = $my_p
                            $(contain(ctx) do ctx_2 
                                assemble!(VirtualFiber(fbr.lvl.lvl, VirtualMaxPositionEnvironment(my_p, ∘(repeated(VirtualArbitraryEnvironment, lvl.N - 1)..., identity)(fbr.env))), ctx_2, mode)
                                quote end
                            end)
                            $(lvl.ex).pos[$(ctx(envposition(envparent(fbr.env)))) + 1] += 1
                        end
                    end,
                    body = refurl(VirtualFiber(lvl.lvl, HollowHashEnvironment(Virtual{lvl.Ti}(my_p), idx, fbr.env)), ctx, mode, idxs...)
                )
            )
        )
    else
        Leaf(
            body = (i) -> refurl(VirtualFiber(lvl, HollowHashBufferEnvironment(i, fbr.env)), ctx, mode, idxs...)
        )
    end
end