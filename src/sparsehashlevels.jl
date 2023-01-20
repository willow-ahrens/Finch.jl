struct SparseHashLevel{N, Ti<:Tuple, Tp, Tbl, Lvl}
    I::Ti
    tbl::Tbl
    pos::Vector{Tp}
    srt::Vector{Pair{Tuple{Tp, Ti}, Tp}}
    lvl::Lvl
end
const SparseHash = SparseHashLevel
SparseHashLevel{N}(lvl) where {N} = SparseHashLevel{N}(((0 for _ in 1:N)...,), lvl)
SparseHashLevel{N, Ti}(lvl) where {N, Ti} = SparseHashLevel{N, Ti}((map(zero, Ti.parameters)..., ), lvl)
SparseHashLevel{N, Ti, Tp}(lvl) where {N, Ti, Tp} = SparseHashLevel{N, Ti, Tp}((map(zero, Ti.parameters)..., ), lvl)
SparseHashLevel{N, Ti, Tp, Tbl}(lvl) where {N, Ti, Tp, Tbl} = SparseHashLevel{N, Ti, Tp, Tbl}((map(zero, Ti.parameters)..., ), lvl)

SparseHashLevel{N}(I::Ti, lvl) where {N, Ti} = SparseHashLevel{N, Ti}(I, lvl)
SparseHashLevel{N, Ti}(I, lvl) where {N, Ti} = SparseHashLevel{N, Ti, Int}(Ti(I), lvl)
SparseHashLevel{N, Ti, Tp}(I, lvl) where {N, Ti, Tp} =
    SparseHashLevel{N, Ti, Tp}(Ti(I), Dict{Tuple{Tp, Ti}, Tp}(), lvl)
SparseHashLevel{N, Ti, Tp, Tbl}(I, lvl) where {N, Ti, Tp, Tbl} =
    SparseHashLevel{N, Ti, Tp, Tbl}(Ti(I), Tbl(), lvl)

SparseHashLevel{N}(I::Ti, tbl::Tbl, lvl) where {N, Ti, Tp, Tbl<:AbstractDict{Tuple{Tp, Ti}}} =
    SparseHashLevel{N, Ti, Tp, Tbl}(I, tbl, lvl)
SparseHashLevel{N, Ti}(I, tbl::Tbl, lvl) where {N, Ti, Tp, Tbl<:AbstractDict{Tuple{Tp, Ti}}} =
    SparseHashLevel{N, Ti, Tp, Tbl}(Ti(I), tbl, lvl)
SparseHashLevel{N, Ti, Tp}(I, tbl::Tbl, lvl) where {N, Ti, Tp, Tbl} =
    SparseHashLevel{N, Ti, Tp, Tbl}(Ti(I), tbl, lvl)
SparseHashLevel{N, Ti, Tp, Tbl}(I, tbl, lvl::Lvl) where {N, Ti, Tp, Tbl, Lvl} =
    SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(Ti(I), tbl, Tp[1, 1], Pair{Tuple{Tp, Ti}, Tp}[], lvl)

SparseHashLevel{N}(I::Ti, tbl::Tbl, pos::Vector{Tp}, srt, lvl::Lvl) where {N, Ti, Tp, Tbl, Lvl} =
    SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(I, tbl, pos, srt, lvl) 
SparseHashLevel{N, Ti}(I, tbl::Tbl, pos::Vector{Tp}, srt, lvl::Lvl) where {N, Ti, Tp, Tbl, Lvl} =
    SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(Ti(I), tbl, pos, srt, lvl) 
SparseHashLevel{N, Ti, Tp}(I, tbl::Tbl, pos, srt, lvl::Lvl) where {N, Ti, Tp, Tbl, Lvl} =
    SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(Ti(I), tbl, pos, srt, lvl) 
SparseHashLevel{N, Ti, Tp, Tbl}(I, tbl, pos, srt, lvl::Lvl) where {N, Ti, Tp, Tbl, Lvl} =
    SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(Ti(I), tbl, pos, srt, lvl) 

"""
`f_code(sh)` = [SparseHashLevel](@ref).
"""
f_code(::Val{:sh}) = SparseHash
summary_f_code(lvl::SparseHashLevel{N}) where {N} = "sh{$N}($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SparseHashLevel{N}) where {N} = SparseHashLevel{N}(similar_level(lvl.lvl))
similar_level(lvl::SparseHashLevel{N}, tail...) where {N} = SparseHashLevel{N}(ntuple(n->tail[n], N), similar_level(lvl.lvl, tail[N + 1:end]...))

