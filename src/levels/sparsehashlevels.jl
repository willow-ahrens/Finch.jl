"""
    SparseHashLevel{[N], [Ti=Tuple{Int...}], [Tp=Int]}(lvl, [dims])

A subfiber of a sparse level does not need to represent slices which are
entirely [`default`](@ref). Instead, only potentially non-default slices are
stored as subfibers in `lvl`. The sparse hash level corresponds to `N` indices
in the subfiber, so fibers in the sublevel are the slices `A[:, ..., :, i_1,
..., i_n]`.  A hash table is used to record which slices are stored. Optionally,
`dims` are the sizes of the last dimensions.

`Ti` is the type of the last `N` fiber indices, and `Tp` is the type used for
positions in the level.

In the [@fiber](@ref) constructor, `sh` is an alias for `SparseHashLevel`.

```jldoctest
julia> @fiber(d(sh{1}(e(0.0))), [10 0 20; 30 0 0; 0 0 40])
Dense [:,1:3]
├─[:,1]: SparseHash (0.0) [1:3]
│ ├─[1]: 10.0
│ ├─[2]: 30.0
├─[:,2]: SparseHash (0.0) [1:3]
├─[:,3]: SparseHash (0.0) [1:3]
│ ├─[1]: 20.0
│ ├─[3]: 40.0

julia> @fiber(sh{2}(e(0.0)), [10 0 20; 30 0 0; 0 0 40])
SparseHash (0.0) [1:3,1:3]
├─├─[1, 1]: 10.0
├─├─[2, 1]: 30.0
├─├─[1, 3]: 20.0
├─├─[3, 3]: 40.0
```
"""
struct SparseHashLevel{N, Ti<:Tuple, Tp, Tbl, Lvl}
    lvl::Lvl
    shape::Ti
    tbl::Tbl
    ptr::Vector{Tp}
    srt::Vector{Pair{Tuple{Tp, Ti}, Tp}}
end
const SparseHash = SparseHashLevel

SparseHashLevel(lvl) = throw(ArgumentError("You must specify the number of dimensions in a SparseHashLevel, e.g. @fiber(sh{2}(e(0.0)))"))
SparseHashLevel(lvl, shape, args...) = SparseHashLevel{length(shape)}(lvl, shape, args...)
SparseHashLevel{N}(lvl) where {N} = SparseHashLevel{N, NTuple{N, Int}}(lvl)
SparseHashLevel{N}(lvl, shape, args...) where {N} = SparseHashLevel{N, typeof(shape)}(lvl, shape, args...)

SparseHashLevel{N, Ti}(lvl, args...) where {N, Ti} = SparseHashLevel{N, Ti, Int}(lvl, args...)
SparseHashLevel{N, Ti, Tp}(lvl, args...) where {N, Ti, Tp} = SparseHashLevel{N, Ti, Tp, Dict{Tuple{Tp, Ti}, Tp}}(lvl, args...)
SparseHashLevel{N, Ti, Tp, Tbl}(lvl::Lvl, args...) where {N, Ti, Tp, Tbl, Lvl} = SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(lvl, args...)

SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(lvl) where {N, Ti, Tp, Tbl, Lvl} =
    SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(lvl, ((zero(ti) for ti in Ti.parameters)..., ))
SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(lvl, shape) where {N, Ti, Tp, Tbl, Lvl} =
    SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(lvl, shape, Tbl())
SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(lvl, shape, tbl) where {N, Ti, Tp, Tbl, Lvl} =
    SparseHashLevel{N, Ti, Tp, Tbl, Lvl}(lvl, Ti(shape), tbl, Tp[1], Pair{Tuple{Tp, Ti}, Tp}[])

"""
`fiber_abbrev(sh)` = [SparseHashLevel](@ref).
"""
fiber_abbrev(::Val{:sh}) = SparseHash
summary_fiber_abbrev(lvl::SparseHashLevel{N}) where {N} = "sh{$N}($(summary_fiber_abbrev(lvl.lvl)))"
similar_level(lvl::SparseHashLevel{N}) where {N} = SparseHashLevel{N}(similar_level(lvl.lvl))
similar_level(lvl::SparseHashLevel{N}, tail...) where {N} = SparseHashLevel{N}(similar_level(lvl.lvl, tail[1:end-N]...), (tail[end-N+1:end]...,))

pattern!(lvl::SparseHashLevel{N, Ti, Tp, Tbl}) where {N, Ti, Tp, Tbl} = 
    SparseHashLevel{N, Ti, Tp, Tbl}(pattern!(lvl.lvl), lvl.shape, lvl.tbl, lvl.ptr, lvl.srt)

function countstored_level(lvl::SparseHashLevel, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1] - 1)
end

redefault!(lvl::SparseHashLevel{N, Ti, Tp, Tbl}, init) where {N, Ti, Tp, Tbl} = 
    SparseHashLevel{N, Ti, Tp, Tbl}(redefault!(lvl.lvl, init), lvl.shape, lvl.tbl, lvl.ptr, lvl.srt)

