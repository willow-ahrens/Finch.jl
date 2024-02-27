"""
    SingleListLevel{[Ti=Int], [Ptr, Idx]}(lvl, [dim])

A subfiber of a SingleList level does not need to represent slices `A[:, ..., :, i]`
which are entirely [`default`](@ref). Instead, only potentially non-default
slices are stored as subfibers in `lvl`. A main difference compared to SparseList 
level is that SingleList level only stores a 'single' non-default slice. It emits
an error if the program tries to write multiple (>=2) coordinates into SingleList.

`Ti` is the type of the last tensor index. The types `Ptr` and `Idx` are the 
types of the arrays used to store positions and indicies. 

```jldoctest
julia> Tensor(Dense(SingleList(Element(0.0))), [10 0 0; 0 20 0; 0 0 30]) 
Dense [:,1:3]
├─ [:, 1]: SingleList (0.0) [1:3]
│  └─ 10.0
├─ [:, 2]: SingleList (0.0) [1:3]
│  └─ 20.0
└─ [:, 3]: SingleList (0.0) [1:3]
   └─ 30.0

julia> Tensor(Dense(SingleList(Element(0.0))), [10 0 0; 0 20 0; 0 40 30])
ERROR: Finch.FinchProtocolError("SingleListLevels can only be updated once")

julia> Tensor(SingleList(Dense(Element(0.0))), [0 0 0; 0 0 30; 0 0 30]) 
SingleList (0.0) [:,1:3]
└─ Dense [1:3]
   ├─ [1]: 0.0
   ├─ [2]: 30.0
   └─ [3]: 30.0

julia> Tensor(SingleList(SingleList(Element(0.0))), [0 0 0; 0 0 30; 0 0 30]) 
ERROR: Finch.FinchProtocolError("SingleListLevels can only be updated once")

```
"""
struct SingleListLevel{Ti, Ptr, Idx, Lvl} <: AbstractLevel
    lvl::Lvl
    shape::Ti
    ptr::Ptr
    idx::Idx
end
const SingleList = SingleListLevel
SingleListLevel(lvl) = SingleListLevel{Int}(lvl)
SingleListLevel(lvl, shape::Ti) where {Ti} = SingleListLevel{Ti}(lvl, shape)
SingleListLevel{Ti}(lvl) where {Ti} = SingleListLevel{Ti}(lvl, zero(Ti))
SingleListLevel{Ti}(lvl, shape) where {Ti} = SingleListLevel{Ti}(lvl, shape, postype(lvl)[1], Ti[])

SingleListLevel{Ti}(lvl::Lvl, shape, ptr::Ptr, idx::Idx) where {Ti, Lvl, Ptr, Idx} =
    SingleListLevel{Ti, Ptr, Idx, Lvl}(lvl, shape, ptr, idx)
    
Base.summary(lvl::SingleListLevel) = "SingleList($(summary(lvl.lvl)))"
similar_level(lvl::SingleListLevel, fill_value, eltype::Type, dim, tail...) =
    SingleList(similar_level(lvl.lvl, fill_value, eltype, tail...), dim)

function postype(::Type{SingleListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl}
    return postype(Lvl)
end

function moveto(lvl::SingleListLevel{Ti, Ptr, Idx, Lvl}, Tm) where {Ti, Ptr, Idx, Lvl}
    lvl_2 = moveto(lvl.lvl, Tm)
    ptr_2 = moveto(lvl.ptr, Tm)
    idx_2 = moveto(lvl.idx, Tm)
    return SingleListLevel{Ti}(lvl_2, lvl.shape, ptr_2, idx_2)
end

function countstored_level(lvl::SingleListLevel, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1] - 1)
end

pattern!(lvl::SingleListLevel{Ti}) where {Ti} = 
    SingleListLevel{Ti}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.idx)

redefault!(lvl::SingleListLevel{Ti}, init) where {Ti} = 
    SingleListLevel{Ti}(redefault!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.idx)

Base.resize!(lvl::SingleListLevel{Ti}, dims...) where {Ti} = 
    SingleListLevel{Ti}(resize!(lvl.lvl, dims[1:end-1]...), dims[end], lvl.ptr, lvl.idx)

