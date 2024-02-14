"""
    SparseHashLevel{[N], [TI=Tuple{Int...}], [Ptr, Tbl, Srt]}(lvl, [dims])

A subfiber of a sparse level does not need to represent slices which are
entirely [`default`](@ref). Instead, only potentially non-default slices are
stored as subfibers in `lvl`. The sparse hash level corresponds to `N` indices
in the subfiber, so fibers in the sublevel are the slices `A[:, ..., :, i_1,
..., i_n]`.  A hash table is used to record which slices are stored. Optionally,
`dims` are the sizes of the last dimensions.

`TI` is the type of the last `N` tensor indices, and `Tp` is the type used for
positions in the level. `Tbl` is the type of the dictionary used to do hashing,
`Ptr` stores the positions of subfibers, and `Srt` stores the sorted key/value
pairs in the hash table.

```jldoctest
julia> Tensor(Dense(SparseHash{1}(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
Dense [:,1:3]
├─ [:, 1]: SparseHash{1} (0.0) [1:3]
│  ├─ [1]: 10.0
│  └─ [2]: 30.0
├─ [:, 2]: SparseHash{1} (0.0) [1:3]
└─ [:, 3]: SparseHash{1} (0.0) [1:3]
   ├─ [1]: 20.0
   └─ [3]: 40.0

julia> Tensor(SparseHash{2}(Element(0.0)), [10 0 20; 30 0 0; 0 0 40])
SparseHash{2} (0.0) [:,1:3]
├─ [1, 1]: 10.0
├─ [2, 1]: 30.0
├─ [1, 3]: 20.0
└─ [3, 3]: 40.0
```
"""
struct SparseHashLevel{N, TI<:Tuple, Ptr, Tbl, Srt, Lvl} <: AbstractLevel
    lvl::Lvl
    shape::TI
    ptr::Ptr
    tbl::Tbl
    srt::Srt
end
const SparseHash = SparseHashLevel

SparseHashLevel(lvl) = throw(ArgumentError("You must specify the number of dimensions in a SparseHashLevel, e.g. Tensor(SparseHash{2}(Element(0.0)))"))
SparseHashLevel(lvl, shape, args...) = SparseHashLevel{length(shape)}(lvl, shape, args...)
SparseHashLevel{N}(lvl::Lvl) where {N, Lvl} = SparseHashLevel{N, NTuple{N, Int}}(lvl)
SparseHashLevel{N}(lvl, shape::TI, args...) where {N, TI} = SparseHashLevel{N, TI}(lvl, shape, args...)
SparseHashLevel{N, TI}(lvl) where {N, TI} = SparseHashLevel{N, TI}(lvl, ((zero(ti) for ti in TI.parameters)...,))

SparseHashLevel{N, TI}(lvl, shape) where {N, TI} =
    SparseHashLevel{N, TI}(
        lvl,
        shape,
        postype(lvl)[1],
        Dict{Tuple{postype(lvl), TI}, postype(lvl)}(),
        Pair{Tuple{postype(lvl), TI}, postype(lvl)}[]
    )

SparseHashLevel{N, TI}(lvl::Lvl, shape, ptr::Ptr, tbl::Tbl, srt::Srt) where {N, TI, Lvl, Ptr, Tbl, Srt} =
    SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}(lvl, shape, ptr, tbl, srt)

Base.summary(lvl::SparseHashLevel{N}) where {N} = "SparseHash{$N}($(summary(lvl.lvl)))"
similar_level(lvl::SparseHashLevel{N}) where {N} = SparseHashLevel{N}(similar_level(lvl.lvl))
similar_level(lvl::SparseHashLevel{N}, tail...) where {N} = SparseHashLevel{N}(similar_level(lvl.lvl, tail[1:end-N]...), (tail[end-N+1:end]...,))

function postype(::Type{SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}}) where {N, TI, Ptr, Tbl, Srt, Lvl}
    return postype(Lvl)
end

function moveto(lvl::SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}, device) where {N, TI, Ptr, Tbl, Srt, Lvl}
    lvl_2 = moveto(lvl.lvl, device)
    ptr_2 = moveto(lvl.ptr, device)
    tbl_2 = moveto(lvl.tbl, device)
    srt_2 = moveto(lvl.srt, device)
    return SparseHashLevel{N, TI, Ptr, Tbl, typeof(ptr_2), typeof(srt_2), typeof(lvl_2)}(lvl_2, lvl.shape, ptr_2, tbl_2, srt_2)
