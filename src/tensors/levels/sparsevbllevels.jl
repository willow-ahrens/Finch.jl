"""
SparseVBLLevel{[Ti=Int], [Tp=Int], [Ptr=Vector{Tp}], [Idx=Vector{Ti}], [Ofs=Vector{Ofs}]}(lvl, [dim])

Like the [`SparseListLevel`](@ref), but contiguous subfibers are stored together in blocks.

```jldoctest
julia> Fiber!(Dense(SparseVBL(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
Dense [:,1:3]
├─[:,1]: SparseList (0.0) [1:3]
│ ├─[1]: 10.0
│ ├─[2]: 30.0
├─[:,2]: SparseList (0.0) [1:3]
├─[:,3]: SparseList (0.0) [1:3]
│ ├─[1]: 20.0
│ ├─[3]: 40.0

julia> Fiber!(SparseVBL(SparseVBL(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
SparseList (0.0) [:,1:3]
├─[:,1]: SparseList (0.0) [1:3]
│ ├─[1]: 10.0
│ ├─[2]: 30.0
├─[:,3]: SparseList (0.0) [1:3]
│ ├─[1]: 20.0
│ ├─[3]: 40.0
"""
struct SparseVBLLevel{Ti, Ptr<:AbstractVector, Idx<:AbstractVector, Ofs<:AbstractVector, Lvl} <: AbstractLevel
    lvl::Lvl
    shape::Ti
    ptr::Ptr
    idx::Idx
    ofs::Ofs
end

const SparseVBL = SparseVBLLevel
SparseVBLLevel(lvl::Lvl) where {Lvl} = SparseVBLLevel{Int}(lvl)
SparseVBLLevel(lvl, shape, args...) = SparseVBLLevel{typeof(shape)}(lvl, shape, args...)
SparseVBLLevel{Ti}(lvl) where {Ti} = SparseVBLLevel{Ti}(lvl, zero(Ti))
SparseVBLLevel{Ti}(lvl, shape) where {Ti} = SparseVBLLevel{Ti}(lvl, shape, postype(lvl)[1], Ti[], postype(lvl)[])
SparseVBLLevel{Ti}(lvl::Lvl, shape, ptr::Ptr, idx::Idx, ofs::Ofs) where {Ti, Lvl, Ptr, Idx, Ofs} =
    SparseVBLLevel{Ti, Ptr, Idx, Ofs, Lvl}(lvl, Ti(shape), ptr, idx, ofs)

function postype(::Type{SparseVBLLevel{Ti, Ptr, Idx, Ofs, Lvl}}) where {Ti, Ptr, Idx, Ofs, Lvl}
    return postype(Lvl)
end

function moveto(lvl::SparseVBLLevel{Ti}, device) where {Ti}
    lvl_2 = moveto(lvl.lvl, device)
    ptr_2 = moveto(lvl.ptr, device)
    idx_2 = moveto(lvl.idx, device)
    ofs_2 = moveto(lvl.ofs, device)
    return SparseVBLLevel{Ti}(lvl_2, lvl.shape, ptr_2, idx_2, ofs_2)
end

Base.summary(lvl::SparseVBLLevel) = "SparseVBL($(summary(lvl.lvl)))"
similar_level(lvl::SparseVBLLevel) = SparseVBL(similar_level(lvl.lvl))
similar_level(lvl::SparseVBLLevel, dim, tail...) = SparseVBL(similar_level(lvl.lvl, tail...), dim)

pattern!(lvl::SparseVBLLevel{Ti}) where {Ti} = 
    SparseVBLLevel{Ti}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.idx, lvl.ofs)

function countstored_level(lvl::SparseVBLLevel, pos)
    countstored_level(lvl.lvl, lvl.ofs[lvl.ptr[pos + 1]]-1)
end

redefault!(lvl::SparseVBLLevel{Ti}, init) where {Ti} = 
    SparseVBLLevel{Ti}(redefault!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.idx, lvl.ofs)

