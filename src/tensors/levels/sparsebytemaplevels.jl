"""
    SparseByteMapLevel{[Ti=Int], [Ptr, Tbl]}(lvl, [dims])

Like the [`SparseListLevel`](@ref), but a dense bitmap is used to encode
which slices are stored. This allows the ByteMap level to support random access.

`Ti` is the type of the last tensor index, and `Tp` is the type used for
positions in the level. 

```jldoctest
julia> Tensor(Dense(SparseByteMap(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
Dense [:,1:3]
├─ [:, 1]: SparseByteMap (0.0) [1:3]
│  ├─ [1]: 10.0
│  └─ [2]: 30.0
├─ [:, 2]: SparseByteMap (0.0) [1:3]
└─ [:, 3]: SparseByteMap (0.0) [1:3]
   ├─ [1]: 0.0
   └─ [3]: 0.0

julia> Tensor(SparseByteMap(SparseByteMap(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
SparseByteMap (0.0) [:,1:3]
├─ [:, 1]: SparseByteMap (0.0) [1:3]
│  ├─ [1]: 10.0
│  └─ [2]: 30.0
└─ [:, 3]: SparseByteMap (0.0) [1:3]
```
"""
struct SparseByteMapLevel{Ti, Ptr, Tbl, Srt, Lvl} <: AbstractLevel
    lvl::Lvl
    shape::Ti
    ptr::Ptr
    tbl::Tbl
    srt::Srt
end
const SparseByteMap = SparseByteMapLevel
SparseByteMapLevel(lvl::Lvl) where {Lvl} = SparseByteMapLevel{Int}(lvl)
SparseByteMapLevel(lvl, shape, args...) = SparseByteMapLevel{typeof(shape)}(lvl, shape, args...)
SparseByteMapLevel{Ti}(lvl) where {Ti} = SparseByteMapLevel{Ti}(lvl, zero(Ti))
SparseByteMapLevel{Ti}(lvl, shape) where {Ti} = 
    SparseByteMapLevel{Ti}(lvl, shape, postype(lvl)[1], Bool[], Tuple{postype(lvl), Ti}[])
SparseByteMapLevel{Ti}(lvl::Lvl, shape, ptr::Ptr, tbl::Tbl, srt::Srt) where {Ti, Lvl, Ptr, Tbl, Srt} = 
    SparseByteMapLevel{Ti, Ptr, Tbl, Srt, Lvl}(lvl, shape, ptr, tbl, srt)

Base.summary(lvl::SparseByteMapLevel) = "SparseByteMap($(summary(lvl.lvl)))"
similar_level(lvl::SparseByteMapLevel) = SparseByteMap(similar_level(lvl.lvl))
similar_level(lvl::SparseByteMapLevel, dims...) = SparseByteMap(similar_level(lvl.lvl, dims[1:end-1]...), dims[end])

function postype(::Type{SparseByteMapLevel{Ti, Ptr, Tbl, Srt, Lvl}}) where {Ti, Ptr, Tbl, Srt, Lvl}
    return postype(Lvl)
end

function moveto(lvl::SparseByteMapLevel{Ti}, device) where {Ti}
    lvl_2 = moveto(lvl.lvl, device)
    ptr_2 = moveto(lvl.ptr, device)
    tbl_2 = moveto(lvl.tbl, device)
    srt_2 = moveto(lvl.srt, device)
    return  SparseByteMapLevel{Ti}(lvl_2, lvl.shape, ptr_2, tbl_2, srt_2)
end


pattern!(lvl::SparseByteMapLevel{Ti}) where {Ti} = 
    SparseByteMapLevel{Ti}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)

redefault!(lvl::SparseByteMapLevel{Ti}, init) where {Ti} = 
    SparseByteMapLevel{Ti}(redefault!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)

Base.resize!(lvl::SparseByteMapLevel{Ti}, dims...) where {Ti} = 
    SparseByteMapLevel{Ti}(resize!(lvl.lvl, dims[1:end-1]...), dims[end], lvl.ptr, lvl.tbl, lvl.srt)

