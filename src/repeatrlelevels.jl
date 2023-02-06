struct RepeatRLELevel{D, Ti, Tp, Tv}
    I::Ti
    pos::Vector{Tp}
    idx::Vector{Ti}
    val::Vector{Tv}
end
const RepeatRLE = RepeatRLELevel
RepeatRLELevel(D, args...) = RepeatRLELevel{D}(args...)

RepeatRLELevel{D}() where {D} = RepeatRLELevel{D}(0)
RepeatRLELevel{D, Ti}() where {D, Ti} = RepeatRLELevel{D, Ti}(zero(Ti))
RepeatRLELevel{D, Ti, Tp}() where {D, Ti, Tp} = RepeatRLELevel{D, Ti, Tp}(zero(Ti))
RepeatRLELevel{D, Ti, Tp, Tv}() where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(zero(Ti))

RepeatRLELevel{D}(I::Ti) where {D, Ti} = RepeatRLELevel{D, Ti}(I)
RepeatRLELevel{D, Ti}(I) where {D, Ti} = RepeatRLELevel{D, Ti, Int}(Ti(I))
RepeatRLELevel{D, Ti, Tp}(I) where {D, Ti, Tp} = RepeatRLELevel{D, Ti, Tp, typeof(D)}(Ti(I))
RepeatRLELevel{D, Ti, Tp, Tv}(I) where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(Ti(I), Tp[1], Ti[], Tv[])

RepeatRLELevel{D}(I::Ti, pos::Vector{Tp}, idx, val::Vector{Tv}) where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(I, pos, idx, val)
RepeatRLELevel{D, Ti}(I, pos::Vector{Tp}, idx, val::Vector{Tv}) where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(Ti(I), pos, idx, val)
RepeatRLELevel{D, Ti, Tp}(I, pos, idx, val::Vector{Tv}) where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(Ti(I), pos, idx, val)

"""
`f_code(rl)` = [RepeatRLELevel](@ref).
"""
f_code(::Val{:rl}) = RepeatRLE
summary_f_code(::RepeatRLE{D}) where {D} = "rl($(D))"
similar_level(::RepeatRLELevel{D}) where {D} = RepeatRLE{D}()
similar_level(::RepeatRLELevel{D}, dim, tail...) where {D} = RepeatRLE{D}(dim)
data_rep_level(::Type{<:RepeatRLELevel{D, Ti, Tp, Tv}}) where {D, Ti, Tp, Tv} = RepeatData(D, Tv)

pattern!(lvl::RepeatRLELevel{D, Ti}) where {D, Ti} = 
    DenseLevel{Ti}(lvl.I, Pattern())

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
        show(IOContext(io, :typeinfo=>Vector{Tp}), lvl.pos)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Ti}), lvl.idx)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Tv}), lvl.val)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:RepeatRLELevel})
    p = envposition(fbr.env)
    crds = fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1
    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "["); show(io, crd == fbr.lvl.pos[p] ? 1 : fbr.lvl.idx[crd - 1] + 1); print(io, ":"); show(io, fbr.lvl.idx[crd]); print(io, "]"))
    get_fbr(crd) = fbr.lvl.val[crd]

    print(io, "│ " ^ depth); print(io, "RepeatRLE ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:RepeatRLELevel}) = 1
@inline level_size(lvl::RepeatRLELevel) = (lvl.I,)
@inline level_axes(lvl::RepeatRLELevel) = (Base.OneTo(lvl.I),)
@inline level_eltype(::Type{RepeatRLELevel{D, Ti, Tp, Tv}}) where {D, Ti, Tp, Tv} = Tv
@inline level_default(::Type{<:RepeatRLELevel{D}}) where {D} = D
(fbr::Fiber{<:RepeatRLELevel})() = fbr
function (fbr::Fiber{<:RepeatRLELevel})(i, tail...)
    lvl = fbr.lvl
    p = envposition(fbr.env)
    r = searchsortedfirst(@view(lvl.idx[lvl.pos[p]:lvl.pos[p + 1] - 1]), i)
    q = lvl.pos[p] + r - 1
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
            $(lvl.ex).pos,
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

function initialize_level!(lvl::VirtualRepeatRLELevel, ctx::LowerJulia, mode)
    Tp = lvl.Tp
    Ti = lvl.Ti
    push!(ctx.preamble, quote
        $(lvl.ex).pos[1] = $(Tp(1))
        $(lvl.ros_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
    end)
    return lvl
end

function trim_level!(lvl::VirtualRepeatRLELevel, ctx::LowerJulia, pos)
    qos = ctx.freshen(:qos)
    push!(ctx.preamble, quote
        resize!($(lvl.ex).pos, $(ctx(pos)) + 1)
        $qos = $(lvl.ex).pos[end] - $(lvl.Tp(1))
        resize!($(lvl.ex).idx, $qos)
        resize!($(lvl.ex).val, $qos)
    end)
    return lvl
end

function assemble_level!(lvl::VirtualRepeatRLELevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_stop, pos_stop))
    quote
        $resize_if_smaller!($(lvl.ex).pos, $pos_stop + 1)
        $fill_range!($(lvl.ex).pos, 1, $pos_start + 1, $pos_stop + 1)
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
            $(lvl.ex).pos[$p] += $(lvl.ex).pos[$p - 1]
        end
        $qos_fill = $(lvl.ex).pos[$pos_stop + 1] - 1
        $resize_if_smaller!($(lvl.ex).idx, $qos_fill)
        $fill_range!($(lvl.ex).idx, $(ctx(lvl.I)), $qos_stop + 1, $qos_fill)
        $resize_if_smaller!($(lvl.ex).val, $qos_fill)
        $fill_range!($(lvl.ex).val, $(lvl.D), $qos_stop + 1, $qos_fill)
    end)
    return lvl
end

function get_level_reader(lvl::VirtualRepeatRLELevel, ctx, pos, ::Union{Nothing, Walk})
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
                $my_q = $(lvl.ex).pos[$(ctx(pos))]
                $my_q_stop = $(lvl.ex).pos[$(ctx(pos)) + $(Tp(1))]
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
                    while $my_q + $(Tp(1)) < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                        $my_q += $(Tp(1))
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

set_clean!(lvl::VirtualRepeatRLELevel, ctx) = :($(lvl.dirty) = false)
get_dirty(lvl::VirtualRepeatRLELevel, ctx) = value(lvl.dirty, Bool)

function get_level_updater(lvl::VirtualRepeatRLELevel, ctx, pos, ::Union{Nothing, Extrude})
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
            $(lvl.dirty) = true
            $(lvl.ex).idx[$my_q] = $(ctx(stop))
            $(lvl.ex).val[$my_q] = $v
            $my_q += $(Tp(1))
        end
    end
    
    Furlable(
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
                $(lvl.ex).pos[$(ctx(pos)) + $(Tp(1))] += ($my_q - ($(lvl.ros_fill) + $(ctx(pos))))
                $(lvl.ros_fill) += $my_q - ($(lvl.ros_fill) + $(ctx(pos)))
            end
        )
    )
end