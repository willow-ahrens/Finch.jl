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
function RepeatRLELevel{D, Ti, Tp, Tv}(I) where {D, Ti, Tp, Tv}
    if iszero(I)
        RepeatRLELevel{D, Ti, Tp, Tv}(Ti(I), Tp[1, 1], Ti[], Tv[])
    else
        RepeatRLELevel{D, Ti, Tp, Tv}(Ti(I), Tp[1, 2], Ti[Ti(I)], Tv[D])
    end
end

RepeatRLELevel{D}(I::Ti, pos::Vector{Tp}, idx, val::Vector{Tv}) where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(I, pos, idx, val)
RepeatRLELevel{D, Ti}(I, pos::Vector{Tp}, idx, val::Vector{Tv}) where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(Ti(I), pos, idx, val)
RepeatRLELevel{D, Ti, Tp}(I, pos, idx, val::Vector{Tv}) where {D, Ti, Tp, Tv} = RepeatRLELevel{D, Ti, Tp, Tv}(Ti(I), pos, idx, val)

"""
`f_code(rl)` = [RepeatRLELevel](@ref).
"""
f_code(::Val{:rl}) = RepeatRLE
summary_f_code(::RepeatRLE{D}) where {D} = "r($(D))"
similar_level(::RepeatRLELevel{D}) where {D} = RepeatRLE{D}()
similar_level(::RepeatRLELevel{D}, dim, tail...) where {D} = RepeatRLE{D}(dim)

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
    pos_alloc
    pos_fill
    pos_stop
    idx_alloc
    val_alloc
end
function virtualize(ex, ::Type{RepeatRLELevel{D, Ti, Tp, Tv}}, ctx, tag=:lvl) where {D, Ti, Tp, Tv}
    sym = ctx.freshen(tag)
    I = value(:($sym.I), Int)
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    pos_fill = ctx.freshen(sym, :_pos_fill)
    pos_stop = ctx.freshen(sym, :_pos_stop)
    idx_alloc = ctx.freshen(sym, :_idx_alloc)
    val_alloc = ctx.freshen(sym, :_val_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $pos_alloc = length($sym.pos)
        $idx_alloc = length($sym.idx)
        $val_alloc = length($sym.val)
    end)
    VirtualRepeatRLELevel(sym, D, Ti, Tp, Tv, I, pos_alloc, pos_fill, pos_stop, idx_alloc, val_alloc)
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

function initialize_level!(fbr::VirtualFiber{VirtualRepeatRLELevel}, ctx::LowerJulia, mode)
    lvl = fbr.lvl
    Tp = lvl.Tp
    Ti = lvl.Ti
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = length($(lvl.ex).pos)
        $(lvl.ex).pos[1] = $(Tp(1))
        $(lvl.pos_fill) = 1
        $(lvl.pos_stop) = 1
        $(lvl.idx_alloc) = length($(lvl.ex).idx)
        $(lvl.val_alloc) = length($(lvl.ex).val)
    end)
    return lvl
end

interval_assembly_depth(::VirtualRepeatRLELevel) = Inf

#This function is quite simple, since RepeatRLELevels don't support reassembly.
function assemble!(fbr::VirtualFiber{VirtualRepeatRLELevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = $Finch.regrow!($(lvl.ex).pos, $(lvl.pos_alloc), $p_stop + 1))
        $(lvl.pos_stop) = $p_stop + 1
    end)
end

function freeze_level!(fbr::VirtualFiber{VirtualRepeatRLELevel}, ctx::LowerJulia, mode)
    lvl = fbr.lvl
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_p = ctx.freshen(:p)
    my_q = ctx.freshen(:q)
    push!(ctx.preamble, quote
        $my_q = $(lvl.ex).pos[$(lvl.pos_fill)]
        for $my_p = $(lvl.pos_fill) + 1:$(lvl.pos_stop)
            $(lvl.idx_alloc) < $my_q && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q))
            $(lvl.val_alloc) < $my_q && ($(lvl.val_alloc) = $Finch.regrow!($(lvl.ex).val, $(lvl.val_alloc), $my_q))
            $(lvl.ex).idx[$(my_q)] = $(ctx(lvl.I))
            $(lvl.ex).val[$(my_q)] = $(lvl.D)
            $my_q += $(Tp(1))
            $(lvl.ex).pos[$(my_p)] = $my_q
        end
    end)
    return fbr.lvl
