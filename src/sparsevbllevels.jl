struct SparseVBLLevel{Ti, Tp, Lvl}
    I::Ti
    pos::Vector{Tp}
    idx::Vector{Ti}
    ofs::Vector{Tp}
    lvl::Lvl
end
const SparseVBL = SparseVBLLevel
SparseVBLLevel(lvl) = SparseVBLLevel(0, lvl)
SparseVBLLevel{Ti}(lvl) where {Ti} = SparseVBLLevel{Ti}(zero(Ti), lvl)
SparseVBLLevel{Ti, Tp}(lvl) where {Ti, Tp} = SparseVBLLevel{Ti, Tp}(zero(Ti), lvl)

SparseVBLLevel(I::Ti, lvl) where {Ti} = SparseVBLLevel{Ti}(I, lvl)
SparseVBLLevel{Ti}(I, lvl) where {Ti} = SparseVBLLevel{Ti, Int}(Ti(I), lvl)
SparseVBLLevel{Ti, Tp}(I, lvl::Lvl) where {Ti, Tp, Lvl} = SparseVBLLevel{Ti, Tp, Lvl}(Ti(I), Tp[1], Ti[], Ti[], lvl)

SparseVBLLevel(I::Ti, pos::Vector{Tp}, idx, ofs, lvl::Lvl) where {Ti, Tp, Lvl} = SparseVBLLevel{Ti, Tp, Lvl}(I, pos, idx, ofs, lvl)
SparseVBLLevel{Ti}(I, pos::Vector{Tp}, idx, ofs, lvl::Lvl) where {Ti, Tp, Lvl} = SparseVBLLevel{Ti, Tp, Lvl}(Ti(I), pos, idx, ofs, lvl)
SparseVBLLevel{Ti, Tp}(I, pos, idx, ofs, lvl::Lvl) where {Ti, Tp, Lvl} = SparseVBLLevel{Ti, Tp, Lvl}(Ti(I), pos, idx, ofs, lvl)

"""
`f_code(sv)` = [SparseVBLLevel](@ref).
"""
f_code(::Val{:sv}) = SparseVBL
summary_f_code(lvl::SparseVBLLevel) = "sv($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SparseVBLLevel) = SparseVBL(similar_level(lvl.lvl))
similar_level(lvl::SparseVBLLevel, dim, tail...) = SparseVBL(dim, similar_level(lvl.lvl, tail...))

pattern!(lvl::SparseVBLLevel{Ti}) where {Ti} = 
    SparseVBLLevel{Ti}(lvl.I, lvl.pos, lvl.idx, lvl.ofs, pattern!(lvl.lvl))

