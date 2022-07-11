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
    Environment([parent]; kwargs...)

An environment can be thought of as the argument to a level that yeilds a fiber.
Environments also allow parents levels to pass attributes to their children.
"""
struct Environment{Props <: NamedTuple}
    props::Props
    Environment(; kwargs...) = new{typeof(values(kwargs))}(values(kwargs))
end
Environment(parent; kwargs...) = Environment(; parent=parent, kwargs...)

const Env = Environment

function Base.show(io::IO, env::Environment)
    print(io, "Env(")
    props = getfield(env, :props)
    for (i, (key, value)) in enumerate(pairs(props))
        print(io, key, "=")
        print(io, value)
        if i != length(props) print(io, ", ") end
    end
    print(io, ")")
end

Base.getproperty(env::Environment, name::Symbol) = getproperty(getfield(env, :props), name)

Base.hasproperty(env::Environment, name::Symbol) = hasproperty(getfield(env, :props), name)

Base.get(env::Environment, name::Symbol, x) = get(getfield(env, :props), name, x)

function virtualize(ex, ::Type{Environment{NamedTuple{names, Args}}}, ctx) where {names, Args}
    props = Dict{Symbol, Any}(map(zip(names, Args.parameters)) do (name, Arg)
        name => virtualize(:($ex.$name), Arg, ctx)
    end)
    return VirtualEnvironment(;props...)
end

"""
    VirtualEnvironment([parent]; kwargs...)

In addition to holding information about the environment instance itself,
virtual environments may also hold information about the scope that this fiber
lives in.
"""
struct VirtualEnvironment
    props
    VirtualEnvironment(; kwargs...) = new(Dict{Symbol, Any}(pairs(kwargs)...))
end
VirtualEnvironment(parent; kwargs...) = VirtualEnvironment(; parent=parent, kwargs...)

isliteral(env::VirtualEnvironment) = false

function (ctx::Finch.LowerJulia)(env::VirtualEnvironment)
    kwargs = map(collect(getfield(env, :props))) do (name, arg)
        Expr(:kw, name, ctx(arg))
    end
    :($Environment(;$(kwargs...)))
end

Base.getproperty(env::VirtualEnvironment, name::Symbol) = getindex(getfield(env, :props), name)

Base.hasproperty(env::VirtualEnvironment, name::Symbol) = haskey(getfield(env, :props), name)

Base.setproperty!(env::VirtualEnvironment, name::Symbol, x) = setindex!(getfield(env, :props), x, name)

Base.get(env::VirtualEnvironment, name::Symbol, x) = get(getfield(env, :props), name, x)

Base.get!(env::VirtualEnvironment, name::Symbol, x) = get!(getfield(env, :props), name, x)

"""
    envposition(env)

Get the position in the environment. The position is an integer identifying
which fiber to access in a level.
"""
envposition(env) = envparent(env) === nothing ? 1 : env.position
"""
    envcoordinate(env)

Get the coordinate (index) in the previous environment.
"""
envcoordinate(env::Union{Environment, VirtualEnvironment}) = env.index
envdeferred(env::Union{Environment, VirtualEnvironment}) = hasproperty(env, :internal) ? (env.index, envdeferred(env.parent)...) : ()

"""
    envexternal(env)

Strip environments which are internal to the level, leaving the parent environment of the level.
"""
envexternal(env::Union{Environment, VirtualEnvironment}) = hasproperty(env, :internal) ? envexternal(env.parent) : env
envguard(env::Union{Environment, VirtualEnvironment}) = hasproperty(env, :guard) ? env.guard : nothing
envparent(env::Union{Environment, VirtualEnvironment}) = get(env, :parent, nothing)

"""
    hasdefaultcheck(lvl)

Can the level check whether it is entirely default?
"""
hasdefaultcheck(lvl) = false

"""
    getdefaultcheck(env)

Return a variable which should be set to false if the subfiber is not entirely default.
"""
getdefaultcheck(lvl) = nothing

"""
    envdefaultcheck(env)

Return a variable which should be set to false if the subfiber is not entirely default.
"""
envdefaultcheck(env) = get(env, :guard, nothing)

"""
    reinitializeable(lvl)

Does the level support selective initialization through assembly?
"""
reinitializeable(lvl) = false

"""
    envreinitialized(env)

did the previous level selectively initialize this one?
"""
envreinitialized(env) = get(env, :reinitialized, false)

"""
    interval_assembly_depth(lvl)

to what depth will the level tolerate interval environment properties for assembly?
"""
interval_assembly_depth(lvl) = 0