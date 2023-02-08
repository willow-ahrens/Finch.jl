struct SparseBytemapLevel{Ti, Tp, Lvl}
    I::Ti
    pos::Vector{Tp}
    tbl::Vector{Bool}
    srt::Vector{Tuple{Tp, Ti}}
    lvl::Lvl
end
const SparseBytemap = SparseBytemapLevel

SparseBytemapLevel(lvl) = SparseBytemapLevel(0, lvl)
SparseBytemapLevel{Ti}(lvl) where {Ti} = SparseBytemapLevel{Ti}(zero(Ti), lvl)
SparseBytemapLevel{Ti, Tp}(lvl) where {Ti, Tp} = SparseBytemapLevel{Ti, Tp}(zero(Ti), lvl)

SparseBytemapLevel(I::Ti, lvl) where {Ti} = SparseBytemapLevel{Ti}(I, lvl)
SparseBytemapLevel{Ti}(I, lvl) where {Ti} = SparseBytemapLevel{Ti, Int}(Ti(I), lvl)
SparseBytemapLevel{Ti, Tp}(I, lvl) where {Ti, Tp} =
    SparseBytemapLevel{Ti, Tp}(Ti(I), Tp[1], Bool[], Tuple{Tp, Ti}[], lvl)

SparseBytemapLevel(I::Ti, pos::Vector{Tp}, tbl, srt, lvl::Lvl) where {Ti, Tp, Lvl} =
    SparseBytemapLevel{Ti, Tp, Lvl}(I, pos, tbl, srt, lvl)
SparseBytemapLevel{Ti}(I, pos::Vector{Tp}, tbl, srt, lvl::Lvl) where {Ti, Tp, Lvl} =
    SparseBytemapLevel{Ti, Tp, Lvl}(Ti(I), pos, tbl, srt, lvl)
SparseBytemapLevel{Ti, Tp}(I, pos, tbl, srt, lvl::Lvl) where {Ti, Tp, Lvl} =
    SparseBytemapLevel{Ti, Tp, Lvl}(Ti(I), pos, tbl, srt, lvl)

pattern!(lvl::SparseBytemapLevel{Ti, Tp}) where {Ti, Tp} = 
    SparseBytemapLevel{Ti, Tp}(lvl.I, lvl.pos, lvl.tbl, lvl.srt, lvl.srt_stop, pattern!(lvl.lvl))

"""
`f_code(sm)` = [SparseBytemapLevel](@ref).
"""
f_code(::Val{:sm}) = SparseBytemap
summary_f_code(lvl::SparseBytemapLevel) = "sm($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SparseBytemapLevel) = SparseBytemap(similar_level(lvl.lvl))
similar_level(lvl::SparseBytemapLevel, dim, tail...) = SparseBytemap(dim, similar_level(lvl.lvl, tail...))

function Base.show(io::IO, lvl::SparseBytemapLevel{Ti, Tp}) where {Ti, Tp}
    if get(io, :compact, false)
        print(io, "SparseBytemap(")
    else
        print(io, "SparseBytemap{$Ti, $Tp}(")
    end
    show(IOContext(io, :typeinfo=>Ti), lvl.I)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>Vector{Tp}), lvl.pos)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Bool}), lvl.tbl)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Tuple{Tp, Ti}}), lvl.srt)
    end
    print(io, ", ")
    show(io, lvl.lvl)
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:SparseBytemapLevel}, depth)
    p = fbr.pos
    crds = @view(fbr.lvl.srt[fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1])

    print_coord(io, (p, i)) = (print(io, "["); show(io, i); print(io, "]"))
    get_fbr((p, i),) = fbr(i)

    print(io, "│ " ^ depth); print(io, "SparseBytemap ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, depth, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:SparseBytemapLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseBytemapLevel) = (lvl.I, level_size(lvl.lvl)...)
@inline level_axes(lvl::SparseBytemapLevel) = (Base.OneTo(lvl.I), level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:SparseBytemapLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseBytemapLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseBytemapLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = SparseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SparseBytemapLevel})() = fbr
function (fbr::SubFiber{<:SparseBytemapLevel{Ti}})(i, tail...) where {Ti}
    lvl = fbr.lvl
    p = fbr.pos
    q = (p - 1) * lvl.I + i
    if lvl.tbl[q]
        fbr_2 = SubFiber(lvl.lvl, q)
        fbr_2(tail...)
    else
        default(fbr)
    end
end