resize!(lvl::SparseVBLLevel{Ti}, dims...) where {Ti} = 
    SparseVBLLevel{Ti}(resize!(lvl.lvl, dims[1:end-1]...), dims[end], lvl.ptr, lvl.idx, lvl.ofs)

function Base.show(io::IO, lvl::SparseVBLLevel{Ti, Ptr, Idx, Ofs, Lvl}) where {Ti, Ptr, Idx, Ofs, Lvl}
    if get(io, :compact, false)
        print(io, "SparseVBL(")
    else
        print(io, "SparseVBL{$Ti}(")
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
        show(io, lvl.idx)
        print(io, ", ")
        show(io, lvl.ofs)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:SparseVBLLevel}, depth)
    p = fbr.pos
    crds = []
    for r in fbr.lvl.ptr[p]:fbr.lvl.ptr[p + 1] - 1
        i = fbr.lvl.idx[r]
        l = fbr.lvl.ofs[r + 1] - fbr.lvl.ofs[r]
        append!(crds, (i - l + 1):i)
    end

    print_coord(io, crd) = show(io, crd)
    get_fbr(crd) = fbr(crd)

    print(io, "SparseVBL (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", fbr.lvl.shape, "]")
    display_fiber_data(io, mime, fbr, depth, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:SparseVBLLevel{Ti, Ptr, Idx, Ofs, Lvl}}) where {Ti, Ptr, Idx, Ofs, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseVBLLevel) = (lvl.shape, level_size(lvl.lvl)...)
