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

struct VirtualHollowListLevel
    ex
    D
    Tv
    Ti
    I
    pos_q
    idx_q
end

(ctx::Finch.LowerJulia)(lvl::VirtualHollowListLevel) = lvl.ex

function virtualize(ex, ::Type{HollowListLevel{D, Tv, Ti}}, ctx, tag=:lvl) where {D, Tv, Ti}
    sym = ctx.freshen(tag)
    I = ctx.freshen(tag, :_I)
    pos_q = ctx.freshen(tag, :_pos_q)
    idx_q = ctx.freshen(tag, :_idx_q)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
        $pos_q = length($sym.pos)
        $idx_q = length($sym.idx)
    end)
    VirtualHollowListLevel(sym, D, Tv, Ti, I, pos_q, idx_q)
end

function getdims_level!(lvl::VirtualHollowListLevel, arr, R, ctx, mode)
    ext = Extent(1, Virtual{Int}(lvl.I))
    return mode isa Read ? ext : SuggestedExtent(ext)
end

function initialize_level!(lvl::VirtualHollowListLevel, tns, R, ctx, mode)
    push!(ctx.preamble, quote
        if $(lvl.pos_q) < 4
            resize!($(lvl.ex).pos, 4)
        end
        $(lvl.pos_q) = 4
        $(lvl.ex).pos[1] = 1
        if $(lvl.idx_q) < 4
            resize!($(lvl.ex).idx, 4)
        end
        $(lvl.idx_q) = 4
    end)
    if mode isa Union{Write, Update}
        push!(ctx.preamble, quote
            $(lvl.I) = $(ctx(ctx.dims[(getname(tns), R)].stop))
            $(lvl.ex) = HollowListLevel{$(lvl.D), $(lvl.Tv), $(lvl.Ti)}(
                $(lvl.Ti)($(lvl.I)),
                $(lvl.ex).pos,
                $(lvl.ex).idx,
            )
        end)
        lvl
    else
        return nothing
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

virtual_unfurl(lvl::VirtualHollowListLevel, tns, ctx, mode::Read, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, walk(idx), tail...)

function virtual_unfurl(lvl::VirtualHollowListLevel, tns, ctx, mode::Read, idx::Walk, tail...)
    R = tns.R
    tag = Symbol(getname(tns), :_lvl, R)
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

virtual_unfurl(lvl::VirtualHollowListLevel, tns, ctx, mode::Union{Write, Update}, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, extrude(idx), tail...)

function virtual_unfurl(lvl::VirtualHollowListLevel, tns, ctx, mode::Union{Write, Update}, idx::Extrude, tail...)
    R = tns.R
    tag = Symbol(getname(tns), :_lvl, R)
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
                    $(lvl.ex).idx[$my_p] = $(ctx(idx))
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
    I
end

(ctx::Finch.LowerJulia)(lvl::VirtualSolidLevel) = lvl.ex

function virtualize(ex, ::Type{<:SolidLevel{Ti}}, ctx, tag=:lvl) where {Ti}
    sym = ctx.freshen(tag)
    I = ctx.freshen(tag, :_stop)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
    end)
    VirtualSolidLevel(sym, Ti, I)
end

virtual_unfurl(lvl::VirtualSolidLevel, tns, ctx, mode::Read, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, follow(idx), tail...)
virtual_unfurl(lvl::VirtualSolidLevel, tns, ctx, mode::Union{Write, Update}, idx::Name, tail...) =
    virtual_unfurl(lvl, tns, ctx, mode, laminate(idx), tail...)


function getdims_level!(lvl::VirtualSolidLevel, arr, R, ctx, mode)
    ext = Extent(1, Virtual{Int}(lvl.I))
    return mode isa Read ? ext : SuggestedExtent(ext)
end

function initialize_level!(lvl::VirtualSolidLevel, tns, R, ctx, mode)
    if mode isa Union{Write, Update}
        push!(ctx.preamble, quote
            $(lvl.I) = $(ctx(ctx.dims[(getname(tns), R)].stop))
            $(lvl.ex) = SolidLevel{$(lvl.Ti)}(
                $(lvl.Ti)($(lvl.I)),
            )
        end)
        lvl
    else
        return nothing
    end
end

function virtual_assemble(lvl::VirtualSolidLevel, tns, ctx, qoss, q)
    if q == nothing
        return quote end
    else
        q2 = ctx.freshen(getname(fbr), :_lvl, R, :_q)
        return quote
            $q2 = ($(ctx(qoss)) - 1) * $(lvl.ex).I + $(ctx(i))
            $(virtual_assemble(tns, ctx, qoss, q2))
        end
    end
end

function virtual_unfurl(lvl::VirtualSolidLevel, fbr, ctx, mode::Union{Read, Write, Update}, idx::Union{Follow, Laminate, Extrude}, tail...)
    R = fbr.R
    q = fbr.poss[R]
    p = ctx.freshen(getname(fbr), :_, R, :_p)

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

(ctx::Finch.LowerJulia)(lvl::VirtualElementLevel) = lvl.ex

function virtualize(ex, ::Type{ElementLevel{D, Tv}}, ctx, tag) where {D, Tv}
    sym = ctx.freshen(tag)
    val_q = ctx.freshen(tag, :_val_q)
    push!(ctx.preamble, quote
        $sym = $ex
        $val_q = length($ex.val)
    end)
    VirtualElementLevel(sym, Tv, D, val_q)
end

function initialize_level!(lvl::VirtualElementLevel, tns, R, ctx, mode)
    my_q = ctx.freshen(:lvl, tns.R, :_q)
    push!(ctx.preamble, quote
        if $(lvl.val_q) < 4
            resize!($(lvl.ex).val, 4)
        end
        $(lvl.val_q) = 4
        for $my_q = 1:4
            $(lvl.ex).val[$my_q] = $(lvl.D)
        end
    end)
    nothing
end

function virtual_assemble(lvl::VirtualElementLevel, tns, ctx, qoss, q)
    if q == nothing
        return quote end
    else
        my_q = ctx.freshen(:lvl, tns.R, :_q)
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


function virtual_unfurl(lvl::VirtualElementLevel, fbr, ctx, ::Read)
    R = fbr.R
    val = ctx.freshen(getname(fbr), :_val)

    Thunk(
        preamble = quote
            $val = $(lvl.ex).val[$(ctx(fbr.poss[end]))]
        end,
        body = Virtual{lvl.Tv}(val)
    )
end

function virtual_unfurl(lvl::VirtualElementLevel, fbr, ctx, ::Write)
    R = fbr.R
    val = ctx.freshen(getname(fbr), :_val)

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

function virtual_unfurl(lvl::VirtualElementLevel, fbr, ctx, ::Update)
    R = fbr.R
    val = ctx.freshen(getname(fbr), :_val)

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