function countstored_level(lvl::SparseByteMapLevel, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1] - 1)
end

function Base.show(io::IO, lvl::SparseByteMapLevel{Ti, Ptr, Tbl, Srt, Lvl},) where {Ti, Ptr, Tbl, Srt, Lvl}
    if get(io, :compact, false)
        print(io, "SparseByteMap(")
    else
        print(io, "SparseByteMap{$Ti}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(IOContext(io, :typeinfo=>Ti), lvl.shape)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(io, lvl.ptr)
        print(io, ", ")
        show(io, lvl.tbl)
        print(io, ", ")
        show(io, lvl.srt)
    end
    print(io, ")")
end

labelled_show(io::IO, fbr::SubFiber{<:SparseByteMapLevel}) =
    print(io, "SparseByteMap (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", size(fbr)[end], "]")

function labelled_children(fbr::SubFiber{<:SparseByteMapLevel})
    lvl = fbr.lvl
    pos = fbr.pos
    pos + 1 > length(lvl.ptr) && return []
    map(lvl.ptr[pos]:lvl.ptr[pos + 1] - 1) do qos
        LabelledTree(cartesian_label([range_label() for _ = 1:ndims(fbr) - 1]..., lvl.srt[qos][2]), SubFiber(lvl.lvl, qos))
    end
end

@inline level_ndims(::Type{<:SparseByteMapLevel{Ti, Ptr, Tbl, Srt, Lvl}}) where {Ti, Ptr, Tbl, Srt, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseByteMapLevel) = (level_size(lvl.lvl)..., lvl.shape)
@inline level_axes(lvl::SparseByteMapLevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.shape))
@inline level_eltype(::Type{<:SparseByteMapLevel{Ti, Ptr, Tbl, Srt, Lvl}}) where {Ti, Ptr, Tbl, Srt, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseByteMapLevel{Ti, Ptr, Tbl, Srt, Lvl}}) where {Ti, Ptr, Tbl, Srt, Lvl}= level_default(Lvl)
data_rep_level(::Type{<:SparseByteMapLevel{Ti, Ptr, Tbl, Srt, Lvl}}) where {Ti, Ptr, Tbl, Srt, Lvl} = SparseData(data_rep_level(Lvl))

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

mutable struct VirtualSparseByteMapLevel <: AbstractVirtualLevel
    lvl
    ex
    Ti
    ptr
    tbl
    srt
    shape
    qos_fill
    qos_stop
end
  
is_level_injective(ctx, lvl::VirtualSparseByteMapLevel) = [is_level_injective(ctx, lvl.lvl)..., false]
function is_level_atomic(ctx, lvl::VirtualSparseByteMapLevel)
    (below, atomic) = is_level_atomic(ctx, lvl.lvl)
    return ([below; [atomic for _ in 1:num_indexable(lvl, ctx)]], atomic)
end
function is_level_concurrent(ctx, lvl::VirtualSparseByteMapLevel)
    (data, _) = is_level_concurrent(ctx, lvl.lvl)
    return ([data; [false for _ in 1:num_indexable(lvl, ctx)]], false)
end
num_indexable(lvl::VirtualSparseByteMapLevel, ctx) = virtual_level_ndims(lvl, ctx) - virtual_level_ndims(lvl.lvl, ctx)