@inline level_axes(lvl::SparseVBLLevel) = (Base.OneTo(lvl.shape), level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:SparseVBLLevel{Ti, Ptr, Idx, Ofs, Lvl}}) where {Ti, Ptr, Idx, Ofs, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseVBLLevel{Ti, Ptr, Idx, Ofs, Lvl}}) where {Ti, Ptr, Idx, Ofs, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseVBLLevel{Ti, Ptr, Idx, Ofs, Lvl}}) where {Ti, Ptr, Idx, Ofs, Lvl} = SparseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SparseVBLLevel})() = fbr
function (fbr::SubFiber{<:SparseVBLLevel})(idxs...)
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    r = lvl.ptr[p] + searchsortedfirst(@view(lvl.idx[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), idxs[end]) - 1
    r < lvl.ptr[p + 1] || return default(fbr)
    q = lvl.ofs[r + 1] - 1 - lvl.idx[r] + idxs[end]
    q >= lvl.ofs[r] || return default(fbr)
    fbr_2 = SubFiber(lvl.lvl, q)
    return fbr_2(idxs[1:end-1]...)
end

mutable struct VirtualSparseVBLLevel <: AbstractVirtualLevel
    lvl
    ex
    Ti
    shape
    qos_fill
    qos_stop
    ros_fill
    ros_stop
    dirty
    ptr
    idx
    ofs
    prev_pos
end

is_level_injective(lvl::VirtualSparseVBLLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., false]
is_level_atomic(lvl::VirtualSparseVBLLevel, ctx) = false
  
postype(lvl::VirtualSparseVBLLevel) = postype(lvl.lvl)


function virtualize(ex, ::Type{SparseVBLLevel{Ti, Ptr, Idx, Ofs, Lvl}}, ctx, tag=:lvl) where {Ti, Ptr, Idx, Ofs, Lvl}
    sym = freshen(ctx, tag)
    shape = value(:($sym.shape), Int)
    qos_fill = freshen(ctx, sym, :_qos_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    ros_fill = freshen(ctx, sym, :_ros_fill)
    ros_stop = freshen(ctx, sym, :_ros_stop)
    dirty = freshen(ctx, sym, :_dirty)
    ptr = freshen(ctx, tag, :_ptr)
    idx = freshen(ctx, tag, :_idx)
    ofs = freshen(ctx, tag, :_ofs)
    push!(ctx.preamble, quote
        $sym = $ex
        $ptr = $sym.ptr
        $idx = $sym.idx
        $ofs = $sym.ofs
    end)
    prev_pos = freshen(ctx, sym, :_prev_pos)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseVBLLevel(lvl_2, sym, Ti, shape, qos_fill, qos_stop, ros_fill, ros_stop, dirty, ptr, idx, ofs, prev_pos)
end
function lower(lvl::VirtualSparseVBLLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SparseVBLLevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.ptr),
            $(lvl.idx),
            $(lvl.ofs),
        )
    end
end

Base.summary(lvl::VirtualSparseVBLLevel) = "SparseVBL($(summary(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseVBLLevel, ctx)
    ext = Extent(literal(lvl.Ti(1)), lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext)
end

function virtual_level_resize!(lvl::VirtualSparseVBLLevel, ctx, dims...)
    lvl.shape = getstop(dims[end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-1]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseVBLLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseVBLLevel) = virtual_level_default(lvl.lvl)

function virtual_moveto_level(lvl::VirtualSparseVBLLevel, ctx::AbstractCompiler, arch)
    ptr_2 = freshen(ctx.code, lvl.ptr)
    tbl_2 = freshen(ctx.code, lvl.tbl)
    ofs_2 = freshen(ctx.code, lvl.ofs)
    push!(ctx.code.preamble, quote
        $ptr_2 = $(lvl.ptr)
        $tbl_2 = $(lvl.tbl)
        $ofs_2 = $(lvl.ofs)
        $(lvl.ptr) = $moveto($(lvl.ptr), $(ctx(arch)))
        $(lvl.tbl) = $moveto($(lvl.tbl), $(ctx(arch)))
        $(lvl.ofs) = $moveto($(lvl.ofs), $(ctx(arch)))
    end)
    push!(ctx.code.epilogue, quote
        $(lvl.ptr) = $ptr_2
        $(lvl.tbl) = $tbl_2
        $(lvl.ofs) = $ofs_2
    end)
    virtual_moveto_level(lvl.lvl, ctx, arch)
end

function declare_level!(lvl::VirtualSparseVBLLevel, ctx::AbstractCompiler, pos, init)
    Tp = postype(lvl)
    Ti = lvl.Ti
    ros = call(-, call(getindex, :($(lvl.ptr)), call(+, pos, 1)), 1)
    qos = call(-, call(getindex, :($(lvl.ofs)), call(+, ros, 1)), 1)
    push!(ctx.code.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
        $(lvl.ros_fill) = $(Tp(0))
        $(lvl.ros_stop) = $(Tp(0))
        Finch.resize_if_smaller!($(lvl.ofs), 1)
        $(lvl.ofs)[1] = 1
    end)
    if issafe(ctx.mode)
        push!(ctx.code.preamble, quote
            $(lvl.prev_pos) = $(Tp(0))
        end)
    end
    lvl.lvl = declare_level!(lvl.lvl, ctx, qos, init)
    return lvl
end

function trim_level!(lvl::VirtualSparseVBLLevel, ctx::AbstractCompiler, pos)
    Tp = postype(lvl)
    Ti = lvl.Ti
    ros = freshen(ctx.code, :ros)
    qos = freshen(ctx.code, :qos)
    push!(ctx.code.preamble, quote
        resize!($(lvl.ptr), $(ctx(pos)) + 1)
        $ros = $(lvl.ptr)[end] - $(Tp(1))
        resize!($(lvl.idx), $ros)
        resize!($(lvl.ofs), $ros + 1)
        $qos = $(lvl.ofs)[end] - $(Tp(1))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, Tp))
    return lvl
end

