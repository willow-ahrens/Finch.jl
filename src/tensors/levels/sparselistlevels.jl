"""
    SparseListLevel{[Ti=Int], [Tp=Int], [Ptr=Vector{Tp}], [Idx=Vector{Ti}]}(lvl, [dim])

A subfiber of a sparse level does not need to represent slices `A[:, ..., :, i]`
which are entirely [`default`](@ref). Instead, only potentially non-default
slices are stored as subfibers in `lvl`.  A sorted list is used to record which
slices are stored. Optionally, `dim` is the size of the last dimension.

`Ti` is the type of the last fiber index, and `Tp` is the type used for
positions in the level. The types `Ptr` and `Idx` are the types of the
arrays used to store positions and indicies. 

```jldoctest
julia> Fiber!(Dense(SparseList(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
Dense [:,1:3]
├─[:,1]: SparseList (0.0) [1:3]
│ ├─[1]: 10.0
│ ├─[2]: 30.0
├─[:,2]: SparseList (0.0) [1:3]
├─[:,3]: SparseList (0.0) [1:3]
│ ├─[1]: 20.0
│ ├─[3]: 40.0

julia> Fiber!(SparseList(SparseList(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
SparseList (0.0) [:,1:3]
├─[:,1]: SparseList (0.0) [1:3]
│ ├─[1]: 10.0
│ ├─[2]: 30.0
├─[:,3]: SparseList (0.0) [1:3]
│ ├─[1]: 20.0
│ ├─[3]: 40.0

```
"""
struct SparseListLevel{Ti, Ptr, Idx, Lvl}
    lvl::Lvl
    shape::Ti
    ptr::Ptr
    idx::Idx
end
const SparseList = SparseListLevel
SparseListLevel(lvl) = SparseListLevel{Int}(lvl)
SparseListLevel(lvl, shape::Ti) where {Ti} = SparseListLevel{Ti}(lvl, shape)
SparseListLevel{Ti}(lvl) where {Ti} = SparseListLevel{Ti}(lvl, zero(Ti))
SparseListLevel{Ti}(lvl, shape) where {Ti} = SparseListLevel{Ti}(lvl, shape, postype(lvl)[1], Ti[])

SparseListLevel{Ti}(lvl::Lvl, shape, ptr::Ptr, idx::Idx) where {Ti, Lvl, Ptr, Idx} =
    SparseListLevel{Ti, Ptr, Idx, Lvl}(lvl, shape, ptr, idx)
    
Base.summary(lvl::SparseListLevel) = "SparseList($(summary(lvl.lvl)))"
similar_level(lvl::SparseListLevel) = SparseList(similar_level(lvl.lvl))
similar_level(lvl::SparseListLevel, dim, tail...) = SparseList(similar_level(lvl.lvl, tail...), dim)

function postype(::Type{SparseListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl}
    return postype(Lvl)
end

function moveto(lvl::SparseListLevel{Ti, Ptr, Idx, Lvl}, Tm) where {Ti, Ptr, Idx, Lvl}
    lvl_2 = moveto(lvl.lvl, Tm)
    ptr_2 = moveto(lvl.ptr, Tm)
    idx_2 = moveto(lvl.idx, Tm)
    return SparseListLevel{Ti}(lvl_2, lvl.shape, ptr_2, idx_2)
end

function countstored_level(lvl::SparseListLevel, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1] - 1)
end

pattern!(lvl::SparseListLevel{Ti}) where {Ti} = 
    SparseListLevel{Ti}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.idx)

redefault!(lvl::SparseListLevel{Ti}, init) where {Ti} = 
    SparseListLevel{Ti}(redefault!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.idx)

