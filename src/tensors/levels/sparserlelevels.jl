struct SparseRLELevel{Ti, Tp, VTp<:AbstractVector, VLTi<:AbstractVector, VRTi<:AbstractVector, Lvl}
    lvl::Lvl
    shape::Ti
    ptr::VTp
    left::VLTi
    right::VRTi
end

const SparseRLE = SparseRLELevel
SparseRLELevel(lvl:: Lvl) where {Lvl} = SparseRLELevel{indextype(Lvl)}(lvl)
SparseRLELevel(lvl, shape, args...) = SparseRLELevel{typeof(shape)}(lvl, shape, args...)
SparseRLELevel{Ti}(lvl, args...) where {Ti} =
    SparseRLELevel{Ti,
        postype(typeof(lvl)),
        (memtype(typeof(lvl))){postype(typeof(lvl)), 1},
        (memtype(typeof(lvl))){Ti, 1},
        (memtype(typeof(lvl))){Ti, 1},
        typeof(lvl)}(lvl, args...)
#SparseRLELevel{Ti, Tp}(lvl, args...) where {Ti, Tp} = SparseRLELevel{Ti, Tp, typeof(lvl)}(lvl, args...)

SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}(lvl) where {Ti, Tp, VTp, VLTi, VRTi, Lvl} = SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}(lvl, zero(Ti))
SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}(lvl, shape) where {Ti, Tp, VTp, VLTi, VRTi, Lvl} = 
    SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}(lvl, shape, single(VTp), empty(VLTi), empty(VRTi))

Base.summary(lvl::SparseRLELevel) = "SparseRLE($(summary(lvl.lvl)))"
similar_level(lvl::SparseRLELevel) = SparseRLE(similar_level(lvl.lvl))
similar_level(lvl::SparseRLELevel, dim, tail...) = SparseRLE(similar_level(lvl.lvl, tail...), dim)

function memtype(::Type{SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}}) where {Ti, Tp, VTp, VLTi, VRTi, Lvl}
    return containertype(VTp)
end

function postype(::Type{SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}}) where {Ti, Tp, VTp, VLTi, VRTi, Lvl}
    return Tp
end

function indextype(::Type{SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}}) where {Ti, Tp, VTp, VLTi, VRTi, Lvl}
    return indextype(Ti)
end

function moveto(lvl::SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}, ::Type{MemType}) where {Ti, Tp, VTp, VLTi, VRTi, Lvl, MemType <: AbstractArray}
    lvl_2 = moveto(lvl.lvl, MemType)
    ptr_2 = MemType{Tp, 1}(lvl.ptr)
    left_2 = MemType{Ti, 1}(lvl.left)
    right_2 = MemType{Ti, 1}(lvl.right)
    return SparseRLELevel{Ti, Tp, MemType{Tp, 1}, MemType{Ti, 1}, MemType{Ti, 1}, typeof(lvl_2)}(lvl_2, lvl.shape, ptr_2, left_2, right_2)
end

pattern!(lvl::SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}) where {Ti, Tp, VTp, VLTi, VRTi, Lvl} = 
    SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.left, lvl.right)

function countstored_level(lvl::SparseRLELevel, pos)
    countstored_level(lvl.lvl, lvl.left[lvl.ptr[pos + 1]]-1)
end

redefault!(lvl::SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}, init) where {Ti, Tp, VTp, VLTi, VRTi, Lvl} = 
    SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}(redefault!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.left, lvl.right)

function Base.show(io::IO, lvl::SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}) where {Ti, Tp, VTp, VLTi, VRTi, Lvl}
    if get(io, :compact, false)
        print(io, "SparseRLE(")
    else
        print(io, "SparseRLE{$Ti, $Tp, $VTp, $VLTi, $VRTi, $Lvl}(")
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
        show(IOContext(io, :typeinfo=>VLTi), lvl.left)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>VRTi), lvl.right)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:SparseRLELevel}, depth)
    p = fbr.pos
    lvl = fbr.lvl
    left_endpoints = @view(lvl.left[lvl.ptr[p]:lvl.ptr[p + 1] - 1])

    crds = []
    for l in left_endpoints 
        append!(crds, l)
    end

    print_coord(io, crd) = print(io, crd, ":", lvl.right[lvl.ptr[p]-1+searchsortedfirst(left_endpoints, crd)])  
    get_fbr(crd) = fbr(crd)

    print(io, "SparseRLE (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", fbr.lvl.shape, "]")
    display_fiber_data(io, mime, fbr, depth, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}}) where {Ti, Tp, VTp, VLTi, VRTi, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseRLELevel) = (lvl.shape, level_size(lvl.lvl)...)
