struct SparseByteMapLevel{Ti, Tp, VTp<:AbstractVector, BV<:AbstractVector{Bool}, VTpi<:AbstractVector{<:Tuple{Any, Any}}, Lvl}
    lvl::Lvl
    shape::Ti
    ptr:: VTp
    tbl::BV
    srt::VTpi
end
const SparseByteMap = SparseByteMapLevel
SparseByteMapLevel(lvl::Lvl) where {Lvl} = SparseByteMapLevel{indextype(Lvl)}(lvl)
SparseByteMapLevel(lvl, shape, args...) = SparseByteMapLevel{typeof(shape)}(lvl, shape, args...)
SparseByteMapLevel{Ti}(lvl::Lvl, args...) where {Ti, Lvl} = SparseByteMapLevel{Ti, postype(Lvl)}(lvl, args...)
SparseByteMapLevel{Ti, Tp}(lvl, args...) where {Ti, Tp} = SparseByteMapLevel{Ti, Tp,  memory_type(typeof(lvl)){Tp, 1}, memory_type(typeof(lvl)){Bool, 1}, memory_type(typeof(lvl)){Tuple{Tp, Ti}, 1}, typeof(lvl)}(lvl, args...)

SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl}(lvl) where {Ti, Tp, VTp, BV, VTpi, Lvl} = SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl}(lvl, zero(Ti))
SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl}(lvl, shape) where {Ti, Tp, VTp, BV, VTpi, Lvl} = 
    SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl}(lvl, Ti(shape), single(memory_type(Lvl){Tp, 1}), empty( memory_type(Lvl){Bool, 1}), empty(memory_type(Lvl){Tuple{Tp, Ti}, 1}))


Base.summary(lvl::SparseByteMapLevel) = "SparseByteMap($(summary(lvl.lvl)))"
similar_level(lvl::SparseByteMapLevel) = SparseByteMap(similar_level(lvl.lvl))
similar_level(lvl::SparseByteMapLevel, dims...) = SparseByteMap(similar_level(lvl.lvl, dims[1:end-1]...), dims[end])

function memory_type(::Type{SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl}}) where {Ti, Tp, VTp, BV, VTpi, Lvl}
    return memory_type(Lvl)
end

function postype(::Type{SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl}}) where {Ti, Tp, VTp, BV, VTpi, Lvl}
    return Tp
end

indextype(::Type{SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl}}) where {Ti, Tp, VTp, BV, VTpi, Lvl} = indextype(Ti)

function moveto(lvl:: SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl}, ::Type{MemType}) where {Ti, Tp, VTp, BV, VTpi, Lvl, MemType <: AbstractArray}
    lvl_2 = moveto(lvl.lvl, MemType)
    ptr_2 = MemType{Tp, 1}(lvl.ptr)
    tbl_2 = MemType{Bool, 1}(lvl.tbl)
    srt_2 = MemType{Tuple{Tp, Ti}, 1}(lvl.srt)
    return  SparseByteMapLevel{Ti, Tp, MemType{Tp, 1}, MemType{Bool, 1}, MemType{Tuple{Tp, Ti}, 1}, typeof(lvl_2)}(lvl_2, lvl.shape, ptr_2, tbl_2, srt_2)
end



pattern!(lvl::SparseByteMapLevel{Ti, Tp}) where {Ti, Tp} = 
    SparseByteMapLevel{Ti, Tp}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)

redefault!(lvl::SparseByteMapLevel{Ti, Tp}, init) where {Ti, Tp} = 
    SparseByteMapLevel{Ti, Tp}(redefault!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)

function countstored_level(lvl::SparseByteMapLevel, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1] - 1)
end

function Base.show(io::IO, lvl::SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl},) where {Ti, Tp, VTp, BV, VTpi, Lvl}
    if get(io, :compact, false)
        print(io, "SparseByteMap(")
    else
        print(io, "SparseByteMap{$Ti, $Tp}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(IOContext(io, :typeinfo=>Ti), lvl.shape)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>VTp), lvl.ptr)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>BV), lvl.tbl)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>VTpi), lvl.srt)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:SparseByteMapLevel}, depth)
    p = fbr.pos
    crds = @view(fbr.lvl.srt[fbr.lvl.ptr[p]:fbr.lvl.ptr[p + 1] - 1])

    print_coord(io, (p, i)) = show(io, i)
    get_fbr((p, i),) = fbr(i)

    print(io, "SparseByteMap (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", fbr.lvl.shape, "]")
    display_fiber_data(io, mime, fbr, depth, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl}}) where {Ti, Tp, VTp, BV, VTpi, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseByteMapLevel) = (level_size(lvl.lvl)..., lvl.shape)
