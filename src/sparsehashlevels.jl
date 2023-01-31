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
    SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(Ti(I), tbl, Tp[1], Pair{Tuple{Tp, Ti}, Tp}[], lvl)

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
@inline level_ndims(::Type{<:SparseHashLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = N + level_ndims(Lvl)
@inline level_size(lvl::SparseHashLevel) = (lvl.I..., level_size(lvl.lvl)...)
@inline level_axes(lvl::SparseHashLevel) = (map(Base.OneTo, lvl.I)..., level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:SparseHashLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseHashLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = level_default(Lvl)

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
    qos_fill
    qos_stop
    dirty
    lvl
end
function virtualize(ex, ::Type{SparseHashLevel{N, Ti, Tp, Tbl, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tp, Tbl, Lvl}   
    sym = ctx.freshen(tag)
    I = map(n->value(:($sym.I[$n]), Int), 1:N)
    P = ctx.freshen(sym, :_P)
    qos_fill = ctx.freshen(sym, :_qos_fill)
    qos_stop = ctx.freshen(sym, :_qos_stop)
    push!(ctx.preamble, quote
        $sym = $ex
        $(qos_fill) = length($sym.tbl)
        $(qos_stop) = $(qos_fill)
    end)
    dirty = ctx.freshen(sym, :_dirty)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseHashLevel(sym, N, Ti, Tp, Tbl, I, qos_fill, qos_stop, dirty, lvl_2)
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

virtual_level_eltype(lvl::VirtualSparseHashLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseHashLevel) = virtual_level_default(lvl.lvl)

function initialize_level!(lvl::VirtualSparseHashLevel, ctx::LowerJulia, pos)
    Ti = lvl.Ti
    Tp = lvl.Tp

    qos = call(-, call(getindex, :($(lvl.ex).pos), call(+, pos, 1)), 1)
    push!(ctx.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
        empty!($(lvl.ex).tbl)
        empty!($(lvl.ex).srt)
    end)
    lvl.lvl = initialize_level!(lvl.lvl, ctx, qos)
    return lvl
end

function trim_level!(lvl::VirtualSparseHashLevel, ctx::LowerJulia, pos)
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos = ctx.freshen(:qos)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).pos, $(ctx(pos)) + 1)
        $qos = $(lvl.ex).pos[end] - $(Tp(1))
        resize!($(lvl.ex).srt, $qos)
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, Tp))
    return lvl
end

function assemble_level!(lvl::VirtualSparseHashLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        $resize_if_smaller!($(lvl.ex).pos, $pos_stop + 1)
        $fill_range!($(lvl.ex).pos, 0, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualSparseHashLevel, ctx::LowerJulia, pos_stop)
    p = ctx.freshen(:p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = ctx.freshen(:qos_stop)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).srt, length($(lvl.ex).tbl))
        copyto!($(lvl.ex).srt, pairs($(lvl.ex).tbl))
        sort!($(lvl.ex).srt)
        for $p = 2:($pos_stop + 1)
            $(lvl.ex).pos[$p] += $(lvl.ex).pos[$p - 1]
        end
        $qos_stop = $(lvl.ex).pos[$pos_stop + 1] - 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function get_level_reader(lvl::VirtualSparseHashLevel, ctx, pos, proto::Union{Nothing, Walk}, protos...)
    start = value(:($(lvl.ex).pos[$(ctx(pos))]), lvl.Tp)
    stop = value(:($(lvl.ex).pos[$(ctx(pos)) + 1]), lvl.Tp)

    get_multilevel_range_reader(lvl::VirtualSparseHashLevel, ctx, 1, start, stop, proto, protos...)
end

function get_multilevel_range_reader(lvl::VirtualSparseHashLevel, ctx, R, start, stop, ::Union{Nothing, Walk}, protos...)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_step = ctx.freshen(tag, :_q_step)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)

    Thunk(
        preamble = quote
            $my_q = $(ctx(start))
            $my_q_stop = $(ctx(stop))
            if $my_q < $my_q_stop
                $my_i = $(lvl.ex).srt[$my_q][$R]
                $my_i_stop = $(lvl.ex).tbl[$my_q_stop - 1][$R]
            else
                $my_i = $(Ti.parameters[R](1))
                $my_i_stop = $(Ti.parameters[R](0))
            end
        end,
        body = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> value(my_i_stop),
                body = (start, stop) -> Stepper(
                    seek = (ctx, ext) -> quote
                        while $my_q + $(Tp(1)) < $my_q_stop && $(lvl.ex).srt[$my_q][$R] < $(ctx(getstart(ext)))
                            $my_q += $(Tp(1))
                        end
                    end,
                    body = if R == lvl.N
                        Thunk(
                            preamble = quote
                                $my_i = $(lvl.ex).srt[$my_q][$R]
                            end,
                            body = Step(
                                stride =  (ctx, idx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Simplify(Fill(virtual_level_default(lvl))),
                                    tail = get_level_reader(lvl.lvl, ctx, my_q, protos...),
                                ),
                                next = (ctx, idx, ext) -> quote
                                    $my_q += $(Tp(1))
                                end
                            )
                        )
                    else
                        Thunk(
                            preamble = quote
                                $my_i = $(lvl.ex).srt[$my_q][$R]
                                $my_q_step = $my_q
                                while $my_q_step < $my_q_stop && $(lvl.ex).srt[$my_q_step][$R] == $my_i
                                    $my_q_step += $(Tp(1))
                                end
                            end,
                            body = Step(
                                stride = (ctx, idx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Simplify(Fill(virtual_level_default(lvl))),
                                    tail = get_multilevel_range_reader(lvl, ctx, R + 1, value(my_q, lvl.Ti), value(my_q_step, lvl.Ti), protos...),
                                ),
                                next = (ctx, idx, ext) -> quote
                                    $my_q = $my_q_step
                                end
                            )
                        )
                    end
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(Fill(virtual_level_default(lvl))))
            )
        ])
    )