mutable struct VirtualSparseBytemapLevel
    ex
    Ti
    Tp
    I
    qos_fill
    qos_stop
    dirty
    lvl
end
function virtualize(ex, ::Type{SparseBytemapLevel{Ti, Tp, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, Lvl}   
    sym = ctx.freshen(tag)
    I = value(:($sym.I), Int)
    qos_fill = ctx.freshen(sym, :_qos_fill)
    qos_stop = ctx.freshen(sym, :_qos_stop)
    push!(ctx.preamble, quote
        $sym = $ex
        #TODO this line is not strictly correct unless the tensor is trimmed.
        $qos_stop = $qos_fill = length($sym.srt)
    end)
    dirty = ctx.freshen(sym, :_dirty)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseBytemapLevel(sym, Ti, Tp, I, qos_fill, qos_stop, dirty, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSparseBytemapLevel)
    quote
        $SparseBytemapLevel{$(lvl.Ti), $(lvl.Tp)}(
            $(ctx(lvl.I)),
            $(lvl.ex).pos,
            $(lvl.ex).tbl,
            $(lvl.ex).srt,
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_code(lvl::VirtualSparseBytemapLevel) = "sm($(summary_f_code(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseBytemapLevel, ctx)
    ext = Extent(literal(lvl.Ti(1)), lvl.I)
    (ext, virtual_level_size(lvl.lvl, ctx)...)
end

function virtual_level_resize!(lvl::VirtualSparseBytemapLevel, ctx, dim, dims...)
    lvl.I = getstop(dim)
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseBytemapLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseBytemapLevel) = virtual_level_default(lvl.lvl)

function initialize_level!(lvl::VirtualSparseBytemapLevel, ctx::LowerJulia, pos)
    Ti = lvl.Ti
    Tp = lvl.Tp
    r = ctx.freshen(lvl.ex, :_r)
    p = ctx.freshen(lvl.ex, :_p)
    q = ctx.freshen(lvl.ex, :_q)
    i = ctx.freshen(lvl.ex, :_i)
    push!(ctx.preamble, quote
        for $r = 1:$(lvl.qos_fill)
            $p = first($(lvl.ex).srt[$r])
            $(lvl.ex).pos[$p] = $(Tp(0))
            $(lvl.ex).pos[$p + 1] = $(Tp(0))
            $i = last($(lvl.ex).srt[$r])
            $q = ($p - $(Tp(1))) * $(ctx(lvl.I)) + $i
            $(lvl.ex).tbl[$q] = false
            if $(supports_reassembly(lvl.lvl))
                $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(q, lvl.Tp), value(q, lvl.Tp)), ctx))
            end
        end
        $(lvl.qos_fill) = 0
        if $(!supports_reassembly(lvl.lvl))
            $(lvl.qos_stop) = $(Tp(0))
        end
        $(lvl.ex).pos[1] = 1
    end)
    if !supports_reassembly(lvl.lvl)
        lvl.lvl = initialize_level!(lvl.lvl, ctx, call(*, pos, lvl.I))
    end
    return lvl
end

function trim_level!(lvl::VirtualSparseBytemapLevel, ctx::LowerJulia, pos)
    ros = ctx.freshen(:ros)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).pos, $(ctx(pos)) + 1)
        resize!($(lvl.ex).tbl, $(ctx(pos)) * $(ctx(lvl.I)))
        resize!($(lvl.ex).srt, $(lvl.qos_fill))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, call(*, pos, lvl.I))
    return lvl
end

function assemble_level!(lvl::VirtualSparseBytemapLevel, ctx, pos_start, pos_stop)
    Ti = lvl.Ti
    Tp = lvl.Tp
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    q_start = ctx.freshen(lvl.ex, :q_start)
    q_stop = ctx.freshen(lvl.ex, :q_stop)
    q = ctx.freshen(lvl.ex, :q)

    quote
        $q_start = ($(ctx(pos_start)) - $(Tp(1))) * $(ctx(lvl.I)) + $(Tp(1))
        $q_stop = $(ctx(pos_stop)) * $(ctx(lvl.I))
        $resize_if_smaller!($(lvl.ex).pos, $pos_stop + 1)
        $fill_range!($(lvl.ex).pos, 0, $pos_start + 1, $pos_stop + 1)
        $resize_if_smaller!($(lvl.ex).tbl, $q_stop)
        $fill_range!($(lvl.ex).tbl, false, $q_start, $q_stop)
        $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(q_start, lvl.Tp), value(q_stop, lvl.Tp)), ctx))
    end
