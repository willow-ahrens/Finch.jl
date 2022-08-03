struct HollowHashLevel{N, Ti<:Tuple, Tp, T_q, Tbl, Lvl}
    I::Ti
    tbl::Tbl
    srt::Vector{Pair{Tuple{Tp, Ti}, T_q}}
    pos::Vector{T_q}
    lvl::Lvl
end
const HollowHash = HollowHashLevel
HollowHashLevel{N}(lvl) where {N} = HollowHashLevel{N}(((0 for _ in 1:N)...,), lvl)
HollowHashLevel{N, Ti}(lvl) where {N, Ti} = HollowHashLevel{N, Ti}((map(zero, Ti.parameters)..., ), lvl)
HollowHashLevel{N}(I::Ti, lvl) where {N, Ti} = HollowHashLevel{N, Ti}(I, lvl)
HollowHashLevel{N, Ti}(I::Ti, lvl) where {N, Ti} = HollowHashLevel{N, Ti, Int, Int}(I, lvl)
HollowHashLevel{N, Ti, Tp, T_q}(I::Ti, lvl) where {N, Ti, Tp, T_q} =
    HollowHashLevel{N, Ti, Tp, T_q}(I, Dict{Tuple{Tp, Ti}, T_q}(), lvl)
HollowHashLevel{N, Ti, Tp, T_q}(I::Ti, tbl::Tbl, lvl) where {N, Ti, Tp, T_q, Tbl} =
    HollowHashLevel{N, Ti, Tp, T_q, Tbl}(I, tbl, lvl)
HollowHashLevel{N, Ti}(I::Ti, tbl::Tbl, lvl) where {N, Ti, Tp, T_q, Tbl <: AbstractDict{Tuple{Tp, Ti}, T_q}} =
    HollowHashLevel{N, Ti, Tp, T_q, Tbl}(I, tbl, lvl)
#TODO it would be best if we could supply defaults all at once.
HollowHashLevel{N, Ti, Tp, T_q, Tbl}(I::Ti, tbl::Tbl, lvl) where {N, Ti, Tp, T_q, Tbl} =
    HollowHashLevel{N, Ti, Tp, T_q, Tbl}(I::Ti, tbl, Vector{Pair{Tuple{Tp, Ti}, T_q}}(undef, 0), T_q[1, 1, 2:17...], lvl) 
HollowHashLevel{N, Ti, Tp, T_q, Tbl}(I::Ti, tbl::Tbl, srt, pos, lvl::Lvl) where {N, Ti, Tp, T_q, Tbl, Lvl} =
    HollowHashLevel{N, Ti, Tp, T_q, Tbl, Lvl}(I, tbl, srt, pos, lvl)

"""
`f_code(h)` = [HollowHashLevel](@ref).
"""
f_code(::Val{:h}) = HollowHash
summary_f_code(lvl::HollowHashLevel{N}) where {N} = "h{$N}($(summary_f_code(lvl.lvl)))"
similar_level(lvl::HollowHashLevel{N}) where {N} = HollowHashLevel{N}(similar_level(lvl.lvl))
similar_level(lvl::HollowHashLevel{N}, tail...) where {N} = HollowHashLevel{N}(ntuple(n->tail[n], N), similar_level(lvl.lvl, tail[N + 1:end]...))

function Base.show(io::IO, lvl::HollowHashLevel{N}) where {N}
    print(io, "HollowHash{$N}(")
    print(io, lvl.I)
    print(io, ", ")
    if get(io, :compact, true)
        print(io, "…")
    else
        print(io, typeof(lvl.tbl))
        print(io, "(…), ")
        show_region(io, lvl.srt)
        print(io, ", ")
        show_region(io, lvl.pos)
    end
    print(io, ", ")
    show(io, lvl.lvl)
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:HollowHashLevel{N}}) where {N}
    p = envposition(fbr.env)
    crds = fbr.lvl.srt[fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1]
    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "["); foreach(n -> (show(io, crd[1][2][n]); print(io, ", ")), 1:N-1); show(io, crd[1][2][N]); print(io, "]"))
    get_coord(crd) = crd[1][2]

    dims = shape(fbr)
    print(io, "│ " ^ depth); print(io, "HollowHash ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); foreach(dim -> (print(io, "1:"); show(io, dim); print(io, "×")), dims[1:N-1]); print(io, "1:"); show(io, dims[end]); println(io, "]")
    display_fiber_data(io, mime, fbr, N, crds, print_coord, get_coord)