function Base.show(io::IO, lvl::SingleListLevel{Ti, Ptr, Idx, Lvl}) where {Ti, Lvl, Idx, Ptr}
    if get(io, :compact, false)
        print(io, "SingleList(")
    else
        print(io, "SingleList{$Ti}(")
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
    end
    print(io, ")")
end

labelled_show(io::IO, fbr::SubFiber{<:SingleListLevel}) =
    print(io, "SingleList (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", size(fbr)[end], "]")

function labelled_children(fbr::SubFiber{<:SingleListLevel})
    lvl = fbr.lvl
    pos = fbr.pos
    pos + 1 > length(lvl.ptr) && return []
    map(lvl.ptr[pos]:lvl.ptr[pos + 1] - 1) do qos
        cartesian_label([range_label() for _ = 1:ndims(fbr) - 1]..., lvl.idx[qos])
        LabelledTree(SubFiber(lvl.lvl, qos))
    end
end

@inline level_ndims(::Type{<:SingleListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SingleListLevel) = (level_size(lvl.lvl)..., lvl.shape)
@inline level_axes(lvl::SingleListLevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.shape))
@inline level_eltype(::Type{<:SingleListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SingleListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SingleListLevel{Ti, Ptr, Idx, Lvl}}) where {Ti, Ptr, Idx, Lvl} = SparseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SingleListLevel})() = fbr
function (fbr::SubFiber{<:SingleListLevel{Ti}})(idxs...) where {Ti}
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    r = searchsorted(@view(lvl.idx[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), idxs[end])
    q = lvl.ptr[p] + first(r) - 1
    fbr_2 = SubFiber(lvl.lvl, q)
    length(r) == 0 ? default(fbr_2) : fbr_2(idxs[1:end-1]...)
end

mutable struct VirtualSingleListLevel <: AbstractVirtualLevel
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
  
is_level_injective(lvl::VirtualSingleListLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., false]
is_level_atomic(lvl::VirtualSingleListLevel, ctx) = false

function virtualize(ex, ::Type{SingleListLevel{Ti, Ptr, Idx, Lvl}}, ctx, tag=:lvl) where {Ti, Ptr, Idx, Lvl}
    sym = freshen(ctx, tag)
    ptr = freshen(ctx, tag, :_ptr)
    idx = freshen(ctx, tag, :_idx)
    push!(ctx.preamble, quote
        $sym = $ex
        $ptr = $sym.ptr
        $idx = $sym.idx
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    shape = value(:($sym.shape), Int)
    qos_fill = freshen(ctx, sym, :_qos_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    prev_pos = freshen(ctx, sym, :_prev_pos)
    VirtualSingleListLevel(lvl_2, sym, Ti, ptr, idx, shape, qos_fill, qos_stop, prev_pos)
end
function lower(lvl::VirtualSingleListLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SingleListLevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.ptr),
            $(lvl.idx),
        )
    end
end

Base.summary(lvl::VirtualSingleListLevel) = "SingleList($(summary(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSingleListLevel, ctx)
    ext = make_extent(lvl.Ti, literal(lvl.Ti(1)), lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext)
end

function virtual_level_resize!(lvl::VirtualSingleListLevel, ctx, dims...)
    lvl.shape = getstop(dims[end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-1]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSingleListLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSingleListLevel) = virtual_level_default(lvl.lvl)

postype(lvl::VirtualSingleListLevel) = postype(lvl.lvl)

function declare_level!(lvl::VirtualSingleListLevel, ctx::AbstractCompiler, pos, init)
    #TODO check that init == default
    Ti = lvl.Ti
    Tp = postype(lvl)
    push!(ctx.code.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
    end)
    if issafe(ctx.mode)
        push!(ctx.code.preamble, quote
            $(lvl.prev_pos) = $(Tp(0))
        end)
    end
    lvl.lvl = declare_level!(lvl.lvl, ctx, literal(Tp(0)), init)
    return lvl
end

function assemble_level!(lvl::VirtualSingleListLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        Finch.resize_if_smaller!($(lvl.ptr), $pos_stop + 1)
        Finch.fill_range!($(lvl.ptr), 0, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualSingleListLevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        resize!($(lvl.ptr), $pos_stop + 1)
        for $p = 1:$pos_stop
            $(lvl.ptr)[$p + 1] += $(lvl.ptr)[$p]
        end
        $qos_stop = $(lvl.ptr)[$pos_stop + 1] - 1
        resize!($(lvl.idx), $qos_stop)
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function thaw_level!(lvl::VirtualSingleListLevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        $(lvl.qos_fill) = $(lvl.ptr)[$pos_stop + 1] - 1
        $(lvl.qos_stop) = $(lvl.qos_fill)
        $qos_stop = $(lvl.qos_fill)
        $(if issafe(ctx.mode)
            quote
                $(lvl.prev_pos) = Finch.scansearch($(lvl.ptr), $(lvl.qos_stop) + 1, 1, $pos_stop) - 1
            end
        end)
        for $p = $pos_stop:-1:1
            $(lvl.ptr)[$p + 1] -= $(lvl.ptr)[$p]
        end
    end)
    lvl.lvl = thaw_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function virtual_moveto_level(lvl::VirtualSingleListLevel, ctx::AbstractCompiler, arch)
    ptr_2 = freshen(ctx.code, lvl.ptr)
    idx_2 = freshen(ctx.code, lvl.idx)
    push!(ctx.code.preamble, quote
        $ptr_2 = $(lvl.ptr)
        $idx_2 = $(lvl.idx)
        $(lvl.ptr) = $moveto($(lvl.ptr), $(ctx(arch)))
        $(lvl.idx) = $moveto($(lvl.idx), $(ctx(arch)))
    end)
    push!(ctx.code.epilogue, quote
        $(lvl.ptr) = $ptr_2
        $(lvl.idx) = $idx_2
    end)
    virtual_moveto_level(lvl.lvl, ctx, arch)
end

function instantiate(fbr::VirtualSubFiber{VirtualSingleListLevel}, ctx, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = postype(lvl)
    Ti = lvl.Ti
    my_i = freshen(ctx.code, tag, :_i)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_q = $(lvl.ptr)[$(ctx(pos))]
                $my_q_stop = $(lvl.ptr)[$(ctx(pos)) + $(Tp(1))]
                if $my_q < $my_q_stop
                    $my_i = $(lvl.idx)[$my_q]
                else
                    $my_i = $(Ti(0))
                end
            end,
            body = (ctx) -> Sequence([
                Phase(
                    start = (ctx, ext) -> literal(lvl.Ti(1)),
                    stop = (ctx, ext) -> value(my_i),
                    body = (ctx, ext) -> Spike(
                            body = Fill(virtual_level_default(lvl)),
                            tail = instantiate(VirtualSubFiber(lvl.lvl, value(my_q, Ti)), ctx, mode, subprotos))
                ),
                Phase(
                    stop = (ctx, ext) -> lvl.shape,
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])

        )
    )
end

instantiate(fbr::VirtualSubFiber{VirtualSingleListLevel}, ctx, mode::Updater, protos) = begin
    instantiate(VirtualHollowSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, mode, protos)
end
function instantiate(fbr::VirtualHollowSubFiber{VirtualSingleListLevel}, ctx, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
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
                $(lvl.ptr)[$(ctx(pos)) + 1] == 0 || throw(FinchProtocolError("SingleListLevels can only be updated once"))
                $(if issafe(ctx.mode)
                    quote
                        $(lvl.prev_pos) < $(ctx(pos)) || throw(FinchProtocolError("SingleListLevels cannot be updated multiple times"))
                    end
                end)
            end,
            body = (ctx) -> Lookup(
                body = (ctx, idx) -> Thunk(
                    preamble = quote
                        if $qos > $qos_stop
                            $qos_stop = max($qos_stop << 1, 1)
                            Finch.resize_if_smaller!($(lvl.idx), $qos_stop)
                            $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, Tp), value(qos_stop, Tp)), ctx))
                        end
                        $dirty = false
                    end,
                    body = (ctx) -> instantiate(VirtualHollowSubFiber(lvl.lvl, value(qos, Tp), dirty), ctx, mode, subprotos),
                    epilogue = quote
                        if $dirty
                            $(fbr.dirty) = true
                            $qos == $qos_fill + 1 || throw(FinchProtocolError("SingleListLevels can only be updated once"))
                            $(lvl.idx)[$qos] = $(ctx(idx))
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
                $(lvl.ptr)[$(ctx(pos)) + 1] += $qos - $qos_fill - 1
                $qos_fill = $qos - 1
            end
        )
    )
end