pattern!(lvl::SparseHashLevel{N, Ti, Tp, Tbl}) where {N, Ti, Tp, Tbl} = 
    SparseHashLevel{N, Ti, Tp, Tbl}(lvl.I, lvl.tbl, lvl.pos, lvl.srt, pattern!(lvl.lvl))

function Base.show(io::IO, lvl::SparseHashLevel{N, Ti, Tp}) where {N, Ti, Tp}
    if get(io, :compact, false)
        print(io, "SparseHash{$N}(")
    else
        print(io, "SparseHash{$N, $Ti, $Tp}(")
    end
    show(IOContext(io, :typeinfo=>Ti), lvl.I)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        print(io, typeof(lvl.tbl))
        print(io, "(")
        print(io, join(sort!(collect(pairs(lvl.tbl))), ", "))
        print(io, "), ")
        show(IOContext(io, :typeinfo=>Vector{Tp}), lvl.pos)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Pair{Tuple{Tp, Ti}, Tp}}), lvl.srt)
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
    get_fbr(crd) = fbr(crd[1][2]...)

    dims = size(fbr)
    print(io, "│ " ^ depth); print(io, "SparseHash ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); foreach(dim -> (print(io, "1:"); show(io, dim); print(io, "×")), dims[1:N-1]); print(io, "1:"); show(io, dims[end]); println(io, "]")
    display_fiber_data(io, mime, fbr, N, crds, print_coord, get_fbr)
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
            $(lvl.ex).pos,
            $(lvl.ex).srt,
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_code(lvl::VirtualSparseHashLevel) = "sh{$(lvl.N)}($(summary_f_code(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseHashLevel, ctx::LowerJulia)
    ext = map((ti, stop)->Extent(literal(ti(1)), stop), lvl.Ti.parameters, lvl.I)
    (ext..., virtual_level_size(lvl.lvl, ctx)...)
end

function virtual_level_resize!(lvl::VirtualSparseHashLevel, ctx::LowerJulia, dims...)
    lvl.I = map(getstop, dims[1:lvl.N])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[lvl.N+1:end]...)
    lvl
end

@inline default(fbr::VirtualFiber{<:VirtualSparseHashLevel}) = default(VirtualFiber(fbr.lvl.lvl, (VirtualEnvironment^fbr.lvl.N)(fbr.env)))
Base.eltype(fbr::VirtualFiber{<:VirtualSparseHashLevel}) = eltype(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)))