end

@inline arity(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = N + arity(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))
@inline shape(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = (fbr.lvl.I..., shape(Fiber(fbr.lvl.lvl,  (Environment^N)(fbr.env)))...)
@inline domain(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = (map(Base.OneTo, fbr.lvl.I)..., domain(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))...)
@inline image(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = image(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))
@inline default(fbr::Fiber{<:HollowHashLevel{N}}) where {N} = default(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))

(fbr::Fiber{<:HollowHashLevel})() = fbr
function (fbr::Fiber{<:HollowHashLevel{N, Ti}})(i, tail...) where {N, Ti}
    lvl = fbr.lvl
    if length(envdeferred(fbr.env)) == N - 1
        p = (envposition(envexternal(fbr.env)), (envdeferred(fbr.env)..., i))

        if !haskey(lvl.tbl, p)
            return default(fbr)
        else
            q = lvl.tbl[p]
            fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
            return fbr_2(tail...)
        end
    else
        fbr_2 = Fiber(lvl, Environment(index=i, parent=fbr.env, internal=true))
        fbr_2(tail...)
    end
end



mutable struct VirtualHollowHashLevel
    ex
    N
    Ti
    Tp
    T_q
    Tbl
    I
    P
    pos_alloc
    idx_alloc
    lvl
end
function virtualize(ex, ::Type{HollowHashLevel{N, Ti, Tp, T_q, Tbl, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tp, T_q, Tbl, Lvl}   
    sym = ctx.freshen(tag)
    I = map(n->Virtual{Int}(:($sym.I[$n])), 1:N)
    P = ctx.freshen(sym, :_P)
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    idx_alloc = ctx.freshen(sym, :_idx_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $P = length($sym.pos)
        $pos_alloc = $P
        $idx_alloc = length($sym.tbl)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualHollowHashLevel(sym, N, Ti, Tp, T_q, Tbl, I, P, pos_alloc, idx_alloc, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualHollowHashLevel)
    quote
        $HollowHashLevel{$(lvl.N), $(lvl.Ti), $(lvl.Tp), $(lvl.T_q), $(lvl.Tbl)}(
            ($(map(ctx, lvl.I)...),),
            $(lvl.ex).tbl,
            $(lvl.ex).srt,
            $(lvl.ex).pos,
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_str(lvl::VirtualHollowHashLevel) = "h$(lvl.N)$(summary_f_str(lvl.lvl))"
summary_f_str_args(lvl::VirtualHollowHashLevel) = summary_f_str_args(lvl.lvl)

function getsites(fbr::VirtualFiber{VirtualHollowHashLevel})
    d = envdepth(fbr.env)
    return [(d + 1:d + fbr.lvl.N)..., getsites(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^fbr.lvl.N)(fbr.env)))...]
end

function getdims(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx::LowerJulia, mode)
    ext = map(stop->Extent(1, stop), fbr.lvl.I)
    if mode != Read()
        ext = map(suggest, ext)
    end
    (ext..., getdims(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^fbr.lvl.N)(fbr.env)), ctx, mode)...)
end

function setdims!(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx::LowerJulia, mode, dims...)
    fbr.lvl.I = map(getstop, dims[1:fbr.lvl.N])
    fbr.lvl.lvl = setdims!(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^fbr.lvl.N)(fbr.env)), ctx, mode, dims[fbr.lvl.N + 1:end]...).lvl
    fbr
end

@inline default(fbr::VirtualFiber{VirtualHollowHashLevel}) = default(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^fbr.lvl.N)(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    my_p = ctx.freshen(lvl.ex, :_p)
    push!(ctx.preamble, quote
        $(lvl.idx_alloc) = 0
        empty!($(lvl.ex).tbl)
        empty!($(lvl.ex).srt)
        $(lvl.pos_alloc) = $Finch.refill!($(lvl.ex).pos, 0, 0, 5)
        $(lvl.ex).pos[1] = 1
        $(lvl.P) = 0
    end)
    lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^lvl.N)(fbr.env)), ctx, mode)
    return lvl
