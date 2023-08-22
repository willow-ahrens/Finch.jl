struct SparseRLELevel{Ti, Tp, Lvl}
    lvl::Lvl
    shape::Ti
    ptr::Vector{Tp}
    left::Vector{Ti}
    right::Vector{Ti}
end

const SparseRLE = SparseRLELevel
SparseRLELevel(lvl, ) = SparseRLELevel{Int}(lvl)
SparseRLELevel(lvl, shape, args...) = SparseRLELevel{typeof(shape)}(lvl, shape, args...)
SparseRLELevel{Ti}(lvl, args...) where {Ti} = SparseRLELevel{Ti, Int}(lvl, args...)
SparseRLELevel{Ti, Tp}(lvl, args...) where {Ti, Tp} = SparseRLELevel{Ti, Tp, typeof(lvl)}(lvl, args...)

SparseRLELevel{Ti, Tp, Lvl}(lvl) where {Ti, Tp, Lvl} = SparseRLELevel{Ti, Tp, Lvl}(lvl, zero(Ti))
SparseRLELevel{Ti, Tp, Lvl}(lvl, shape) where {Ti, Tp, Lvl} = 
    SparseRLELevel{Ti, Tp, Lvl}(lvl, shape, Tp[1], Ti[], Ti[])

Base.summary(lvl::SparseRLELevel) = "SparseRLE($(summary(lvl.lvl)))"
similar_level(lvl::SparseRLELevel) = SparseRLE(similar_level(lvl.lvl))
similar_level(lvl::SparseRLELevel, dim, tail...) = SparseRLE(similar_level(lvl.lvl, tail...), dim)

pattern!(lvl::SparseRLELevel{Ti, Tp}) where {Ti, Tp} = 
    SparseRLELevel{Ti, Tp}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.left, lvl.right)

function countstored_level(lvl::SparseRLELevel, pos)
    countstored_level(lvl.lvl, lvl.left[lvl.ptr[pos + 1]]-1)
end

redefault!(lvl::SparseRLELevel{Ti, Tp}, init) where {Ti, Tp} = 
    SparseRLELevel{Ti, Tp}(redefault!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.left, lvl.right)

function Base.show(io::IO, lvl::SparseRLELevel{Ti, Tp}) where {Ti, Tp}
    if get(io, :compact, false)
        print(io, "SparseRLE(")
    else
        print(io, "SparseRLE{$Ti, $Tp}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(IOContext(io, :typeinfo=>Ti), lvl.shape)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>Vector{Tp}), lvl.ptr)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Ti}), lvl.left)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Ti}), lvl.right)
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

@inline level_ndims(::Type{<:SparseRLELevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseRLELevel) = (lvl.shape, level_size(lvl.lvl)...)
@inline level_axes(lvl::SparseRLELevel) = (Base.OneTo(lvl.shape), level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:SparseRLELevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseRLELevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseRLELevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = SparseData(data_rep_level(Lvl))

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

mutable struct VirtualSparseRLELevel
    lvl
    ex
    Ti
    Tp
    shape
    qos_fill
    qos_stop
end
function virtualize(ex, ::Type{SparseRLELevel{Ti, Tp, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, Lvl}
    sym = ctx.code.freshen(tag)
    shape = value(:($sym.shape), Int)
    qos_fill = ctx.code.freshen(sym, :_qos_fill)
    qos_stop = ctx.code.freshen(sym, :_qos_stop)
    dirty = ctx.code.freshen(sym, :_dirty)
    push!(ctx.code.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseRLELevel(lvl_2, sym, Ti, Tp, shape, qos_fill, qos_stop)
end
function lower(lvl::VirtualSparseRLELevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SparseRLELevel{$(lvl.Ti), $(lvl.Tp)}(
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
    lvl.lvl = declare_level!(lvl.lvl, ctx, qos, init)
    return lvl
end

function trim_level!(lvl::VirtualSparseRLELevel, ctx::AbstractCompiler, pos)
    qos = ctx.code.freshen(:qos)
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
    p = ctx.code.freshen(:p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = ctx.code.freshen(:qos_stop)
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
    my_i_end = ctx.code.freshen(tag, :_i_end)
    my_i_stop = ctx.code.freshen(tag, :_i_stop)
    my_i_start = ctx.code.freshen(tag, :_i_start)
    my_q = ctx.code.freshen(tag, :_q)
    my_q_stop = ctx.code.freshen(tag, :_q_stop)

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


is_laminable_updater(lvl::VirtualSparseRLELevel, ctx, ::Union{typeof(defaultupdate), typeof(extrude)}) = false

instantiate_updater(fbr::VirtualSubFiber{VirtualSparseRLELevel}, ctx, protos) = 
    instantiate_updater(VirtualTrackedSubFiber(fbr.lvl, fbr.pos, ctx.code.freshen(:null)), ctx, protos)

function instantiate_updater(fbr::VirtualTrackedSubFiber{VirtualSparseRLELevel}, ctx, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos) = (fbr.lvl, fbr.pos) 
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    qos = ctx.code.freshen(tag, :_qos)
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    dirty = ctx.code.freshen(tag, :dirty)
    
    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $qos = $qos_fill + 1
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