function virtualize(ex, ::Type{SparseByteMapLevel{Ti, Ptr, Tbl, Srt, Lvl}}, ctx, tag=:lvl) where {Ti, Ptr, Tbl, Srt, Lvl}
    sym = freshen(ctx, tag)
    shape = value(:($sym.shape), Int)
    qos_fill = freshen(ctx, sym, :_qos_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    ptr = freshen(ctx, tag, :_ptr)
    tbl = freshen(ctx, tag, :_tbl)
    srt = freshen(ctx, tag, :_srt)
    push!(ctx.preamble, quote
        $sym = $ex
        $ptr = $ex.ptr
        $tbl = $ex.tbl
        $srt = $ex.srt
        $qos_stop = $qos_fill = length($sym.srt)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseByteMapLevel(lvl_2, sym, Ti, ptr, tbl, srt, shape, qos_fill, qos_stop)
end
function lower(lvl::VirtualSparseByteMapLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SparseByteMapLevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.ptr),
            $(lvl.tbl),
            $(lvl.srt),
        )
    end
end

function virtual_moveto_level(lvl::VirtualSparseByteMapLevel, ctx::AbstractCompiler, arch)
    ptr_2 = freshen(ctx.code, lvl.ptr)
    tbl_2 = freshen(ctx.code, lvl.tbl)
    srt_2 = freshen(ctx.code, lvl.srt)
    push!(ctx.code.preamble, quote
        $ptr_2 = $(lvl.ptr)
        $tbl_2 = $(lvl.tbl)
        $srt_2 = $(lvl.srt)
        $(lvl.ptr) = moveto($(lvl.ptr), $(ctx(arch)))
        $(lvl.tbl) = moveto($(lvl.tbl), $(ctx(arch)))
        $(lvl.srt) = moveto($(lvl.srt), $(ctx(arch)))
    end)
    push!(ctx.code.epilogue, quote
        $(lvl.ptr) = $ptr_2
        $(lvl.tbl) = $tbl_2
        $(lvl.srt) = $srt_2
    end)
    virtual_moveto_level(lvl.lvl, ctx, arch)
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

postype(lvl::VirtualSparseByteMapLevel) = postype(lvl.lvl)

function declare_level!(lvl::VirtualSparseByteMapLevel, ctx::AbstractCompiler, pos, init)
    Ti = lvl.Ti
    Tp = postype(lvl)
    r = freshen(ctx.code, lvl.ex, :_r)
    p = freshen(ctx.code, lvl.ex, :_p)
    q = freshen(ctx.code, lvl.ex, :_q)
    i = freshen(ctx.code, lvl.ex, :_i)
    push!(ctx.code.preamble, quote
        for $r = 1:$(lvl.qos_fill)
            $p = first($(lvl.srt)[$r])
            $(lvl.ptr)[$p] = $(Tp(0))
            $(lvl.ptr)[$p + 1] = $(Tp(0))
            $i = last($(lvl.srt)[$r])
            $q = ($p - $(Tp(1))) * $(ctx(lvl.shape)) + $i
            $(lvl.tbl)[$q] = false
            if $(supports_reassembly(lvl.lvl))
                $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(q, Tp), value(q, Tp)), ctx))
            end
        end
        $(lvl.qos_fill) = 0
        if $(!supports_reassembly(lvl.lvl))
            $(lvl.qos_stop) = $(Tp(0))
        end
        $(lvl.ptr)[1] = 1
    end)
    if !supports_reassembly(lvl.lvl)
        lvl.lvl = declare_level!(lvl.lvl, ctx, call(*, pos, lvl.shape), init)
    end
    return lvl
end

function thaw_level!(lvl::VirtualSparseByteMapLevel, ctx::AbstractCompiler, pos)
    Ti = lvl.Ti
    Tp = postype(lvl)
    p = freshen(ctx.code, lvl.ex, :_p)
    lvl.lvl = thaw_level!(lvl.lvl, ctx, call(*, pos, lvl.shape))
    return lvl
end

function assemble_level!(lvl::VirtualSparseByteMapLevel, ctx, pos_start, pos_stop)
    Ti = lvl.Ti
    Tp = postype(lvl)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    q_start = freshen(ctx.code, lvl.ex, :q_start)
    q_stop = freshen(ctx.code, lvl.ex, :q_stop)
    q = freshen(ctx.code, lvl.ex, :q)

    quote
        $q_start = ($(ctx(pos_start)) - $(Tp(1))) * $(ctx(lvl.shape)) + $(Tp(1))
        $q_stop = $(ctx(pos_stop)) * $(ctx(lvl.shape))
        Finch.resize_if_smaller!($(lvl.ptr), $pos_stop + 1)
        Finch.fill_range!($(lvl.ptr), 0, $pos_start + 1, $pos_stop + 1)
        Finch.resize_if_smaller!($(lvl.tbl), $q_stop)
        Finch.fill_range!($(lvl.tbl), false, $q_start, $q_stop)
        $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(q_start, Tp), value(q_stop, Tp)), ctx))
    end