function assemble_level!(lvl::VirtualSparseVBLLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        Finch.resize_if_smaller!($(lvl.ptr), $pos_stop + 1)
        Finch.fill_range!($(lvl.ptr), 0, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualSparseVBLLevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        for $p = 2:($pos_stop + 1)
            $(lvl.ptr)[$p] += $(lvl.ptr)[$p - 1]
        end
        $qos_stop = $(lvl.ptr)[$pos_stop + 1] - 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function instantiate(fbr::VirtualSubFiber{VirtualSparseVBLLevel}, ctx, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    Ti = lvl.Ti
    my_i = freshen(ctx.code, tag, :_i)
    my_i_start = freshen(ctx.code, tag, :_i)
    my_r = freshen(ctx.code, tag, :_r)
    my_r_stop = freshen(ctx.code, tag, :_r_stop)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)
    my_q_ofs = freshen(ctx.code, tag, :_q_ofs)
    my_i1 = freshen(ctx.code, tag, :_i1)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_r = $(lvl.ptr)[$(ctx(pos))]
                $my_r_stop = $(lvl.ptr)[$(ctx(pos)) + $(Tp(1))]
                if $my_r < $my_r_stop
                    $my_i = $(lvl.idx)[$my_r]
                    $my_i1 = $(lvl.idx)[$my_r_stop - $(Tp(1))]
                else
                    $my_i = $(Ti(1))
                    $my_i1 = $(Ti(0))
                end
            end,
            body = (ctx) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> value(my_i1),
                    body = (ctx, ext) -> Stepper(
                        seek = (ctx, ext) -> quote
                            if $(lvl.idx)[$my_r] < $(ctx(getstart(ext)))
                                $my_r = Finch.scansearch($(lvl.idx), $(ctx(getstart(ext))), $my_r, $my_r_stop - 1)
                            end
                        end,
                        preamble = quote
                            $my_i = $(lvl.idx)[$my_r]
                            $my_q_stop = $(lvl.ofs)[$my_r + $(Tp(1))]
                            $my_i_start = $my_i - ($my_q_stop - $(lvl.ofs)[$my_r])
                            $my_q_ofs = $my_q_stop - $my_i - $(Tp(1))
                        end,
                        stop = (ctx, ext) -> value(my_i),
                        body = (ctx, ext) -> Thunk(
                            body = (ctx) -> Sequence([
                                Phase(
                                    stop = (ctx, ext) -> value(my_i_start),
                                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl))),
                                ),
                                Phase(
                                    body = (ctx, ext) -> Lookup(
                                        body = (ctx, i) -> Thunk(
                                            preamble = :($my_q = $my_q_ofs + $(ctx(i))),
                                            body = (ctx) -> instantiate(VirtualSubFiber(lvl.lvl, value(my_q, Tp)), ctx, mode, subprotos),
                                        )
                                    )
                                )
                            ]),
                            epilogue = quote
                                $my_r += ($(ctx(getstop(ext))) == $my_i)
                            end
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

function instantiate(fbr::VirtualSubFiber{VirtualSparseVBLLevel}, ctx, mode::Reader, subprotos, ::typeof(gallop))
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    Ti = lvl.Ti
    my_i = freshen(ctx.code, tag, :_i)
    my_j = freshen(ctx.code, tag, :_j)
    my_i_start = freshen(ctx.code, tag, :_i)
    my_r = freshen(ctx.code, tag, :_r)
    my_r_stop = freshen(ctx.code, tag, :_r_stop)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)
    my_q_ofs = freshen(ctx.code, tag, :_q_ofs)
    my_i1 = freshen(ctx.code, tag, :_i1)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_r = $(lvl.ptr)[$(ctx(pos))]
                $my_r_stop = $(lvl.ptr)[$(ctx(pos)) + $(Tp(1))]
                if $my_r < $my_r_stop
                    $my_i = $(lvl.idx)[$my_r]
                    $my_i1 = $(lvl.idx)[$my_r_stop - $(Tp(1))]
                else
                    $my_i = $(Ti(1))
                    $my_i1 = $(Ti(0))
                end
            end,
            body = (ctx) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> value(my_i1),
                    body = (ctx, ext) -> Jumper(
                        seek = (ctx, ext) -> quote
                            if $(lvl.idx)[$my_r] < $(ctx(getstart(ext)))
                                $my_r = Finch.scansearch($(lvl.idx), $(ctx(getstart(ext))), $my_r, $my_r_stop - 1)
                            end
                        end,
                        preamble = quote
                            $my_i = $(lvl.idx)[$my_r]
                            $my_q_stop = $(lvl.ofs)[$my_r + $(Tp(1))]
                            $my_i_start = $my_i - ($my_q_stop - $(lvl.ofs)[$my_r])
                            $my_q_ofs = $my_q_stop - $my_i - $(Tp(1))
                        end,
                        stop = (ctx, ext) -> value(my_i),
                        chunk = Sequence([
                                    Phase(
                                        stop = (ctx, ext) -> value(my_i_start),
                                        body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl))),
                                    ),
                                    Phase(
                                        body = (ctx, ext) -> Lookup(
                                            body = (ctx, i) -> Thunk(
                                                preamble = :($my_q = $my_q_ofs + $(ctx(i))),
                                                body = (ctx) -> instantiate(VirtualSubFiber(lvl.lvl, value(my_q, Tp)), ctx, mode, subprotos),
                                            )
                                        )
                                    )
                                ]),
                        next = (ctx, ext) -> :($my_r += $(Tp(1))),
                    ), 
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end