end

interval_assembly_depth(lvl::VirtualHollowHashLevel) = Inf #This level supports interval assembly, and this assembly isn't recursive.

#This function is quite simple, since HollowHashLevels don't support reassembly.
#TODO what would it take to support reassembly?
function assemble!(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.P) = max($p_stop, $(lvl.P))
        $(lvl.pos_alloc) < ($(lvl.P) + 1) && ($(lvl.pos_alloc) = Finch.refill!($(lvl.ex).pos, 0, $(lvl.pos_alloc), $(lvl.P) + 1))
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    my_p = ctx.freshen(lvl.ex, :_p)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).srt, length($(lvl.ex).tbl))
        copyto!($(lvl.ex).srt, pairs($(lvl.ex).tbl))
        sort!($(lvl.ex).srt)
        #resize!($(lvl.ex).pos, $(lvl.P) + 1)
        for $my_p = 1:$(lvl.P)
            $(lvl.ex).pos[$my_p + 1] += $(lvl.ex).pos[$my_p]
        end
    end)
    lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^lvl.N)(fbr.env)), ctx, mode)
    return lvl
end

unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Read, idx, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, walk))

function unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Read, idx::Protocol{<:Any, Walk}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_step = ctx.freshen(tag, :_q_step)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)
    R = length(envdeferred(fbr.env)) + 1
    @assert R == 1 || (envgetstart(fbr.env) !== nothing && envgetstop(fbr.env) !== nothing)
    if R == 1
        q_start = Virtual{lvl.Tp}(:($(lvl.ex).pos[$(ctx(envposition(fbr.env)))]))
        q_stop = Virtual{lvl.Tp}(:($(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]))
    else
        q_start = envgetstart(fbr.env)
        q_stop = envgetstop(fbr.env)
    end

    body = Thunk(
        preamble = quote
            $my_q = $(ctx(q_start))
            $my_q_stop = $(ctx(q_stop))
            if $my_q < $my_q_stop
                $my_i = last(first($(lvl.ex).srt[$my_q]))[$R]
                $my_i_stop = last(first($(lvl.ex).srt[$my_q_stop - 1]))[$R]
            else
                $my_i = 1
                $my_i_stop = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> my_i_stop,
                body = (start, step) -> Stepper(
                    seek = (ctx, ext) -> quote
                        $my_q_step = $my_q + 1
                        while $my_q_step < $my_q_stop && last(first($(lvl.ex).srt[$my_q_step]))[$R] < $(ctx(getstart(ext)))
                            $my_q_step += 1
                        end
                    end,
                    body = Thunk(
                        preamble = :(
                            $my_i = last(first($(lvl.ex).srt[$my_q]))[$R]
                        ),
                        body = if R == lvl.N
                            Step(
                                stride =  (ctx, idx, ext) -> my_i,
                                chunk = Spike(
                                    body = Simplify(default(fbr)),
                                    tail = begin
                                        env_2 = VirtualEnvironment(
                                        position=Virtual{lvl.Ti}(:(last($(lvl.ex).srt[$my_q])[$R])),
                                        index=Virtual{lvl.Ti}(my_i),
                                        parent=fbr.env)
                                        refurl(VirtualFiber(lvl.lvl, env_2), ctx, mode, idxs...)
                                    end,
                                ),
                                next =  (ctx, idx, ext) -> quote
                                    $my_q += 1
                                end
                            )
                        else
                            Step(
                                stride =  (ctx, idx, ext) -> my_i,
                                chunk = Spike(
                                    body = Simplify(default(fbr)),
                                    tail = begin
                                        env_2 = VirtualEnvironment(
                                            start=Virtual{lvl.Ti}(my_q),
                                            stop=Virtual{lvl.Ti}(my_q_step),
                                            index=Virtual{lvl.Ti}(my_i),
                                            parent=fbr.env,
                                            internal=true)
                                        refurl(VirtualFiber(lvl, env_2), ctx, mode, idxs...)
                                    end,
                                ),
                                next =  (ctx, idx, ext) -> quote
                                    $my_q = $my_q_step
                                    $my_q_step = $my_q + 1
                                    while $my_q_step < $my_q_stop && last(first($(lvl.ex).srt[$my_q_step]))[$R] == $my_i
                                        $my_q_step += 1
                                    end
                                end
                            )
                        end
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(default(fbr)))
            )
        ])
    )

    exfurl(body, ctx, mode, idx.idx)
