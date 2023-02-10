struct SparseCooLevel{N, Ti<:Tuple, Tp, Tbl, Lvl}
    lvl::Lvl
    I::Ti
    tbl::Tbl
    pos::Vector{Tp}
end
const SparseCoo = SparseCooLevel

SparseCooLevel(lvl, I, args...) = SparseCooLevel{length(I)}(lvl, I, args...)
SparseCooLevel{N}(lvl) where {N} = SparseCooLevel{N, NTuple{N, Int}}(lvl)
SparseCooLevel{N}(lvl, I, args...) where {N} = SparseCooLevel{N, typeof(I)}(lvl, I, args...)

SparseCooLevel{N, Ti}(lvl, args...) where {N, Ti} = SparseCooLevel{N, Ti, Int}(lvl, args...)
SparseCooLevel{N, Ti, Tp}(lvl::Lvl, args...) where {N, Ti, Tp, Lvl} =
    SparseCooLevel{N, Ti, Tp, Tuple{(Vector{ti} for ti in Ti.parameters)...}, Lvl}(lvl, args...)

SparseCooLevel{N, Ti, Tp, Tbl, Lvl}(lvl) where {N, Ti, Tp, Tbl, Lvl} =
    SparseCooLevel{N, Ti, Tp, Tbl, Lvl}(lvl, ((zero(ti) for ti in Ti.parameters)...,))
SparseCooLevel{N, Ti, Tp, Tbl, Lvl}(lvl, I) where {N, Ti, Tp, Tbl, Lvl} =
    SparseCooLevel{N, Ti, Tp, Tbl, Lvl}(lvl, Ti(I), ((Vector{ti}() for ti in Ti.parameters)...,), Tp[1])

"""
`f_code(sc)` = [SparseCooLevel](@ref).
"""
f_code(::Val{:sc}) = SparseCoo
summary_f_code(lvl::SparseCooLevel{N}) where {N} = "sc{$N}($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SparseCooLevel{N}) where {N} = SparseCooLevel{N}(similar_level(lvl.lvl))
similar_level(lvl::SparseCooLevel{N}, tail...) where {N} = SparseCooLevel{N}(similar_level(lvl.lvl, tail[N + 1:end]...), (tail[1:N]...,))

pattern!(lvl::SparseCooLevel{N, Ti, Tp}) where {N, Ti, Tp} = 
    SparseCooLevel{N, Ti, Tp}(pattern!(lvl.lvl), lvl.I, lvl.tbl, lvl.pos)

