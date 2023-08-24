"""
    RepeatRLELevel{[D], [Ti=Int], [Tp=Int], [Tv=typeof(D)]}([dim])

A subfiber of a repeat level is a vector that only stores contiguous repeated
values once. The RepeatRLELevel records locations of repeats using a sorted
list. Optionally, `dim` is the size of the vectors.

The fibers have type `Tv`, initialized to `D`. `D` may optionally be given as
the first argument.  `Ti` is the type of the last fiber index, and `Tp` is the
type used for positions in the level.

In the [`Fiber!`](@ref) constructor, `rl` is an alias for `RepeatRLELevel`.

```jldoctest
julia> Fiber!(RepeatRLE(0.0), [11, 11, 22, 22, 00, 00, 00, 33, 33])
RepeatRLE (0.0) [1:9]
├─[1:2]: 11.0
├─[3:4]: 22.0
├─[5:7]: 0.0
├─[8:9]: 33.0
├─[10:9]: 0.0

```
"""
struct RepeatRLELevel{D, Ti, Tp, Tv}
    shape::Ti
    ptr::Vector{Tp}
    idx::Vector{Ti}
    val::Vector{Tv}
end

const RepeatRLE = RepeatRLELevel
function RepeatRLELevel(d, args...)
    isbits(d) || throw(ArgumentError("Finch currently only supports isbits defaults"))
    RepeatRLELevel{d}(args...)
end
RepeatRLELevel{D}() where {D} = RepeatRLELevel{D, Int}()
RepeatRLELevel{D}(shape, args...) where {D} = RepeatRLELevel{D, typeof(shape)}(shape, args...)
RepeatRLELevel{D, Ti}(args...) where {D, Ti} = RepeatRLELevel{D, Ti, Int}(args...)
RepeatRLELevel{D, Ti, Tp}(args...) where {D, Ti, Tp} = RepeatRLELevel{D, Ti, Tp, typeof(D)}(args...)

RepeatRLELevel{D, Ti, Tp, Tv}() where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(zero(Ti))
RepeatRLELevel{D, Ti, Tp, Tv}(shape) where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(Ti(shape), Tp[1], Ti[], Tv[])

Base.summary(::RepeatRLE{D}) where {D} = "RepeatRLE($(D))"
similar_level(::RepeatRLELevel{D}) where {D} = RepeatRLE{D}()
similar_level(::RepeatRLELevel{D}, dim, tail...) where {D} = RepeatRLE{D}(dim)
data_rep_level(::Type{<:RepeatRLELevel{D, Ti, Tp, Tv}}) where {D, Ti, Tp, Tv} = RepeatData(D, Tv)

countstored_level(lvl::RepeatRLELevel, pos) = lvl.ptr[pos + 1] - 1

pattern!(lvl::RepeatRLELevel{D, Ti}) where {D, Ti} = 
    DenseLevel{Ti}(Pattern(), lvl.shape)

redefault!(lvl::RepeatRLELevel{D, Ti, Tp, Tv}, init) where {D, Ti, Tp, Tv} = 
    RepeatRLELevel{init, Ti, Tp, Tv}(lvl.val)

function Base.show(io::IO, lvl::RepeatRLELevel{D, Ti, Tp, Tv}) where {D, Ti, Tp, Tv}
    print(io, "RepeatRLE{")
    print(io, D)
    if get(io, :compact, false)
        print(io, "}(")
    else
        print(io, ", $Ti, $Tp, $Tv}(")
    end

    show(io, lvl.shape)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>Vector{Tp}), lvl.ptr)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Ti}), lvl.idx)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Tv}), lvl.val)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:RepeatRLELevel}, depth)
    p = fbr.pos
    crds = fbr.lvl.ptr[p]:fbr.lvl.ptr[p + 1] - 1

    print_coord(io, crd) = print(io, crd == fbr.lvl.ptr[p] ? 1 : fbr.lvl.idx[crd - 1] + 1, ":", fbr.lvl.idx[crd])
    get_fbr(crd) = fbr.lvl.val[crd]

    print(io, "RepeatRLE (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", fbr.lvl.shape, "]")
    display_fiber_data(io, mime, fbr, depth, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:RepeatRLELevel}) = 1
