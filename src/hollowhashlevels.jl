struct HollowHashLevel{N, Ti<:Tuple, Tp, Tp_2, Tbl, Lvl}
    I::Ti
    tbl::Tbl
    srt::Vector{Pair{Tuple{Tp, Ti}, Tp_2}}
    pos::Vector{Tp_2}
    lvl::Lvl
end
const HollowHash = HollowHashLevel
HollowHashLevel{N}(lvl) where {N} = HollowHashLevel{N}((0 for _ in 1:N...), lvl)
HollowHashLevel{N, Ti}(lvl) where {N, Ti} = HollowHashLevel{N, Ti}((map(zero, Ti.parameters)..., ), lvl)
HollowHashLevel{N}(I::Ti, lvl) where {N, Ti} = HollowHashLevel{N, Ti}(I, lvl)
HollowHashLevel{N, Ti}(I::Ti, lvl) where {N, Ti} = HollowHashLevel{N, Ti, Int, Int}(I, lvl)
HollowHashLevel{N, Ti, Tp, Tp_2}(I::Ti, lvl) where {N, Ti, Tp, Tp_2} =
    HollowHashLevel{N, Ti, Tp, Tp_2}(I, Dict{Tp, Tuple{Ti, Tp_2}}(), lvl)
HollowHashLevel{N, Ti, Tp, Tp_2}(I::Ti, tbl::Tbl, lvl) where {N, Ti, Tp, Tp_2, Tbl} =
    HollowHashLevel{N, Ti, Tp, Tp_2, Tbl}(I, tbl, lvl)
HollowHashLevel{N, Ti}(I::Ti, tbl::Tbl, lvl) where {N, Ti, Tp, Tp_2, Tbl <: AbstractDict{Tuple{Tp, Ti}, Tp_2}} =
    HollowHashLevel{N, Ti, Tp, Tp_2, Tbl}(I, tbl, lvl)
HollowHashLevel{N, Ti, Tp, Tp_2, Tbl}(I::Ti, tbl::Tbl, lvl) where {N, Ti, Tp, Tp_2, Tbl} =
    HollowHashLevel{N, Ti, Tp, Tp_2, Tbl}(I::Ti, tbl, Vector{Pair{Tuple{Tp, Ti}, Tp_2}}(undef, 0), Vector{Tp_2}(undef, 4), lvl)
HollowHashLevel{N, Ti, Tp, Tp_2, Tbl}(I::Ti, tbl::Tbl, srt, pos, lvl::Lvl) where {N, Ti, Tp, Tp_2, Tbl, Lvl} =
    HollowHashLevel{N, Ti, Tp, Tp_2, Tbl, Lvl}(I, tbl, srt, pos, lvl)

@inline arity(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = N + arity(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))
@inline shape(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = (fbr.lvl.Is..., shape(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))...)
@inline domain(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = (map(Base.OneTo, fbr.lvl.Is)..., domain(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))...)
@inline image(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = image(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))
@inline default(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = default(Fiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, N)...)(fbr.env)))

function (fbr::Fiber{<:HollowHashLevel{N, Ti}})(i, tail...) where {N, Ti}
    if length(envdeferred(env)) == N - 1
        lvl = fbr.lvl
        q = (envposition(fbr.env), envdeferred(fbr.env)..., i)

        if !haskey(lvl.next, q)
            return default(fbr)
        else
            p = lvl.next[q]
            fbr_2 = Fiber(lvl.lvl, PositionEnvironment(p, i, fbr.env))
            return fbr_2(tail...)
        end
    else
        return Fiber(lvl, DeferredCoordinateEnvironment(i, fbr.env))
    end
end



mutable struct VirtualHollowHashLevel
    ex
    N
    Ti
    Tp
    Tp_2
    Tbl
    I
    idx_q
    lvl