function initialize_level!(fbr::VirtualFiber{VirtualSparseHashLevel}, ctx::LowerJulia, mode)
    @assert isempty(envdeferred(fbr.env))
    lvl = fbr.lvl
    Ti = lvl.Ti
    Tp = lvl.Tp
    my_p = ctx.freshen(lvl.ex, :_p)

    if mode.kind === updater && mode.mode.kind === create
        push!(ctx.preamble, quote
            $(lvl.idx_alloc) = $(Tp(0))
            empty!($(lvl.ex).tbl)
            empty!($(lvl.ex).srt)
            $(lvl.pos_alloc) = $Finch.refill!($(lvl.ex).pos, 0, 0, 5)
            $(lvl.ex).pos[1] = $(Tp(1))
            $(lvl.P) = $(Tp(0))
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
    Ti = lvl.Ti
    Tp = lvl.Tp
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.P) = max($Tp($p_stop), $(lvl.P))
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
    Ti = lvl.Ti
    Tp = lvl.Tp
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = $(ctx(pos)) + 1
        resize!($(lvl.ex).pos, $(lvl.pos_alloc))
        $(lvl.idx_alloc) = $(lvl.ex).pos[$(lvl.pos_alloc)] - $(Tp(1))
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
    Ti = lvl.Ti
    Tp = lvl.Tp
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
                $my_i = $(Ti.parameters[R](1))
                $my_i_stop = $(Ti.parameters[R](0))
            end
        end,
        body = if R == lvl.N
            Pipeline([
                Phase(
                    stride = (ctx, idx, ext) -> value(my_i_stop),
                    body = (start, step) -> Stepper(
                        seek = (ctx, ext) -> quote
                            while $my_q + $(Tp(1)) < $my_q_stop && last(first($(lvl.ex).srt[$my_q]))[$R] < $(ctx(getstart(ext)))
                                $my_q += $(Tp(1))
                            end
                        end,
                        body = Thunk(
                            preamble = :(
                                $my_i = last(first($(lvl.ex).srt[$my_q]))[$R]
                            ),
                            body = Step(
                                stride =  (ctx, idx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Simplify(Fill(default(fbr))),
                                    tail = begin
                                        env_2 = VirtualEnvironment(
                                        position=value(:(last($(lvl.ex).srt[$my_q])), lvl.Ti),
                                        index=value(my_i, lvl.Ti),
                                        parent=fbr.env)
                                        refurl(VirtualFiber(lvl.lvl, env_2), ctx, mode)
                                    end,
                                ),
                                next =  (ctx, idx, ext) -> quote
                                    $my_q += $(Tp(1))
                                end
                            )
                        )
                    )
                ),
                Phase(
                    body = (start, step) -> Run(Simplify(Fill(default(fbr))))
                )
            ])
        else
            Pipeline([
                Phase(
                    stride = (ctx, idx, ext) -> value(my_i_stop),
                    body = (start, step) -> Stepper(
                        seek = (ctx, ext) -> quote
                            while $my_q + $(Tp(1)) < $my_q_stop && last(first($(lvl.ex).srt[$my_q]))[$R] < $(ctx(start))
                                $my_q += $(Tp(1))
                            end
                        end,
                        body = Thunk(
                            preamble = quote
                                $my_i = last(first($(lvl.ex).srt[$my_q]))[$R]
                                $my_q_step = $my_q + $(Tp(1))
                                while $my_q_step < $my_q_stop && last(first($(lvl.ex).srt[$my_q_step]))[$R] == $my_i
                                    $my_q_step += $(Tp(1))
                                end
                            end,
                            body = Step(
                                stride =  (ctx, idx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Simplify(Fill(default(fbr))),
                                    tail = begin
                                        env_2 = VirtualEnvironment(
                                            start=value(my_q, lvl.Ti),
                                            stop=value(my_q_step, lvl.Ti),
                                            index=value(my_i, lvl.Ti),
                                            parent=fbr.env,
                                            internal=true)
                                        refurl(VirtualFiber(lvl, env_2), ctx, mode)
                                    end
                                ),
                                next =  (ctx, idx, ext) -> quote
                                    $my_q = $my_q_step
                                end
                            )
                        )
                    )
                ),
                Phase(
                    body = (start, step) -> Run(Simplify(Fill(default(fbr))))
                )
            ])
        end
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
                    value(:($my_q != 0)) => refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Tp), index=i, parent=fbr.env)), ctx, mode),
                    literal(true) => Simplify(Fill(default(fbr)))
                ])
            )
        )
    else
        body = Lookup(
            body = (i) -> refurl(VirtualFiber(lvl, VirtualEnvironment(index=i, parent=fbr.env, internal=true)), ctx, mode)
        )
    end

    exfurl(body, ctx, mode, idx)
end

hasdefaultcheck(lvl::VirtualSparseHashLevel) = true

function unfurl(fbr::VirtualFiber{VirtualSparseHashLevel}, ctx, mode, ::Union{Extrude, Laminate}, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
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
                        $my_q = get($(lvl.ex).tbl, $my_key, $(lvl.idx_alloc) + $(Tp(1)))
                        if $(lvl.idx_alloc) < $my_q 
                            $(contain(ctx) do ctx_2 
                                #THIS code reassembles every time. TODO
                                assemble!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), parent=(VirtualEnvironment^(lvl.N - 1))(fbr.env))), ctx_2, mode)
                                quote end
                            end)
                        end
                    end,
                    body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode),
                    epilogue = begin
                        body = quote
                            $(lvl.idx_alloc) = $my_q
                            $(lvl.ex).tbl[$my_key] = $(lvl.idx_alloc)
                            $(lvl.ex).pos[$(ctx(envposition(envexternal(fbr.env)))) + 1] += $(Tp(1))
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
            body = (i) -> refurl(VirtualFiber(lvl, VirtualEnvironment(index=i, parent=fbr.env, internal=true)), ctx, mode)
        )
    end

    exfurl(body, ctx, mode, idx)
end