@inline level_size(lvl::RepeatRLELevel) = (lvl.shape,)
@inline level_axes(lvl::RepeatRLELevel) = (Base.OneTo(lvl.shape),)
@inline level_eltype(::Type{RepeatRLELevel{D, Ti, Tp, Tv}}) where {D, Ti, Tp, Tv} = Tv
@inline level_default(::Type{<:RepeatRLELevel{D}}) where {D} = D
(fbr::AbstractFiber{<:RepeatRLELevel})() = fbr
(fbr::Fiber{<:RepeatRLELevel})(idx...) = SubFiber(fbr.lvl, 1)(idx...)
function (fbr::SubFiber{<:RepeatRLELevel})(i, tail...)
    lvl = fbr.lvl
    p = fbr.pos
    r = searchsortedfirst(@view(lvl.idx[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), i)
    q = lvl.ptr[p] + r - 1
    return lvl.val[q]
end

mutable struct VirtualRepeatRLELevel
    ex
    D
    Ti
    Tp
    Tv
    shape
    ros_fill
    qos_stop
    dirty
end
function virtualize(ex, ::Type{RepeatRLELevel{D, Ti, Tp, Tv}}, ctx, tag=:lvl) where {D, Ti, Tp, Tv}
    sym = freshen(ctx, tag)
    shape = value(:($sym.shape), Int)
    ros_fill = freshen(ctx, sym, :_ros_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    dirty = freshen(ctx, sym, :_dirty)
    VirtualRepeatRLELevel(sym, D, Ti, Tp, Tv, shape, ros_fill, qos_stop, dirty)
end
function lower(lvl::VirtualRepeatRLELevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $RepeatRLELevel{$(lvl.D), $(lvl.Ti), $(lvl.Tp), $(lvl.Tv)}(
            $(ctx(lvl.shape)),
            $(lvl.ex).ptr,
            $(lvl.ex).idx,
            $(lvl.ex).val
        )
    end
end

Base.summary(lvl::VirtualRepeatRLELevel) = "RepeatRLE($(lvl.D))"

function virtual_level_size(lvl::VirtualRepeatRLELevel, ctx)
    ext = Extent(literal(lvl.Ti(1)), lvl.shape)
    (ext,)
end

function virtual_level_resize!(lvl::VirtualRepeatRLELevel, ctx, dim)
    lvl.shape = getstop(dim)
    lvl
end

virtual_level_default(lvl::VirtualRepeatRLELevel) = lvl.D
virtual_level_eltype(lvl::VirtualRepeatRLELevel) = lvl.Tv

function declare_level!(lvl::VirtualRepeatRLELevel, ctx::AbstractCompiler, mode, init)
    init == literal(lvl.D) || throw(FormatLimitation("Cannot initialize RepeatRLE Levels to non-default values"))
    Tp = lvl.Tp
    Ti = lvl.Ti
    push!(ctx.code.preamble, quote
        $(lvl.ex).ptr[1] = $(Tp(1))
        $(lvl.ros_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
    end)
    return lvl
end

function trim_level!(lvl::VirtualRepeatRLELevel, ctx::AbstractCompiler, pos)
    qos = freshen(ctx.code, :qos)
    push!(ctx.code.preamble, quote
        resize!($(lvl.ex).ptr, $(ctx(pos)) + 1)
        $qos = $(lvl.ex).ptr[end] - $(lvl.Tp(1))
        resize!($(lvl.ex).idx, $qos)
        resize!($(lvl.ex).val, $qos)
    end)
    return lvl
end

function assemble_level!(lvl::VirtualRepeatRLELevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_stop, pos_stop))
    quote
        Finch.resize_if_smaller!($(lvl.ex).ptr, $pos_stop + 1)
        Finch.fill_range!($(lvl.ex).ptr, 1, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualRepeatRLELevel, ctx::AbstractCompiler, pos_stop)
    Tp = lvl.Tp
    Ti = lvl.Ti
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :p_stop, pos_stop))
    qos_stop = lvl.qos_stop
    ros_fill = lvl.ros_fill
    qos_fill = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        for $p = 2:($pos_stop + 1)
            $(lvl.ex).ptr[$p] += $(lvl.ex).ptr[$p - 1]
        end
        $qos_fill = $(lvl.ex).ptr[$pos_stop + 1] - 1
        Finch.resize_if_smaller!($(lvl.ex).idx, $qos_fill)
        Finch.fill_range!($(lvl.ex).idx, $(ctx(lvl.shape)), $qos_stop + 1, $qos_fill)
        Finch.resize_if_smaller!($(lvl.ex).val, $qos_fill)
        Finch.fill_range!($(lvl.ex).val, $(lvl.D), $qos_stop + 1, $qos_fill)
    end)
    return lvl
end

