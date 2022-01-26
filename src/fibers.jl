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



struct HollowListLevel{D, Tv, Ti}
    I::Ti
    pos::Vector{Ti}
    idx::Vector{Ti}
end
const HollowList = HollowListLevel

HollowListLevel{D}(args...) where {D} = HollowListLevel{D, typeof(D)}(args...)
HollowListLevel{D, Tv}(I::Ti) where {D, Tv, Ti} = HollowListLevel{D, Tv, Ti}(I)
HollowListLevel{D, Tv}(I::Ti, pos, idx) where {D, Tv, Ti} = HollowListLevel{D, Tv, Ti}(I, pos, idx)
HollowListLevel{D, Tv, Ti}(I::Ti) where {D, Tv, Ti} = HollowListLevel{D, Tv, Ti}(I, Vector{Ti}(undef, 4), Vector{Ti}(undef, 4))

dimension(lvl::HollowListLevel) = lvl.I
cardinality(lvl::HollowListLevel) = pos[end] - 1

function unfurl(lvl::HollowListLevel{D, Tv, Ti}, fbr::Fiber{Tv, N, R}, i, tail...) where {D, Tv, Ti, N, R}
    q = fbr.poss[R]
    r = searchsorted(@view(lvl.idx[lvl.pos[q]:lvl.pos[q + 1] - 1]), i)
    p = lvl.pos[q] + first(r) - 1
    length(r) == 0 ? D : readindex(refurl(fbr, p, i), tail...)
end



struct SolidLevel{Ti}
    I::Ti
end
const Solid = SolidLevel

dimension(lvl::SolidLevel) = lvl.I
cardinality(lvl::SolidLevel) = lvl.I

function unfurl(lvl::SolidLevel{Ti}, fbr::Fiber{Tv, N, R}, i, tail...) where {Tv, Ti, N, R}
    q = fbr.poss[R]
    p = (q - 1) * lvl.I + i
    readindex(refurl(fbr, p, i), tail...)
end



struct ElementLevel{D, Tv}
    val::Vector{Tv}
end
ElementLevel{D}(args...) where {D} = ElementLevel{D, typeof(D)}(args...)
ElementLevel{D, Tv}() where {D, Tv} = ElementLevel{D, Tv}(Vector{Tv}(undef, 4))
const Element = ElementLevel

@inline valtype(lvl::ElementLevel{D, Tv}) where {D, Tv} = Tv

function unfurl(lvl::ElementLevel, fbr::Fiber{Tv, N, R}) where {Tv, N, R}
    q = fbr.poss[R]
    return lvl.val[q]
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

Pigeon.isliteral(::VirtualFiber) = false

function Pigeon.make_style(root::Loop, ctx::Finch.LowerJuliaContext, node::Access{VirtualFiber})
    if isempty(node.idxs)
        return AccessStyle()
    elseif getname(root.idxs[1]) == getname(node.idxs[1])
        return ChunkStyle()
    else
        return DefaultStyle()
    end
end

function Pigeon.make_style(root, ctx::Finch.LowerJuliaContext, node::Access{VirtualFiber})
    if isempty(node.idxs)
        return AccessStyle()
    else
        return DefaultStyle()
    end
end

function Pigeon.lower_axes(arr::VirtualFiber, ctx::LowerJuliaContext) where {T <: AbstractArray}
    dims = map(i -> ctx.freshen(arr.name, :_, i, :_stop), 1:arr.N)
    for (dim, lvl) in zip(dims, arr.lvls)
        #Could unroll more manually, but I'm not convinced it's worth it.
        push!(ctx.preamble, :($dim = dimension($(lvl.ex)))) #TODO we don't know if every level has a .ex
    end
    return map(i->Extent(1, Virtual{Int}(dims[i])), 1:arr.N)
end