@inline level_axes(lvl::SparseByteMapLevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.shape))
@inline level_eltype(::Type{<:SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl}}) where {Ti, Tp, VTp, BV, VTpi, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl}}) where {Ti, Tp, VTp, BV, VTpi, Lvl}= level_default(Lvl)
data_rep_level(::Type{<:SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl}}) where {Ti, Tp, VTp, BV, VTpi, Lvl} = SparseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SparseByteMapLevel})() = fbr
function (fbr::SubFiber{<:SparseByteMapLevel{Ti}})(idxs...) where {Ti}
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    q = (p - 1) * lvl.shape + idxs[end]
    if lvl.tbl[q]
        fbr_2 = SubFiber(lvl.lvl, q)
        fbr_2(idxs[1:end-1]...)
    else
        default(fbr)
    end
end

mutable struct VirtualSparseByteMapLevel
    lvl
    ex
    Ti
    Tp
    shape
    qos_fill
    qos_stop
end
function virtualize(ex, ::Type{SparseByteMapLevel{Ti, Tp, VTp, BV, VTpi, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, VTp, BV, VTpi, Lvl}
    sym = ctx.freshen(tag)
    shape = value(:($sym.shape), Int)
    qos_fill = ctx.freshen(sym, :_qos_fill)
    qos_stop = ctx.freshen(sym, :_qos_stop)
    push!(ctx.preamble, quote
        $sym = $ex
        #TODO this line is not strictly correct unless the tensor is trimmed.
        $qos_stop = $qos_fill = length($sym.srt)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseByteMapLevel(lvl_2, sym, Ti, Tp, shape, qos_fill, qos_stop)
end
function lower(lvl::VirtualSparseByteMapLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SparseByteMapLevel{$(lvl.Ti), $(lvl.Tp)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.ex).ptr,
            $(lvl.ex).tbl,
            $(lvl.ex).srt,
        )
    end
end

Base.summary(lvl::VirtualSparseByteMapLevel) = "SparseByteMap($(summary(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseByteMapLevel, ctx)
    ext = Extent(literal(lvl.Ti(1)), lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext)
end

function virtual_level_resize!(lvl::VirtualSparseByteMapLevel, ctx, dims...)
    lvl.shape = getstop(dims[end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-1]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseByteMapLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseByteMapLevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualSparseByteMapLevel, ctx::AbstractCompiler, pos, init)
    Ti = lvl.Ti
    Tp = lvl.Tp
    r = ctx.freshen(lvl.ex, :_r)
    p = ctx.freshen(lvl.ex, :_p)
    q = ctx.freshen(lvl.ex, :_q)
    i = ctx.freshen(lvl.ex, :_i)
    push!(ctx.preamble, quote
        for $r = 1:$(lvl.qos_fill)
            $p = first($(lvl.ex).srt[$r])
            $(lvl.ex).ptr[$p] = $(Tp(0))
            $(lvl.ex).ptr[$p + 1] = $(Tp(0))
            $i = last($(lvl.ex).srt[$r])
            $q = ($p - $(Tp(1))) * $(ctx(lvl.shape)) + $i
            $(lvl.ex).tbl[$q] = false
            if $(supports_reassembly(lvl.lvl))
                $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(q, lvl.Tp), value(q, lvl.Tp)), ctx))
            end
        end
        $(lvl.qos_fill) = 0
        if $(!supports_reassembly(lvl.lvl))
            $(lvl.qos_stop) = $(Tp(0))
        end
        $(lvl.ex).ptr[1] = 1
    end)
    if !supports_reassembly(lvl.lvl)
        lvl.lvl = declare_level!(lvl.lvl, ctx, call(*, pos, lvl.shape), init)
    end
    return lvl
end

function thaw_level!(lvl::VirtualSparseByteMapLevel, ctx::AbstractCompiler, pos)
    Ti = lvl.Ti
    Tp = lvl.Tp
    p = ctx.freshen(lvl.ex, :_p)
    push!(ctx.preamble, quote
        for $p = 1:$(ctx(pos))
            $(lvl.ex).ptr[$p] -= $(lvl.ex).ptr[$p + 1]
        end
        $(lvl.ex).ptr[1] = 1
    end)
    lvl.lvl = thaw_level!(lvl.lvl, ctx, call(*, pos, lvl.shape))
    return lvl
end

function trim_level!(lvl::VirtualSparseByteMapLevel, ctx::AbstractCompiler, pos)
    ros = ctx.freshen(:ros)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).ptr, $(ctx(pos)) + 1)
        resize!($(lvl.ex).tbl, $(ctx(pos)) * $(ctx(lvl.shape)))
        resize!($(lvl.ex).srt, $(lvl.qos_fill))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, call(*, pos, lvl.shape))
    return lvl
end

