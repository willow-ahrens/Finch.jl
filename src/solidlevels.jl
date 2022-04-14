struct SolidLevel{Ti, Lvl}
    I::Ti
    lvl::Lvl
end
SolidLevel{Ti}(lvl) where {Ti} = SolidLevel(zero(Ti), lvl)
SolidLevel(lvl) = SolidLevel(0, lvl)
const Solid = SolidLevel

dimension(lvl::SolidLevel) = lvl.I

@inline arity(fbr::Fiber{<:SolidLevel}) = 1 + arity(Fiber(fbr.lvl.lvl, ArbitraryEnvironment(fbr.env)))
@inline shape(fbr::Fiber{<:SolidLevel}) = (fbr.lvl.I, shape(Fiber(fbr.lvl.lvl, ArbitraryEnvironment(fbr.env)))...)
@inline domain(fbr::Fiber{<:SolidLevel}) = (1:fbr.lvl.I, domain(Fiber(fbr.lvl.lvl, ArbitraryEnvironment(fbr.env)))...)
@inline image(fbr::Fiber{<:SolidLevel}) = image(Fiber(fbr.lvl.lvl, ArbitraryEnvironment(fbr.env)))
@inline default(fbr::Fiber{<:SolidLevel}) = default(Fiber(fbr.lvl.lvl, ArbitraryEnvironment(fbr.env)))

"""
    SolidEnvironment(pos, idx, env)

The environment introduced by the SolidLevel.
"""
struct SolidEnvironment{Pos, Idx, Env}
    pos::Pos
    idx::Idx
    env::Env
end
envdepth(env::SolidEnvironment) = 1 + envdepth(env.env)
envposition(env::SolidEnvironment) = env.pos
envcoordinate(env::SolidEnvironment) = env.idx

struct VirtualSolidEnvironment
    pos
    idx
    env
end
function virtualize(ex, ::Type{SolidEnvironment{Pos, Idx, Env}}, ctx) where {Pos, Idx, Env}
    pos = virtualize(:($ex.pos), Pos, ctx)
    idx = virtualize(:($ex.idx), Idx, ctx)
    env = virtualize(:($ex.env), Env, ctx)
    VirtualSolidEnvironment(pos, idx, env)
end
(ctx::Finch.LowerJulia)(env::VirtualSolidEnvironment) = :(SolidEnvironment($(ctx(env.pos)), $(ctx(env.idx)), $(ctx(env.env))))
isliteral(::VirtualSolidEnvironment) = false

envposition(env::VirtualSolidEnvironment) = env.pos
envcoordinate(env::VirtualSolidEnvironment) = env.idx
envdepth(env::VirtualSolidEnvironment) = 1 + envdepth(env.env)

function (fbr::Fiber{<:SolidLevel{Ti}})(i, tail...) where {D, Tv, Ti, N, R}
    lvl = fbr.lvl
    q = envposition(fbr.env)
    p = (q - 1) * lvl.I + i
    fbr_2 = Fiber(lvl.lvl, SolidEnvironment(p, i, fbr.env))
    fbr_2(tail...)
end


mutable struct VirtualSolidLevel
    ex
    Ti
    I
    lvl
end
function virtualize(ex, ::Type{SolidLevel{Ti, Lvl}}, ctx, tag=:lvl) where {Ti, Lvl}
    sym = ctx.freshen(tag)
    I = ctx.freshen(sym, :_I)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSolidLevel(sym, Ti, I, lvl_2)
end
(ctx::Finch.LowerJulia)(lvl::VirtualSolidLevel) = lvl.ex

function reconstruct!(lvl::VirtualSolidLevel, ctx)
    push!(ctx.preamble, quote
        $(lvl.ex) = SolidLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(ctx(lvl.lvl)),
        )
    end)
end

function getsites(fbr::VirtualFiber{VirtualSolidLevel})
    return (envdepth(fbr.env) + 1, getsites(VirtualFiber(fbr.lvl.lvl, VirtualArbitraryEnvironment(fbr.env)))...)
end

function getdims(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode)
    ext = Extent(1, Virtual{Int}(fbr.lvl.I))
    dim = mode isa Read ? ext : SuggestedExtent(ext)
    (dim, getdims(VirtualFiber(fbr.lvl.lvl, VirtualArbitraryEnvironment(fbr.env)), ctx, mode)...)
end

@inline default(fbr::VirtualFiber{<:VirtualSolidLevel}) = default(VirtualFiber(fbr.lvl.lvl, VirtualArbitraryEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode::Union{Write, Update})
    lvl = fbr.lvl
    push!(ctx.preamble, quote
        $(lvl.I) = $(ctx(stop(ctx.dims[(getname(fbr), envdepth(fbr.env) + 1)])))
    end)
    if (lvl_2 = initialize_level!(VirtualFiber(lvl.lvl, ArbitraryEnvironment(fbr.env)), ctx, mode)) !== nothing
        lvl = shallowcopy(lvl)
        lvl.lvl = lvl_2
    end
    reconstruct!(lvl, ctx)
    return lvl
end

function assemble!(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode)
    q = envmaxposition(fbr.env)
    lvl = fbr.lvl
    q_2 = ctx.freshen(lvl.ex, :_q)
    push!(ctx.preamble, quote
        $q_2 = $(ctx(q)) * $(lvl.I)
    end)
    assemble!(VirtualFiber(lvl.lvl, VirtualMaxPositionEnvironment(q_2, fbr.env)), ctx, mode)
end

finalize_level!(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode::Union{Write, Update}) = nothing

function unfurl(fbr::VirtualFiber{VirtualSolidLevel}, ctx, mode::Union{Read, Write, Update}, idx::Union{Name, Walk, Follow, Laminate, Extrude}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex

    p = envposition(fbr.env)
    p_1 = ctx.freshen(tag, :_p)
    if p == 1
        Leaf(
            body = (i) -> refurl(VirtualFiber(lvl.lvl, SolidEnvironment(i, i, fbr.env)), ctx, mode, idxs...),
        )
    else
        Leaf(
            body = (i) -> Thunk(
                preamble = quote
                    $p_1 = ($(ctx(p)) - 1) * $(lvl.ex).I + $(ctx(i))
                end,
                body = refurl(VirtualFiber(lvl.lvl, SolidEnvironment(Virtual{lvl.Ti}(p_1), i, fbr.env)), ctx, mode, idxs...),
            )
        )
    end
end