function Base.show(io::IO, lvl::SparseHashLevel{N, Ti, Tp}) where {N, Ti, Tp}
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
        show(IOContext(io, :typeinfo=>Vector{Tp}), lvl.ptr)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Pair{Tuple{Tp, Ti}, Tp}}), lvl.srt)
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
@inline level_ndims(::Type{<:SparseHashLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = N + level_ndims(Lvl)
@inline level_size(lvl::SparseHashLevel) = (lvl.shape..., level_size(lvl.lvl)...)
@inline level_axes(lvl::SparseHashLevel) = (map(Base.OneTo, lvl.shape)..., level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:SparseHashLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseHashLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseHashLevel{N, Ti, Tp, Tbl, Lvl}}) where {N, Ti, Tp, Tbl, Lvl} = (SparseData^N)(data_rep_level(Lvl))

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



mutable struct VirtualSparseHashLevel
    lvl
    ex
    N
    Ti
    Tp
    Tbl
    shape
    qos_fill
    qos_stop
end
function virtualize(ex, ::Type{SparseHashLevel{N, Ti, Tp, Tbl, Lvl}}, ctx, tag=:lvl) where {N, Ti, Tp, Tbl, Lvl}   
    sym = ctx.freshen(tag)
    shape = map(n->value(:($sym.shape[$n]), Int), 1:N)
    P = ctx.freshen(sym, :_P)
    qos_fill = ctx.freshen(sym, :_qos_fill)
    qos_stop = ctx.freshen(sym, :_qos_stop)
    push!(ctx.preamble, quote
        $sym = $ex
        $(qos_fill) = length($sym.tbl)
        $(qos_stop) = $(qos_fill)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseHashLevel(lvl_2, sym, N, Ti, Tp, Tbl, shape, qos_fill, qos_stop)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSparseHashLevel)
    quote
        $SparseHashLevel{$(lvl.N), $(lvl.Ti), $(lvl.Tp), $(lvl.Tbl)}(
            $(ctx(lvl.lvl)),
            ($(map(ctx, lvl.shape)...),),
            $(lvl.ex).tbl,
            $(lvl.ex).ptr,
            $(lvl.ex).srt,
        )
    end
end

summary_fiber_abbrev(lvl::VirtualSparseHashLevel) = "sh{$(lvl.N)}($(summary_fiber_abbrev(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseHashLevel, ctx::LowerJulia)
    ext = map((ti, stop)->Extent(literal(ti(1)), stop), lvl.Ti.parameters, lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext...)
end

function virtual_level_resize!(lvl::VirtualSparseHashLevel, ctx::LowerJulia, dims...)
    lvl.shape = map(getstop, dims[end-lvl.N+1:end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-lvl.N]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseHashLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseHashLevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualSparseHashLevel, ctx::LowerJulia, pos, init)
    Ti = lvl.Ti
    Tp = lvl.Tp

    qos = call(-, call(getindex, :($(lvl.ex).ptr), call(+, pos, 1)), 1)
    push!(ctx.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
        empty!($(lvl.ex).tbl)
        empty!($(lvl.ex).srt)
    end)
    lvl.lvl = declare_level!(lvl.lvl, ctx, qos, init)
    return lvl
end

function trim_level!(lvl::VirtualSparseHashLevel, ctx::LowerJulia, pos)
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos = ctx.freshen(:qos)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).ptr, $(ctx(pos)) + 1)
        $qos = $(lvl.ex).ptr[end] - $(Tp(1))
        resize!($(lvl.ex).srt, $qos)
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, Tp))
    return lvl
end

function thaw_level!(lvl::VirtualSparseHashLevel, ctx::LowerJulia, pos)
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

function assemble_level!(lvl::VirtualSparseHashLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        $resize_if_smaller!($(lvl.ex).ptr, $pos_stop + 1)
        $fill_range!($(lvl.ex).ptr, 0, $pos_start + 1, $pos_stop + 1)
    end
end

hashkeycmp(((pos, idx), qos),) = (pos, reverse(idx)...)

function freeze_level!(lvl::VirtualSparseHashLevel, ctx::LowerJulia, pos_stop)
    p = ctx.freshen(:p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = ctx.freshen(:qos_stop)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).srt, length($(lvl.ex).tbl))
        copyto!($(lvl.ex).srt, pairs($(lvl.ex).tbl))
        sort!($(lvl.ex).srt, by=hashkeycmp)
        for $p = 2:($pos_stop + 1)
            $(lvl.ex).ptr[$p] += $(lvl.ex).ptr[$p - 1]
        end
        $qos_stop = $(lvl.ex).ptr[$pos_stop + 1] - 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function get_reader(fbr::VirtualSubFiber{VirtualSparseHashLevel}, ctx, proto::Union{Nothing, Walk}, protos...)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    start = value(:($(lvl.ex).ptr[$(ctx(pos))]), lvl.Tp)
    stop = value(:($(lvl.ex).ptr[$(ctx(pos)) + 1]), lvl.Tp)

    get_multilevel_range_reader(lvl::VirtualSparseHashLevel, ctx, lvl.N, start, stop, proto, protos...)
end