function assemble_level!(lvl::VirtualSparseByteMapLevel, ctx, pos_start, pos_stop)
    Ti = lvl.Ti
    Tp = lvl.Tp
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    q_start = ctx.freshen(lvl.ex, :q_start)
    q_stop = ctx.freshen(lvl.ex, :q_stop)
    q = ctx.freshen(lvl.ex, :q)

    quote
        $q_start = ($(ctx(pos_start)) - $(Tp(1))) * $(ctx(lvl.shape)) + $(Tp(1))
        $q_stop = $(ctx(pos_stop)) * $(ctx(lvl.shape))
        Finch.resize_if_smaller!($(lvl.ex).ptr, $pos_stop + 1)
        Finch.fill_range!($(lvl.ex).ptr, 0, $pos_start + 1, $pos_stop + 1)
        Finch.resize_if_smaller!($(lvl.ex).tbl, $q_stop)
        Finch.fill_range!($(lvl.ex).tbl, false, $q_start, $q_stop)
        $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(q_start, lvl.Tp), value(q_stop, lvl.Tp)), ctx))
    end
end

function freeze_level!(lvl::VirtualSparseByteMapLevel, ctx::AbstractCompiler, pos_stop)
    r = ctx.freshen(lvl.ex, :_r)
    p = ctx.freshen(lvl.ex, :_p)
    p_prev = ctx.freshen(lvl.ex, :_p_prev)
    pos_stop = cache!(ctx, :pos_stop, pos_stop)
    Ti = lvl.Ti
    Tp = lvl.Tp
    push!(ctx.preamble, quote
        sort!(view($(lvl.ex).srt, 1:$(lvl.qos_fill)))
        $p_prev = $(Tp(0))
        for $r = 1:$(lvl.qos_fill)
            $p = first($(lvl.ex).srt[$r])
            if $p != $p_prev
                $(lvl.ex).ptr[$p_prev + 1] = $r
                $(lvl.ex).ptr[$p] = $r
            end
            $p_prev = $p
        end
        $(lvl.ex).ptr[$p_prev + 1] = $(lvl.qos_fill) + 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, call(*, pos_stop, lvl.shape))
    return lvl
end

