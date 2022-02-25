"""
    RootEnvironment()

An environment can be thought of as the argument to a level that yeilds a fiber.
Environments also allow parents levels to pass attributes to their children.  By
default, the top level has access to the RootEnvironment.
"""
struct RootEnvironment end

envposition(env::RootEnvironment) = 1
envmaxposition(env::RootEnvironment) = 1

"""
    envdepth()

Return the number of accesses (coordinates) unfurled so far in this environment.
"""
envdepth(env::RootEnvironment) = 0

"""
    VirtualRootEnvironment()

In addition to holding information about the environment instance itself,
virtual environments may also hold information about the contain that this fiber
lives in.
"""
struct VirtualRootEnvironment end
virtualize(ex, ::Type{RootEnvironment}, ctx) = VirtualRootEnvironment()
(ctx::Finch.LowerJulia)(::VirtualRootEnvironment) = :(RootEnvironment())
isliteral(::VirtualRootEnvironment) = false

envposition(env::VirtualRootEnvironment) = 1
envmaxposition(env::VirtualRootEnvironment) = 1
envdepth(env::VirtualRootEnvironment) = 0

abstract type AbstractMetaEnvironment end

"""
    VirtualNameEnvironment(env)

Holds the name of the tensor at the point it was named.
"""
mutable struct VirtualNameEnvironment <: AbstractMetaEnvironment
    name
    env
end
(ctx::Finch.LowerJulia)(env::VirtualNameEnvironment) = ctx(env.env)
isliteral(::VirtualNameEnvironment) = false

envposition(env::AbstractMetaEnvironment) = envposition(env.env)
envmaxposition(env::AbstractMetaEnvironment) = envmaxposition(env.env)
envdepth(env::AbstractMetaEnvironment) = envdepth(env.env)
envgetname(env) = envgetname(env.env) #TODO add getter for environment child
envgetname(env::VirtualNameEnvironment) = env.name
envsetname!(env, name) = (envsetname!(env.env, name); env) #TODO should this really be mutable?
envsetname!(env::VirtualNameEnvironment, name) = (env.name = name; env)

"""
    PositionEnvironment(pos, idx, env)

An environment that holds a position `pos`, corresponding coordinate `idx`, and parent
environment `env`.

See also: [`envposition`](@ref), [`envcoordinate`](@ref), [`getparent`](@ref)
"""
struct PositionEnvironment{Tp, Ti, Env}
    pos::Tp
    idx::Ti
    env::Env
end
envdepth(env::PositionEnvironment) = 1 + envdepth(env.env)

struct VirtualPositionEnvironment
    pos
    idx
    env
end
function virtualize(ex, ::Type{PositionEnvironment{Tp, Ti, Env}}, ctx) where {Tp, Ti, Env}
    pos = virtualize(:($ex.pos), Tp, ctx)
    idx = virtualize(:($ex.idx), Ti, ctx)
    env = virtualize(:($ex.env), Env, ctx)
    VirtualPositionEnvironment(pos, idx, env)
end
(ctx::Finch.LowerJulia)(env::VirtualPositionEnvironment) = :(PositionEnvironment($(ctx(env.pos)), $(ctx(env.idx)), $(ctx(env.env))))
isliteral(::VirtualPositionEnvironment) = false

envposition(env::VirtualPositionEnvironment) = env.pos
envcoordinate(env::VirtualPositionEnvironment) = env.idx
envdepth(env::VirtualPositionEnvironment) = 1 + envdepth(env.env)

"""
    DeferredEnvironment(idx, env)

An environment that holds a deferred coordinate `idx`, and parent
environment `env`.

See also: [`envdeferred`](@ref), [`envcoordinate`](@ref), [`getparent`](@ref)
"""
struct DeferredEnvironment{Ti, Env}
    idx::Ti
    env::Env
end
envdepth(env::DeferredEnvironment) = 1 + envdepth(env.env)
envcoordinate(env::DeferredEnvironment) = env.idx
envposition(env::DeferredEnvironment) = envposition(env.env)
envmaxposition(env::DeferredEnvironment) = envmaxposition(env.env)
envdeferred(env::DeferredEnvironment) = (env.idx, envdeferred(env.env)...)
envdeferred(env) = envdeferred(env.env) #TODO abstract type here?
envdeferred(env::PositionEnvironment) = ()
envdeferred(env::RootEnvironment) = ()

struct VirtualDeferredEnvironment
    idx
    env
end
function virtualize(ex, ::Type{DeferredEnvironment{Ti, Env}}, ctx) where {Ti, Env}
    idx = virtualize(:($ex.idx), Ti, ctx)
    env = virtualize(:($ex.env), Env, ctx)
    VirtualDeferredEnvironment(pos, idx, env)