function Base.show(io::IO, lvl::SparseVBLLevel{Ti, Tp}) where {Ti, Tp}
    if get(io, :compact, false)
        print(io, "SparseVBL(")
    else
        print(io, "SparseVBL{$Ti, $Tp}(")
    end
    show(IOContext(io, :typeinfo=>Ti), lvl.I)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>Vector{Tp}), lvl.pos)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Ti}), lvl.idx)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Tp}), lvl.ofs)
    end
    print(io, ", ")
    show(io, lvl.lvl)
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:SparseVBLLevel})
    p = envposition(fbr.env)
    crds = []
    for r in fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1
        i = fbr.lvl.idx[r]
        l = fbr.lvl.ofs[r + 1] - fbr.lvl.ofs[r]
        append!(crds, (i - l + 1):i)
    end

    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "["); show(io, crd); print(io, "]"))
    get_fbr(crd) = fbr(crd)

    print(io, "│ " ^ depth); print(io, "SparseVBL ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:SparseVBLLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseVBLLevel) = (lvl.I, level_size(lvl.lvl)...)
@inline level_axes(lvl::SparseVBLLevel) = (Base.OneTo(lvl.I), level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:SparseVBLLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseVBLLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = level_default(Lvl)
(fbr::Fiber{<:SparseVBLLevel})() = fbr
function (fbr::Fiber{<:SparseVBLLevel})(i, tail...)
    lvl = fbr.lvl
    p = envposition(fbr.env)
    r = lvl.pos[p] + searchsortedfirst(@view(lvl.idx[lvl.pos[p]:lvl.pos[p + 1] - 1]), i) - 1
    r < lvl.pos[p + 1] || return default(fbr)
    q = lvl.ofs[r + 1] - 1 - lvl.idx[r] + i
    q >= lvl.ofs[r] || return default(fbr)
    fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
    return fbr_2(tail...)
end

mutable struct VirtualSparseVBLLevel
    ex
    Ti
    Tp
    I
    qos_fill
    qos_stop
    ros_fill
    ros_stop
    dirty
    lvl
end
function virtualize(ex, ::Type{SparseVBLLevel{Ti, Tp, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, Lvl}
    sym = ctx.freshen(tag)
    I = value(:($sym.I), Int)
    qos_fill = ctx.freshen(sym, :_qos_fill)
    qos_stop = ctx.freshen(sym, :_qos_stop)
    ros_fill = ctx.freshen(sym, :_ros_fill)
    ros_stop = ctx.freshen(sym, :_ros_stop)
    dirty = ctx.freshen(sym, :_dirty)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseVBLLevel(sym, Ti, Tp, I, qos_fill, qos_stop, ros_fill, ros_stop, dirty, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSparseVBLLevel)
    quote
        $SparseVBLLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(lvl.ex).pos,
            $(lvl.ex).idx,
            $(lvl.ex).ofs,
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_code(lvl::VirtualSparseVBLLevel) = "sv($(summary_f_code(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseVBLLevel, ctx)
    ext = Extent(literal(lvl.Ti(1)), lvl.I)
    (ext, virtual_level_size(lvl.lvl, ctx)...)
end

function virtual_level_resize!(lvl::VirtualSparseVBLLevel, ctx, dim, dims...)
    lvl.I = getstop(dim)
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseVBLLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseVBLLevel) = virtual_level_default(lvl.lvl)

function initialize_level!(lvl::VirtualSparseVBLLevel, ctx::LowerJulia, pos)
    Tp = lvl.Tp
    Ti = lvl.Ti
    ros = call(-, call(getindex, :($(lvl.ex).pos), call(+, pos, 1)), 1)
    qos = call(-, call(getindex, :($(lvl.ex).ofs), call(+, ros, 1)), 1)
    push!(ctx.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
        $(lvl.ros_fill) = $(Tp(0))
        $(lvl.ros_stop) = $(Tp(0))
        $resize_if_smaller!($(lvl.ex).ofs, 1)
        $(lvl.ex).ofs[1] = 1
    end)
    lvl.lvl = initialize_level!(lvl.lvl, ctx, qos)
    return lvl
end

function trim_level!(lvl::VirtualSparseVBLLevel, ctx::LowerJulia, pos)
    Tp = lvl.Tp
    Ti = lvl.Ti
    ros = ctx.freshen(:ros)
    qos = ctx.freshen(:qos)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).pos, $(ctx(pos)) + 1)
        $ros = $(lvl.ex).pos[end] - $(lvl.Tp(1))
        resize!($(lvl.ex).idx, $ros)
        resize!($(lvl.ex).ofs, $ros + 1)
        $qos = $(lvl.ex).ofs[end] - $(lvl.Tp(1))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, Tp))
    return lvl
end