end
function virtualize(ex, ::Type{HollowHashLevel{N, Ti, Tp, Tp_2, Tbl, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tp, Tp_2, Tbl, Lvl}   
    sym = ctx.freshen(tag)
    I = ctx.freshen(sym, :_I)
    idx_q = ctx.freshen(sym, :_idx_q)
    push!(ctx.preamble, quote
        $sym = $ex
        $I = $sym.I
        $idx_q = length($sym.tbl)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualHollowHashLevel(sym, N, Ti, Tp, Tp_2, Tbl, I, idx_q, lvl_2)
end
(ctx::Finch.LowerJulia)(lvl::VirtualHollowHashLevel) = lvl.ex

function reconstruct!(lvl::VirtualHollowHashLevel, ctx)
    push!(ctx.preamble, quote
        $(lvl.ex) = HollowHashLevel{$(lvl.N), $(lvl.Ti), $(lvl.Tp), $(lvl.Tp_2), $(lvl.Tbl)}(
            $(ctx(lvl.I)),
            $(lvl.ex).tbl,
            $(lvl.ex).srt,
            $(lvl.ex).pos,
            $(ctx(lvl.lvl)),
        )
    end)
end

function getsites(fbr::VirtualFiber{VirtualHollowHashLevel})
    return (map(n-> envdepth(fbr.env) + n, 1:fbr.lvl.N)..., getsites(VirtualFiber(fbr.lvl.lvl, ∘(repeated(VirtualArbitraryEnvironment, fbr.lvl.N)...)(fbr.env)))...)
end

function getdims(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode)
    ext = map(n->Extent(1, Virtual{Int}(:($(fbr.lvl.I)[$n]))), 1:fbr.lvl.N)
    dim = mode isa Read ? ext : SuggestedExtent(ext)
    (dim, getdims(VirtualFiber(fbr.lvl.lvl, VirtualArbitraryEnvironment(fbr.env)), ctx, mode)...)
end

@inline default(fbr::VirtualFiber{VirtualHollowHashLevel}) = default(VirtualFiber(fbr.lvl.lvl, ∘(repeated(VirtualArbitraryEnvironment, fbr.lvl.N)...)(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode)
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    push!(ctx.preamble, quote
        $(lvl.idx_q) = 0
        $(lvl.I) = $(lvl.Ti)($(map(n->ctx(ctx.dims[(getname(fbr), envdepth(fbr.env) + n)].stop), 1:lvl.N))...,)
        empty!($(lvl.ex).tbl)
        empty!($(lvl.ex).srt)
        empty!($(lvl.ex).pos)
    end)
    if (lvl_2 = initialize_level!(VirtualFiber(fbr.lvl.lvl, ∘(repeated(VirtualArbitraryEnvironment, lvl.N)...)(fbr.env)), ctx_2, mode)) !== nothing
        lvl = shallowcopy(lvl)
        lvl.lvl = lvl_2
    end
    reconstruct!(lvl, ctx)
    return lvl
end

function assemble!(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode)
    return nothing
end

function finalize_level!(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode)
    @assert isempty(envdeferred(fbr.env))
    push!(ctx.preamble, quote
        resize!($lvl.srt, length($lvl.tbl))
        copyto!($lvl.srt, pairs($lvl.tbl))
        sort!($lvl.srt)
    end)
    if (lvl_2 = finalize_level!(VirtualFiber(fbr.lvl.lvl, ∘(repeated(VirtualArbitraryEnvironment, lvl.N)...)(fbr.env)), ctx_2, mode)) !== nothing
        lvl = shallowcopy(lvl)
        lvl.lvl = lvl_2
        reconstruct!(lvl, ctx)
        return lvl
    else
        return nothing
    end
end

unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Read, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, walk(idx))

function unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Read, idx::Walk, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_p = ctx.freshen(tag, :_p)
    my_p1 = ctx.freshen(tag, :_p1)
    my_i1 = ctx.freshen(tag, :_i1)

    Thunk(
        preamble = quote
            $my_p = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_p1 = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_p < $my_p1
                $my_i = $(lvl.ex).srt[$my_p][1]
                $my_i1 = $(lvl.ex).srt[$my_p1 - 1][1]
            else
                $my_i = 1
                $my_i1 = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (start) -> my_i1,
                body = (start, step) -> Stepper(
                    guard = (start) -> :($my_p < $my_p1),
                    stride = (start) -> my_i,
                    body = (start, step) -> Thunk(
                        body = Cases([
                            :($step < $my_i) =>
                                Run(
                                    body = default(fbr),
                                ),
                            true =>
                                Thunk(
                                    body = Spike(
                                        body = default(fbr),
                                        tail = access(VirtualFiber(lvl.lvl, PositionEnvironment(Virtual{lvl.Ti}(my_p), Virtual{lvl.Ti}(my_i), fbr.env)), mode, idxs...),
                                    ),
                                    epilogue = quote
                                        while $my_p < $my_p1 && $(lvl.ex).srt[$my_p][1] == $my_i
                                            $my_p += 1
                                        end
                                        $my_i = $(lvl.ex).srt[$my_p][1]
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

function unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Read, idx::Union{Follow}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    p = ctx.freshen(tag, :_p)

    Leaf(
        body = (i) -> Thunk(
            preamble = quote
                $p = $lvl.tbl[$(map(ctx, envdeferred(fbr.env))..., ctx(i))]
            end,
            body = access(VirtualFiber(lvl.lvl, PositionEnvironment(Virtual{lvl.Tp_2}(my_p), i, fbr.env)), mode, idxs...)
        )
    )
end

unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Union{Write, Update}, idx::Name, idxs...) =
    unfurl(fbr, ctx, mode, laminate(idx), idxs...)

function unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Union{Write, Update}, idx::Union{Name, Extrude, Laminate}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_p = ctx.freshen(tag, :_p)
    my_p1 = ctx.freshen(tag, :_p1)
    my_i1 = ctx.freshen(tag, :_i1)
    lvl_2 = nothing

    Thunk(
        preamble = quote
            $my_p = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
        end,
        body = AcceptSpike(
            val = default(fbr),
            tail = (ctx, idx) -> Thunk(
                preamble = quote
                    $(scope(ctx) do ctx_2 
                        if (lvl_2 = assemble!(VirtualFiber(fbr.lvl.lvl, ∘(repeated(ArbitraryEnvironment, lvl.N - 1)..., identity)(VirtualMaxPositionEnvironment(q, fbr.env))), ctx_2, mode))
                            lvl_2 = lvl.lvl
                        end
                        quote end
                    end)
                end,
                body = access(VirtualFiber(lvl_2, PositionEnvironment(Virtual{lvl.Ti}(my_p), idx, fbr.env)), mode, idxs...),
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
            $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1] = $my_p
        end
    )
end