struct ContinuousLevel{Ti, Tp, Lvl}
    lvl::Lvl
    shape::Ti
    ptr::Vector{Tp}
    right::Vector{Ti}
    left::Vector{Ti}
end

const Continuous = ContinuousLevel
ContinuousLevel(lvl, ) = ContinuousLevel{Int}(lvl)
ContinuousLevel(lvl, shape, args...) = ContinuousLevel{typeof(shape)}(lvl, shape, args...)
ContinuousLevel{Ti}(lvl, args...) where {Ti} = ContinuousLevel{Ti, Int}(lvl, args...)
ContinuousLevel{Ti, Tp}(lvl, args...) where {Ti, Tp} = ContinuousLevel{Ti, Tp, typeof(lvl)}(lvl, args...)

ContinuousLevel{Ti, Tp, Lvl}(lvl) where {Ti, Tp, Lvl} = ContinuousLevel{Ti, Tp, Lvl}(lvl, zero(Ti))
ContinuousLevel{Ti, Tp, Lvl}(lvl, shape) where {Ti, Tp, Lvl} = 
    ContinuousLevel{Ti, Tp, Lvl}(lvl, shape, Tp[1], Ti[], Ti[])

"""
`fiber_abbrev(cont)` = [`ContinuousLevel`](@ref).
"""
fiber_abbrev(::Val{:cont}) = Continuous
summary_fiber_abbrev(lvl::ContinuousLevel) = "cont($(summary_fiber_abbrev(lvl.lvl)))"
similar_level(lvl::ContinuousLevel) = Continuous(similar_level(lvl.lvl))
similar_level(lvl::ContinuousLevel, dim, tail...) = Continuous(similar_level(lvl.lvl, tail...), dim)

pattern!(lvl::ContinuousLevel{Ti, Tp}) where {Ti, Tp} = 
    ContinuousLevel{Ti, Tp}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.right, lvl.left)

function countstored_level(lvl::ContinuousLevel, pos)
    countstored_level(lvl.lvl, lvl.left[lvl.ptr[pos + 1]]-1)
end

redefault!(lvl::ContinuousLevel{Ti, Tp}, init) where {Ti, Tp} = 
    ContinuousLevel{Ti, Tp}(redefault!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.right, lvl.left)

function Base.show(io::IO, lvl::ContinuousLevel{Ti, Tp}) where {Ti, Tp}
    if get(io, :compact, false)
        print(io, "Continuous(")
    else
        print(io, "Continuous{$Ti, $Tp}(")
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
        show(IOContext(io, :typeinfo=>Vector{Ti}), lvl.right)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Ti}), lvl.left)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:ContinuousLevel}, depth)
    p = fbr.pos
    crds = []
    for r in fbr.lvl.ptr[p]:fbr.lvl.ptr[p + 1] - 1
        i = fbr.lvl.right[r]
        l = fbr.lvl.left[r + 1] - fbr.lvl.left[r]
        append!(crds, (i - l + 1):i)
    end

    print_coord(io, crd) = show(io, crd)
    get_fbr(crd) = fbr(crd)

    print(io, "Continuous (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", fbr.lvl.shape, "]")
    display_fiber_data(io, mime, fbr, depth, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:ContinuousLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::ContinuousLevel) = (lvl.shape, level_size(lvl.lvl)...)
