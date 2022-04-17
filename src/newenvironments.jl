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

envcoordinate(env::Union{Environment, VirtualEnvironment}) = env.index
envposition(env::Union{Environment, VirtualEnvironment}) = env.position
envdepth(env::Union{Environment, VirtualEnvironment}) = haskey(env, :index) + envdepth(env.parent)
envdeferred(env::Union{Environment, VirtualEnvironment}) = haskey(env, :internal) ? (env.index, envdeferred(env.parent)...) : ()
envparent(env::Union{Environment, VirtualEnvironment}) = haskey(env, :internal) ? env.parent : ()
envguard(env::Union{Environment, VirtualEnvironment}) = haskey(env, :guard) ? env.guard : nothing

struct Arbitrary{T} end
Arbitrary() = Arbitrary{Any}()

Base.length(::Arbitrary) = 1
Base.iterate(x::Arbitrary) = (x, nothing)

#ArbitraryEnvironment(env) = Environment(env = env, pos=Arbitrary(), idx=Arbitrary())
#VirtualArbitraryEnvironment(env) = VirtualEnvironment(env = env, pos=Arbitrary(), idx=Arbitrary())
