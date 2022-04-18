"""
    envdepth()

Return the number of accesses (coordinates) unfurled so far in this environment.
"""
envdepth(env) = envparent(env) === nothing ? 0 : 1 + envdepth(envparent(env))

"""
    envname()

The name of the tensor when it was last named.
"""
envname(env) = hasproperty(env, :name) ? getvalue(env.name) : envname(envparent(env))
function envrename!(env, name)
    if hasproperty(env, :name)
        env.name = Literal(name)
    else
        env.env = envrename!(envparent(env), name)
    end
    env
end

"""
    ArbitraryEnvironment(env)

An environment that abstracts over all positions, not making a choice. The
parent environment is `env`.
"""
ArbitraryEnvironment(env) = Environment(parent=env, index=nothing)
VirtualArbitraryEnvironment(env) = VirtualEnvironment(parent=env, index=nothing)

"""
    envcoordinate(env)

Get the coordinate (index) in the previous environment.
"""

"""
    envparent(env)

Strip internal environments, leaving the parent environment.
"""