end

function freeze_level!(lvl::VirtualSparseByteMapLevel, ctx::AbstractCompiler, pos_stop)
    r = freshen(ctx.code, lvl.ex, :_r)
    p = freshen(ctx.code, lvl.ex, :_p)
    p_prev = freshen(ctx.code, lvl.ex, :_p_prev)
    pos_stop = cache!(ctx, :pos_stop, pos_stop)
    Ti = lvl.Ti
    Tp = postype(lvl)
    push!(ctx.code.preamble, quote
        resize!($(lvl.ptr), $(ctx(pos_stop)) + 1)
        resize!($(lvl.tbl), $(ctx(pos_stop)) * $(ctx(lvl.shape)))
        resize!($(lvl.srt), $(lvl.qos_fill))
        sort!($(lvl.srt))
        $p_prev = $(Tp(0))
        for $r = 1:$(lvl.qos_fill)
            $p = first($(lvl.srt)[$r])
            if $p != $p_prev
                $(lvl.ptr)[$p_prev + 1] = $r
                $(lvl.ptr)[$p] = $r
            end
            $p_prev = $p
        end
        $(lvl.ptr)[$p_prev + 1] = $(lvl.qos_fill) + 1
        $(lvl.qos_stop) = $(lvl.qos_fill)
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, call(*, pos_stop, lvl.shape))
    return lvl
end

