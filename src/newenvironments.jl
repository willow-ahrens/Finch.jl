"""
    Environment()

An environment can be thought of as the argument to a level that yeilds a fiber.
Environments also allow parents levels to pass attributes to their children.
"""
struct Environment{Props <: NamedTuple}
    props::Props
end

Environment(;kwargs...) = Environment((;kwargs...))

Base.getproperty(env::Environment, name::Symbol) = getproperty(getfield(env, :props), name)

Base.hasproperty(env::Environment, name::Symbol) = hasproperty(getfield(env, :props), name)

Base.get(env::Environment, name::Symbol, x) = get(getfield(env, :props), name, x)

function virtualize(ex, ::Type{Environment{NamedTuple{names, Args}}}, ctx) where {names, Args}
    props = Dict{Symbol, Any}(map(zip(names, Args.parameters)) do (name, Arg)
        name => virtualize(:($ex.$name), Arg, ctx)
    end)
    return VirtualEnvironment(props)
end

"""
    VirtualRootEnvironment()

In addition to holding information about the environment instance itself,
virtual environments may also hold information about the scope that this fiber
lives in.
"""
struct VirtualEnvironment
    props
end

VirtualEnvironment(;kwargs...) = VirtualEnvironment(Dict{Symbol, Any}(pairs(kwargs)))

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
envcoordinate(env::Union{Environment, VirtualEnvironment}) = env.index
envdeferred(env::Union{Environment, VirtualEnvironment}) = hasproperty(env, :internal) ? (env.index, envdeferred(env.parent)...) : ()
envexternal(env::Union{Environment, VirtualEnvironment}) = hasproperty(env, :internal) ? envexternal(env.parent) : env
envguard(env::Union{Environment, VirtualEnvironment}) = hasproperty(env, :guard) ? env.guard : nothing
envparent(env::Union{Environment, VirtualEnvironment}) = get(env, :parent, nothing)

struct Arbitrary{T} end
Arbitrary() = Arbitrary{Any}()

Base.length(::Arbitrary) = 1
Base.iterate(x::Arbitrary) = (x, nothing)

#ArbitraryEnvironment(env) = Environment(env = env, pos=Arbitrary(), idx=Arbitrary())
#VirtualArbitraryEnvironment(env) = VirtualEnvironment(env = env, pos=Arbitrary(), idx=Arbitrary())
