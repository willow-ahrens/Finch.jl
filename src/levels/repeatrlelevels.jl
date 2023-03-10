"""
    RepeatRLELevel{[D], [Ti=Int], [Tp=Int], [Tv=typeof(D)]}([dim])

A subfiber of a repeat level is a vector that only stores contiguous repeated
values once. The RepeatRLELevel records locations of repeats using a sorted
list. Optionally, `dim` is the size of the vectors.

The fibers have type `Tv`, initialized to `D`. `D` may optionally be given as
the first argument.  `Ti` is the type of the last fiber index, and `Tp` is the
type used for positions in the level.

In the [@fiber](@ref) constructor, `rl` is an alias for `RepeatRLELevel`.

```jldoctest
julia> @fiber(rl(0.0), [11, 11, 22, 22, 00, 00, 00, 33, 33])
RepeatRLE (0.0) [1:9]
├─[1:2]: 11.0
├─[3:4]: 22.0
├─[5:7]: 0.0
├─[8:9]: 33.0
├─[10:9]: 0.0

```
"""
struct RepeatRLELevel{D, Ti, Tp, Tv}
    I::Ti
    ptr::Vector{Tp}
    idx::Vector{Ti}
    val::Vector{Tv}
end

const RepeatRLE = RepeatRLELevel
RepeatRLELevel(d, args...) = RepeatRLELevel{d}(args...)
RepeatRLELevel{D}() where {D} = RepeatRLELevel{D, Int}()
RepeatRLELevel{D}(I, args...) where {D} = RepeatRLELevel{D, typeof(I)}(I, args...)
RepeatRLELevel{D, Ti}(args...) where {D, Ti} = RepeatRLELevel{D, Ti, Int}(args...)
RepeatRLELevel{D, Ti, Tp}(args...) where {D, Ti, Tp} = RepeatRLELevel{D, Ti, Tp, typeof(D)}(args...)

RepeatRLELevel{D, Ti, Tp, Tv}() where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(zero(Ti))
RepeatRLELevel{D, Ti, Tp, Tv}(I) where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(Ti(I), Tp[1], Ti[], Tv[])

"""
`f_code(rl)` = [RepeatRLELevel](@ref).
"""
f_code(::Val{:rl}) = RepeatRLE
summary_f_code(::RepeatRLE{D}) where {D} = "rl($(D))"
similar_level(::RepeatRLELevel{D}) where {D} = RepeatRLE{D}()
similar_level(::RepeatRLELevel{D}, dim, tail...) where {D} = RepeatRLE{D}(dim)
data_rep_level(::Type{<:RepeatRLELevel{D, Ti, Tp, Tv}}) where {D, Ti, Tp, Tv} = RepeatData(D, Tv)

pattern!(lvl::RepeatRLELevel{D, Ti}) where {D, Ti} = 
    DenseLevel{Ti}(Pattern(), lvl.I)

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

    show(io, lvl.I)
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

    print(io, "RepeatRLE (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", fbr.lvl.I, "]")
    display_fiber_data(io, mime, fbr, depth, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:RepeatRLELevel}) = 1
@inline level_size(lvl::RepeatRLELevel) = (lvl.I,)
@inline level_axes(lvl::RepeatRLELevel) = (Base.OneTo(lvl.I),)
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
    I
    ros_fill
    qos_stop
    dirty
end
function virtualize(ex, ::Type{RepeatRLELevel{D, Ti, Tp, Tv}}, ctx, tag=:lvl) where {D, Ti, Tp, Tv}
    sym = ctx.freshen(tag)
    I = value(:($sym.I), Int)
    ros_fill = ctx.freshen(sym, :_ros_fill)
    qos_stop = ctx.freshen(sym, :_qos_stop)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    dirty = ctx.freshen(sym, :_dirty)
    VirtualRepeatRLELevel(sym, D, Ti, Tp, Tv, I, ros_fill, qos_stop, dirty)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualRepeatRLELevel)
    quote
        $RepeatRLELevel{$(lvl.D), $(lvl.Ti), $(lvl.Tp), $(lvl.Tv)}(
            $(ctx(lvl.I)),
            $(lvl.ex).ptr,
            $(lvl.ex).idx,
            $(lvl.ex).val
        )
    end
end

summary_f_code(lvl::VirtualRepeatRLELevel) = "rl($(lvl.D))"

function virtual_level_size(lvl::VirtualRepeatRLELevel, ctx)
    ext = Extent(literal(lvl.Ti(1)), lvl.I)
    (ext,)
end

function virtual_level_resize!(lvl::VirtualRepeatRLELevel, ctx, dim)
    lvl.I = getstop(dim)
    lvl
end

virtual_level_default(lvl::VirtualRepeatRLELevel) = lvl.D
virtual_level_eltype(lvl::VirtualRepeatRLELevel) = lvl.Tv