function instantiate_reader(fbr::VirtualSubFiber{VirtualRepeatRLELevel}, ctx, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_i = freshen(ctx.code, tag, :_i)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)
    my_i1 = freshen(ctx.code, tag, :_i1)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = (quote
                $my_q = $(lvl.ex).ptr[$(ctx(pos))]
                $my_q_stop = $(lvl.ex).ptr[$(ctx(pos)) + $(Tp(1))]
                #TODO I think this if is only ever true
                if $my_q < $my_q_stop
                    $my_i = $(lvl.ex).idx[$my_q]
                    $my_i1 = $(lvl.ex).idx[$my_q_stop - $(Tp(1))]
                else
                    $my_i = $(Ti(1))
                    $my_i1 = $(Ti(0))
                end
            end),
            body = (ctx) -> Stepper(
                seek = (ctx, ext) -> quote
                    if $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                        $my_q = Finch.scansearch($(lvl.ex).idx, $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                    end
                end,
                body = Thunk(
                    preamble = :(
                        $my_i = $(lvl.ex).idx[$my_q]
                    ),
                    body = (ctx) -> Step(
                        stop = (ctx, ext) -> value(my_i),
                        chunk = Run(
                            body = Fill(value(:($(lvl.ex).val[$my_q]), lvl.Tv)) #TODO Flesh out fill to assert ndims and handle writes
                        ),
                        next = (ctx, ext) -> quote
                            $my_q += $(Tp(1))
                        end
                    )
                )
            )
        )
    )
end

is_laminable_updater(lvl::VirtualRepeatRLELevel, ctx, ::Union{typeof(defaultupdate), typeof(extrude)}) = false

instantiate_updater(fbr::VirtualSubFiber{VirtualRepeatRLELevel}, ctx, protos) = 
    instantiate_updater(VirtualTrackedSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, protos)
function instantiate_updater(fbr::VirtualTrackedSubFiber{VirtualRepeatRLELevel}, ctx, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_q = freshen(ctx.code, tag, :_q)
    my_p = freshen(ctx.code, tag, :_p)
    my_v = freshen(ctx.code, tag, :_v)
    D = lvl.D

    my_i_prev = freshen(ctx.code, tag, :_i_prev)
    my_v_prev = freshen(ctx.code, tag, :_v_prev)

    qos_stop = lvl.qos_stop
    ros_fill = lvl.ros_fill
    qos_fill = freshen(ctx.code, tag, :qos_fill)

    function record_run(ctx, stop, v)
        quote
            if $my_q > $qos_stop
                $qos_fill = $qos_stop
                $qos_stop = max($qos_stop << 1, $my_q)
                Finch.resize_if_smaller!($(lvl.ex).idx, $qos_stop)
                Finch.fill_range!($(lvl.ex).idx, $(ctx(lvl.shape)), $qos_fill + 1, $qos_stop)
                Finch.resize_if_smaller!($(lvl.ex).val, $qos_stop)
                Finch.fill_range!($(lvl.ex).val, $(lvl.D), $qos_fill + 1, $qos_stop)
            end
            $(fbr.dirty) = true
            $(lvl.ex).idx[$my_q] = $(ctx(stop))
            $(lvl.ex).val[$my_q] = $v
            $my_q += $(Tp(1))
        end
    end
    
    Furlable(
        tight = lvl,
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_q = $(lvl.ros_fill) + $(ctx(pos))
                $my_i_prev = $(Ti(0))
                $my_v_prev = $D
            end,
            body = (ctx) -> AcceptRun(
                body = (ctx, ext) -> Thunk(
                    preamble = quote
                        if $my_v_prev != $D && ($my_i_prev + 1) < $(ctx(getstart(ext)))
                            $(lvl.dirty) = true
                            $(record_run(ctx, my_i_prev, my_v_prev))
                            $my_v_prev = $D
                        end
                        $my_i_prev = $(ctx(getstart(ext))) - $(Ti(1))
                        $my_v = $D
                    end,
                    body = (ctx) -> Fill(value(my_v, lvl.Tv)),
                    epilogue = quote
                        if $my_v_prev != $my_v && $my_i_prev > 0
                            $(record_run(ctx, my_i_prev, my_v_prev))
                        end
                        $my_v_prev = $my_v
                        $my_i_prev = $(ctx(getstop(ext)))
                    end
                )
            ),
            epilogue = quote
                if $my_v_prev != $D
                    if $my_i_prev < $(ctx(lvl.shape))
                        $(record_run(ctx, my_i_prev, my_v_prev))
                    else
                        $(record_run(ctx, lvl.shape, my_v_prev))
                    end
                end
                $(lvl.ex).ptr[$(ctx(pos)) + $(Tp(1))] += ($my_q - ($(lvl.ros_fill) + $(ctx(pos))))
                $(lvl.ros_fill) += $my_q - ($(lvl.ros_fill) + $(ctx(pos)))
            end
        )
    )
end
