struct SparseHashLevel{N, Ti<:Tuple, Tp, Tbl, Lvl}
    I::Ti
    tbl::Tbl
    srt::Vector{Pair{Tuple{Tp, Ti}}}
    pos::Vector{Tp}
    lvl::Lvl
end
const SparseHash = SparseHashLevel
SparseHashLevel{N}(lvl) where {N} = SparseHashLevel{N}(((0 for _ in 1:N)...,), lvl)
SparseHashLevel{N, Ti}(lvl) where {N, Ti} = SparseHashLevel{N, Ti}((map(zero, Ti.parameters)..., ), lvl)
SparseHashLevel{N, Ti, Tp}(lvl) where {N, Ti, Tp} = SparseHashLevel{N, Ti, Tp}((map(zero, Ti.parameters)..., ), lvl)
SparseHashLevel{N}(I::Ti, lvl) where {N, Ti} = SparseHashLevel{N, Ti}(I, lvl)
SparseHashLevel{N, Ti}(I, lvl) where {N, Ti} = SparseHashLevel{N, Ti, Int}(Ti(I), lvl)
SparseHashLevel{N, Ti, Tp}(I, lvl) where {N, Ti, Tp} =
    SparseHashLevel{N, Ti, Tp}(Ti(I), Dict{Tuple{Tp, Ti}, Tp}(), lvl)
SparseHashLevel{N, Ti, Tp}(I, tbl::Tbl, lvl) where {N, Ti, Tp, Tbl} =
    SparseHashLevel{N, Ti, Tp, Tbl}(Ti(I), tbl, lvl)
SparseHashLevel{N, Ti}(I, tbl::Tbl, lvl) where {N, Ti, Tp, Tbl <: AbstractDict{Tuple{Tp, Ti}}} =
    SparseHashLevel{N, Ti, Tp, Tbl}(Ti(I), tbl, lvl)
#TODO it would be best if we could supply defaults all at once.
SparseHashLevel{N, Ti, Tp, Tbl}(I, tbl::Tbl, lvl) where {N, Ti, Tp, Tbl} =
    SparseHashLevel{N, Ti, Tp, Tbl}(Ti(I), tbl, Vector{Pair{Tuple{Tp, Ti}}}(undef, 0), Tp[1, 1, 2:17...], lvl) 
SparseHashLevel{N, Ti, Tp, Tbl}(I, tbl::Tbl, srt, pos, lvl::Lvl) where {N, Ti, Tp, Tbl, Lvl} =
    SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(Ti(I), tbl, srt, pos, lvl)

"""
`f_code(sh)` = [SparseHashLevel](@ref).
"""
f_code(::Val{:sh}) = SparseHash
summary_f_code(lvl::SparseHashLevel{N}) where {N} = "sh{$N}($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SparseHashLevel{N}) where {N} = SparseHashLevel{N}(similar_level(lvl.lvl))
similar_level(lvl::SparseHashLevel{N}, tail...) where {N} = SparseHashLevel{N}(ntuple(n->tail[n], N), similar_level(lvl.lvl, tail[N + 1:end]...))

pattern!(lvl::SparseHashLevel{N, Ti, Tp, Tbl}) where {N, Ti, Tp, Tbl} = 
    SparseHashLevel{N, Ti, Tp, Tbl}(lvl.I, lvl.tbl, lvl.srt, lvl.pos, pattern!(lvl.lvl))

function Base.show(io::IO, lvl::SparseHashLevel{N, Ti}) where {N, Ti}
    if get(io, :compact, false)
        print(io, "SparseHash{$N}(")
    else
        print(io, "SparseHash{$N, $Ti}(")
    end
    print(io, lvl.I)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        print(io, typeof(lvl.tbl))
        print(io, "(…), ")
        show(io, lvl.srt)
        print(io, ", ")
        show(io, lvl.pos)
    end
    print(io, ", ")
    show(io, lvl.lvl)
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:SparseHashLevel{N}}) where {N}
    p = envposition(fbr.env)
    crds = fbr.lvl.srt[fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1]
    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "["); foreach(n -> (show(io, crd[1][2][n]); print(io, ", ")), 1:N-1); show(io, crd[1][2][N]); print(io, "]"))
    get_coord(crd) = crd[1][2]

    dims = size(fbr)
    print(io, "│ " ^ depth); print(io, "SparseHash ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); foreach(dim -> (print(io, "1:"); show(io, dim); print(io, "×")), dims[1:N-1]); print(io, "1:"); show(io, dims[end]); println(io, "]")
    display_fiber_data(io, mime, fbr, N, crds, print_coord, get_coord)