function virtual_initialize!(arr::VirtualFiber, ctx::LowerJuliaContext)
    @assert arr.R == 1
    N = arr.N
    thunk = Expr(:block)
    for R = 1:N + 1
        push!(thunk.args, virtual_initialize_level!(arr.lvls[R], arr, ctx))
        arr.R += 1
        arr.N -= 1
    end
    arr.N = N
    arr.R = 1
    push!(thunk.args, virtual_assemble(arr, ctx, 1))
    return thunk
end

Pigeon.getsites(arr::VirtualFiber) = 1:arr.N
Pigeon.getname(arr::VirtualFiber) = arr.name

virtual_assemble(tns, ctx, q) =
    virtual_assemble(tns, ctx, [nothing for _ = 1:tns.R], q)
virtual_assemble(tns::VirtualFiber, ctx, qoss, q) =
    virtual_assemble(tns.lvls[length(qoss) + 1], tns::VirtualFiber, ctx, vcat(qoss, [q]), q)

function virtualize(ex, ::Type{<:Fiber{Tv, N, R, Lvls, Poss, Idxs}}, ctx, tag=:tns) where {Tv, N, R, Lvls, Poss, Idxs}
    sym = ctx.freshen(:tns_, tag)
    push!(ctx.preamble, :($sym = $ex))
    lvls = map(enumerate(Lvls.parameters)) do (n, Lvl)
        virtualize(:($sym.lvls[$n]), Lvl, ctx)
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

function Pigeon.visit!(node::Access{VirtualFiber}, ctx::Finch.ChunkifyContext, ::Pigeon.DefaultStyle) where {Tv, Ti}
    if getname(ctx.idx) == getname(node.idxs[1])
        Access(virtual_unfurl(node.tns.lvls[node.tns.R], node.tns, ctx.ctx, node.mode, node.idxs...), node.mode, node.idxs)
    else
        node
    end
end

function Pigeon.visit!(node::Access{VirtualFiber}, ctx::Finch.AccessContext, ::Pigeon.DefaultStyle) where {Tv, Ti}
    if isempty(node.idxs)
        virtual_unfurl(node.tns.lvls[node.tns.R], node.tns, ctx.ctx, node.mode)
    else
        node
    end
end

struct VirtualHollowListLevel
    ex
    D
    Tv
    Ti
    pos_q
    idx_q
end

function virtualize(ex, ::Type{HollowListLevel{D, Tv, Ti}}, ctx) where {D, Tv, Ti}
    pos_q = ctx.freshen(:pos_q)
    idx_q = ctx.freshen(:idx_q)
    push!(ctx.preamble, quote
        $pos_q = length($ex.pos)
        $idx_q = length($ex.idx)
    end)
    VirtualHollowListLevel(ex, D, Tv, Ti, pos_q, idx_q)
end

function virtual_initialize_level!(lvl::VirtualHollowListLevel, tns, ctx)
    return quote
        if $(lvl.pos_q) < 4
            resize!($(lvl.ex).pos, 4)
        end
        $(lvl.pos_q) = 4
        $(lvl.ex).pos[1] = 1
        if $(lvl.idx_q) < 4
            resize!($(lvl.ex).idx, 4)
        end
        $(lvl.idx_q) = 4
    end
end

function virtual_assemble(lvl::VirtualHollowListLevel, tns, ctx, qoss, q)
    if q == nothing
        return quote end
    else
        return quote
            if $(lvl.pos_q) < $(ctx(q))
                resize!($(lvl.ex).pos, $(lvl.pos_q) * 4)
                $(lvl.pos_q) *= 4
            end
            $(virtual_assemble(tns, ctx, qoss, nothing))
        end
    end
end

virtual_unfurl(lvl::VirtualHollowListLevel, tns, ctx, mode::Pigeon.Read, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, walk(idx), tail...)