function instantiate(fbr::VirtualSubFiber{VirtualSparseByteMapLevel}, ctx, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = postype(lvl)
    my_i = freshen(ctx.code, tag, :_i)
    my_q = freshen(ctx.code, tag, :_q)
    my_r = freshen(ctx.code, tag, :_r)
    my_r_stop = freshen(ctx.code, tag, :_r_stop)
    my_i_stop = freshen(ctx.code, tag, :_i_stop)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_r = $(lvl.ptr)[$(ctx(pos))]
                $my_r_stop = $(lvl.ptr)[$(ctx(pos)) + 1]
                if $my_r != 0 && $my_r < $my_r_stop
                    $my_i = last($(lvl.srt)[$my_r])
                    $my_i_stop = last($(lvl.srt)[$my_r_stop - 1])
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
                            while $my_r + $(Tp(1)) < $my_r_stop && last($(lvl.srt)[$my_r]) < $(ctx(getstart(ext)))
                                $my_r += $(Tp(1))
                            end
                        end,
                        preamble = :($my_i = last($(lvl.srt)[$my_r])),
                        stop = (ctx, ext) -> value(my_i),
                        chunk = Spike(
                            body = Fill(virtual_level_default(lvl)),
                            tail = Thunk(
                                preamble = :($my_q = ($(ctx(pos)) - $(Tp(1))) * $(ctx(lvl.shape)) + $my_i),
                                body = (ctx) -> instantiate(VirtualSubFiber(lvl.lvl, value(my_q, lvl.Ti)), ctx, mode, subprotos),
                            ),
                        ),
                        next = (ctx, ext) -> :($my_r += $(Tp(1))),
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end

function instantiate(fbr::VirtualSubFiber{VirtualSparseByteMapLevel}, ctx, mode::Reader, subprotos, ::typeof(gallop))
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = postype(lvl)
    my_i = freshen(ctx.code, tag, :_i)
    my_q = freshen(ctx.code, tag, :_q)
    my_r = freshen(ctx.code, tag, :_r)
    my_r_stop = freshen(ctx.code, tag, :_r_stop)
    my_i_stop = freshen(ctx.code, tag, :_i_stop)
    my_j = freshen(ctx.code, tag, :_j)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_r = $(lvl.ptr)[$(ctx(pos))]
                $my_r_stop = $(lvl.ptr)[$(ctx(pos)) + 1]
                if $my_r != 0 && $my_r < $my_r_stop
                    $my_i = last($(lvl.srt)[$my_r])
                    $my_i_stop = last($(lvl.srt)[$my_r_stop - 1])
                else
                    $my_i = $(Tp(1))
                    $my_i_stop = $(Tp(0))
                end
            end,
            body = (ctx) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> value(my_i_stop),
                    body = (ctx, ext) -> Jumper(
                        seek = (ctx, ext) -> quote
                            while $my_r + $(Tp(1)) < $my_r_stop && last($(lvl.srt)[$my_r]) < $(ctx(getstart(ext)))
                                $my_r += $(Tp(1))
                            end
                        end,
                        preamble = :($my_i = last($(lvl.srt)[$my_r])),
                        stop = (ctx, ext) -> value(my_i),
                        chunk =  Spike(
                            body = Fill(virtual_level_default(lvl)),
                            tail = Thunk(
                                preamble = :($my_q = ($(ctx(pos)) - $(Tp(1))) * $(ctx(lvl.shape)) + $my_i),
                                body = (ctx) -> instantiate(VirtualSubFiber(lvl.lvl, value(my_q, lvl.Ti)), ctx, mode, subprotos),
                            ),
                        ),
                        next = (ctx, ext) -> :($my_r += $(Tp(1)))
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end


function instantiate(fbr::VirtualSubFiber{VirtualSparseByteMapLevel}, ctx, mode::Reader, subprotos, ::typeof(follow))
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    my_q = freshen(ctx.code, tag, :_q)
    q = pos


    Furlable(
        body = (ctx, ext) -> Lookup(
            body = (ctx, i) -> Thunk(
                preamble = quote
                    $my_q = $(ctx(q)) * $(ctx(lvl.shape)) + $(ctx(i))
                end,
                body = (ctx) -> Switch([
                    value(:($tbl[$my_q])) => instantiate(VirtualSubFiber(lvl.lvl, pos), ctx, mode, subprotos),
                    literal(true) => Fill(virtual_level_default(lvl))
                ])
            )
        )
    )
end

instantiate(fbr::VirtualSubFiber{VirtualSparseByteMapLevel}, ctx, mode::Updater, protos) = 
    instantiate(VirtualHollowSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, mode, protos)
function instantiate(fbr::VirtualHollowSubFiber{VirtualSparseByteMapLevel}, ctx, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(extrude), typeof(laminate)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    my_q = freshen(ctx.code, tag, :_q)
    dirty = freshen(ctx.code, :dirty)

    Furlable(
        body = (ctx, ext) -> Lookup(
            body = (ctx, idx) -> Thunk(
                preamble = quote
                    $my_q = ($(ctx(pos)) - $(Tp(1))) * $(ctx(lvl.shape)) + $(ctx(idx))
                    $dirty = false
                end,
                body = (ctx) -> instantiate(VirtualHollowSubFiber(lvl.lvl, value(my_q, lvl.Ti), dirty), ctx, mode, subprotos),
                epilogue = quote
                    if $dirty
                        $(fbr.dirty) = true
                        if !$(lvl.tbl)[$my_q]
                            $(lvl.tbl)[$my_q] = true
                            $(lvl.qos_fill) += 1
                            if $(lvl.qos_fill) > $(lvl.qos_stop)
                                $(lvl.qos_stop) = max($(lvl.qos_stop) << 1, 1)
                                Finch.resize_if_smaller!($(lvl.srt), $(lvl.qos_stop))
                            end
                            $(lvl.srt)[$(lvl.qos_fill)] = ($(ctx(pos)), $(ctx(idx)))
                        end
                    end
                end
            )
        )
    )
end