@inline level_axes(lvl::ContinuousLevel) = (Base.OneTo(lvl.shape), level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:ContinuousLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:ContinuousLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:ContinuousLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = SparseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:ContinuousLevel})() = fbr
function (fbr::SubFiber{<:ContinuousLevel})(idxs...)
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    r = lvl.ptr[p] + searchsortedfirst(@view(lvl.right[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), idxs[end]) - 1
    r < lvl.ptr[p + 1] || return default(fbr)
    q = lvl.left[r + 1] - 1 - lvl.right[r] + idxs[end]
    q >= lvl.left[r] || return default(fbr)
    fbr_2 = SubFiber(lvl.lvl, q)
    return fbr_2(idxs[1:end-1]...)
end

mutable struct VirtualContinuousLevel
    lvl
    ex
    Ti
    Tp
    shape
    qos_fill
    qos_stop
    ros_fill
    ros_stop
    dirty
end
function virtualize(ex, ::Type{ContinuousLevel{Ti, Tp, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, Lvl}
    sym = ctx.freshen(tag)
    shape = value(:($sym.shape), Int)
    qos_fill = ctx.freshen(sym, :_qos_fill)
    qos_stop = ctx.freshen(sym, :_qos_stop)
    ros_fill = ctx.freshen(sym, :_ros_fill)
    ros_stop = ctx.freshen(sym, :_ros_stop)
    dirty = ctx.freshen(sym, :_dirty)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualContinuousLevel(lvl_2, sym, Ti, Tp, shape, qos_fill, qos_stop, ros_fill, ros_stop, dirty)
end
function lower(lvl::VirtualContinuousLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $ContinuousLevel{$(lvl.Ti), $(lvl.Tp)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.ex).ptr,
            $(lvl.ex).right,
            $(lvl.ex).left,
        )
    end
end

summary_fiber_abbrev(lvl::VirtualContinuousLevel) = "cont($(summary_fiber_abbrev(lvl.lvl)))"

function virtual_level_size(lvl::VirtualContinuousLevel, ctx)
    ext = Extent(literal(lvl.Ti(1)), lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext)
end

virtual_level_eltype(lvl::VirtualContinuousLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualContinuousLevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualContinuousLevel, ctx::AbstractCompiler, pos, init)
    Tp = lvl.Tp
    Ti = lvl.Ti
    ros = call(-, call(getindex, :($(lvl.ex).ptr), call(+, pos, 1)), 1)
    qos = call(-, call(getindex, :($(lvl.ex).left), call(+, ros, 1)), 1)
    push!(ctx.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
        $(lvl.ros_fill) = $(Tp(0))
        $(lvl.ros_stop) = $(Tp(0))
        $resize_if_smaller!($(lvl.ex).left, 1)
        $(lvl.ex).left[1] = 1
    end)
    lvl.lvl = declare_level!(lvl.lvl, ctx, qos, init)
    return lvl
end

function trim_level!(lvl::VirtualContinuousLevel, ctx::AbstractCompiler, pos)
    Tp = lvl.Tp
    Ti = lvl.Ti
    ros = ctx.freshen(:ros)
    qos = ctx.freshen(:qos)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).ptr, $(ctx(pos)) + 1)
        $ros = $(lvl.ex).ptr[end] - $(lvl.Tp(1))
        resize!($(lvl.ex).right, $ros)
        resize!($(lvl.ex).left, $ros + 1)
        $qos = $(lvl.ex).left[end] - $(lvl.Tp(1))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, Tp))
    return lvl
end

function assemble_level!(lvl::VirtualContinuousLevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        $resize_if_smaller!($(lvl.ex).ptr, $pos_stop + 1)
        $fill_range!($(lvl.ex).ptr, 0, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualContinuousLevel, ctx::AbstractCompiler, pos_stop)
    p = ctx.freshen(:p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = ctx.freshen(:qos_stop)
    push!(ctx.preamble, quote
        for $p = 2:($pos_stop + 1)
            $(lvl.ex).ptr[$p] += $(lvl.ex).ptr[$p - 1]
        end
        $qos_stop = $(lvl.ex).ptr[$pos_stop + 1] - 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end



function get_reader(fbr::VirtualSubFiber{VirtualContinuousLevel}, ctx, ::Union{Nothing, Walk}, protos...)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_i_stop = ctx.freshen(tag, :_i_stop)
    my_i_start = ctx.freshen(tag, :_i_start)
    my_r = ctx.freshen(tag, :_r)
    my_r_stop = ctx.freshen(tag, :_r_stop)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_q_left = ctx.freshen(tag, :_q_left)
    my_i_end = ctx.freshen(tag, :_i_end)

    Furlable(
        size = virtual_level_size(lvl, ctx),
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_r = $(lvl.ex).ptr[$(ctx(pos))]
                $my_r_stop = $(lvl.ex).ptr[$(ctx(pos)) + $(Tp(1))]
                $my_i_end = $(lvl.ex).right[$my_r_stop - $(Tp(1))]
            end,
            body = (ctx) -> Pipeline([
                Phase(
                    stop = (ctx, ext) -> value(my_i_end),
                    body = (ctx, ext) -> Stepper(
                        seek = (ctx, ext) -> quote
                            if $(lvl.ex).right[$my_r] < $(ctx(getstart(ext)))
                                $my_r = scansearch($(lvl.ex).right, $(ctx(getstart(ext))), $my_r, $my_r_stop - 1)
                            end
                        end,
                        body = Thunk(
                            preamble = quote
                                $my_i_start = $(lvl.ex).left[$my_r]
                                $my_i_stop = $(lvl.ex).right[$my_r]
                            end,
                            body = (ctx) -> Phase(
                                stop = (ctx, ext) -> value(my_i_stop),
                                body = (ctx, ext) -> Thunk( 
                                     body = (ctx) -> Pipeline([
                                        Phase(
                                            stop = (ctx, ext) -> value(my_i_start),
                                            body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl))),
                                        ),
                                        Phase(
                                            #stop = (ctx, ext) -> value(my_i_stop),
                                            body = (ctx,ext) -> Run(
                                                                    body = Simplify(get_reader(VirtualSubFiber(lvl.lvl, value(my_r)), ctx, protos...))
                                                                   )
                                        )
                                    ]),
                                    epilogue = quote
                                        $my_r += ($(ctx(getstop(ext))) == $my_i_stop)
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
