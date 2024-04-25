struct All{F}
    f::F
end

@inline (f::All{F})(args) where {F} = all(f.f, args)

struct Or{Fs}
    fs::Fs
end

Or(fs...) = Or{typeof(fs)}(fs)

@inline (f::Or{Fs})(arg) where {Fs} = any(g->g(arg), f.fs)

struct And{Fs}
    fs::Fs
end

And(fs...) = And{typeof(fs)}(fs)

@inline (f::And{Fs})(arg) where {Fs} = all(g->g(arg), f.fs)

shallowcopy(x::T) where T = T([getfield(x, k) for k ∈ fieldnames(T)]...)

kwfields(x::T) where T = Dict((k=>getfield(x, k) for k ∈ fieldnames(T))...)


(Base.:^)(T::Type, i::Int) = ∘(repeated(T, i)..., identity)
(Base.:^)(f::Function, i::Int) = ∘(repeated(f, i)..., identity)

include("compile.jl")
include("limits.jl")
include("shims.jl")
include("staging.jl")
include("vectors.jl")