function Base.show(io::IO, lvl::SparseCooLevel{N, Ti, Tp}) where {N, Ti, Tp}
    if get(io, :compact, false)
        print(io, "SparseCoo{$N}(")
    else
        print(io, "SparseCoo{$N, $Ti, $Tp}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(IOContext(io, :typeinfo=>Ti), lvl.I)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        print(io, "(")
        for (n, ti) = enumerate(Ti.parameters)
            print(io, ti) #TODO we have to do something about this.
            show(IOContext(io, :typeinfo=>Vector{ti}), lvl.tbl[n])
            print(io, ", ")
        end
        print(io, "), ")
        show(IOContext(io, :typeinfo=>Vector{Tp}), lvl.pos)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:SparseCooLevel{N}}, depth) where {N}
    p = fbr.pos
    crds = fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1

    print_coord(io, q) = (print(io, "["); foreach(n -> (show(io, fbr.lvl.tbl[n][q]); print(io, ", ")), 1:N-1); show(io, fbr.lvl.tbl[N][q]); print(io, "]"))
    get_fbr(q) = fbr(map(n -> fbr.lvl.tbl[n][q], 1:N)...)

    dims = size(fbr)
    print(io, "│ " ^ depth); print(io, "SparseCoo ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); foreach(dim -> (print(io, "1:"); show(io, dim); print(io, "×")), dims[1:N-1]); print(io, "1:"); show(io, dims[end]); println(io, "]")
    display_fiber_data(io, mime, fbr, depth, N, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:SparseCooLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = N + level_ndims(Lvl)
@inline level_size(lvl::SparseCooLevel) = (lvl.I..., level_size(lvl.lvl)...)
@inline level_axes(lvl::SparseCooLevel) = (map(Base.OneTo, lvl.I)..., level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:SparseCooLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseCooLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseCooLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = (SparseData^N)(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SparseCooLevel})() = fbr
(fbr::SubFiber{<:SparseCooLevel})() = fbr
function (fbr::SubFiber{<:SparseCooLevel{N, Ti}})(idxs...) where {N, Ti}
    lvl = fbr.lvl
    target = lvl.pos[fbr.pos]:lvl.pos[fbr.pos + 1] - 1
    for n = 1:N
        target = searchsorted(view(lvl.tbl[n], target), idxs[n]) .+ (first(target) - 1)
    end
    isempty(target) ? default(fbr) : SubFiber(lvl.lvl, first(target))(idxs[N + 1:end]...)
end

mutable struct VirtualSparseCooLevel
    lvl
    ex
    N
    Ti
    Tp
    Tbl
    I
    qos_fill
    qos_stop
    dirty
end
function virtualize(ex, ::Type{SparseCooLevel{N, Ti, Tp, Tbl, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tp, Tbl, Lvl}   
    sym = ctx.freshen(tag)
    I = map(n->value(:($sym.I[$n]), Int), 1:N)
    qos_fill = ctx.freshen(sym, :_qos_fill)
    qos_stop = ctx.freshen(sym, :_qos_stop)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    dirty = ctx.freshen(sym, :_dirty)
    VirtualSparseCooLevel(lvl_2, sym, N, Ti, Tp, Tbl, I, qos_fill, qos_stop, dirty)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSparseCooLevel)
    quote
        $SparseCooLevel{$(lvl.N), $(lvl.Ti), $(lvl.Tp)}(
            $(ctx(lvl.lvl)),
            ($(map(ctx, lvl.I)...),),
            $(lvl.ex).tbl,
            $(lvl.ex).pos,
        )
    end
end

summary_f_code(lvl::VirtualSparseCooLevel) = "sc{$(lvl.N)}($(summary_f_code(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseCooLevel, ctx::LowerJulia)
    ext = map((ti, stop)->Extent(literal(ti(1)), stop), lvl.Ti.parameters, lvl.I)
    (ext..., virtual_level_size(lvl.lvl, ctx)...)
end

function virtual_level_resize!(lvl::VirtualSparseCooLevel, ctx::LowerJulia, dims...)
    lvl.I = map(getstop, dims[1:lvl.N])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[lvl.N + 1:end]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseCooLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseCooLevel) = virtual_level_default(lvl.lvl)

function initialize_level!(lvl::VirtualSparseCooLevel, ctx::LowerJulia, pos)
    Ti = lvl.Ti
    Tp = lvl.Tp

    qos = call(-, call(getindex, :($(lvl.ex).pos), call(+, pos, 1)), 1)
    push!(ctx.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
    end)
    lvl.lvl = initialize_level!(lvl.lvl, ctx, qos)
    return lvl
end

function trim_level!(lvl::VirtualSparseCooLevel, ctx::LowerJulia, pos)
    Tp = lvl.Tp
    qos = ctx.freshen(:qos)

    push!(ctx.preamble, quote
        resize!($(lvl.ex).pos, $(ctx(pos)) + 1)
        $qos = $(lvl.ex).pos[end] - $(Tp(1))
        $(Expr(:block, map(1:lvl.N) do n
            :(resize!($(lvl.ex).tbl[$n], $qos))
        end...))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, Tp))
    return lvl
end