function declare_level!(lvl::VirtualRepeatRLELevel, ctx::LowerJulia, mode, init)
    init == literal(lvl.D) || throw(FormatLimitation("Cannot initialize RepeatRLE Levels to non-default values"))
    Tp = lvl.Tp
    Ti = lvl.Ti
    push!(ctx.preamble, quote
        $(lvl.ex).ptr[1] = $(Tp(1))
        $(lvl.ros_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
    end)
    return lvl
end

function trim_level!(lvl::VirtualRepeatRLELevel, ctx::LowerJulia, pos)
    qos = ctx.freshen(:qos)
    push!(ctx.preamble, quote
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
        $resize_if_smaller!($(lvl.ex).ptr, $pos_stop + 1)
        $fill_range!($(lvl.ex).ptr, 1, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualRepeatRLELevel, ctx::LowerJulia, pos_stop)
    Tp = lvl.Tp
    Ti = lvl.Ti
    p = ctx.freshen(:p)
    pos_stop = ctx(cache!(ctx, :p_stop, pos_stop))
    qos_stop = lvl.qos_stop
    ros_fill = lvl.ros_fill
    qos_fill = ctx.freshen(:qos_stop)
    push!(ctx.preamble, quote
        for $p = 2:($pos_stop + 1)
            $(lvl.ex).ptr[$p] += $(lvl.ex).ptr[$p - 1]
        end
        $qos_fill = $(lvl.ex).ptr[$pos_stop + 1] - 1
        $resize_if_smaller!($(lvl.ex).idx, $qos_fill)
        $fill_range!($(lvl.ex).idx, $(ctx(lvl.I)), $qos_stop + 1, $qos_fill)
        $resize_if_smaller!($(lvl.ex).val, $qos_fill)
        $fill_range!($(lvl.ex).val, $(lvl.D), $qos_stop + 1, $qos_fill)
    end)
    return lvl
end

function get_reader(fbr::VirtualSubFiber{VirtualRepeatRLELevel}, ctx, ::Union{Nothing, Walk})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)

    Furlable(
        size = virtual_level_size(lvl, ctx),
        body = (ctx, idx, ext) -> Thunk(
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
            body = Stepper(
                seek = (ctx, ext) -> quote
                    if $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                        $my_q = scansearch($(lvl.ex).idx, $(ctx(getstart(ext))), $my_q, $my_q_stop - 1)
                    end
                end,
                body = Thunk(
                    preamble = :(
                        $my_i = $(lvl.ex).idx[$my_q]
                    ),
                    body = Step(
                        stride = (ctx, idx, ext) -> value(my_i),
                        chunk = Run(
                            body = Simplify(Fill(value(:($(lvl.ex).val[$my_q]), lvl.Tv))) #TODO Flesh out fill to assert ndims and handle writes
                        ),
                        next = (ctx, idx, ext) -> quote
                            $my_q += $(Tp(1))
                        end
                    )
                )
            )
        )
    )
end

is_laminable_updater(lvl::VirtualRepeatRLELevel, ctx, ::Union{Nothing, Extrude}) = false
get_updater(fbr::VirtualSubFiber{VirtualRepeatRLELevel}, ctx, protos...) = 
    get_updater(VirtualTrackedSubFiber(fbr.lvl, fbr.pos, ctx.freshen(:null)), ctx, protos...)
function get_updater(fbr::VirtualTrackedSubFiber{VirtualRepeatRLELevel}, ctx, ::Union{Nothing, Extrude})
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_q = ctx.freshen(tag, :_q)
    my_p = ctx.freshen(tag, :_p)
    my_v = ctx.freshen(tag, :_v)
    D = lvl.D

    my_i_prev = ctx.freshen(tag, :_i_prev)
    my_v_prev = ctx.freshen(tag, :_v_prev)

    qos_stop = lvl.qos_stop
    ros_fill = lvl.ros_fill
    qos_fill = ctx.freshen(tag, :qos_fill)

    function record_run(ctx, stop, v)
        quote
            if $my_q > $qos_stop
                $qos_fill = $qos_stop
                $qos_stop = max($qos_stop << 1, $my_q)
                $resize_if_smaller!($(lvl.ex).idx, $qos_stop)
                $fill_range!($(lvl.ex).idx, $(ctx(lvl.I)), $qos_fill + 1, $qos_stop)
                $resize_if_smaller!($(lvl.ex).val, $qos_stop)
                $fill_range!($(lvl.ex).val, $(lvl.D), $qos_fill + 1, $qos_stop)
            end
            $(fbr.dirty) = true
            $(lvl.ex).idx[$my_q] = $(ctx(stop))
            $(lvl.ex).val[$my_q] = $v
            $my_q += $(Tp(1))
        end
    end
    
    Furlable(
        tight = lvl,
        val = D,
        size = virtual_level_size(lvl, ctx),
        body = (ctx, idx, ext) -> Thunk(
            preamble = quote
                $my_q = $(lvl.ros_fill) + $(ctx(pos))
                $my_i_prev = $(Ti(0))
                $my_v_prev = $D
            end,
            body = AcceptRun(
                val = D,
                body = (ctx, start, stop) -> Thunk(
                    preamble = quote
                        if $my_v_prev != $D && ($my_i_prev + 1) < $(ctx(start))
                            $(lvl.dirty) = true
                            $(record_run(ctx, my_i_prev, my_v_prev))
                            $my_v_prev = $D
                        end
                        $my_i_prev = $(ctx(start)) - $(Ti(1))
                        $my_v = $D
                    end,
                    body = Simplify(Fill(value(my_v, lvl.Tv), D)),
                    epilogue = quote
                        if $my_v_prev != $my_v && $my_i_prev > 0
                            $(record_run(ctx, my_i_prev, my_v_prev))
                        end
                        $my_v_prev = $my_v
                        $my_i_prev = $(ctx(stop))
                    end
                )
            ),
            epilogue = quote
                if $my_v_prev != $D
                    if $my_i_prev < $(ctx(lvl.I))
                        $(record_run(ctx, my_i_prev, my_v_prev))
                    else
                        $(record_run(ctx, lvl.I, my_v_prev))
                    end
                end
                $(lvl.ex).ptr[$(ctx(pos)) + $(Tp(1))] += ($my_q - ($(lvl.ros_fill) + $(ctx(pos))))
                $(lvl.ros_fill) += $my_q - ($(lvl.ros_fill) + $(ctx(pos)))
            end
        )
    )
end