"""
    SparseHashLevel{[N], [Ti=Tuple{Int...}], [Tp=Int], [Tbl], [Vp] [VTpip]}(lvl, [dims])

A subfiber of a sparse level does not need to represent slices which are
entirely [`default`](@ref). Instead, only potentially non-default slices are
stored as subfibers in `lvl`. The sparse hash level corresponds to `N` indices
in the subfiber, so fibers in the sublevel are the slices `A[:, ..., :, i_1,
..., i_n]`.  A hash table is used to record which slices are stored. Optionally,
`dims` are the sizes of the last dimensions.

`Ti` is the type of the last `N` fiber indices, and `Tp` is the type used for
positions in the level. `Tbl` is the type of the dictionary used to do hashing,
a subtype of `Dict{Tuple{Tp, Ti}, Tp}`. Finally, `Vp` stores the positions
of subfibers and `VTpip` is a storage type that is a subtype of `AbstractVector{Pair{Tuple{Tp, Ti}, Tp}}`.

```jldoctest
julia> Fiber!(Dense(SparseHash{1}(Element(0.0))), [10 0 20; 30 0 0; 0 0 40])
Dense [:,1:3]
├─[:,1]: SparseHash (0.0) [1:3]
│ ├─[1]: 10.0
│ ├─[2]: 30.0
├─[:,2]: SparseHash (0.0) [1:3]
├─[:,3]: SparseHash (0.0) [1:3]
│ ├─[1]: 20.0
│ ├─[3]: 40.0

julia> Fiber!(SparseHash{2}(Element(0.0)), [10 0 20; 30 0 0; 0 0 40])
SparseHash (0.0) [1:3,1:3]
├─├─[1, 1]: 10.0
├─├─[2, 1]: 30.0
├─├─[1, 3]: 20.0
├─├─[3, 3]: 40.0
```
"""
struct SparseHashLevel{N, Ti<:Tuple, Tp, Tbl<:Dict{Tuple{Tp, Ti}, Tp}, Vp<:AbstractVector{<:Tp}, VTpip<:AbstractVector{Pair{Tuple{Tp, Ti}, Tp}}, Lvl}
    lvl::Lvl
    shape::Ti
    tbl::Tbl
    ptr::Vp
    srt::VTpip
end
const SparseHash = SparseHashLevel

SparseHashLevel(lvl) = throw(ArgumentError("You must specify the number of dimensions in a SparseHashLevel, e.g. Fiber!(SparseHash{2}(Element(0.0)))"))
SparseHashLevel(lvl, shape, args...) = SparseHashLevel{length(shape)}(lvl, shape, args...)
SparseHashLevel{N}(lvl::Lvl) where {N, Lvl} = SparseHashLevel{N, NTuple{N, Int}}(lvl)
SparseHashLevel{N}(lvl, shape, args...) where {N} = SparseHashLevel{N, typeof(shape)}(lvl, shape, args...)

SparseHashLevel{N, Ti}(lvl, args...) where {N, Ti} = SparseHashLevel{N, Ti, postype(typeof(lvl)), Dict{Tuple{postype(typeof(lvl)), Ti}, postype(typeof(lvl))}, (memtype(typeof(lvl))){postype(typeof(lvl)), 1}, (memtype(typeof(lvl))){Pair{Tuple{postype(typeof(lvl)), Ti}, postype(typeof(lvl))}, 1}, typeof(lvl)}(lvl, args...)
# FIXME: Adding pos here is not neeccesarily the right thing...
SparseHashLevel{N, Ti, Tp}(lvl, args...) where {N, Ti, Tp} = SparseHashLevel{N, Ti, postype(typeof(lvl)), Dict{Tuple{postype(typeof(lvl)), Ti}, postype(typeof(lvl))}, (memtype(typeof(lvl))){postype(typeof(lvl)), 1}, (memtype(typeof(lvl))){Pair{Tuple{postype(typeof(lvl)), Ti}, postype(typeof(lvl))}, 1}, typeof(lvl)}(lvl, args...)
# SparseHashLevel{N, Ti, Tp}(lvl, args...) where {N, Ti, Tp} =
#     SparseHashLevel{N, Ti, Tp, Dict{Tuple{Tp, Ti}, Tp}}(lvl, args...)
SparseHashLevel{N, Ti, Tp, Tbl}(lvl::Lvl, args...) where {N, Ti, Tp, Tbl, Lvl} = SparseHashLevel{N, Ti, Tp, Tbl, (memtype(typeof(lvl))){Tp, 1}, (memtype(typeof(lvl))){Pair{Tuple{Tp, Ti}, Tp}, 1}, Lvl}(lvl, args...)
SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip}(lvl::Lvl, args...) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl} = SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}(lvl::Lvl, args...)

SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}(lvl) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl} =
    SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}(lvl, ((zero(ti) for ti in Ti.parameters)..., ))
SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}(lvl, shape) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl} =
    SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}(lvl, shape, Tbl())
SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}(lvl, shape, tbl) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl} =
    SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}(lvl, Ti(shape), tbl, Tp[1], Pair{Tuple{Tp, Ti}, Tp}[])

Base.summary(lvl::SparseHashLevel{N}) where {N} = "SparseHash{$N}($(summary(lvl.lvl)))"
similar_level(lvl::SparseHashLevel{N}) where {N} = SparseHashLevel{N}(similar_level(lvl.lvl))
similar_level(lvl::SparseHashLevel{N}, tail...) where {N} = SparseHashLevel{N}(similar_level(lvl.lvl, tail[1:end-N]...), (tail[end-N+1:end]...,))

function memtype(::Type{SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}}) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl}
    return containertype(Vp)
end

function postype(::Type{SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}}) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl}
    return Tp
end

function moveto(lvl::SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}, ::Type{MemType}) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl, MemType <: AbstractArray}
    lvl_2 = moveto(lvl.lvl, MemType)
    ptr_2 = MemType{Tp, 1}(lvl.ptr)
    srt_2 = MemType{Pair{Tuple{Tp, Ti}, Tp}, 1}(lvl.srt)
    return SparseHashLevel{N, Ti, Tp, Tbl, typeof(ptr_2), typeof(srt_2), typeof(lvl_2)}(lvl_2, lvl.shape, lvl.tbl, ptr_2, srt_2)
end

pattern!(lvl::SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl} = 
    SparseHashLevel{N, Ti, Tp, Tbl}(pattern!(lvl.lvl), lvl.shape, lvl.tbl, lvl.ptr, lvl.srt)

function countstored_level(lvl::SparseHashLevel, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1] - 1)
end

redefault!(lvl::SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}, init) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl} = 
    SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}(redefault!(lvl.lvl, init), lvl.shape, lvl.tbl, lvl.ptr, lvl.srt)

function Base.show(io::IO, lvl::SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl}
    if get(io, :compact, false)
        print(io, "SparseHash{$N}(")
    else
        print(io, "SparseHash{$N, $Ti, $Tp}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(IOContext(io, :typeinfo=>Ti), lvl.shape)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        print(io, typeof(lvl.tbl))
        print(io, "(")
        print(io, join(sort!(collect(pairs(lvl.tbl))), ", "))
        print(io, "), ")
        show(IOContext(io, :typeinfo=>Vp), lvl.ptr)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>VTpip), lvl.srt)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:SparseHashLevel{N}}, depth) where {N}
    p = fbr.pos
    crds = fbr.lvl.srt[fbr.lvl.ptr[p]:fbr.lvl.ptr[p + 1] - 1]

    print_coord(io, crd) = join(io, map(n -> crd[1][2][n], 1:N), ", ")
    get_fbr(crd) = fbr(crd[1][2]...)

    print(io, "SparseHash (", default(fbr), ") [", ":,"^(ndims(fbr) - N), "1:")
    join(io, fbr.lvl.shape, ",1:") 
    print(io, "]")
    display_fiber_data(io, mime, fbr, depth, N, crds, print_coord, get_fbr)
end
@inline level_ndims(::Type{<:SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}}) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl} = N + level_ndims(Lvl)
@inline level_size(lvl::SparseHashLevel) = (lvl.shape..., level_size(lvl.lvl)...)
@inline level_axes(lvl::SparseHashLevel) = (map(Base.OneTo, lvl.shape)..., level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}}) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}}) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}}) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl} = (SparseData^N)(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SparseHashLevel})() = fbr
(fbr::SubFiber{<:SparseHashLevel})() = fbr
function (fbr::SubFiber{<:SparseHashLevel{N, Ti}})(idxs...) where {N, Ti}
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
    Ti
    Tp
    Tbl
    Vp
    VTpip
    shape
    qos_fill
    qos_stop
    Lvl
end
  
is_level_injective(lvl::VirtualSparseHashLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., (true for _ in 1:lvl.N)...]
is_level_concurrent(lvl::VirtualSparseHashLevel, ctx) = [is_level_concurrent(lvl.lvl, ctx)..., (true for _ in 1:lvl.N)...]
is_level_atomic(lvl::VirtualSparseHashLevel, ctx) = false

