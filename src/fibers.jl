export HollowListLevel
export SolidLevel
export ElementLevel

struct Fiber{Tv, N, R, Lvls<:Tuple, Poss<:Tuple, Idxs<:Tuple} <: AbstractArray{Tv, N}
    lvls::Lvls
    poss::Poss
    idxs::Idxs
end

Fiber(lvls) = Fiber{valtype(last(lvls))}(lvls)
Fiber{Tv}(lvls) where {Tv} = Fiber{Tv, length(lvls) - 1, 1}(lvls, (1,), ())
Fiber{Tv, N, R}(lvls, poss, idxs) where {Tv, N, R} = Fiber{Tv, N, R, typeof(lvls), typeof(poss), typeof(idxs)}(lvls, poss, idxs)

Base.size(fbr::Fiber{Tv, N, R}) where {Tv, N, R} = map(dimension, fbr.lvls[R:end-1])

function Base.getindex(fbr::Fiber{Tv, N}, idxs::Vararg{<:Any, N}) where {Tv, N}
    readindex(fbr, idxs...)
end

function readindex(fbr::Fiber{Tv, N, R}, idxs...) where {Tv, N, R}
    unfurl(fbr.lvls[R], fbr, idxs...)
end

function refurl(fbr::Fiber{Tv, N, R}, p, i) where {Tv, N, R}
    return Fiber{Tv, N - 1, R + 1}(fbr.lvls, (fbr.poss..., p), (fbr.idxs..., i))
end



mutable struct VirtualFiber
    name
    ex
    N
    Tv
    R
    lvls::Vector{Any}
    poss::Vector{Any}
    idxs::Vector{Any}
end

(ctx::Finch.LowerJulia)(arr::VirtualFiber) = arr.ex

isliteral(::VirtualFiber) = false

function make_style(root::Loop, ctx::Finch.LowerJulia, node::Access{VirtualFiber})
    if isempty(node.idxs)
        return AccessStyle()
    elseif getname(root.idxs[1]) == getname(node.idxs[1])
        return ChunkStyle()
    else
        return DefaultStyle()
    end
end

function make_style(root, ctx::Finch.LowerJulia, node::Access{VirtualFiber})
    if isempty(node.idxs)
        return AccessStyle()
    else
        return DefaultStyle()
    end
end

function getdims(arr::VirtualFiber, ctx::LowerJulia, mode)
    @assert arr.R == 1
    return map(1:arr.N) do R
        getdims_level!(arr.lvls[R], arr, R, ctx, mode)
    end
end

function initialize!(arr::VirtualFiber, ctx::LowerJulia, mode)
    @assert arr.R == 1
    lvls_2 = map(1:arr.N + 1) do R
        initialize_level!(arr.lvls[R], arr, R, ctx, mode)
    end
    if !all(isnothing, lvls_2)
        lvls_3 = map(zip(arr.lvls, lvls_2)) do (lvl, lvl_2)
            lvl_2 === nothing ? lvl : lvl_2
        end
        arr_2 = deepcopy(arr)
        arr_2.lvls = lvls_3
        push!(ctx.preamble, quote
            $(arr_2.ex) = Fiber{$(arr.Tv), $(arr.N), $(arr.R)}(
                ($(map(ctx, lvls_3)...),),
                ($(map(ctx, arr.poss)...),),
                ($(map(ctx, arr.idxs)...),),
            )
        end)
        arr_2
    else
        arr
    end
end

getsites(arr::VirtualFiber) = 1:arr.N
getname(arr::VirtualFiber) = arr.name
setname(arr::VirtualFiber, name) = (arr_2 = deepcopy(arr); arr_2.name = name; arr_2)

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