end

function unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Read, idx::Protocol{<:Any, Follow}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    R = length(envdeferred(fbr.env)) + 1
    my_key = cgx.freshen(tag, :_key)
    my_q = cgx.freshen(tag, :_q)

    if R == lvl.N
        body = Leaf(
            body = (i) -> Thunk(
                preamble = quote
                    $my_key = ($(ctx(envposition(envexternal(fbr.env)))), ($(map(ctx, envdeferred(fbr.env))...), $(ctx(i))))
                    $my_q = get($(lvl.ex).tbl, $my_key, 0)
                end,
                body = Cases([
                    :($my_q != 0) => refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Tq_2}(my_q), index=i, parent=fbr.env)), ctx, mode, idxs...),
                    true => Simplify(default(fbr))
                ])
            )
        )
    else
        body = Leaf(
            body = (i) -> refurl(VirtualFiber(lvl, VirtualEnvironment(index=i, parent=fbr.env, internal=true)), ctx, mode, idxs...)
        )
    end

    exfurl(body, ctx, mode, idx.idx)
end

unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Union{Write, Update}, idx, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, laminate), idxs...)

hasdefaultcheck(lvl::VirtualHollowHashLevel) = true

function unfurl(fbr::VirtualFiber{VirtualHollowHashLevel}, ctx, mode::Union{Write, Update}, idx::Protocol{<:Any, <:Union{Extrude, Laminate}}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    R = length(envdeferred(fbr.env)) + 1
    my_key = ctx.freshen(tag, :_key)
    my_q = ctx.freshen(tag, :_q)
    my_guard = ctx.freshen(tag, :_guard)

    if R == lvl.N
        body = Thunk(
            preamble = quote
                $my_q = $(lvl.ex).pos[$(ctx(envposition(envexternal(fbr.env))))]
            end,
            body = AcceptSpike(
                val = default(fbr),
                tail = (ctx, idx) -> Thunk(
                    preamble = quote
                        $my_guard = true
                        $my_key = ($(ctx(envposition(envexternal(fbr.env)))), ($(map(ctx, envdeferred(fbr.env))...), $(ctx(idx))))
                        $my_q = get($(lvl.ex).tbl, $my_key, $(lvl.idx_alloc) + 1)
                        if $(lvl.idx_alloc) < $my_q 
                            $(contain(ctx) do ctx_2 
                                #THIS code reassembles every time. TODO
                                assemble!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(position=my_q, parent=(VirtualEnvironment^(lvl.N - 1))(fbr.env))), ctx_2, mode)
                                quote end
                            end)
                        end
                    end,
                    body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=Virtual{lvl.Ti}(my_q), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode, idxs...),
                    epilogue = begin
                        body = quote
                            $(lvl.idx_alloc) = $my_q
                            $(lvl.ex).tbl[$my_key] = $(lvl.idx_alloc)
                            $(lvl.ex).pos[$(ctx(envposition(envexternal(fbr.env)))) + 1] += 1
                        end
                        if envdefaultcheck(fbr.env) !== nothing
                            body = quote
                                $body
                                $(envdefaultcheck(fbr.env)) = false
                            end
                        end
                        if hasdefaultcheck(lvl.lvl)
                            body = quote
                                if !$(my_guard)
                                    $body
                                end
                            end
                        end
                        body
                    end
                )
            )
        )
    else
        body = Leaf(
            body = (i) -> refurl(VirtualFiber(lvl, VirtualEnvironment(index=i, parent=fbr.env, internal=true)), ctx, mode, idxs...)
        )
    end

    exfurl(body, ctx, mode, idx.idx)
end