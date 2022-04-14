struct Environment{Props <: NamedTuple}
    props::Props
end

Environment(;kwargs...) = Environment((;kwargs...))

Base.getproperty(env::Environment, name::Symbol) = getproperty(getfield(env, :props), name)

Base.hasproperty(env::Environment, name::Symbol) = hasproperty(getfield(env, :props), name)

function virtualize(ex, ::Type{Environment{NamedTuple{names, Args}}}, ctx) where {names, Args}
    props = Dict{Symbol, Any}(map(zip(names, Args.parameters)) do (name, Arg)
        name => virtualize(:($ex.$name), Arg, ctx)
    end)
    return VirtualEnvironment(props)
end

struct VirtualEnvironment
    props
end

VirtualEnvironment(;kwargs...) = VirtualEnvironment((;kwargs...))

isliteral(env::VirtualEnvironment) = false

function (ctx::Finch.LowerJulia)(env::VirtualEnvironment)
    kwargs = map(pairs(getfield(env, :props))) do name, arg
        Expr(:kw, name, ctx(arg))
    end
    :($Environment(;$(kwargs...)))
end

Base.getproperty(env::VirtualEnvironment, name::Symbol) = getindex(getfield(env, :props), name)

Base.hasproperty(env::VirtualEnvironment, name::Symbol) = haskey(getfield(env, :props), name)

Base.setproperty!(env::VirtualEnvironment, name::Symbol, x) = setindex(getfield(env, :props), name, x)

Base.get(env::VirtualEnvironment, name::Symbol, x) = get(getfield(env, :props), name, x)

Base.get!(env::VirtualEnvironment, name::Symbol, x) = get!(getfield(env, :props), name, x)

envcoordinate(env::Environment) = env.index
envposition(env::Environment) = env.position
envdepth(env::Environment) = haskey(env, :index) + envdepth(env.parent)
envdeferred(env::Environment) = haskey(env, :internal) ? (env.index, envdeferred(env.parent)...) : ()
envparent(env::Environment) = haskey(env, :internal) ? env.parent : ()
envguard(env::Environment) = haskey(env, :guard) ? env.guard : nothing