end

function get_level_reader(lvl::VirtualSparseHashLevel, ctx, pos, proto::Follow, protos...)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    my_key = ctx.freshen(tag, :_key)

    return get_multilevel_group_reader(lvl, ctx, pos, qos, (), proto, protos...)
end

function get_multilevel_group_reader(lvl::VirtualSparseHashLevel, ctx, pos, qos, coords, ::Follow, protos...)
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    qos = ctx.freshen(tag, :_q)
    if length(coords)  + 1 < lvl.N
        body = Lookup(
            val = virtual_level_default(lvl),
            body = (i) -> get_multilevel_group_reader(lvl, ctx, pos, qos, (coords..., i), protos...)
        )
    else
        body = Lookup(
            val = virtual_level_default(lvl),
            body = (i) -> Thunk(
                preamble = quote
                    $my_key = ($(ctx(pos)), ($(map(ctx, coords)...), $(ctx(i))))
                    $qos = get($(lvl.ex).tbl, $my_key, 0)
                end,
                body = Switch([
                    value(:($qos != 0)) => get_level_reader(lvl.lvl, ctx, value(qos, lvl.Tp)),
                    literal(true) => Simplify(Fill(virtual_level_default(lvl)))
                ])
            )
        )
    end
end

set_clean!(lvl::VirtualSparseHashLevel, ctx) = :($(lvl.dirty) = false)
get_dirty(lvl::VirtualSparseHashLevel, ctx) = value(lvl.dirty, Bool)

function get_level_updater(lvl::VirtualSparseHashLevel, ctx, pos, protos...)
    return get_multilevel_group_updater(lvl, ctx, pos, (), protos...)
end

function get_multilevel_group_updater(lvl::VirtualSparseHashLevel, ctx, pos, coords, ::Union{Nothing, Extrude}, protos...)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    my_key = ctx.freshen(tag, :_key)
    qos = ctx.freshen(tag, :_q)
    if length(coords)  + 1 < lvl.N
        body = Lookup(
            val = virtual_level_default(lvl),
            body = (i) -> get_multilevel_group_updater(lvl, ctx, pos, (coords..., i), protos...)
        )
    else
        body = AcceptSpike(
            val = virtual_level_default(lvl),
            tail = (ctx, idx) -> Thunk(
                preamble = quote
                    $my_key = ($(ctx(pos)), ($(map(ctx, coords)...), $(ctx(idx))))
                    $qos = get($(lvl.ex).tbl, $my_key, $(qos_fill) + $(Tp(1)))
                    if $qos > $qos_stop
                        $qos_stop = max($qos_stop << 1, 1)
                        $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, lvl.Tp), value(qos_stop, lvl.Tp)), ctx))
                    end
                    $(set_clean!(lvl.lvl, ctx))
                end,
                body = get_level_updater(lvl.lvl, ctx, qos, protos...),
                epilogue = quote
                    if $(ctx(get_dirty(lvl.lvl, ctx)))
                        $(lvl.dirty) = true
                        if $qos > $qos_fill
                            $(lvl.qos_fill) = $qos
                            $(lvl.ex).tbl[$my_key] = $qos
                            $(lvl.ex).pos[$(ctx(pos)) + 1] += $(Tp(1))
                        end
                    end
                end
            )
        )
    end
end