function virtual_unfurl(lvl::VirtualHollowListLevel, tns, ctx, mode::Pigeon.Read, idx::Walk, tail...)
    R = tns.R
    tag = Symbol(:tns_, Pigeon.getname(tns), :_, R)
    my_i = ctx.freshen(tag, :_i)
    my_p = ctx.freshen(tag, :_p)
    my_p1 = ctx.freshen(tag, :_p1)
    my_i1 = ctx.freshen(tag, :_i1)

    Thunk(
        preamble = quote
            $my_p = $(lvl.ex).pos[$(ctx(tns.poss[R]))]
            $my_p1 = $(lvl.ex).pos[$(ctx(tns.poss[R])) + 1]
            if $my_p < $my_p1
                $my_i = $(lvl.ex).idx[$my_p]
                $my_i1 = $(lvl.ex).idx[$my_p1 - 1]
            else
                $my_i = 1
                $my_i1 = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (start) -> my_i1,
                body = (start, step) -> Stepper(
                    preamble = :(
                        $my_i = $(lvl.ex).idx[$my_p]
                    ),
                    guard = (start) -> :($my_p < $my_p1),
                    stride = (start) -> my_i,
                    body = (start, step) -> Thunk(
                        body = Cases([
                            :($step < $my_i) =>
                                Run(
                                    body = lvl.D,
                                ),
                            true =>
                                Thunk(
                                    body = Spike(
                                        body = lvl.D,
                                        tail = virtual_refurl(tns, Virtual{lvl.Tv}(my_p), Virtual{lvl.Ti}(my_i), mode, tail...),
                                    ),
                                    epilogue = quote
                                        $my_p += 1
                                    end
                                ),
                        ])
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(0)
            )
        ])
    )
end

virtual_unfurl(lvl::VirtualHollowListLevel, tns, ctx, mode::Union{Pigeon.Write, Pigeon.Update}, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, extrude(idx), tail...)

function virtual_unfurl(lvl::VirtualHollowListLevel, tns, ctx, mode::Union{Pigeon.Write, Pigeon.Update}, idx::Extrude, tail...)
    R = tns.R
    tag = Symbol(:tns_, Pigeon.getname(tns), :_, R)
    my_i = ctx.freshen(tag, :_i)
    my_p = ctx.freshen(tag, :_p)
    my_p1 = ctx.freshen(tag, :_p1)
    my_i1 = ctx.freshen(tag, :_i1)

    Thunk(
        preamble = quote
            $my_p = $(lvl.ex).pos[$(ctx(tns.poss[R]))]
        end,
        body = AcceptSpike(
            val = lvl.D,
            tail = (ctx, idx) -> Thunk(
                preamble = quote
                    $(scope(ctx) do ctx2 
                        virtual_assemble(tns, ctx2, my_p)
                    end)
                end,
                body = virtual_refurl(tns, Virtual{lvl.Tv}(my_p), idx, mode, tail...),
                epilogue = quote
                    if $(lvl.idx_q) < $my_p
                        resize!($(lvl.ex).idx, $(lvl.idx_q) * 4)
                        $(lvl.idx_q) *= 4
                    end
                    $(lvl.ex).idx[$my_p] = $(Pigeon.visit!(idx, ctx))
                    $my_p += 1
                end
            )
        ),
        epilogue = quote
            $(lvl.ex).pos[$(ctx(tns.poss[R])) + 1] = $my_p
        end
    )
end

struct VirtualSolidLevel
    ex
    Ti
end

function virtualize(ex, ::Type{<:SolidLevel{Ti}}, ctx) where {Ti}
    VirtualSolidLevel(ex, Ti)
end

virtual_unfurl(lvl::VirtualSolidLevel, tns, ctx, mode::Pigeon.Read, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, follow(idx), tail...)
virtual_unfurl(lvl::VirtualSolidLevel, tns, ctx, mode::Union{Pigeon.Write, Pigeon.Update}, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, laminate(idx), tail...)

virtual_initialize_level!(lvl::VirtualSolidLevel, tns, ctx) = quote end