function assemble_level!(lvl::VirtualSparseVBLLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        $resize_if_smaller!($(lvl.ex).pos, $pos_stop + 1)
        $fill_range!($(lvl.ex).pos, 0, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualSparseVBLLevel, ctx::LowerJulia, pos_stop)
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

function get_level_reader(lvl::VirtualSparseVBLLevel, ctx, pos, ::Union{Nothing, Walk}, protos...)
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_i = ctx.freshen(tag, :_i)
    my_i_start = ctx.freshen(tag, :_i)
    my_r = ctx.freshen(tag, :_r)
    my_r_stop = ctx.freshen(tag, :_r_stop)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_q_ofs = ctx.freshen(tag, :_q_ofs)
    my_i1 = ctx.freshen(tag, :_i1)

    Furlable(
        size = virtual_level_size(lvl, ctx),
        body = (ctx, idx, ext) -> Thunk(
            preamble = quote
                $my_r = $(lvl.ex).pos[$(ctx(pos))]
                $my_r_stop = $(lvl.ex).pos[$(ctx(pos)) + $(Tp(1))]
                if $my_r < $my_r_stop
                    $my_i = $(lvl.ex).idx[$my_r]
                    $my_i1 = $(lvl.ex).idx[$my_r_stop - $(Tp(1))]
                else
                    $my_i = $(Ti(1))
                    $my_i1 = $(Ti(0))
                end
            end,
            body = Pipeline([
                Phase(
                    stride = (ctx, idx, ext) -> value(my_i1),
                    body = (start, step) -> Stepper(
                        seek = (ctx, ext) -> quote
                            while $my_r + $(Tp(1)) < $my_r_stop && $(lvl.ex).idx[$my_r] < $(ctx(getstart(ext)))
                                $my_r += $(Tp(1))
                            end
                        end,
                        body = Thunk(
                            preamble = quote
                                $my_i = $(lvl.ex).idx[$my_r]
                                $my_q_stop = $(lvl.ex).ofs[$my_r + $(Tp(1))]
                                $my_i_start = $my_i - ($my_q_stop - $(lvl.ex).ofs[$my_r])
                                $my_q_ofs = $my_q_stop - $my_i - $(Tp(1))
                            end,
                            body = Step(
                                stride = (ctx, idx, ext) -> value(my_i),
                                body = (ctx, idx, ext, ext_2) -> Thunk(
                                    body = Pipeline([
                                        Phase(
                                            stride = (ctx, idx, ext) -> value(my_i_start),
                                            body = (start, step) -> Run(Simplify(Fill(virtual_level_default(lvl)))),
                                        ),
                                        Phase(
                                            body = (start, step) -> Lookup(
                                                body = (i) -> Thunk(
                                                    preamble = quote
                                                        $my_q = $my_q_ofs + $(ctx(i))
                                                    end,
                                                    body = get_level_reader(lvl.lvl, ctx, value(my_q, lvl.Tp), protos...),
                                                )
                                            )
                                        )
                                    ]),
                                    epilogue = quote
                                        $my_r += ($(ctx(getstop(ext_2))) == $my_i)
                                    end
                                )
                            )
                        )
                    )
                ),
                Phase(
                    body = (start, step) -> Run(Simplify(Fill(virtual_level_default(lvl))))
                )
            ])
        )
    )
end

function get_level_reader(lvl::VirtualSparseVBLLevel, ctx, pos, ::Gallop, protos...)
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_i = ctx.freshen(tag, :_i)
    my_i_start = ctx.freshen(tag, :_i)
    my_r = ctx.freshen(tag, :_r)
    my_r_stop = ctx.freshen(tag, :_r_stop)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_q_ofs = ctx.freshen(tag, :_q_ofs)
    my_i1 = ctx.freshen(tag, :_i1)

    Furlable(
        size = virtual_level_size(lvl, ctx),
        body = (ctx, idx, ext) -> Thunk(
            preamble = quote
                $my_r = $(lvl.ex).pos[$(ctx(pos))]
                $my_r_stop = $(lvl.ex).pos[$(ctx(pos)) + $(Tp(1))]
                if $my_r < $my_r_stop
                    $my_i = $(lvl.ex).idx[$my_r]
                    $my_i1 = $(lvl.ex).idx[$my_r_stop - $(Tp(1))]
                else
                    $my_i = $(Ti(1))
                    $my_i1 = $(Ti(0))
                end
            end,

            body = Pipeline([
                Phase(
                    stride = (ctx, idx, ext) -> value(my_i1),
                    body = (start, step) -> Jumper(
                        body = Thunk(
                            preamble = quote
                                $my_i = $(lvl.ex).idx[$my_r]
                            end,
                            body = Jump(
                                seek = (ctx, ext) -> quote
                                    while $my_r + $(Tp(1)) < $my_r_stop && $(lvl.ex).idx[$my_r] < $(ctx(getstart(ext)))
                                        $my_r += $(Tp(1))
                                    end
                                    $my_i = $(lvl.ex).idx[$my_r]
                                end,
                                stride = (ctx, ext) -> value(my_i),
                                body = (ctx, ext, ext_2) -> Switch([
                                    value(:($(ctx(getstop(ext_2))) == $my_i)) => Thunk(
                                        preamble=quote
                                            $my_q_stop = $(lvl.ex).ofs[$my_r + $(Tp(1))]
                                            $my_i_start = $my_i - ($my_q_stop - $(lvl.ex).ofs[$my_r])
                                            $my_q_ofs = $my_q_stop - $my_i - $(Tp(1))
                                        end,
                                        body = Pipeline([
                                            Phase(
                                                stride = (ctx, idx, ext) -> value(my_i_start),
                                                body = (start, step) -> Run(Simplify(Fill(virtual_level_default(lvl)))),
                                            ),
                                            Phase(
                                                body = (start, step) -> Lookup(
                                                    body = (i) -> Thunk(
                                                        preamble = quote
                                                            $my_q = $my_q_ofs + $(ctx(i))
                                                        end,
                                                        body = get_level_reader(lvl.lvl, ctx, value(my_q, lvl.Tp), protos...),
                                                    )
                                                )
                                            )
                                        ]),
                                        epilogue = quote
                                            $my_r += $(Tp(1))
                                        end
                                    ),
                                    literal(true) => Stepper(
                                        seek = (ctx, ext) -> quote
                                            while $my_r + $(Tp(1)) < $my_r_stop && $(lvl.ex).idx[$my_r] < $(ctx(getstart(ext)))
                                                $my_r += $(Tp(1))
                                            end
                                        end,
                                        body = Thunk(
                                            preamble = quote
                                                $my_i = $(lvl.ex).idx[$my_r]
                                                $my_q_stop = $(lvl.ex).ofs[$my_r + $(Tp(1))]
                                                $my_i_start = $my_i - ($my_q_stop - $(lvl.ex).ofs[$my_r])
                                                $my_q_ofs = $my_q_stop - $my_i - $(Tp(1))
                                            end,
                                            body = Step(
                                                stride = (ctx, idx, ext) -> value(my_i),
                                                body = (ctx, idx, ext, ext_2) -> Thunk(
                                                    body = Pipeline([
                                                        Phase(
                                                            stride = (ctx, idx, ext) -> value(my_i_start),
                                                            body = (start, step) -> Run(Simplify(Fill(virtual_level_default(lvl)))),
                                                        ),
                                                        Phase(
                                                            body = (start, step) -> Lookup(
                                                                body = (i) -> Thunk(
                                                                    preamble = quote
                                                                        $my_q = $my_q_ofs + $(ctx(i))
                                                                    end,
                                                                    body = get_level_reader(lvl.lvl, ctx, value(my_q, lvl.Tp), protos...),
                                                                )
                                                            )
                                                        )
                                                    ]),
                                                    epilogue = quote
                                                        $my_r += ($(ctx(getstop(ext_2))) == $my_i)
                                                    end
                                                )
                                            )
                                        )
                                    )
                                ])
                            )
                        ),
                    )
                ),
                Phase(
                    body = (start, step) -> Run(Simplify(Fill(virtual_level_default(lvl))))
                )
            ])
        )
    )
end

set_clean!(lvl::VirtualSparseVBLLevel, ctx) = :($(lvl.dirty) = false)
get_dirty(lvl::VirtualSparseVBLLevel, ctx) = value(lvl.dirty, Bool)

function get_level_updater(lvl::VirtualSparseVBLLevel, ctx, pos, ::Union{Nothing, Extrude}, protos...)
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_p = ctx.freshen(tag, :_p)
    my_q = ctx.freshen(tag, :_q)
    my_i_prev = ctx.freshen(tag, :_i_prev)
    qos = ctx.freshen(tag, :_qos)
    ros = ctx.freshen(tag, :_ros)
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    ros_fill = lvl.ros_fill
    ros_stop = lvl.ros_stop

    Furlable(
        val = virtual_level_default(lvl),
        size = virtual_level_size(lvl, ctx),
        body = (ctx, idx, ext) -> Thunk(
            preamble = quote
                $ros = $ros_fill
                $qos = $qos_fill + 1
                $my_i_prev = $(Ti(-1))
            end,
            body = AcceptSpike(
                val = virtual_level_default(lvl),
                tail = (ctx, idx) -> Thunk(
                    preamble = quote
                        if $qos > $qos_stop
                            $qos_stop = max($qos_stop << 1, 1)
                            $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, lvl.Tp), value(qos_stop, lvl.Tp)), ctx))
                        end
                        $(set_clean!(lvl.lvl, ctx))
                    end,
                    body = get_level_updater(lvl.lvl, ctx, value(qos, lvl.Tp), protos...),
                    epilogue = quote
                        if $(ctx(get_dirty(lvl.lvl, ctx)))
                            $(lvl.dirty) = true
                            if $(ctx(idx)) > $my_i_prev + $(Ti(1))
                                $ros += $(Tp(1))
                                if $ros > $ros_stop
                                    $ros_stop = max($ros_stop << 1, 1)
                                    $resize_if_smaller!($(lvl.ex).idx, $ros_stop)
                                    $resize_if_smaller!($(lvl.ex).ofs, $ros_stop + 1)
                                end
                            end
                            $(lvl.ex).idx[$ros] = $my_i_prev = $(ctx(idx))
                            $(qos) += $(Tp(1))
                            $(lvl.ex).ofs[$ros + 1] = $qos
                        end
                    end
                )
            ),
            epilogue = quote
                $(lvl.ex).pos[$(ctx(pos)) + 1] = $ros - $ros_fill
                $ros_fill = $ros
                $qos_fill = $qos - 1
            end
        )
    )
end