function get_multilevel_range_reader(lvl::VirtualSparseHashLevel, ctx, R, start, stop, ::Union{Nothing, Walk}, protos...)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_step = ctx.freshen(tag, :_q_step)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i_stop = ctx.freshen(tag, :_i_stop)

    Furlable(
        size = virtual_level_size(lvl, ctx)[R:end],
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
            body = Pipeline([
                Phase(
                    stride = (ctx, ext) -> value(my_i_stop),
                    body = (start, stop) -> Stepper(
                        seek = (ctx, ext) -> quote
                            while $my_q + $(Tp(1)) < $my_q_stop && $(lvl.ex).srt[$my_q][1][2][$R] < $(ctx(getstart(ext)))
                                $my_q += $(Tp(1))
                            end
                        end,
                        body = if R == 1
                            Thunk(
                                preamble = quote
                                    $my_i = $(lvl.ex).srt[$my_q][1][2][$R]
                                end,
                                body = Step(
                                    stride =  (ctx, ext) -> value(my_i),
                                    chunk = Spike(
                                        body = Fill(virtual_level_default(lvl)),
                                        tail = get_reader(VirtualSubFiber(lvl.lvl, value(:($(lvl.ex).srt[$my_q][2]))), ctx, protos...),
                                    ),
                                    next = (ctx, ext) -> quote
                                        $my_q += $(Tp(1))
                                    end
                                )
                            )
                        else
                            Thunk(
                                preamble = quote
                                    $my_i = $(lvl.ex).srt[$my_q][1][2][$R]
                                    $my_q_step = $my_q
                                    while $my_q_step < $my_q_stop && $(lvl.ex).srt[$my_q_step][1][2][$R] == $my_i
                                        $my_q_step += $(Tp(1))
                                    end
                                end,
                                body = Step(
                                    stride = (ctx, ext) -> value(my_i),
                                    chunk = Spike(
                                        body = Fill(virtual_level_default(lvl)),
                                        tail = get_multilevel_range_reader(lvl, ctx, R - 1, value(my_q, lvl.Ti), value(my_q_step, lvl.Ti), protos...),
                                    ),
                                    next = (ctx, ext) -> quote
                                        $my_q = $my_q_step
                                    end
                                )
                            )
                        end
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end

function get_reader(fbr::VirtualSubFiber{VirtualSparseHashLevel}, ctx, protos...)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    return get_reader_hash_helper(lvl, ctx, pos, qos, (), proto, protos...)
end

function get_reader_hash_helper(lvl::VirtualSparseHashLevel, ctx, pos, coords, ::Follow, protos...)
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    qos = ctx.freshen(tag, :_q)
    Furlable(
        size = virtual_level_size(lvl, ctx)[1 + length(coords):end],
        body = (ctx, ext) ->
            if length(coords)  + 1 < lvl.N
                Lookup(
                    body = (ctx, i) -> get_reader_hash_helper(lvl, ctx, pos, qos, (i, coords...), protos...)
                )
            else
                Lookup(
                    body = (ctx, i) -> Thunk(
                        preamble = quote
                            $my_key = ($(ctx(pos)), ($(map(ctx, (i, coords...,))...)))
                            $qos = get($(lvl.ex).tbl, $my_key, 0)
                        end,
                        body = Switch([
                            value(:($qos != 0)) => get_reader(VirtualSubFiber(lvl.lvl, value(qos, lvl.Tp)), ctx, protos...),
                            literal(true) => Fill(virtual_level_default(lvl))
                        ])
                    )
                )
            end
    )
end


is_laminable_updater(lvl::VirtualSparseHashLevel, ctx, protos...) =
    is_laminable_updater(lvl.lvl, ctx, protos[lvl.N + 1:end]...)
get_updater(fbr::VirtualSubFiber{VirtualSparseHashLevel}, ctx, protos...) =
    get_updater(VirtualTrackedSubFiber(fbr.lvl, fbr.pos, ctx.freshen(:null)), ctx, protos...)
function get_updater(fbr::VirtualTrackedSubFiber{VirtualSparseHashLevel}, ctx, protos...)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    return Thunk(
        preamble = quote
            $(lvl.qos_fill) = length($(lvl.ex).tbl)
        end,
        body = get_updater_hash_helper(lvl, ctx, pos, fbr.dirty, (), protos...)
    )
end

function get_updater_hash_helper(lvl::VirtualSparseHashLevel, ctx, pos, fbr_dirty, coords, p::Union{Nothing, Extrude}, protos...)
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    my_key = ctx.freshen(tag, :_key)
    qos = ctx.freshen(tag, :_q)
    dirty = ctx.freshen(tag, :dirty)
    Furlable(
        tight = is_laminable_updater(lvl.lvl, ctx, protos[lvl.N - length(coords): end]...) ? nothing : lvl.lvl,
        size = virtual_level_size(lvl, ctx)[1 + length(coords):end],
        body = (ctx, ext) ->
            if length(coords) + 1 < lvl.N
                Lookup(
                    body = (ctx, i) -> get_updater_hash_helper(lvl, ctx, pos, fbr_dirty, (i, coords...), protos...)
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
                        body = get_updater(VirtualTrackedSubFiber(lvl.lvl, qos, dirty), ctx, protos...),
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