end

function freeze_level!(lvl::VirtualSparseBytemapLevel, ctx::LowerJulia, pos_stop)
    r = ctx.freshen(lvl.ex, :_r)
    p = ctx.freshen(lvl.ex, :_p)
    p_prev = ctx.freshen(lvl.ex, :_p_prev)
    pos_stop = cache!(ctx, :pos_stop, pos_stop)
    Ti = lvl.Ti
    Tp = lvl.Tp
    push!(ctx.preamble, quote
        sort!(@view $(lvl.ex).srt[1:$(lvl.qos_fill)])
        $p_prev = $(Tp(0))
        for $r = 1:$(lvl.qos_fill)
            $p = first($(lvl.ex).srt[$r])
            if $p != $p_prev
                $(lvl.ex).pos[$p_prev + 1] = $r
                $(lvl.ex).pos[$p] = $r
            end
            $p_prev = $p
        end
        $(lvl.ex).pos[$p_prev + 1] = $(lvl.qos_fill) + 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, call(*, pos_stop, lvl.I))
    return lvl
end

function get_level_reader(lvl::VirtualSparseBytemapLevel, ctx, pos, ::Union{Nothing, Walk}, protos...)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_r = ctx.freshen(tag, :_r)
    my_r_stop = ctx.freshen(tag, :_r_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)

    Furlable(
        size = virtual_level_size(lvl, ctx),
        body = (ctx, idx, ext) -> Thunk(
            preamble = quote
                $my_r = $(lvl.ex).pos[$(ctx(pos))]
                $my_r_stop = $(lvl.ex).pos[$(ctx(pos)) + 1]
                if $my_r != 0 && $my_r < $my_r_stop
                    $my_i = last($(lvl.ex).srt[$my_r])
                    $my_i_stop = last($(lvl.ex).srt[$my_r_stop - 1])
                else
                    $my_i = $(Ti(1))
                    $my_i_stop = $(Ti(0))
                end
            end,
            body = Pipeline([
                Phase(
                    stride = (ctx, idx, ext) -> value(my_i_stop),
                    body = (start, step) -> Stepper(
                        seek = (ctx, ext) -> quote
                            while $my_r + $(Tp(1)) < $my_r_stop && last($(lvl.ex).srt[$my_r]) < $(ctx(getstart(ext)))
                                $my_r += $(Tp(1))
                            end
                        end,
                        body = Thunk(
                            preamble = :(
                                $my_i = last($(lvl.ex).srt[$my_r])
                            ),
                            body = Step(
                                stride = (ctx, idx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Simplify(Fill(virtual_level_default(lvl))),
                                    tail = Thunk(
                                        preamble = quote
                                            $my_q = ($(ctx(pos)) - $(Tp(1))) * $(ctx(lvl.I)) + $my_i
                                        end,
                                        body = get_level_reader(lvl.lvl, ctx, value(my_q, lvl.Ti), protos...),
                                    ),
                                ),
                                next = (ctx, idx, ext) -> quote
                                    $my_r += $(Tp(1))
                                end
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

function get_level_reader(lvl::VirtualSparseBytemapLevel, ctx, pos, ::Gallop, protos...)
    lvl = fbr.lvl
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_r = ctx.freshen(tag, :_r)
    my_r_stop = ctx.freshen(tag, :_r_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)

    Furlable(
        size = virtual_level_size(lvl, ctx),
        body = (ctx, idx, ext) -> Thunk(
            preamble = quote
                $my_r = $(lvl.ex).pos[$(ctx(pos))]
                $my_r_stop = $(lvl.ex).pos[$(ctx(pos)) + 1]
                if $my_r != 0 && $my_r < $my_r_stop
                    $my_i = last($(lvl.ex).srt[$my_r])
                    $my_i_stop = last($(lvl.ex).srt[$my_r_stop - 1])
                else
                    $my_i = $(Tp(1))
                    $my_i_stop = $(Tp(0))
                end
            end,
            body = Pipeline([
                Phase(
                    stride = (ctx, idx, ext) -> value(my_i_stop),
                    body = (start, step) -> Jumper(
                        body = Thunk(
                            body = Jump(
                                seek = (ctx, ext) -> quote
                                    while $my_r + $(Tp(1)) < $my_r_stop && last($(lvl.ex).srt[$my_r]) < $(ctx(getstart(ext)))
                                        $my_r += $(Tp(1))
                                    end
                                    $my_i = last($(lvl.ex).srt[$my_r])
                                end,
                                stride = (ctx, ext) -> value(my_i),
                                body = (ctx, ext, ext_2) -> Switch([
                                    value(:($(ctx(getstop(ext_2))) == $my_i)) => Thunk(
                                        body = Spike(
                                            body = Simplify(Fill(virtual_level_default(lvl))),
                                            tail = Thunk(
                                                preamble = quote
                                                    $my_q = ($(ctx(pos)) - $(Tp(1))) * $(ctx(lvl.I)) + $my_i
                                                end,
                                                body = get_level_reader(lvl.lvl, ctx, value(my_q, lvl.Ti), protos...),
                                            ),
                                        ),
                                        epilogue = quote
                                            $my_r += $(Tp(1))
                                        end
                                    ),
                                    literal(true) => Stepper(
                                        seek = (ctx, ext) -> quote
                                            while $my_r + $(Tp(1)) < $my_r_stop && last($(lvl.ex).srt[$my_r]) < $(ctx(getstart(ext)))
                                                $my_r += $(Tp(1))
                                            end
                                        end,
                                        body = Thunk(
                                            preamble = :(
                                                $my_i = last($(lvl.ex).srt[$my_r])
                                            ),
                                            body = Step(
                                                stride = (ctx, idx, ext) -> value(my_i),
                                                chunk = Spike(
                                                    body = Simplify(Fill(virtual_level_default(lvl))),
                                                    tail = Thunk(
                                                        preamble = quote
                                                            $my_q = ($(ctx(pos)) - $(Tp(1))) * $(ctx(lvl.I)) + $my_i
                                                        end,
                                                        body = get_level_reader(lvl.lvl, ctx, value(my_q, lvl.Ti), protos...),
                                                    ),
                                                ),
                                                next = (ctx, idx, ext) -> quote
                                                    $my_r += $(Tp(1))
                                                end
                                            )
                                        )
                                    ),
                                ])
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


function get_level_reader(::VirtualSparseBytemapLevel, ctx, pos, ::Follow, protos...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_q = cgx.freshen(tag, :_q)
    q = pos


    Furlable(
        size = virtual_level_size(lvl, ctx),
        body = (ctx, idx, ext) -> Lookup(
            body = (i) -> Thunk(
                preamble = quote
                    $my_q = $(ctx(q)) * $(ctx(lvl.I)) + $(ctx(i))
                end,
                body = Switch([
                    value(:($tbl[$my_q])) => get_level_reader(lvl.lvl, ctx, pos, protos...),
                    literal(true) => Simplify(Fill(virtual_level_default(lvl)))
                ])
            )
        )
    )
end

set_clean!(lvl::VirtualSparseBytemapLevel, ctx) = :($(lvl.dirty) = false)
get_dirty(lvl::VirtualSparseBytemapLevel, ctx) = value(lvl.dirty, Bool)

function get_level_updater(lvl::VirtualSparseBytemapLevel, ctx, pos, ::Union{Nothing, Extrude, Laminate}, protos...)
    tag = lvl.ex
    Tp = lvl.Tp
    my_q = ctx.freshen(tag, :_q)

    Furlable(
        val = virtual_level_default(lvl),
        size = virtual_level_size(lvl, ctx),
        body = (ctx, idx, ext) -> AcceptSpike(
            val = virtual_level_default(lvl),
            tail = (ctx, idx) -> Thunk(
                preamble = quote
                    $(set_clean!(lvl.lvl, ctx))
                    $my_q = ($(ctx(pos)) - $(Tp(1))) * $(ctx(lvl.I)) + $(ctx(idx))
                end,
                body = get_level_updater(lvl.lvl, ctx, value(my_q, lvl.Ti), protos...),
                epilogue = quote
                    if $(ctx(get_dirty(lvl.lvl, ctx)))
                        $(lvl.dirty) = true
                        if !$(lvl.ex).tbl[$my_q]
                            $(lvl.ex).tbl[$my_q] = true
                            $(lvl.qos_fill) += 1
                            if $(lvl.qos_fill) > $(lvl.qos_stop)
                                $(lvl.qos_stop) = max($(lvl.qos_stop) << 1, 1)
                                $resize_if_smaller!($(lvl.ex).srt, $(lvl.qos_stop))
                            end
                            $(lvl.ex).srt[$(lvl.qos_fill)] = ($(ctx(pos)), $(ctx(idx)))
                        end
                    end
                end
            )
        )
    )
end