end

@inline Base.ndims(fbr::Fiber{<:SparseHashLevel{N}}) where {N} = N + ndims(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))
@inline Base.size(fbr::Fiber{<:SparseHashLevel{N}}) where {N} = (fbr.lvl.I..., size(Fiber(fbr.lvl.lvl,  (Environment^N)(fbr.env)))...)
@inline Base.axes(fbr::Fiber{<:SparseHashLevel{N}}) where {N} = (map(Base.OneTo, fbr.lvl.I)..., axes(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))...)
@inline Base.eltype(fbr::Fiber{<:SparseHashLevel{N}}) where {N} = eltype(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))
@inline default(fbr::Fiber{<:SparseHashLevel{N}}) where {N} = default(Fiber(fbr.lvl.lvl, (Environment^N)(fbr.env)))

(fbr::Fiber{<:SparseHashLevel})() = fbr
function (fbr::Fiber{<:SparseHashLevel{N, Ti}})(i, tail...) where {N, Ti}
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



mutable struct VirtualSparseHashLevel
    ex
    N
    Ti
    Tp
    Tbl
    I
    P
    pos_alloc
    idx_alloc
    lvl
end
function virtualize(ex, ::Type{SparseHashLevel{N, Ti, Tp, Tbl, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tp, Tbl, Lvl}   
    sym = ctx.freshen(tag)
    I = map(n->value(:($sym.I[$n]), Int), 1:N)
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
    VirtualSparseHashLevel(sym, N, Ti, Tp, Tbl, I, P, pos_alloc, idx_alloc, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSparseHashLevel)
    quote
        $SparseHashLevel{$(lvl.N), $(lvl.Ti), $(lvl.Tp), $(lvl.Tbl)}(
            ($(map(ctx, lvl.I)...),),
            $(lvl.ex).tbl,
            $(lvl.ex).srt,
            $(lvl.ex).pos,
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_code(lvl::VirtualSparseHashLevel) = "sh{$(lvl.N)}($(summary_f_code(lvl.lvl)))"

function getsites(fbr::VirtualFiber{VirtualSparseHashLevel})
    d = envdepth(fbr.env)
    return [(d + 1:d + fbr.lvl.N)..., getsites(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^fbr.lvl.N)(fbr.env)))...]
end

function getsize(fbr::VirtualFiber{VirtualSparseHashLevel}, ctx::LowerJulia, mode)
    R = length(envdeferred(fbr.env)) + 1
    ext = map(stop->Extent(literal(1), stop), fbr.lvl.I[R:end])
    if mode.kind !== reader
        ext = map(suggest, ext)
    end
    (ext..., getsize(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^(fbr.lvl.N - R + 1))(fbr.env)), ctx, mode)...)
end

function setsize!(fbr::VirtualFiber{VirtualSparseHashLevel}, ctx::LowerJulia, mode, dims...)
    R = length(envdeferred(fbr.env)) + 1
    fbr.lvl.I = (fbr.lvl.I[1:R-1]..., map(getstop, dims[1:fbr.lvl.N-R+1])...)
    fbr.lvl.lvl = setsize!(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^(fbr.lvl.N - R + 1))(fbr.env)), ctx, mode, dims[fbr.lvl.N + 1 - R + 1:end]...).lvl
    fbr
end

@inline default(fbr::VirtualFiber{<:VirtualSparseHashLevel}) = default(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^fbr.lvl.N)(fbr.env)))
Base.eltype(fbr::VirtualFiber{<:VirtualSparseHashLevel}) = eltype(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualSparseHashLevel}, ctx::LowerJulia, mode)
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    my_p = ctx.freshen(lvl.ex, :_p)

    if mode.kind === updater && mode.mode.kind === create
        push!(ctx.preamble, quote
            $(lvl.idx_alloc) = 0
            empty!($(lvl.ex).tbl)
            empty!($(lvl.ex).srt)
            $(lvl.pos_alloc) = $Finch.refill!($(lvl.ex).pos, 0, 0, 5)
            $(lvl.ex).pos[1] = 1
            $(lvl.P) = 0
        end)
    end
    lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^lvl.N)(fbr.env)), ctx, mode)
    return lvl
end

interval_assembly_depth(lvl::VirtualSparseHashLevel) = Inf #This level supports interval assembly, and this assembly isn't recursive.