function virtualize(ex, ::Type{SparseHashLevel{N, Ti, Tp, Tbl, Vp, VTpip, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tp, Tbl, Vp, VTpip, Lvl}  
    sym = freshen(ctx, tag)

    shape = map(n->value(:($sym.shape[$n]), Int), 1:N)
    P = freshen(ctx, sym, :_P)
    qos_fill = freshen(ctx, sym, :_qos_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    push!(ctx.preamble, quote
        $sym = $ex
        $(qos_fill) = length($sym.tbl)
        $(qos_stop) = $(qos_fill)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseHashLevel(lvl_2, sym, N, Ti, Tp, Tbl, Vp, VTpip, shape, qos_fill, qos_stop, Lvl)
end
function lower(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SparseHashLevel{$(lvl.N), $(lvl.Ti), $(lvl.Tp), $(lvl.Tbl), $(lvl.Vp), $(lvl.VTpip), $(lvl.Lvl)}(
            $(ctx(lvl.lvl)),
            ($(map(ctx, lvl.shape)...),),
            $(lvl.ex).tbl,
            $(lvl.ex).ptr,
            $(lvl.ex).srt,
        )
    end
end

Base.summary(lvl::VirtualSparseHashLevel) = "SparseHash$(lvl.N)}($(summary(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler)
    ext = map((ti, stop)->Extent(literal(ti(1)), stop), lvl.Ti.parameters, lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext...)
end

function virtual_level_resize!(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler, dims...)
    lvl.shape = map(getstop, dims[end-lvl.N+1:end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-lvl.N]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseHashLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseHashLevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler, pos, init)
    Ti = lvl.Ti
    Tp = lvl.Tp

    qos = call(-, call(getindex, :($(lvl.ex).ptr), call(+, pos, 1)), 1)
    push!(ctx.code.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
        empty!($(lvl.ex).tbl)
        empty!($(lvl.ex).srt)
    end)
    lvl.lvl = declare_level!(lvl.lvl, ctx, qos, init)
    return lvl
end

function trim_level!(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler, pos)
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos = freshen(ctx.code, :qos)
    push!(ctx.code.preamble, quote
        resize!($(lvl.ex).ptr, $(ctx(pos)) + 1)
        $qos = $(lvl.ex).ptr[end] - $(Tp(1))
        resize!($(lvl.ex).srt, $qos)
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, Tp))
    return lvl
end

function thaw_level!(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler, pos)
    Ti = lvl.Ti
    Tp = lvl.Tp
    p = freshen(ctx.code, lvl.ex, :_p)
    push!(ctx.code.preamble, quote
        for $p = 1:$(ctx(pos))
            $(lvl.ex).ptr[$p] -= $(lvl.ex).ptr[$p + 1]
        end
        $(lvl.ex).ptr[1] = 1
        $(lvl.qos_fill) = length($(lvl.ex).tbl)
    end)
    lvl.lvl = thaw_level!(lvl.lvl, ctx, call(*, pos, lvl.shape))
    return lvl
end

function assemble_level!(lvl::VirtualSparseHashLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        Finch.resize_if_smaller!($(lvl.ex).ptr, $pos_stop + 1)
        Finch.fill_range!($(lvl.ex).ptr, 0, $pos_start + 1, $pos_stop + 1)
    end
end

hashkeycmp(((pos, idx), qos),) = (pos, reverse(idx)...)

function freeze_level!(lvl::VirtualSparseHashLevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        resize!($(lvl.ex).srt, length($(lvl.ex).tbl))
        copyto!($(lvl.ex).srt, pairs($(lvl.ex).tbl))
        sort!($(lvl.ex).srt, by=$hashkeycmp)
        for $p = 2:($pos_stop + 1)
            $(lvl.ex).ptr[$p] += $(lvl.ex).ptr[$p - 1]
        end
        $qos_stop = $(lvl.ex).ptr[$pos_stop + 1] - 1
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
    start = value(:($(lvl.ex).ptr[$(ctx(pos))]), lvl.Tp)
    stop = value(:($(lvl.ex).ptr[$(ctx(pos)) + 1]), lvl.Tp)

    instantiate(SparseHashWalkTraversal(lvl, lvl.N, start, stop), ctx, mode::Reader, [subprotos..., proto])
end

function instantiate(trv::SparseHashWalkTraversal, ctx, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, R, start, stop) = (trv.lvl, trv.R, trv.start, trv.stop)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
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
                    $my_i = $(lvl.ex).srt[$my_q][1][2][$R]
                    $my_i_stop = $(lvl.ex).srt[$my_q_stop - 1][1][2][$R]
                else
                    $my_i = $(Ti.parameters[R](1))
                    $my_i_stop = $(Ti.parameters[R](0))
                end
            end,
            body = (ctx) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> value(my_i_stop),
                    body = (ctx, ext) -> 
                        if R == 1
                            Stepper(
                                seek = (ctx, ext) -> quote
                                    while $my_q + $(Tp(1)) < $my_q_stop && $(lvl.ex).srt[$my_q][1][2][$R] < $(ctx(getstart(ext)))
                                        $my_q += $(Tp(1))
                                    end
                                end,
                                preamble = :($my_i = $(lvl.ex).srt[$my_q][1][2][$R]),
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
                                    while $my_q + $(Tp(1)) < $my_q_stop && $(lvl.ex).srt[$my_q][1][2][$R] < $(ctx(getstart(ext)))
                                        $my_q += $(Tp(1))
                                    end
                                end,
                                preamble = quote
                                    $my_i = $(lvl.ex).srt[$my_q][1][2][$R]
                                    $my_q_step = $my_q
                                    while $my_q_step < $my_q_stop && $(lvl.ex).srt[$my_q_step][1][2][$R] == $my_i
                                        $my_q_step += $(Tp(1))
                                    end
                                end,
                                stop = (ctx, ext) -> value(my_i),
                                chunk = Spike(
                                    body = Fill(virtual_level_default(lvl)),
                                    tail = instantiate(SparseHashWalkTraversal(lvl, R - 1, value(my_q, lvl.Ti), value(my_q_step, lvl.Ti)), ctx, mode, subprotos),
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
    Ti = lvl.Ti
    Tp = lvl.Tp
    return instantiate(SparseHashFollowTraversal(lvl, pos, ()), ctx, mode::Reader, subprotos, proto)
end

function instantiate(trv::SparseHashFollowTraversal, ctx, mode::Reader, subprotos, ::typeof(follow))
    (lvl, pos, coords) = (trv.lvl, trv.pos, trv.coords)
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    qos = freshen(ctx.code, tag, :_q)
    Furlable(
        body = (ctx, ext) ->
            if length(coords)  + 1 < lvl.N
                Lookup(
                    body = (ctx, i) -> instantiate(SparseHashFollowTraversal(lvl, pos, (i, coords...)), ctx, mode::Reader, subprotos)
                )
            else
                Lookup(
                    body = (ctx, i) -> Thunk(
                        preamble = quote
                            $my_key = ($(ctx(pos)), ($(map(ctx, (i, coords...,))...)))
                            $qos = get($(lvl.ex).tbl, $my_key, 0)
                        end,
                        body = (ctx) -> Switch([
                            value(:($qos != 0)) => instantiate(VirtualSubFiber(lvl.lvl, value(qos, lvl.Tp)), ctx, mode::Reader, subprotos),
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
    instantiate(VirtualTrackedSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, mode::Updater, protos)
function instantiate(fbr::VirtualTrackedSubFiber{VirtualSparseHashLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    instantiate(SparseHashLaminateTraversal(lvl, pos, fbr.dirty, ()), ctx, mode::Updater, protos)
end

function instantiate(trv::SparseHashLaminateTraversal, ctx, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos, fbr_dirty, coords) = (trv.lvl, trv.pos, trv.dirty, trv.coords)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    my_key = freshen(ctx.code, tag, :_key)
    qos = freshen(ctx.code, tag, :_q)
    dirty = freshen(ctx.code, tag, :dirty)
    Furlable(
        body = (ctx, ext) ->
            if length(coords) + 1 < lvl.N
                Lookup(
                    body = (ctx, i) -> instantiate(SparseHashLaminateTraversal(lvl, pos, fbr_dirty, (i, coords...)), ctx, mode::Updater, subprotos)
                )
            else
                Lookup(
                    body = (ctx, idx) -> Thunk(
                        preamble = quote
                            $my_key = ($(ctx(pos)), ($(map(ctx, (idx, coords...,))...),))
                            $qos = get($(lvl.ex).tbl, $my_key, $(qos_fill) + $(Tp(1)))
                            if $qos > $qos_stop
                                $qos_stop = max($qos_stop << 1, 1)
                                $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, lvl.Tp), value(qos_stop, lvl.Tp)), ctx))
                            end
                            $dirty = false
                        end,
                        body = (ctx) -> instantiate(VirtualTrackedSubFiber(lvl.lvl, qos, dirty), ctx, mode::Updater, subprotos),
                        epilogue = quote
                            if $dirty
                                $(fbr_dirty) = true
                                if $qos > $qos_fill
                                    $(lvl.qos_fill) = $qos
                                    $(lvl.ex).tbl[$my_key] = $qos
                                    $(lvl.ex).ptr[$(ctx(pos)) + 1] += $(Tp(1))
                                end
                            end
                        end
                    )
                )
            end
    )
end