end

function trim_level!(lvl::VirtualRepeatRLELevel, ctx::LowerJulia, pos)
    qos = ctx.freshen(:qos)
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = $(ctx(pos)) + 1
        resize!($(lvl.ex).pos, $(lvl.pos_alloc))
        $(lvl.val_alloc) = $(lvl.idx_alloc) = $(lvl.ex).pos[$(lvl.pos_alloc)] - 1
        resize!($(lvl.ex).idx, $(lvl.idx_alloc))
        resize!($(lvl.ex).val, $(lvl.val_alloc))
    end)
    return lvl
end

function unfurl(fbr::VirtualFiber{VirtualRepeatRLELevel}, ctx, mode, ::Nothing, idx, idxs...)
    if idx.kind === protocol
        @assert idx.mode.kind === literal
        unfurl(fbr, ctx, mode, idx.mode.val, idx.idx, idxs...)
    elseif mode.kind === reader
        unfurl(fbr, ctx, mode, walk, idx, idxs...)
    else
        unfurl(fbr, ctx, mode, extrude, idx, idxs...)
    end
end

function unfurl(fbr::VirtualFiber{VirtualRepeatRLELevel}, ctx, mode, ::Walk, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)

    @assert isempty(idxs)

    body = Thunk(
        preamble = (quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + $(Tp(1))]
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

    exfurl(body, ctx, mode, idx)
end

function unfurl(fbr::VirtualFiber{VirtualRepeatRLELevel}, ctx, mode, ::Extrude, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_q = ctx.freshen(tag, :_q)
    my_p = ctx.freshen(tag, :_p)
    my_v = ctx.freshen(tag, :_v)
    D = lvl.D

    my_i_prev = ctx.freshen(tag, :_i_prev)
    my_v_prev = ctx.freshen(tag, :_v_prev)

    @assert isempty(idxs)

    function record_run(ctx, stop, v)
        quote
            $(lvl.idx_alloc) < $my_q && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q))
            $(lvl.val_alloc) < $my_q && ($(lvl.val_alloc) = $Finch.regrow!($(lvl.ex).val, $(lvl.val_alloc), $my_q))
            $(lvl.ex).idx[$my_q] = $(ctx(stop))
            $(lvl.ex).val[$my_q] = $v
            $my_q += $(Tp(1))
        end
    end
    
    push!(ctx.preamble, quote
        $my_q = $(lvl.ex).pos[$(lvl.pos_fill)]
        for $my_p = $(lvl.pos_fill) + 1:$(ctx(envposition(fbr.env)))
            $(record_run(ctx, lvl.I, D))
            $(lvl.ex).pos[$(my_p)] = $my_q
        end
        $my_i_prev = $(Ti(0))
        $my_v_prev = $D
    end)

    body = AcceptRun(
        val = D,
        body = (ctx, start, stop) -> Thunk(
            preamble = quote
                if $my_v_prev != $D && ($my_i_prev + 1) < $(ctx(start))
                    $(record_run(ctx, my_i_prev, my_v_prev))
                    $my_v_prev = $D
                end
                $my_i_prev = $(ctx(start)) - $(Ti(1))
                $my_v = $D
            end,
            body = Simplify(Fill(value(my_v, lvl.Tv), D)),
            epilogue = begin
                body = quote
                    if $my_v_prev != $my_v && $my_i_prev > 0
                        $(record_run(ctx, my_i_prev, my_v_prev))
                    end
                    $my_v_prev = $my_v
                    $my_i_prev = $(ctx(stop))
                end
                if envdefaultcheck(fbr.env) !== nothing
                    body = quote
                        $body
                        $(envdefaultcheck(fbr.env)) = false
                    end
                end
                body
            end
        )
    )

    push!(ctx.epilogue, quote
        if $my_v_prev != $D && $my_i_prev < $(ctx(lvl.I))
            $(record_run(ctx, my_i_prev, my_v_prev))
            $(record_run(ctx, lvl.I, D))
        elseif $(ctx(lvl.I)) > 0
            $(record_run(ctx, lvl.I, my_v_prev))
        end
        $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + $(Tp(1))] = $my_q
        $(lvl.pos_fill) = $(ctx(envposition(fbr.env))) + $(Tp(1))
    end)

    exfurl(body, ctx, mode, idx)
end