end

pattern!(lvl::SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}) where {N, TI, Ptr, Tbl, Srt, Lvl} = 
    SparseHashLevel{N, TI}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)

function countstored_level(lvl::SparseHashLevel, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1] - 1)
end

redefault!(lvl::SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}, init) where {N, TI, Ptr, Tbl, Srt, Lvl} = 
    SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}(redefault!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.tbl, lvl.srt)

Base.resize!(lvl::SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}, dims...) where {N, TI, Ptr, Tbl, Srt, Lvl} = 
    SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}(resize!(lvl.lvl,  dims[1:end-N]...), (dims[end-N + 1:end]...,), lvl.ptr, lvl.tbl, lvl.srt)

function Base.show(io::IO, lvl::SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}) where {N, TI, Ptr, Tbl, Srt, Lvl}
    if get(io, :compact, false)
        print(io, "SparseHash{$N}(")
    else
        print(io, "SparseHash{$N, $TI}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(IOContext(io, :typeinfo=>TI), lvl.shape)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(io, lvl.ptr)
        print(io, ", ")
        print(io, typeof(lvl.tbl))
        print(io, "(")
        if get(io, :limit, false) && length(lvl.tbl) > 10
            print(io, join(sort!(collect(pairs(lvl.tbl)))[1:5], ", "))
            print(io, ", …, ")
            print(io, join(sort!(collect(pairs(lvl.tbl)))[end-5:end], ", "))
        else
            print(io, join(sort!(collect(pairs(lvl.tbl))), ", "))
        end
        print(io, "), ")
        show(io, lvl.srt)
    end
    print(io, ")")
end

labelled_show(io::IO, fbr::SubFiber{<:SparseHashLevel{N}}) where {N} =
    print(io, "SparseHash{", N, "} (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", size(fbr)[end], "]")

function labelled_children(fbr::SubFiber{<:SparseHashLevel{N}}) where {N}
    lvl = fbr.lvl
    pos = fbr.pos
    pos + 1 > length(lvl.ptr) && return []
    map(lvl.ptr[pos]:lvl.ptr[pos + 1] - 1) do qos
        LabelledTree(cartesian_label([range_label() for _ = 1:ndims(fbr) - N]..., lvl.srt[qos][1][2]...), SubFiber(lvl.lvl, qos))
    end
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:SparseHashLevel{N}}, depth) where {N}
    p = fbr.pos
    lvl = fbr.lvl
    if p + 1 > length(lvl.ptr)
        print(io, "SparseHash(undef...)")
        return
    end
    crds = fbr.lvl.srt[fbr.lvl.ptr[p]:fbr.lvl.ptr[p + 1] - 1]

    print_coord(io, crd) = join(io, map(n -> crd[1][2][n], 1:N), ", ")
    get_fbr(crd) = fbr(crd[1][2]...)

    print(io, "SparseHash (", default(fbr), ") [", ":,"^(ndims(fbr) - N), "1:")
    join(io, fbr.lvl.shape, ",1:") 
    print(io, "]")
    display_fiber_data(io, mime, fbr, depth, N, crds, print_coord, get_fbr)
end
@inline level_ndims(::Type{<:SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}}) where {N, TI, Ptr, Tbl, Srt, Lvl} = N + level_ndims(Lvl)
@inline level_size(lvl::SparseHashLevel) = (lvl.shape..., level_size(lvl.lvl)...)
@inline level_axes(lvl::SparseHashLevel) = (map(Base.OneTo, lvl.shape)..., level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}}) where {N, TI, Ptr, Tbl, Srt, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}}) where {N, TI, Ptr, Tbl, Srt, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}}) where {N, TI, Ptr, Tbl, Srt, Lvl} = (SparseData^N)(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SparseHashLevel})() = fbr
(fbr::SubFiber{<:SparseHashLevel})() = fbr
function (fbr::SubFiber{<:SparseHashLevel{N, TI}})(idxs...) where {N, TI}
    isempty(idxs) && return fbr
    idx = idxs[end-N + 1:end]
    lvl = fbr.lvl
    p = (fbr.pos, (idx...,))

    if !haskey(lvl.tbl, p)
        return default(fbr)
    else
        q = lvl.tbl[p]
        return SubFiber(lvl.lvl, q)(idxs[1:end-N]...)
    end