end
(ctx::Finch.LowerJulia)(env::VirtualDeferredEnvironment) = :(DeferredEnvironment($(ctx(env.idx)), $(ctx(env.env))))
isliteral(::VirtualDeferredEnvironment) = false

envdepth(env::VirtualDeferredEnvironment) = 1 + envdepth(env.env)
envcoordinate(env::VirtualDeferredEnvironment) = env.idx
envposition(env::VirtualDeferredEnvironment) = envposition(env.env)
envmaxposition(env::VirtualDeferredEnvironment) = envmaxposition(env.env)
envdeferred(env::VirtualDeferredEnvironment) = (env.idx, envdeferred(env.env)...)
envdeferred(env::VirtualPositionEnvironment) = ()
envdeferred(env::VirtualRootEnvironment) = ()

struct PosRangeEnvironment{Start, Stop, Idx, Env}
    start::Start
    stop::Stop
    idx::Idx
    env::Env
end

envdepth(env::PosRangeEnvironment) = 1 + envdepth(env.env)
envcoordinate(env::PosRangeEnvironment) = env.idx
envstart(env::PosRangeEnvironment) = env.start
envstart(env) = nothing
envstop(env::PosRangeEnvironment) = env.stop
envstop(env) = nothing
envdeferred(env::PosRangeEnvironment) = (env.idx, envdeferred(env.env)...)

struct VirtualPosRangeEnvironment
    start
    stop
    idx
    env
end

function virtualize(ex, ::Type{PosRangeEnvironment{Start, Stop, Idx, Env}}, ctx) where {Start, Stop, Idx, Env}
    idx = virtualize(:($ex.idx), Idx, ctx)
    start = virtualize(:($ex.start), Start, ctx)
    stop = virtualize(:($ex.stop), Stop, ctx)
    env = virtualize(:($ex.env), Env, ctx)
    VirtualPosRangeEnvironment(start, stop, idx, env)
end
(ctx::Finch.LowerJulia)(env::VirtualPosRangeEnvironment) = :(PosRangeEnvironment($(ctx(env.start)), $(ctx(env.stop)), $(ctx(env.idx)), $(ctx(env.env))))
isliteral(::VirtualPosRangeEnvironment) = false

envdepth(env::VirtualPosRangeEnvironment) = 1 + envdepth(env.env)
envcoordinate(env::VirtualPosRangeEnvironment) = env.idx
envstart(env::VirtualPosRangeEnvironment) = env.start
envstart(env::VirtualNameEnvironment) = envstart(env.env)
envstop(env::VirtualPosRangeEnvironment) = env.stop
envstop(env::VirtualNameEnvironment) = envstop(env.env)
envdeferred(env::VirtualPosRangeEnvironment) = (env.idx, envdeferred(env.env)...)

"""
    VirtualMaxPositionEnvironment(maxpos, env)

An environment that holds a maximum position that a level should support, and a parent
environment `env`. The coordinate here is arbitrary

See also: [`envposition`](@ref)
"""
struct VirtualMaxPositionEnvironment
    pos
    env
end
#TODO virtualize this
envdepth(env::VirtualMaxPositionEnvironment) = 1 + envdepth(env.env)
envmaxposition(env::VirtualMaxPositionEnvironment) = env.pos


"""
    ArbitraryEnvironment(env)

An environment that abstracts over all positions, not making a choice. The
parent environment is `env`.

See also: [`getparent`](@ref)
"""
struct ArbitraryEnvironment{Env}
    env::Env
end

envdepth(env::ArbitraryEnvironment) = 1 + envdepth(env.env)

struct VirtualArbitraryEnvironment
    env
end
function virtualize(ex, ::Type{ArbitraryEnvironment{Env}}, ctx) where {Env}
    env = virtualize(:($ex.env), Env, ctx)
    VirtualArbitraryEnvironment(env)
end
(ctx::Finch.LowerJulia)(env::VirtualArbitraryEnvironment) = :(ArbitraryEnvironment($(ctx(env.env))))
isliteral(::VirtualArbitraryEnvironment) = false
envdepth(env::VirtualArbitraryEnvironment) = 1 + envdepth(env.env)

"""
    envposition(env)

Get the position in the environment. The position is an integer identifying
which fiber to access in a level.
"""
envposition(env::PositionEnvironment) = env.pos

"""
    envcoordinate(env)

Get the coordinate (index) in the previous environment.
"""
envcoordinate(env::PositionEnvironment) = env.idx

"""
    getparent(env)

Get the parent of the environment.
"""
getparent(env::PositionEnvironment) = env.env
getparent(env::ArbitraryEnvironment) = env.env