function Base.show(io::IO, lvl::SparseListLevel{Ti, Ptr, Idx, Lvl}) where {Ti, Lvl, Idx, Ptr}
    if get(io, :compact, false)
        print(io, "SparseList(")
    else
        print(io, "SparseList{$Ti}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(IOContext(io, :typeinfo=>Ti), lvl.shape)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>Ptr), lvl.ptr)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Idx), lvl.idx)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:SparseListLevel}, depth)
    p = fbr.pos
    crds = @view(fbr.lvl.idx[fbr.lvl.ptr[p]:fbr.lvl.ptr[p + 1] - 1])

    print_coord(io, crd) = show(io, crd)
    get_fbr(crd) = fbr(crd)

    print(io, "SparseList (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", fbr.lvl.shape, "]")
    display_fiber_data(io, mime, fbr, depth, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:SparseListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseListLevel) = (level_size(lvl.lvl)..., lvl.shape)
@inline level_axes(lvl::SparseListLevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.shape))
@inline level_eltype(::Type{<:SparseListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = SparseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SparseListLevel})() = fbr
function (fbr::SubFiber{<:SparseListLevel{Ti}})(idxs...) where {Ti}
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    r = searchsorted(@view(lvl.idx[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), idxs[end])
    q = lvl.ptr[p] + first(r) - 1
    fbr_2 = SubFiber(lvl.lvl, q)
    length(r) == 0 ? default(fbr_2) : fbr_2(idxs[1:end-1]...)
end

mutable struct VirtualSparseListLevel <: AbstractVirtualLevel
    lvl
    ex
    Ti
    ptr
    idx
    shape
    qos_fill
    qos_stop
    prev_pos
end
  
is_level_injective(lvl::VirtualSparseListLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., false]
is_level_atomic(lvl::VirtualSparseListLevel, ctx) = false

function virtualize(ex, ::Type{SparseListLevel{Ti, Ptr, Idx, Lvl}}, ctx, tag=:lvl) where {Ti, Ptr, Idx, Lvl}
    sym = freshen(ctx, tag)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    ptr = virtualize(:($sym.ptr), Ptr, ctx, Symbol(tag, :_ptr))
    idx = virtualize(:($sym.idx), Idx, ctx, Symbol(tag, :_idx))
    shape = value(:($sym.shape), Int)
    qos_fill = freshen(ctx, sym, :_qos_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    prev_pos = freshen(ctx, sym, :_prev_pos)
    VirtualSparseListLevel(lvl_2, sym, Ti, ptr, idx, shape, qos_fill, qos_stop, prev_pos)
end
function lower(lvl::VirtualSparseListLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SparseListLevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(ctx(lvl.ptr)),
            $(ctx(lvl.idx)),
        )
    end
end

Base.summary(lvl::VirtualSparseListLevel) = "SparseList($(summary(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseListLevel, ctx)
    ext = make_extent(lvl.Ti, literal(lvl.Ti(1)), lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext)
end

function virtual_level_resize!(lvl::VirtualSparseListLevel, ctx, dims...)
    lvl.shape = getstop(dims[end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-1]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseListLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseListLevel) = virtual_level_default(lvl.lvl)

postype(lvl::VirtualSparseListLevel) = postype(lvl.lvl)

function declare_level!(lvl::VirtualSparseListLevel, ctx::AbstractCompiler, pos, init)
    #TODO check that init == default
    Ti = lvl.Ti
    Tp = postype(lvl)
    qos = call(-, call(getindex, :($(ctx(lvl.ptr))), call(+, pos, 1)),  1)
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

function trim_level!(lvl::VirtualSparseListLevel, ctx::AbstractCompiler, pos)
    qos = freshen(ctx.code, :qos)
    Tp = postype(lvl)
    push!(ctx.code.preamble, quote
        resize!($(ctx(lvl.ptr)), $(ctx(pos)) + 1)
        $qos = $(ctx(lvl.ptr))[end] - $(Tp(1))
        resize!($(ctx(lvl.idx)), $qos)
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, Tp))
    return lvl
end

function assemble_level!(lvl::VirtualSparseListLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        Finch.resize_if_smaller!($(ctx(lvl.ptr)), $pos_stop + 1)
        Finch.fill_range!($(ctx(lvl.ptr)), 0, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualSparseListLevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        for $p = 2:($pos_stop + 1)
            $(ctx(lvl.ptr))[$p] += $(ctx(lvl.ptr))[$p - 1]
        end
        $qos_stop = $(ctx(lvl.ptr))[$pos_stop + 1] - 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function virtual_moveto_level(lvl::VirtualSparseListLevel, ctx::AbstractCompiler, arch)
    lvl.ptr = virtual_moveto(lvl.ptr, ctx, arch)
    lvl.idx = virtual_moveto(lvl.idx, ctx, arch)
    lvl.lvl = virtual_moveto_level(lvl.lvl, ctx, arch)
    return lvl
end

function instantiate_reader(fbr::VirtualSubFiber{VirtualSparseListLevel}, ctx, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    Ti = lvl.Ti
    my_i = freshen(ctx.code, tag, :_i)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)
    my_i1 = freshen(ctx.code, tag, :_i1)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_q = $(ctx(lvl.ptr))[$(ctx(pos))]
                $my_q_stop = $(ctx(lvl.ptr))[$(ctx(pos)) + $(Tp(1))]
                if $my_q < $my_q_stop
                    $my_i = $(ctx(lvl.idx))[$my_q]
                    $my_i1 = $(ctx(lvl.idx))[$my_q_stop - $(Tp(1))]
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
                            if $(ctx(lvl.idx))[$my_q] < $(ctx(getstart(ext)))
                                $my_q = Finch.scansearch($(ctx(lvl.idx)), $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                            end
                        end,
                        preamble = :($my_i = $(ctx(lvl.idx))[$my_q]),
                        stop = (ctx, ext) -> value(my_i),
                        chunk = Spike(
                            body = Fill(virtual_level_default(lvl)),
                            tail = Simplify(instantiate_reader(VirtualSubFiber(lvl.lvl, value(my_q, Ti)), ctx, subprotos))
                        ),
                        next = (ctx, ext) -> :($my_q += $(Tp(1))) 
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end

function instantiate_reader(fbr::VirtualSubFiber{VirtualSparseListLevel}, ctx, subprotos, ::typeof(gallop))
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    Ti = lvl.Ti
    my_i = freshen(ctx.code, tag, :_i)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)
    my_i1 = freshen(ctx.code, tag, :_i1)
    my_i2 = freshen(ctx.code, tag, :_i2)
    my_i3 = freshen(ctx.code, tag, :_i3)
    my_i4 = freshen(ctx.code, tag, :_i4)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_q = $(ctx(lvl.ptr))[$(ctx(pos))]
                $my_q_stop = $(ctx(lvl.ptr))[$(ctx(pos)) + 1]
                if $my_q < $my_q_stop
                    $my_i = $(ctx(lvl.idx))[$my_q]
                    $my_i1 = $(ctx(lvl.idx))[$my_q_stop - $(Tp(1))]
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
                            if $(ctx(lvl.idx))[$my_q] < $(ctx(getstart(ext)))
                                $my_q = Finch.scansearch($(ctx(lvl.idx)), $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                            end
                        end,                        
                        preamble = :($my_i2 = $(ctx(lvl.idx))[$my_q]),
                        stop = (ctx, ext) -> value(my_i2),
                        chunk =  Spike(
                            body = Fill(virtual_level_default(lvl)),
                            tail = instantiate_reader(VirtualSubFiber(lvl.lvl, value(my_q, Ti)), ctx, subprotos),
                        ),
                        next = (ctx, ext) -> :($my_q += $(Tp(1))),
                    )  
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end

instantiate_updater(fbr::VirtualSubFiber{VirtualSparseListLevel}, ctx, protos) = begin
    instantiate_updater(VirtualTrackedSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, protos)
end
function instantiate_updater(fbr::VirtualTrackedSubFiber{VirtualSparseListLevel}, ctx, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    #is_serial(ctx.arch) || throw(FinchArchitectureError("SparseListLevel updater is not concurrent"))
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
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
                        $(lvl.prev_pos) < $(ctx(pos)) || throw(FinchProtocolError("SparseListLevels cannot be updated multiple times"))
                    end
                end)
            end,
            body = (ctx) -> Lookup(
                body = (ctx, idx) -> Thunk(
                    preamble = quote
                        if $qos > $qos_stop
                            $qos_stop = max($qos_stop << 1, 1)
                            Finch.resize_if_smaller!($(ctx(lvl.idx)), $qos_stop)
                            $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, Tp), value(qos_stop, Tp)), ctx))
                        end
                        $dirty = false
                    end,
                    body = (ctx) -> instantiate_updater(VirtualTrackedSubFiber(lvl.lvl, value(qos, Tp), dirty), ctx, subprotos),
                    epilogue = quote
                        if $dirty
                            $(fbr.dirty) = true
                            $(ctx(lvl.idx))[$qos] = $(ctx(idx))
                            $qos += $(Tp(1))
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
                $(ctx(lvl.ptr))[$(ctx(pos)) + 1] = $qos - $qos_fill - 1
                $qos_fill = $qos - 1
            end
        )
    )
end