end



mutable struct VirtualSparseHashLevel <: AbstractVirtualLevel
    lvl
    ex
    N
    TI
    ptr
    tbl
    srt
    shape
    qos_fill
    qos_stop
    Lvl
end
  
is_level_injective(lvl::VirtualSparseHashLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., (true for _ in 1:lvl.N)...]
is_level_atomic(lvl::VirtualSparseHashLevel, ctx) = false

function virtual_moveto_level(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler, arch)
    ptr_2 = freshen(ctx.code, lvl.ptr)
    push!(ctx.code.preamble, quote
        $ptr_2 = $(lvl.ptr)
        $tbl_2 = $(lvl.tbl)
        $srt_2 = $(lvl.srt)
        $(lvl.ptr) = $moveto($(lvl.ptr), $(ctx(arch)))
        $(lvl.tbl) = $moveto($(lvl.tbl), $(ctx(arch)))
        $(lvl.srt) = $moveto($(lvl.srt), $(ctx(arch)))
    end)
    push!(ctx.code.epilogue, quote
        $(lvl.ptr) = $ptr_2
        $(lvl.tbl) = $tbl_2
        $(lvl.srt) = $srt_2
    end)
    virtual_moveto_level(lvl.lvl, ctx, arch)
end

function virtualize(ex, ::Type{SparseHashLevel{N, TI, Ptr, Tbl, Srt, Lvl}}, ctx, tag=:lvl) where {N, TI, Ptr, Tbl, Srt, Lvl}  
    sym = freshen(ctx, tag)

    shape = map(n->value(:($sym.shape[$n]), Int), 1:N)
    P = freshen(ctx, sym, :_P)
    qos_fill = freshen(ctx, sym, :_qos_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    ptr = freshen(ctx, tag, :_ptr)
    tbl = freshen(ctx, tag, :_tbl)
    srt = freshen(ctx, tag, :_srt)
    push!(ctx.preamble, quote
        $sym = $ex
        $(qos_fill) = length($sym.tbl)
        $(qos_stop) = $(qos_fill)
        $ptr = $ex.ptr
        $tbl = $ex.tbl
        $srt = $ex.srt
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseHashLevel(lvl_2, sym, N, TI, ptr, tbl, srt, shape, qos_fill, qos_stop, Lvl)
end
function lower(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SparseHashLevel{$(lvl.N), $(lvl.TI)}(
            $(ctx(lvl.lvl)),
            ($(map(ctx, lvl.shape)...),),
            $(lvl.ptr),
            $(lvl.tbl),
            $(lvl.srt),
        )
    end
end

Base.summary(lvl::VirtualSparseHashLevel) = "SparseHash$(lvl.N)}($(summary(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler)
    ext = map((ti, stop)->Extent(literal(ti(1)), stop), lvl.TI.parameters, lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext...)
end

function virtual_level_resize!(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler, dims...)
    lvl.shape = map(getstop, dims[end-lvl.N+1:end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-lvl.N]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseHashLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseHashLevel) = virtual_level_default(lvl.lvl)

postype(lvl::VirtualSparseHashLevel) = postype(lvl.lvl)

function declare_level!(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler, pos, init)
    TI = lvl.TI
    Tp = postype(lvl)

    push!(ctx.code.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
        empty!($(lvl.tbl))
        empty!($(lvl.srt))
    end)
    lvl.lvl = declare_level!(lvl.lvl, ctx, literal(Tp(0)), init)
    return lvl
end

function trim_level!(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler, pos)
    TI = lvl.TI
    Tp = postype(lvl)
    qos = freshen(ctx.code, :qos)
    push!(ctx.code.preamble, quote
        resize!($(lvl.ptr), $(ctx(pos)) + 1)
        $qos = $(lvl.ptr)[end] - $(Tp(1))
        resize!($(lvl.srt), $qos)
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, Tp))
    return lvl
end

function thaw_level!(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler, pos)
    TI = lvl.TI
    Tp = postype(lvl)
    p = freshen(ctx.code, lvl.ex, :_p)
    push!(ctx.code.preamble, quote
        for $p = $(ctx(pos)) + 1:-1:2
            $(lvl.ptr)[$p] -= $(lvl.ptr)[$p - 1]
        end
        $(lvl.ptr)[1] = 1
        $(lvl.qos_fill) = length($(lvl.tbl))
    end)
    lvl.lvl = thaw_level!(lvl.lvl, ctx, value(lvl.qos_fill, Tp))
    return lvl
end

function assemble_level!(lvl::VirtualSparseHashLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        Finch.resize_if_smaller!($(lvl.ptr), $pos_stop + 1)
        Finch.fill_range!($(lvl.ptr), 0, $pos_start + 1, $pos_stop + 1)
    end
end

hashkeycmp(((pos, idx), qos),) = (pos, reverse(idx)...)

function freeze_level!(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        resize!($(lvl.srt), length($(lvl.tbl)))
        copyto!($(lvl.srt), pairs($(lvl.tbl)))
        sort!($(lvl.srt), by=$hashkeycmp)
        for $p = 2:($pos_stop + 1)
            $(lvl.ptr)[$p] += $(lvl.ptr)[$p - 1]
        end
        $qos_stop = $(lvl.ptr)[$pos_stop + 1] - 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

struct SparseHashWalkTraversal
    lvl
    R
    start
    stop
end

function instantiate(fbr::VirtualSubFiber{VirtualSparseHashLevel}, ctx, mode::Reader, subprotos, proto::Union{typeof(defaultread), typeof(walk)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    Tp = postype(lvl)
    start = value(:($(lvl.ptr)[$(ctx(pos))]), Tp)
    stop = value(:($(lvl.ptr)[$(ctx(pos)) + 1]), Tp)

    instantiate(SparseHashWalkTraversal(lvl, lvl.N, start, stop), ctx, mode, [subprotos..., proto])
end

function instantiate(trv::SparseHashWalkTraversal, ctx, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, R, start, stop) = (trv.lvl, trv.R, trv.start, trv.stop)
    tag = lvl.ex
    TI = lvl.TI
    Tp = postype(lvl)
    my_i = freshen(ctx.code, tag, :_i)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_step = freshen(ctx.code, tag, :_q_step)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)
    my_i_stop = freshen(ctx.code, tag, :_i_stop)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_q = $(ctx(start))
                $my_q_stop = $(ctx(stop))
                if $my_q < $my_q_stop
                    $my_i = $(lvl.srt)[$my_q][1][2][$R]
                    $my_i_stop = $(lvl.srt)[$my_q_stop - 1][1][2][$R]
                else
                    $my_i = $(TI.parameters[R](1))
                    $my_i_stop = $(TI.parameters[R](0))
                end
            end,
            body = (ctx) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> value(my_i_stop),
                    body = (ctx, ext) -> 
                        if R == 1
                            Stepper(
                                seek = (ctx, ext) -> quote
                                    while $my_q + $(Tp(1)) < $my_q_stop && $(lvl.srt)[$my_q][1][2][$R] < $(ctx(getstart(ext)))
                                        $my_q += $(Tp(1))
                                    end
                                end,
                                preamble = :($my_i = $(lvl.srt)[$my_q][1][2][$R]),
                                stop =  (ctx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Fill(virtual_level_default(lvl)),
                                    tail = instantiate(VirtualSubFiber(lvl.lvl, value(:($(lvl.ex).srt[$my_q][2]))), ctx, mode, subprotos),
                                ),
                                next = (ctx, ext) -> :($my_q += $(Tp(1)))
                            )
                        else
                             Stepper(
                                seek = (ctx, ext) -> quote
                                    while $my_q + $(Tp(1)) < $my_q_stop && $(lvl.srt)[$my_q][1][2][$R] < $(ctx(getstart(ext)))
                                        $my_q += $(Tp(1))
                                    end
                                end,
                                preamble = quote
                                    $my_i = $(lvl.srt)[$my_q][1][2][$R]
                                    $my_q_step = $my_q
                                    while $my_q_step < $my_q_stop && $(lvl.srt)[$my_q_step][1][2][$R] == $my_i
                                        $my_q_step += $(Tp(1))
                                    end
                                end,
                                stop = (ctx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Fill(virtual_level_default(lvl)),
                                    tail = instantiate(SparseHashWalkTraversal(lvl, R - 1, value(my_q, Tp), value(my_q_step, Tp)), ctx, mode, subprotos),
                                ),
                                next = (ctx, ext) -> :($my_q = $my_q_step)
                            )
                        end
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end

struct SparseHashFollowTraversal
    lvl
    pos
    coords
end


function instantiate(fbr::VirtualSubFiber{VirtualSparseHashLevel}, ctx, mode::Reader, subprotos, proto::typeof(follow))
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    TI = lvl.TI
    Tp = postype(lvl)
    return instantiate(SparseHashFollowTraversal(lvl, pos, ()), ctx, mode, subprotos, proto)
end

function instantiate(trv::SparseHashFollowTraversal, ctx, mode::Reader, subprotos, ::typeof(follow))
    (lvl, pos, coords) = (trv.lvl, trv.pos, trv.coords)
    TI = lvl.TI
    Tp = postype(lvl)
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    qos = freshen(ctx.code, tag, :_q)
    Furlable(
        body = (ctx, ext) ->
            if length(coords)  + 1 < lvl.N
                Lookup(
                    body = (ctx, i) -> instantiate(SparseHashFollowTraversal(lvl, pos, (i, coords...)), ctx, mode, subprotos)
                )
            else
                Lookup(
                    body = (ctx, i) -> Thunk(
                        preamble = quote
                            $my_key = ($(ctx(pos)), ($(map(ctx, (i, coords...,))...)))
                            $qos = get($(lvl.tbl), $my_key, 0)
                        end,
                        body = (ctx) -> Switch([
                            value(:($qos != 0)) => instantiate(VirtualSubFiber(lvl.lvl, value(qos, Tp)), ctx, mode, subprotos),
                            literal(true) => Fill(virtual_level_default(lvl))
                        ])
                    )
                )
            end
    )
end

struct SparseHashLaminateTraversal
    lvl
    pos
    dirty
    coords
end
    
instantiate(fbr::VirtualSubFiber{VirtualSparseHashLevel}, ctx, mode::Updater, protos) =
    instantiate(VirtualHollowSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, mode, protos)
function instantiate(fbr::VirtualHollowSubFiber{VirtualSparseHashLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    instantiate(SparseHashLaminateTraversal(lvl, pos, fbr.dirty, ()), ctx, mode, protos)
end

function instantiate(trv::SparseHashLaminateTraversal, ctx, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos, fbr_dirty, coords) = (trv.lvl, trv.pos, trv.dirty, trv.coords)
    tag = lvl.ex
    TI = lvl.TI
    Tp = postype(lvl)
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    my_key = freshen(ctx.code, tag, :_key)
    qos = freshen(ctx.code, tag, :_q)
    dirty = freshen(ctx.code, tag, :dirty)
    Furlable(
        body = (ctx, ext) ->
            if length(coords) + 1 < lvl.N
                Lookup(
                    body = (ctx, i) -> instantiate(SparseHashLaminateTraversal(lvl, pos, fbr_dirty, (i, coords...)), ctx, mode, subprotos)
                )
            else
                Lookup(
                    body = (ctx, idx) -> Thunk(
                        preamble = quote
                            $my_key = ($(ctx(pos)), ($(map(ctx, (idx, coords...,))...),))
                            $qos = get($(lvl.tbl), $my_key, $(qos_fill) + $(Tp(1)))
                            if $qos > $qos_stop
                                $qos_stop = max($qos_stop << 1, 1)
                                $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, Tp), value(qos_stop, Tp)), ctx))
                            end
                            $dirty = false
                        end,
                        body = (ctx) -> instantiate(VirtualHollowSubFiber(lvl.lvl, qos, dirty), ctx, mode, subprotos),
                        epilogue = quote
                            if $dirty
                                $(fbr_dirty) = true
                                if $qos > $qos_fill
                                    $(lvl.qos_fill) = $qos
                                    $(lvl.tbl)[$my_key] = $qos
                                    $(lvl.ptr)[$(ctx(pos)) + 1] += $(Tp(1))
                                end
                            end
                        end
                    )
                )
            end
    )
end