function virtual_assemble(lvl::VirtualSolidLevel, tns, ctx, qoss, q)
    if q == nothing
        return quote end
    else
        q2 = ctx.freshen(:tns_, getname(fbr), :_, R, :_q)
        return quote
            $q2 = ($(ctx(qoss)) - 1) * $(lvl.ex).I + $(ctx(i))
            $(virtual_assemble(tns, ctx, qoss, q2))
        end
    end
end

function virtual_unfurl(lvl::VirtualSolidLevel, fbr, ctx, mode::Union{Pigeon.Read, Pigeon.Write, Pigeon.Update}, idx::Union{Follow, Laminate, Extrude}, tail...)
    R = fbr.R
    q = fbr.poss[R]
    p = ctx.freshen(:tns_, getname(fbr), :_, R, :_p)

    if R == 1
        Leaf(
            body = (i) -> virtual_refurl(fbr, i, i, mode, tail...),
        )
    else
        Leaf(
            body = (i) -> Thunk(
                preamble = quote
                    $p = ($(ctx(q)) - 1) * $(lvl.ex).I + $(ctx(i))
                end,
                body = virtual_refurl(fbr, Virtual{lvl.Ti}(p), i, mode, tail...),
            )
        )
    end
end



struct VirtualElementLevel
    ex
    Tv
    D
    val_q
end

function virtualize(ex, ::Type{ElementLevel{D, Tv}}, ctx) where {D, Tv}
    val_q = ctx.freshen(:val_q)
    push!(ctx.preamble, quote
        $val_q = length($ex.val)
    end)
    VirtualElementLevel(ex, Tv, D, val_q)
end

function virtual_initialize_level!(lvl::VirtualElementLevel, tns, ctx)
    my_q = ctx.freshen(:q_, tns.R)
    return quote
        if $(lvl.val_q) < 4
            resize!($(lvl.ex).val, 4)
        end
        $(lvl.val_q) = 4
        for $my_q = 1:4
            $(lvl.ex).val[$my_q] = $(lvl.D)
        end
    end
end

function virtual_assemble(lvl::VirtualElementLevel, tns, ctx, qoss, q)
    if q == nothing
        return quote end
    else
        my_q = ctx.freshen(:q_, tns.R)
        return quote
            if $(lvl.val_q) < $q
                resize!($(lvl.ex).val, $(lvl.val_q) * 4)
                @simd for $my_q = $(lvl.val_q) + 1: $(lvl.val_q) * 4
                    $(lvl.ex).val[$my_q] = $(lvl.D)
                end
                $(lvl.val_q) *= 4
            end
        end
    end
end


function virtual_unfurl(lvl::VirtualElementLevel, fbr, ctx, ::Pigeon.Read)
    R = fbr.R
    val = ctx.freshen(:tns_, getname(fbr), :_val)

    Thunk(
        preamble = quote
            $val = $(lvl.ex).val[$(ctx(fbr.poss[end]))]
        end,
        body = Virtual{lvl.Tv}(val)
    )
end

function virtual_unfurl(lvl::VirtualElementLevel, fbr, ctx, ::Pigeon.Write)
    R = fbr.R
    val = ctx.freshen(:tns_, getname(fbr), :_val)

    Thunk(
        preamble = quote
            $val = nothing
        end,
        body = Virtual{lvl.Tv}(val),
        epilogue = quote
            $(lvl.ex).val[$(ctx(fbr.poss[end]))] = $val
        end,
    )
end

function virtual_unfurl(lvl::VirtualElementLevel, fbr, ctx, ::Pigeon.Update)
    R = fbr.R
    val = ctx.freshen(:tns_, getname(fbr), :_val)

    Thunk(
        preamble = quote
            $val = $(lvl.ex).val[$(ctx(fbr.poss[end]))]
        end,
        body = Virtual{lvl.Tv}(val),
        epilogue = quote
            $(lvl.ex).val[$(ctx(fbr.poss[end]))] = $val
        end,
    )
end