#This function is quite simple, since SparseHashLevels don't support reassembly.
#TODO what would it take to support reassembly?
function assemble!(fbr::VirtualFiber{VirtualSparseHashLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.P) = max($p_stop, $(lvl.P))
        $(lvl.pos_alloc) < ($(lvl.P) + 1) && ($(lvl.pos_alloc) = Finch.refill!($(lvl.ex).pos, 0, $(lvl.pos_alloc), $(lvl.P) + 1))
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualSparseHashLevel}, ctx::LowerJulia, mode)
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

function trim_level!(lvl::VirtualSparseHashLevel, ctx::LowerJulia, pos)
    idx = ctx.freshen(:idx)
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = $(ctx(pos)) + 1
        resize!($(lvl.ex).pos, $(lvl.pos_alloc))
        $(lvl.idx_alloc) = $(lvl.ex).pos[$(lvl.pos_alloc)] - 1
        resize!($(lvl.ex).srt, $(lvl.idx_alloc))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, lvl.idx_alloc)
    return lvl
end

function unfurl(fbr::VirtualFiber{VirtualSparseHashLevel}, ctx, mode, ::Nothing, idx, idxs...)
    if idx.kind === protocol
        @assert idx.mode.kind === literal
        unfurl(fbr, ctx, mode, idx.mode.val, idx.idx, idxs...)
    elseif mode.kind === reader
        unfurl(fbr, ctx, mode, walk, idx, idxs...)
    else
        unfurl(fbr, ctx, mode, laminate, idx, idxs...)
    end
end

function unfurl(fbr::VirtualFiber{VirtualSparseHashLevel}, ctx, mode, ::Walk, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_step = ctx.freshen(tag, :_q_step)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)
    R = length(envdeferred(fbr.env)) + 1
    @assert R == 1 || (fbr.env.start !== nothing && fbr.env.stop !== nothing)
    if R == 1
        q_start = value(:($(lvl.ex).pos[$(ctx(envposition(fbr.env)))]), lvl.Tp)
        q_stop = value(:($(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]), lvl.Tp)
    else
        q_start = fbr.env.start
        q_stop = fbr.env.stop
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
                stride = (ctx, idx, ext) -> value(my_i_stop),
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
                                stride =  (ctx, idx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Simplify(literal(default(fbr))),
                                    tail = begin
                                        env_2 = VirtualEnvironment(
                                        position=value(:(last($(lvl.ex).srt[$my_q])[$R]), lvl.Ti),
                                        index=value(my_i, lvl.Ti),
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
                                stride =  (ctx, idx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Simplify(literal(default(fbr))),
                                    tail = begin
                                        env_2 = VirtualEnvironment(
                                            start=value(my_q, lvl.Ti),
                                            stop=value(my_q_step, lvl.Ti),
                                            index=value(my_i, lvl.Ti),
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
                body = (start, step) -> Run(Simplify(literal(default(fbr))))
            )
        ])
    )

    exfurl(body, ctx, mode, idx)
end

function unfurl(fbr::VirtualFiber{VirtualSparseHashLevel}, ctx, mode, ::Follow, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    R = length(envdeferred(fbr.env)) + 1
    my_key = cgx.freshen(tag, :_key)
    my_q = cgx.freshen(tag, :_q)

    if R == lvl.N
        body = Lookup(
            body = (i) -> Thunk(
                preamble = quote
                    $my_key = ($(ctx(envposition(envexternal(fbr.env)))), ($(map(ctx, envdeferred(fbr.env))...), $(ctx(i))))
                    $my_q = get($(lvl.ex).tbl, $my_key, 0)
                end,
                body = Switch([
                    value(:($my_q != 0)) => refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Tp), index=i, parent=fbr.env)), ctx, mode, idxs...),
                    literal(true) => Simplify(literal(default(fbr)))
                ])
            )
        )
    else
        body = Lookup(
            body = (i) -> refurl(VirtualFiber(lvl, VirtualEnvironment(index=i, parent=fbr.env, internal=true)), ctx, mode, idxs...)
        )
    end

    exfurl(body, ctx, mode, idx)
end

hasdefaultcheck(lvl::VirtualSparseHashLevel) = true

function unfurl(fbr::VirtualFiber{VirtualSparseHashLevel}, ctx, mode, ::Union{Extrude, Laminate}, idx, idxs...)
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
                                assemble!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), parent=(VirtualEnvironment^(lvl.N - 1))(fbr.env))), ctx_2, mode)
                                quote end
                            end)
                        end
                    end,
                    body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode, idxs...),
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
        body = Lookup(
            val = default(fbr),
            body = (i) -> refurl(VirtualFiber(lvl, VirtualEnvironment(index=i, parent=fbr.env, internal=true)), ctx, mode, idxs...)
        )
    end

    exfurl(body, ctx, mode, idx)
end