@inline level_axes(lvl::SparseRLELevel) = (Base.OneTo(lvl.shape), level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}}) where {Ti, Tp, VTp, VLTi, VRTi, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}}) where {Ti, Tp, VTp, VLTi, VRTi, Lvl}= level_default(Lvl)
data_rep_level(::Type{<:SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}}) where {Ti, Tp, VTp, VLTi, VRTi, Lvl} = SparseData(data_rep_level(Lvl), Ti)

(fbr::AbstractFiber{<:SparseRLELevel})() = fbr
function (fbr::SubFiber{<:SparseRLELevel})(idxs...)
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    r1 = searchsortedlast(@view(lvl.left[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), idxs[end])
    r2 = searchsortedfirst(@view(lvl.right[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), idxs[end])
    q = lvl.ptr[p] + first(r1) - 1
    fbr_2 = SubFiber(lvl.lvl, q)
    r1 != r2 ? default(fbr_2) : fbr_2(idxs[1:end-1]...)
end


mutable struct VirtualSparseRLELevel <: AbstractVirtualLevel
    lvl
    ex
    Ti
    Tp
    shape
    qos_fill
    qos_stop
    VTp
    VLTi
    VRTi
    Lvl
    prev_pos
end

  is_level_injective(lvl::VirtualSparseRLELevel, ctx) = [false, is_level_injective(lvl.lvl, ctx)...]
is_level_concurrent(lvl::VirtualSparseRLELevel, ctx) = [false, is_level_concurrent(lvl.lvl, ctx)...]
is_level_atomic(lvl::VirtualSparseRLELevel, ctx) = false
  

function virtualize(ex, ::Type{SparseRLELevel{Ti, Tp, VTp, VLTi, VRTi, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, VTp, VLTi, VRTi, Lvl}
    sym = freshen(ctx, tag)
    shape = value(:($sym.shape), Int)
    qos_fill = freshen(ctx, sym, :_qos_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    dirty = freshen(ctx, sym, :_dirty)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    prev_pos = freshen(ctx, sym, :_prev_pos)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseRLELevel(lvl_2, sym, Ti, Tp, shape, qos_fill, qos_stop, VTp, VLTi, VRTi, Lvl, prev_pos)
end
function lower(lvl::VirtualSparseRLELevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SparseRLELevel{$(lvl.Ti), $(lvl.Tp), $(lvl.VTp), $(lvl.VLTi), $(lvl.VRTi), $(lvl.Lvl)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.ex).ptr,
            $(lvl.ex).left,
            $(lvl.ex).right,
        )
    end
end

Base.summary(lvl::VirtualSparseRLELevel) = "SparseRLE($(summary(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseRLELevel, ctx)
    ext = make_extent(lvl.Ti, literal(lvl.Ti(1.0)), lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext)
end

function virtual_level_resize!(lvl::VirtualSparseRLELevel, ctx, dims...)
    lvl.shape = getstop(dims[end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-1]...)
    lvl
end


virtual_level_eltype(lvl::VirtualSparseRLELevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseRLELevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualSparseRLELevel, ctx::AbstractCompiler, pos, init)
    Tp = lvl.Tp
    Ti = lvl.Ti
    qos = call(-, call(getindex, :($(lvl.ex).ptr), call(+, pos, 1)), 1)
    push!(ctx.code.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
    end)
    if issafe(ctx.mode)
        push!(ctx.code.preamble, quote
            $(lvl.prev_pos) = $(Tp(0))
        end)
    end
    lvl.lvl = declare_level!(lvl.lvl, ctx, qos, init)
    return lvl
end

function trim_level!(lvl::VirtualSparseRLELevel, ctx::AbstractCompiler, pos)
    qos = freshen(ctx.code, :qos)
    push!(ctx.code.preamble, quote
        resize!($(lvl.ex).ptr, $(ctx(pos)) + 1)
        $qos = $(lvl.ex).ptr[end] - $(lvl.Tp(1))
        resize!($(lvl.ex).left, $qos)
        resize!($(lvl.ex).right, $qos)
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, lvl.Tp))
    return lvl
end

function assemble_level!(lvl::VirtualSparseRLELevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        Finch.resize_if_smaller!($(lvl.ex).ptr, $pos_stop + 1)
        Finch.fill_range!($(lvl.ex).ptr, 0, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualSparseRLELevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        for $p = 2:($pos_stop + 1)
            $(lvl.ex).ptr[$p] += $(lvl.ex).ptr[$p - 1]
        end
        $qos_stop = $(lvl.ex).ptr[$pos_stop + 1] - 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end



function instantiate_reader(fbr::VirtualSubFiber{VirtualSparseRLELevel}, ctx, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, pos) = (fbr.lvl, fbr.pos) 
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_i_end = freshen(ctx.code, tag, :_i_end)
    my_i_stop = freshen(ctx.code, tag, :_i_stop)
    my_i_start = freshen(ctx.code, tag, :_i_start)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_q = $(lvl.ex).ptr[$(ctx(pos))]
                $my_q_stop = $(lvl.ex).ptr[$(ctx(pos)) + $(Tp(1))]
                if $my_q < $my_q_stop
                    $my_i_end = $(lvl.ex).right[$my_q_stop - $(Tp(1))]
                else
                    $my_i_end = $(Ti(0))
                end

            end,
            body = (ctx) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> value(my_i_end),
                    body = (ctx, ext) -> Stepper(
                        seek = (ctx, ext) -> quote
                            if $(lvl.ex).right[$my_q] < $(ctx(getstart(ext)))
                                $my_q = Finch.scansearch($(lvl.ex).right, $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                            end
                        end,
                        body = Thunk(
                            preamble = quote
                                $my_i_start = $(lvl.ex).left[$my_q]
                                $my_i_stop = $(lvl.ex).right[$my_q]
                            end,
                            body = (ctx) -> Step(
                                stop = (ctx, ext) -> value(my_i_stop),
                                body = (ctx, ext) -> Thunk( 
                                    body = (ctx) -> Sequence([
                                        Phase(
                                            stop = (ctx, ext) -> call(-, value(my_i_start), getunit(ext)),
                                            body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl))),
                                        ),
                                        Phase(
                                            body = (ctx,ext) -> Run(
                                                body = Simplify(instantiate_reader(VirtualSubFiber(lvl.lvl, value(my_q)), ctx, subprotos))
                                            )
                                        )
                                    ]),
                                    epilogue = quote
                                        $my_q += ($(ctx(getstop(ext))) == $my_i_stop)
                                    end
                                )
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


instantiate_updater(fbr::VirtualSubFiber{VirtualSparseRLELevel}, ctx, protos) = 
    instantiate_updater(VirtualTrackedSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, protos)

function instantiate_updater(fbr::VirtualTrackedSubFiber{VirtualSparseRLELevel}, ctx, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos) = (fbr.lvl, fbr.pos) 
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    qos = freshen(ctx.code, tag, :_qos)
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    dirty = freshen(ctx.code, tag, :dirty)
    
    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $qos = $qos_fill + 1
                $(if issafe(ctx.mode)
                    quote
                        $(lvl.prev_pos) < $(ctx(pos)) || throw(FinchProtocolError("SparseRLELevels cannot be updated multiple times"))
                    end
                end)
            end,

            body = (ctx) -> AcceptRun(
                body = (ctx, ext) -> Thunk(
                    preamble = quote
                        if $qos > $qos_stop
                            $qos_stop = max($qos_stop << 1, 1)
                            Finch.resize_if_smaller!($(lvl.ex).left, $qos_stop)
                            Finch.resize_if_smaller!($(lvl.ex).right, $qos_stop)
                            $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, lvl.Tp), value(qos_stop, lvl.Tp)), ctx))
                        end
                        $dirty = false
                    end,
                    body = (ctx) -> instantiate_updater(VirtualTrackedSubFiber(lvl.lvl, value(qos, lvl.Tp), dirty), ctx, subprotos),
                    epilogue = quote
                        if $dirty
                            $(fbr.dirty) = true
                            $(lvl.ex).left[$qos] = $(ctx(getstart(ext)))
                            $(lvl.ex).right[$qos] = $(ctx(getstop(ext)))
                            $(qos) += $(Tp(1))
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
                $(lvl.ex).ptr[$(ctx(pos)) + 1] = $qos - $qos_fill - 1
                $qos_fill = $qos - 1
            end
        )
    )
end