function instantiate_reader(fbr::VirtualSubFiber{VirtualSparseByteMapLevel}, ctx, ::Union{typeof(defaultread), typeof(walk)}, protos...)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_r = ctx.freshen(tag, :_r)
    my_r_stop = ctx.freshen(tag, :_r_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_r = $(lvl.ex).ptr[$(ctx(pos))]
                $my_r_stop = $(lvl.ex).ptr[$(ctx(pos)) + 1]
                if $my_r != 0 && $my_r < $my_r_stop
                    $my_i = last($(lvl.ex).srt[$my_r])
                    $my_i_stop = last($(lvl.ex).srt[$my_r_stop - 1])
                else
                    $my_i = $(Ti(1))
                    $my_i_stop = $(Ti(0))
                end
            end,
            body = (ctx) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> value(my_i_stop),
                    body = (ctx, ext) -> Stepper(
                        seek = (ctx, ext) -> quote
                            while $my_r + $(Tp(1)) < $my_r_stop && last($(lvl.ex).srt[$my_r]) < $(ctx(getstart(ext)))
                                $my_r += $(Tp(1))
                            end
                        end,
                        body = Thunk(
                            preamble = :(
                                $my_i = last($(lvl.ex).srt[$my_r])
                            ),
                            body = (ctx) -> Step(
                                stop = (ctx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Fill(virtual_level_default(lvl)),
                                    tail = Thunk(
                                        preamble = quote
                                            $my_q = ($(ctx(pos)) - $(Tp(1))) * $(ctx(lvl.shape)) + $my_i
                                        end,
                                        body = (ctx) -> instantiate_reader(VirtualSubFiber(lvl.lvl, value(my_q, lvl.Ti)), ctx, protos...),
                                    ),
                                ),
                                next = (ctx, ext) -> quote
                                    $my_r += $(Tp(1))
                                end
                            )
                        )
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end

function instantiate_reader(fbr::VirtualSubFiber{VirtualSparseByteMapLevel}, ctx, ::typeof(gallop), protos...)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_r = ctx.freshen(tag, :_r)
    my_r_stop = ctx.freshen(tag, :_r_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)
    my_j = ctx.freshen(tag, :_j)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_r = $(lvl.ex).ptr[$(ctx(pos))]
                $my_r_stop = $(lvl.ex).ptr[$(ctx(pos)) + 1]
                if $my_r != 0 && $my_r < $my_r_stop
                    $my_i = last($(lvl.ex).srt[$my_r])
                    $my_i_stop = last($(lvl.ex).srt[$my_r_stop - 1])
                else
                    $my_i = $(Tp(1))
                    $my_i_stop = $(Tp(0))
                end
            end,
            body = (ctx) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> value(my_i_stop),
                    body = (ctx, ext) -> Jumper(
                        body = Thunk(
                            body = (ctx) -> Jump(
                                seek = (ctx, ext) -> quote
                                    while $my_r + $(Tp(1)) < $my_r_stop && last($(lvl.ex).srt[$my_r]) < $(ctx(getstart(ext)))
                                        $my_r += $(Tp(1))
                                    end
                                    $my_i = last($(lvl.ex).srt[$my_r])
                                end,
                                stop = (ctx, ext) -> value(my_i),
                                body = (ctx, ext, ext_2) -> Switch([
                                    value(:($(ctx(getstop(ext_2))) == $my_i)) => Thunk(
                                        body = (ctx) -> Spike(
                                            body = Fill(virtual_level_default(lvl)),
                                            tail = Thunk(
                                                preamble = quote
                                                    $my_q = ($(ctx(pos)) - $(Tp(1))) * $(ctx(lvl.shape)) + $my_i
                                                end,
                                                body = (ctx) -> instantiate_reader(VirtualSubFiber(lvl.lvl, value(my_q, lvl.Ti)), ctx, protos...),
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
                                                $my_j = last($(lvl.ex).srt[$my_r])
                                            ),
                                            body = (ctx) -> Step(
                                                stop = (ctx, ext) -> value(my_j),
                                                chunk = Spike(
                                                    body = Fill(virtual_level_default(lvl)),
                                                    tail = Thunk(
                                                        preamble = quote
                                                            $my_q = ($(ctx(pos)) - $(Tp(1))) * $(ctx(lvl.shape)) + $my_j
                                                        end,
                                                        body = (ctx) -> instantiate_reader(VirtualSubFiber(lvl.lvl, value(my_q, lvl.Ti)), ctx, protos...),
                                                    ),
                                                ),
                                                next = (ctx, ext) -> quote
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
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end


function instantiate_reader(fbr::VirtualSubFiber{VirtualSparseByteMapLevel}, ctx, ::typeof(follow), protos...)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    my_q = cgx.freshen(tag, :_q)
    q = pos


    Furlable(
        body = (ctx, ext) -> Lookup(
            body = (ctx, i) -> Thunk(
                preamble = quote
                    $my_q = $(ctx(q)) * $(ctx(lvl.shape)) + $(ctx(i))
                end,
                body = (ctx) -> Switch([
                    value(:($tbl[$my_q])) => instantiate_reader(VirtualSubFiber(lvl.lvl, pos), ctx, protos...),
                    literal(true) => Fill(virtual_level_default(lvl))
                ])
            )
        )
    )
end

is_laminable_updater(lvl::VirtualSparseByteMapLevel, ctx, ::Union{typeof(defaultupdate), typeof(laminate), typeof(extrude)}, protos...) =
    is_laminable_updater(lvl.lvl, ctx, protos...)
instantiate_updater(fbr::VirtualSubFiber{VirtualSparseByteMapLevel}, ctx, protos...) = 
    instantiate_updater(VirtualTrackedSubFiber(fbr.lvl, fbr.pos, ctx.freshen(:null)), ctx, protos...)
function instantiate_updater(fbr::VirtualTrackedSubFiber{VirtualSparseByteMapLevel}, ctx, ::Union{typeof(defaultupdate), typeof(extrude), typeof(laminate)}, protos...)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = lvl.Tp
    my_q = ctx.freshen(tag, :_q)
    dirty = ctx.freshen(:dirty)

    Furlable(
        tight = is_laminable_updater(lvl.lvl, ctx, protos...) ? nothing : lvl.lvl,
        body = (ctx, ext) -> Lookup(
            body = (ctx, idx) -> Thunk(
                preamble = quote
                    $my_q = ($(ctx(pos)) - $(Tp(1))) * $(ctx(lvl.shape)) + $(ctx(idx))
                    $dirty = false
                end,
                body = (ctx) -> instantiate_updater(VirtualTrackedSubFiber(lvl.lvl, value(my_q, lvl.Ti), dirty), ctx, protos...),
                epilogue = quote
                    if $dirty
                        $(fbr.dirty) = true
                        if !$(lvl.ex).tbl[$my_q]
                            $(lvl.ex).tbl[$my_q] = true
                            $(lvl.qos_fill) += 1
                            if $(lvl.qos_fill) > $(lvl.qos_stop)
                                $(lvl.qos_stop) = max($(lvl.qos_stop) << 1, 1)
                                Finch.resize_if_smaller!($(lvl.ex).srt, $(lvl.qos_stop))
                            end
                            $(lvl.ex).srt[$(lvl.qos_fill)] = ($(ctx(pos)), $(ctx(idx)))
                        end
                    end
                end
            )
        )
    )
end
