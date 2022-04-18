"""
    RootEnvironment()

An environment can be thought of as the argument to a level that yeilds a fiber.
Environments also allow parents levels to pass attributes to their children.  By
default, the top level has access to the RootEnvironment.
"""
RootEnvironment() = Environment()

envposition(env) = envparent(env) === nothing ? 1 : env.position

"""
    envdepth()

Return the number of accesses (coordinates) unfurled so far in this environment.
"""
envdepth(env) = envparent(env) === nothing ? 0 : 1 + envdepth(envparent(env))

"""
    VirtualRootEnvironment()

In addition to holding information about the environment instance itself,
virtual environments may also hold information about the contain that this fiber
lives in.
"""
VirtualRootEnvironment() = VirtualEnvironment()

"""
    VirtualNameEnvironment(env)

Holds the name of the tensor at the point it was named.
"""
VirtualNameEnvironment(name, env) = (env.name = Literal(name); env)
envgetname(env) = hasproperty(env, :name) ? getvalue(env.name) : envgetname(envparent(env))
function envsetname!(env, name)
    if hasproperty(env, :name)
        env.name = Literal(name)
    else
        env.env = envsetname!(envparent(env), name)
    end
    env
end

"""
    PositionEnvironment(pos, idx, env)

An environment that holds a position `pos`, corresponding coordinate `idx`, and parent
environment `env`.

See also: [`envposition`](@ref), [`envcoordinate`](@ref)
"""
PositionEnvironment(pos, idx, env) = Environment(position = pos, coordinate = idx, parent=env)

VirtualPositionEnvironment(pos, idx, env) = VirtualEnvironment(position = pos, coordinate = idx, parent=env)

"""
    DeferredEnvironment(idx, env)

An environment that holds a deferred coordinate `idx`, and parent
environment `env`.

See also: [`envdeferred`](@ref), [`envcoordinate`](@ref)
"""
DeferredEnvironment(idx, env) = Environment(index=idx, parent=env, internal=true)
VirtualDeferredEnvironment(idx, env) = VirtualEnvironment(index=idx, parent=env, internal=true)

"""
    VirtualMaxPositionEnvironment(maxpos, env)

An environment that holds a maximum position that a level should support, and a parent
environment `env`. The coordinate here is arbitrary

See also: [`envposition`](@ref)
"""
VirtualMaxPositionEnvironment(pos, env) = VirtualEnvironment(position=pos, parent=env)

"""
    ArbitraryEnvironment(env)

An environment that abstracts over all positions, not making a choice. The
parent environment is `env`.
"""
ArbitraryEnvironment(env) = Environment(parent=env, index=nothing)
VirtualArbitraryEnvironment(env) = VirtualEnvironment(parent=env, index=nothing)
"""
    envposition(env)

Get the position in the environment. The position is an integer identifying
which fiber to access in a level.
"""

"""
    envcoordinate(env)

Get the coordinate (index) in the previous environment.
"""

"""
    envparent(env)

Strip internal environments, leaving the parent environment.
"""