function assemble_level!(lvl::VirtualSparseCooLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        $resize_if_smaller!($(lvl.ex).pos, $pos_stop + 1)
        $fill_range!($(lvl.ex).pos, 0, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualSparseCooLevel, ctx::LowerJulia, pos_stop)
    p = ctx.freshen(:p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = ctx.freshen(:qos_stop)
    push!(ctx.preamble, quote
        for $p = 2:($pos_stop + 1)
            $(lvl.ex).pos[$p] += $(lvl.ex).pos[$p - 1]
        end
        $qos_stop = $(lvl.ex).pos[$pos_stop + 1] - 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function get_level_reader(lvl::VirtualSparseCooLevel, ctx, pos, protos...)
    start = value(:($(lvl.ex).pos[$(ctx(pos))]), lvl.Tp)
    stop = value(:($(lvl.ex).pos[$(ctx(pos)) + 1]), lvl.Tp)

    get_multilevel_range_reader(lvl::VirtualSparseCooLevel, ctx, 1, start, stop, protos...)
end

function get_multilevel_range_reader(lvl::VirtualSparseCooLevel, ctx, R, start, stop, ::Union{Nothing, Walk}, protos...)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_step = ctx.freshen(tag, :_q_step)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)

    Furlable(
        val = virtual_level_default(lvl),
        size = virtual_level_size(lvl, ctx)[R:end],
        body = (ctx, idx, ext) -> Thunk(
            preamble = quote
                $my_q = $(ctx(start))
                $my_q_stop = $(ctx(stop))
                if $my_q < $my_q_stop
                    $my_i = $(lvl.ex).tbl[$R][$my_q]
                    $my_i_stop = $(lvl.ex).tbl[$R][$my_q_stop - 1]
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
                            while $my_q + $(Tp(1)) < $my_q_stop && $(lvl.ex).tbl[$R][$my_q] < $(ctx(getstart(ext)))
                                $my_q += $(Tp(1))
                            end
                        end,
                        body = if R == lvl.N
                            Thunk(
                                preamble = quote
                                    $my_i = $(lvl.ex).tbl[$R][$my_q]
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
                                    $my_i = $(lvl.ex).tbl[$R][$my_q]
                                    $my_q_step = $my_q
                                    while $my_q_step < $my_q_stop && $(lvl.ex).tbl[$R][$my_q_step] == $my_i
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
    )
end

set_clean!(lvl::VirtualSparseCooLevel, ctx) = :($(lvl.dirty) = false)
get_dirty(lvl::VirtualSparseCooLevel, ctx) = value(lvl.dirty, Bool)

function get_level_updater(lvl::VirtualSparseCooLevel, ctx, pos, protos...)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop

    qos = ctx.freshen(tag, :_q)
    Thunk(
        preamble = quote
            $qos = $qos_fill + 1
        end,
        body = get_multilevel_append_updater(lvl, ctx, qos, (), protos...),
        epilogue = quote
            $(lvl.ex).pos[$(ctx(pos)) + 1] = $qos - $qos_fill - 1
            $qos_fill = $qos - 1
        end
    )
end

function get_multilevel_append_updater(lvl::VirtualSparseCooLevel, ctx, qos, coords, ::Union{Nothing, Extrude}, protos...)
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    Furlable(
        val = virtual_level_default(lvl),
        size = virtual_level_size(lvl, ctx)[length(coords) + 1:end],
        body = (ctx, idx, ext) -> 
            if length(coords) + 1 < lvl.N
                Lookup(
                    val = virtual_level_default(lvl),
                    body = (i) -> get_multilevel_append_updater(lvl, ctx, qos, (coords..., i), protos...)
                )
            else
                AcceptSpike(
                    val = virtual_level_default(lvl),
                    tail = (ctx, idx) -> Thunk(
                        preamble = quote
                            if $qos > $qos_stop
                                $qos_stop = max($qos_stop << 1, 1)
                                $(Expr(:block, map(1:lvl.N) do n
                                    :(resize_if_smaller!($(lvl.ex).tbl[$n], $qos_stop))
                                end...))
                                $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, lvl.Tp), value(qos_stop, lvl.Tp)), ctx))
                            end
                            $(set_clean!(lvl.lvl, ctx))
                        end,
                        body = get_level_updater(lvl.lvl, ctx, qos, protos...),
                        epilogue = quote
                            if $(ctx(get_dirty(lvl.lvl, ctx)))
                                $(lvl.dirty) = true
                                $(Expr(:block, map(enumerate((coords..., idx))) do (n, i)
                                    :($(lvl.ex).tbl[$n][$qos] = $(ctx(i)))
                                end...))
                                $qos += $(Tp(1))
                            end
                        end
                    )
                )
            end
    )
end