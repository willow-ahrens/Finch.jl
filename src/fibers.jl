"""
    RootEnvironment()

An environment can be thought of as the argument to a level that yeilds a fiber.
Environments also allow parents levels to pass attributes to their children.  By
default, the top level has access to the RootEnvironment.
"""
struct RootEnvironment end

envposition(env::RootEnvironment) = 1

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

"""
    ArbitraryEnvironment(env)

An environment that abstracts over all positions, not making a choice. The
parent environment is `env`.

See also: [`getparent`](@ref)
"""
struct ArbitraryEnvironment{Env}
    env::Env
end

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



"""
    Fiber(lvl, env=RootEnvironment())

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
Fiber{Lvl}(lvl::Lvl, env::Env=RootEnvironment()) where {Lvl, Env} = Fiber{Lvl, Env}(lvl, env)

fiber(lvl) = FiberArray(Fiber(lvl))



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

#=

"""
    default(fbr)

The default for a fiber is the value the fiber will have after initialization.
This could be a scalar or another fiber. This value is most often zero.

See also: [`initialize`](@ref)
"""
default(fbr::Fiber) = default(fbr.lvl)

struct VirtualRootEnvironment end

envposition(env::RootEnvironment) = 1

"""
    PositionEnvironment(pos, idx, env)

An environment that holds a position `pos`, corresponding coordinate `idx`, and parent
environment `env`.

See also: [`envposition`](@ref), [`envcoordinate`](@ref), [`getparent`](@ref)
"""
struct PositionVirtualEnvironment
    pos::Tp
    idx::Ti
    env::Env
end

"""
    ArbitraryEnvironment(env)

An environment that abstracts over all positions, not making a choice. The
parent environment is `env`.

See also: [`getparent`](@ref)
"""
struct ArbitraryVirtualEnvironment
    env::Env
end

"""
    VirtualFiber(name, ex, lvl, env)

A virtual fiber is the avatar of a fiber for the purposes of compilation. Two
fibers should share a `name` only if they hold the same data. `ex` is a julia
expression identifying the fiber, `lvl` is a virtual object representing the level nest and `env`
is a virtual object representing the environment.
"""
mutable struct VirtualFiber{Lvl, Env}
    lvl::Lvl
    Env::Env
end

(ctx::Finch.LowerJulia)(arr::VirtualFiber) = arr.ex

isliteral(::VirtualFiber) = false

"""
    initialize!(fbr, ctx, mode)

Initialize the virtual fiber to it's default value in the context `ctx` with
access mode `mode`. Return `nothing` if the fiber instance is unchanged, or
the new fiber object otherwise.
"""
function initialize!(fbr::VirtualFiber, ctx, mode)
    lvl = initialize_level!(fbr, ctx, mode)
    if lvl === nothing
        return nothing
    else
        return Fiber(lvl, fbr.env)
    end
end

"""
    initialize_level!(fbr, ctx, mode)

Initialize the level within the virtual fiber to it's default value in the
context `ctx` with access mode `mode`. Return `nothing` if the fiber instance is
unchanged, or the new level otherwise.
"""
function initialize_level! end




function make_style(root::Loop, ctx::Finch.LowerJulia, node::Access{<:VirtualFiber})
    if isempty(node.idxs)
        return AccessStyle()
    elseif getname(root.idxs[1]) == getname(node.idxs[1])
        return ChunkStyle()
    else
        return DefaultStyle()
    end
end

function make_style(root, ctx::Finch.LowerJulia, node::Access{<:VirtualFiber})
    if isempty(node.idxs)
        return AccessStyle()
    else
        return DefaultStyle()
    end
end

getsites(arr::VirtualFiber) = 1:ndims(arr)
getname(arr::VirtualFiber) = arr.name
setname(arr::VirtualFiber, name) = (arr_2 = deepcopy(arr); arr_2.name = name; arr_2)

#TODO Not sure about anything after this line
getdims(arr::VirtualFiber, ctx::LowerJulia, mode) = getdims(arr.lvl, ctx, mode)

initialize!(arr::VirtualFiber, ctx::LowerJulia, mode) = initialize!(arr.lvl, ctx, mode)

virtual_assemble(tns, ctx, q) =
    virtual_assemble(tns, ctx, [nothing for _ = 1:tns.R], q)
virtual_assemble(tns::VirtualFiber, ctx, qoss, q) =
    virtual_assemble(tns.lvls[length(qoss) + 1], tns, ctx, vcat(qoss, [q]), q)

function virtualize(ex, ::Type{<:Fiber{Tv, N, R, Lvls, Poss, Idxs}}, ctx, tag=:tns) where {Tv, N, R, Lvls, Poss, Idxs}
    sym = ctx.freshen(tag)
    push!(ctx.preamble, :($sym = $ex))
    lvls = map(enumerate(Lvls.parameters)) do (n, Lvl)
        virtualize(:($sym.lvls[$n]), Lvl, ctx, Symbol(tag, :_lvl, n))
    end
    poss = map(enumerate(Poss.parameters)) do (n, Pos)
        n == 1 ? 1 : virtualize(:($sym.poss[$n]), Pos, ctx)
    end
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($sym.idxs[$n]), Idx, ctx)
    end
    VirtualFiber(tag, sym, N, Tv, R, lvls, poss, idxs)
end

function virtual_refurl(fbr::VirtualFiber, p, i, mode, tail...)
    res = deepcopy(fbr)
    res.N = fbr.N - 1
    res.R = fbr.R + 1
    push!(res.poss, p)
    push!(res.idxs, i)
    return Access(res, mode, Any[tail...])
end

function (ctx::Finch.ChunkifyVisitor)(node::Access{VirtualFiber}, ::DefaultStyle) where {Tv, Ti}
    if getname(ctx.idx) == getname(node.idxs[1])
        Access(virtual_unfurl(node.tns.lvls[node.tns.R], node.tns, ctx.ctx, node.mode, node.idxs...), node.mode, node.idxs)
    else
        node
    end
end

function (ctx::Finch.AccessVisitor)(node::Access{VirtualFiber}, ::DefaultStyle) where {Tv, Ti}
    if isempty(node.idxs)
        virtual_unfurl(node.tns.lvls[node.tns.R], node.tns, ctx.ctx, node.mode)
    else
        node
    end
end




struct FiberArray{Tv, N, Fbr} <: AbstractArray{Tv, N}
    fbr::Fbr
end
#TODO eventually we should generate the getindex call
function Base.getindex(fbr::Fiber{Tv, N}, idxs::Vararg{<:Any, N}) where {Tv, N}
    readindex(fbr, idxs...)
end
readindex(fbr) = fbr
=#