include("environments.jl")

"""
    Fiber(lvl, env=Environment())

A fiber is a combination of a (possibly nested) level `lvl` and an environment
`env`. The environment is often used to refer to a particular fiber within the
level. Fibers are arrays, of sorts. The function `refindex(fbr, i...)` is used
as a reference implementation of getindex for the fiber. Accessing an
`N`-dimensional fiber with less than `N` indices will return another fiber.
"""
struct Fiber{Lvl, Env}
    lvl::Lvl
    env::Env
end
Fiber(lvl::Lvl) where {Lvl} = Fiber{Lvl}(lvl)
Fiber{Lvl}(lvl::Lvl, env::Env=Environment()) where {Lvl, Env} = Fiber{Lvl, Env}(lvl, env)

fiber(lvl) = FiberArray(Fiber(lvl))

"""
    VirtualFiber(lvl, env)

A virtual fiber is the avatar of a fiber for the purposes of compilation. Two
fibers should share a `name` only if they hold the same data. `lvl` is a virtual
object representing the level nest and `env` is a virtual object representing
the environment.
"""
mutable struct VirtualFiber{Lvl}
    lvl::Lvl
    env
    function VirtualFiber{Lvl}(lvl::Lvl, env) where {Lvl}
        @assert !(lvl isa Vector)
        @assert env != nothing
        new{Lvl}(lvl, env)
    end
end
VirtualFiber(lvl::Lvl, env) where {Lvl} = VirtualFiber{Lvl}(lvl, env)

function virtualize(ex, ::Type{<:Fiber{Lvl, Env}}, ctx, tag=ctx.freshen(:tns)) where {Lvl, Env}
    lvl = virtualize(:($ex.lvl), Lvl, ctx, Symbol(tag, :_lvl))
    env = virtualize(:($ex.env), Env, ctx)
    env.name = tag
    VirtualFiber(lvl, env)
end
(ctx::Finch.LowerJulia)(fbr::VirtualFiber) = :(Fiber($(ctx(fbr.lvl)), $(ctx(fbr.env))))
isliteral(::VirtualFiber) = false

getname(fbr::VirtualFiber) = envname(fbr.env)
setname(fbr::VirtualFiber, name) = VirtualFiber(fbr.lvl, envrename!(fbr.env, name))
#setname(fbr::VirtualFiber, name) = (fbr.env.name = name; fbr)



struct FiberArray{Fbr, T, N} <: AbstractArray{T, N}
    fbr::Fbr
end

FiberArray(fbr::Fbr) where {Fbr} = FiberArray{Fbr}(fbr)
FiberArray{Fbr}(fbr::Fbr) where {Fbr} = FiberArray{Fbr, image(fbr)}(fbr)
FiberArray{Fbr, N}(fbr::Fbr) where {Fbr, N} = FiberArray{Fbr, N, arity(fbr)}(fbr)

"""
    arity(::Fiber)

The "arity" of a fiber is the number of arguments that fiber can be indexed by
before it returns a value. 

See also: [`Base.ndims`](@ref)
"""
function arity end
Base.ndims(arr::FiberArray) = arity(arr.fbr)

"""
    image(::Fiber)

The "image" of a fiber is the smallest julia type that its values assume. 

See also: [`Base.eltype`](@ref)
"""
function image end
Base.eltype(arr::FiberArray) = image(arr.fbr)

"""
    shape(::Fiber)

The "shape" of a fiber is a tuple where each element describes the number of
distinct values that might be given as each argument to the fiber.

See also: [`Base.size`](@ref)
"""
function shape end
Base.size(arr::FiberArray) = shape(arr.fbr)

"""
    domain(::Fiber)

The "domain" of a fiber is a tuple listing the sets of distinct values that might
be given as each argument to the fiber.

See also: [`Base.axes`](@ref)
"""
function domain end
Base.axes(arr::FiberArray) = domain(arr.fbr)

function Base.getindex(arr::FiberArray, idxs::Integer...) where {Tv, N}
    arr.fbr(idxs...)
end

"""
    default(fbr)

The default for a fiber is the value the fiber will have after initialization.
This could be a scalar or another fiber. This value is most often zero or the
fiber itself.

See also: [`initialize`](@ref)
"""
function default end


"""
    initialize!(fbr, ctx, mode)

Initialize the virtual fiber to it's default value in the context `ctx` with
access mode `mode`. Return the new fiber object.
"""
function initialize!(fbr::VirtualFiber, ctx::LowerJulia, mode, idxs...)
    fbr = VirtualFiber(initialize_level!(fbr, ctx, mode), fbr.env)
    if mode isa Union{Write, Update}
        assemble!(fbr, ctx, mode)
    end
    return refurl(fbr, ctx, mode, idxs...)
end

"""
    initialize_level!(fbr, ctx, mode)

Initialize the level within the virtual fiber to it's default value in the
context `ctx` with access mode `mode`. Return the new level.
"""
function initialize_level! end

initialize_level!(fbr, ctx, mode) = fbr.lvl



"""
    finalize!(fbr, ctx, mode, idxs...)

Finalize the virtual fiber in the context `ctx` with access mode `mode`. Return
the new fiber object.
"""
function finalize!(fbr::VirtualFiber, ctx::LowerJulia, mode, idxs...)
    VirtualFiber(finalize_level!(fbr, ctx, mode), fbr.env)
end

"""
    finalize_level!(fbr, ctx, mode)

Finalize the level within the virtual fiber. These are the bulk cleanup steps.
"""
function finalize_level! end

finalize_level!(fbr, ctx, mode) = fbr.lvl

function (ctx::Stylize{LowerJulia})(node::Access{<:VirtualFiber})
    if !isempty(node.idxs)
        if getunbound(node.idxs[1]) ⊆ keys(ctx.ctx.bindings)
            return SelectStyle()
        elseif ctx.root isa Loop && ctx.root.idx == get_furl_root(node.idxs[1])
            return ChunkStyle()
        end
    end
    return mapreduce(ctx, result_style, arguments(node))
end

function (ctx::Finch.SelectVisitor)(node::Access{<:VirtualFiber}, ::DefaultStyle) where {Tv, Ti}
    if !isempty(node.idxs)
        if getunbound(node.idxs[1]) ⊆ keys(ctx.ctx.bindings)
            var = Name(ctx.ctx.freshen(:s))
            ctx.idxs[var] = node.idxs[1]
            ctx.ctx.dims[getname(var)] = getdims(node.tns, ctx, node.idxs...)[1] #TODO redimensionalization
            return access(node.tns, node.mode, var, node.idxs[2:end]...)
        end
    end
    return similarterm(node, operation(node), map(ctx, arguments(node)))
end

getsites(arr::VirtualFiber) = 1:arity(arr) #TODO maybe check how deep the name is in the env first

function (ctx::Finch.ChunkifyVisitor)(node::Access{<:VirtualFiber}, ::DefaultStyle) where {Tv, Ti}
    if !isempty(node.idxs)
        if ctx.idx == get_furl_root(node.idxs[1])
            return Access(unfurl(node.tns, ctx.ctx, node.mode, node.idxs...), node.mode, node.idxs)
        end
    end
    return node
end

get_furl_root(idx) = nothing
get_furl_root(idx::Name) = idx
get_furl_root(idx::Protocol) = idx.idx

refurl(tns, ctx, mode, idxs...) = access(tns, mode, idxs...)