instantiate(fbr::VirtualSubFiber{VirtualSparseVBLLevel}, ctx, mode::Updater, protos) =
    instantiate(VirtualHollowSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, mode, protos)
function instantiate(fbr::VirtualHollowSubFiber{VirtualSparseVBLLevel}, ctx, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    Ti = lvl.Ti
    my_p = freshen(ctx.code, tag, :_p)
    my_q = freshen(ctx.code, tag, :_q)
    my_i_prev = freshen(ctx.code, tag, :_i_prev)
    qos = freshen(ctx.code, tag, :_qos)
    ros = freshen(ctx.code, tag, :_ros)
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    ros_fill = lvl.ros_fill
    ros_stop = lvl.ros_stop
    dirty = freshen(ctx.code, tag, :dirty)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $ros = $ros_fill
                $qos = $qos_fill + 1
                $my_i_prev = $(Ti(-1))
                $(if issafe(ctx.mode)
                    quote
                        $(lvl.prev_pos) < $(ctx(pos)) || throw(FinchProtocolError("SparseVBLLevels cannot be updated multiple times"))
                    end
                end)
            end,
            body = (ctx) -> Lookup(
                body = (ctx, idx) -> Thunk(
                    preamble = quote
                        if $qos > $qos_stop
                            $qos_stop = max($qos_stop << 1, 1)
                            $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, Tp), value(qos_stop, Tp)), ctx))
                        end
                        $dirty = false
                    end,
                    body = (ctx) -> instantiate(VirtualHollowSubFiber(lvl.lvl, value(qos, Tp), dirty), ctx, mode, subprotos),
                    epilogue = quote
                        if $dirty
                            $(fbr.dirty) = true
                            if $(ctx(idx)) > $my_i_prev + $(Ti(1))
                                $ros += $(Tp(1))
                                if $ros > $ros_stop
                                    $ros_stop = max($ros_stop << 1, 1)
                                    Finch.resize_if_smaller!($(lvl.idx), $ros_stop)
                                    Finch.resize_if_smaller!($(lvl.ofs), $ros_stop + 1)
                                end
                            end
                            $(lvl.idx)[$ros] = $my_i_prev = $(ctx(idx))
                            $(qos) += $(Tp(1))
                            $(lvl.ofs)[$ros + 1] = $qos
                            $(if issafe(ctx.mode)
                                quote
                                    $(lvl.prev_pos) = $(ctx(pos))
                                end
                            end)
                        end
                    end
                )
            ),
            epilogue = quote
                $(lvl.ptr)[$(ctx(pos)) + 1] = $ros - $ros_fill
                $ros_fill = $ros
                $qos_fill = $qos - 1
            end
        )
    )
end
