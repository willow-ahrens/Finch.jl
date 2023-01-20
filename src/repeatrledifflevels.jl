struct RepeatRLEDiffLevel{D, Ti, Tp, Tv}
    I::Ti
    pos::Vector{Tp}
    idx::Vector{UInt8}
    val::Vector{Tv}
end
const RepeatRLEDiff = RepeatRLEDiffLevel
RepeatRLEDiffLevel(D, args...) = RepeatRLEDiffLevel{D}(args...)

RepeatRLEDiffLevel{D}() where {D} = RepeatRLEDiffLevel{D}(0)
RepeatRLEDiffLevel{D, Ti}() where {D, Ti} = RepeatRLEDiffLevel{D, Ti}(zero(Ti))
RepeatRLEDiffLevel{D, Ti, Tp}() where {D, Ti, Tp} = RepeatRLEDiffLevel{D, Ti, Tp}(zero(Ti))
RepeatRLEDiffLevel{D, Ti, Tp, Tv}() where {D, Ti, Tp, Tv} = RepeatRLEDiffLevel{D, Ti, Tp, Tv}(zero(Ti))

RepeatRLEDiffLevel{D}(I::Ti) where {D, Ti} = RepeatRLEDiffLevel{D, Ti}(I)
RepeatRLEDiffLevel{D, Ti}(I) where {D, Ti} = RepeatRLEDiffLevel{D, Ti, Int}(Ti(I))
RepeatRLEDiffLevel{D, Ti, Tp}(I) where {D, Ti, Tp} = RepeatRLEDiffLevel{D, Ti, Tp, typeof(D)}(Ti(I))
function RepeatRLEDiffLevel{D, Ti, Tp, Tv}(I) where {D, Ti, Tp, Tv}
    if iszero(I)
        RepeatRLEDiffLevel{D, Ti, Tp, Tv}(Ti(I), Tp[1, 1], UInt8[0x00], Tv[])
    else
        RepeatRLEDiffLevel{D, Ti, Tp, Tv}(Ti(I), Tp[1, 2], UInt8[[0xff for i in 1:cld(I, 0xff) - 1]; mod1(I, 0xff); 0x00], Tv[D])
    end
end

RepeatRLEDiffLevel{D}(I::Ti, pos::Vector{Tp}, idx, val::Vector{Tv}) where {D, Ti, Tp, Tv} = RepeatRLEDiffLevel{D, Ti, Tp, Tv}(I, pos, idx, val)
RepeatRLEDiffLevel{D, Ti}(I, pos::Vector{Tp}, idx, val::Vector{Tv}) where {D, Ti, Tp, Tv} = RepeatRLEDiffLevel{D, Ti, Tp, Tv}(Ti(I), pos, idx, val)
RepeatRLEDiffLevel{D, Ti, Tp}(I, pos, idx, val::Vector{Tv}) where {D, Ti, Tp, Tv} = RepeatRLEDiffLevel{D, Ti, Tp, Tv}(Ti(I), pos, idx, val)

"""
`f_code(rld)` = [RepeatRLEDiffLevel](@ref).
"""
f_code(::Val{:rld}) = RepeatRLEDiff
summary_f_code(::RepeatRLEDiff{D}) where {D} = "rld($(D))"
similar_level(::RepeatRLEDiffLevel{D}) where {D} = RepeatRLEDiff{D}()
similar_level(::RepeatRLEDiffLevel{D}, dim, tail...) where {D} = RepeatRLEDiff{D}(dim)

pattern!(lvl::RepeatRLEDiffLevel{D, Ti}) where {D, Ti} = 
    DenseLevel{Ti}(lvl.I, Pattern())

function Base.show(io::IO, lvl::RepeatRLEDiffLevel{D, Ti, Tp, Tv}) where {D, Ti, Tp, Tv}
    print(io, "RepeatRLEDiff{")
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
        show(IOContext(io, :typeinfo=>Vector{UInt8}), lvl.idx)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Tv}), lvl.val)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:RepeatRLEDiffLevel})
    p = envposition(fbr.env)
    crds = fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1
    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "[:+"); show(io, fbr.lvl.idx[crd]); print(io, "]"))
    get_fbr(crd) = fbr.lvl.val[crd]

    print(io, "│ " ^ depth); print(io, "RepeatRLEDiff ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_fbr)
end


@inline Base.ndims(fbr::Fiber{<:RepeatRLEDiffLevel}) = 1
@inline Base.size(fbr::Fiber{<:RepeatRLEDiffLevel}) = (fbr.lvl.I,)
@inline Base.axes(fbr::Fiber{<:RepeatRLEDiffLevel}) = (1:fbr.lvl.I,)
@inline Base.eltype(::Fiber{<:RepeatRLEDiffLevel{D, Ti, Tv}}) where {D, Ti, Tv} = Tv
@inline default(::Fiber{<:RepeatRLEDiffLevel{D}}) where {D} = D

(fbr::Fiber{<:RepeatRLEDiffLevel})() = fbr
function (fbr::Fiber{<:RepeatRLEDiffLevel})(i, tail...)
    lvl = fbr.lvl
    p = envposition(fbr.env)
    q = lvl.pos[p] - 1
    j = 0
    while j < i
        q += 1
        j += lvl.idx[q]
    end
    return lvl.val[q]
end

mutable struct VirtualRepeatRLEDiffLevel
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
function virtualize(ex, ::Type{RepeatRLEDiffLevel{D, Ti, Tp, Tv}}, ctx, tag=:lvl) where {D, Ti, Tp, Tv}
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
    VirtualRepeatRLEDiffLevel(sym, D, Ti, Tp, Tv, I, pos_alloc, pos_fill, pos_stop, idx_alloc, val_alloc)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualRepeatRLEDiffLevel)
    quote
        $RepeatRLEDiffLevel{$(lvl.D), $(lvl.Ti), $(lvl.Tp), $(lvl.Tv)}(
            $(ctx(lvl.I)),
            $(lvl.ex).pos,
            $(lvl.ex).idx,
            $(lvl.ex).val
        )
    end
end

summary_f_code(lvl::VirtualRepeatRLEDiffLevel) = "rl($(lvl.D))"

function virtual_level_size(lvl::VirtualRepeatRLEDiffLevel, ctx)
    ext = Extent(literal(lvl.Ti(1)), lvl.I)
    (ext,)
end

function virtual_level_resize!(lvl::VirtualRepeatRLEDiffLevel, ctx, dim)
    lvl.I = getstop(dim)
    lvl
end
virtual_level_default(lvl::VirtualRepeatRLEDiffLevel) = lvl.D
virtual_level_eltype(lvl::VirtualRepeatRLEDiffLevel) = lvl.Tv

function initialize_level!(fbr::VirtualFiber{VirtualRepeatRLEDiffLevel}, ctx::LowerJulia, mode)
    lvl = fbr.lvl
    Tp = lvl.Tp
    Ti = lvl.Ti
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = length($(lvl.ex).pos)
        $(lvl.ex).pos[1] = $(Tp(1))
        $(lvl.pos_fill) = 1
        $(lvl.pos_stop) = 2
        $(lvl.idx_alloc) = length($(lvl.ex).idx)
        $(lvl.val_alloc) = length($(lvl.ex).val)
    end)
    return lvl
end

interval_assembly_depth(::VirtualRepeatRLEDiffLevel) = Inf

#This function is quite simple, since RepeatRLEDiffLevels don't support reassembly.
function assemble!(fbr::VirtualFiber{VirtualRepeatRLEDiffLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = $Finch.regrow!($(lvl.ex).pos, $(lvl.pos_alloc), $p_stop + 1))
        $(lvl.pos_stop) = $p_stop + 1
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualRepeatRLEDiffLevel}, ctx::LowerJulia, mode)
    lvl = fbr.lvl
    my_i = ctx.freshen(:i)
    my_p = ctx.freshen(:p)
    my_q = ctx.freshen(:q)
    Tp = lvl.Tp
    Ti = lvl.Ti
    push!(ctx.preamble, quote
        $my_q = $(lvl.ex).pos[$(lvl.pos_fill)]
        for $my_p = $(lvl.pos_fill) + 1:$(lvl.pos_stop)
            $my_i = $(Ti(0))
            while $my_i + 0xff < $(ctx(lvl.I))
                $(lvl.idx_alloc) < $my_q && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q))
                $(lvl.val_alloc) < $my_q && ($(lvl.val_alloc) = $Finch.regrow!($(lvl.ex).val, $(lvl.val_alloc), $my_q))
                $(lvl.ex).idx[$my_q] = 0xff
                $(lvl.ex).val[$my_q] = $(lvl.D)
                $my_i += 0xff
                my_q += $(Tp(1))
            end
            $(lvl.idx_alloc) < $my_q && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q))
            $(lvl.val_alloc) < $my_q && ($(lvl.val_alloc) = $Finch.regrow!($(lvl.ex).val, $(lvl.val_alloc), $my_q))
            $(lvl.ex).idx[$my_q] = $(ctx(lvl.I)) - $my_i
            $(lvl.ex).val[$my_q] = $(lvl.D)
            $my_q += $(Tp(1))
            $(lvl.ex).pos[$(my_p)] = $my_q
        end
        $(lvl.idx_alloc) < $my_q && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q))
        $(lvl.ex).idx[$my_q] = 0x00
    end)
    return fbr.lvl
end

function trim_level!(lvl::VirtualRepeatRLEDiffLevel, ctx::LowerJulia, pos)
    qos = ctx.freshen(:qos)
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = $(ctx(pos)) + 1
        resize!($(lvl.ex).pos, $(lvl.pos_alloc))
        $(lvl.idx_alloc) = $(lvl.ex).pos[$(lvl.pos_alloc)]
        resize!($(lvl.ex).idx, $(lvl.idx_alloc))
        $(lvl.val_alloc) = $(lvl.ex).pos[$(lvl.pos_alloc)] - 1
        resize!($(lvl.ex).val, $(lvl.val_alloc))
    end)
    return lvl
end

function unfurl(fbr::VirtualFiber{VirtualRepeatRLEDiffLevel}, ctx, mode, ::Nothing, idx, idxs...)
    if idx.kind === protocol
        @assert idx.mode.kind === literal
        unfurl(fbr, ctx, mode, idx.mode.val, idx.idx, idxs...)
    elseif mode.kind === reader
        unfurl(fbr, ctx, mode, walk, idx, idxs...)
    else
        unfurl(fbr, ctx, mode, extrude, idx, idxs...)
    end
end

function unfurl(fbr::VirtualFiber{VirtualRepeatRLEDiffLevel}, ctx, mode, ::Walk, idx, idxs...)
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
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))] - $(Tp(1))
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + $(Tp(1))]
            $my_i = $(lvl.Ti(0))
            $my_i1 = $(lvl.I)
        end,
        body = Stepper(
            seek = (ctx, ext) -> quote
                while $my_q + $(Tp(1)) < $my_q_stop && $my_i < $(ctx(getstart(ext)))
                    $my_q += $(Tp(1))
                    $my_i += $(lvl.ex).idx[$my_q]
                end
            end,
            body = Step(
                stride = (ctx, idx, ext) -> value(my_i),
                chunk = Run(
                    body = Simplify(Fill(value(:($(lvl.ex).val[$my_q]), lvl.Tv))) #TODO Flesh out fill to assert ndims and handle writes
                ),
                next = (ctx, idx, ext) -> quote
                    $my_q += $(Tp(1))
                    $my_i += $(lvl.ex).idx[$my_q]
                end
            )
        )
    )

    exfurl(body, ctx, mode, idx)
end

function unfurl(fbr::VirtualFiber{VirtualRepeatRLEDiffLevel}, ctx, mode, ::Extrude, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    Tp = lvl.Tp
    Ti = lvl.Ti
    my_q = ctx.freshen(tag, :_q)
    my_p = ctx.freshen(tag, :_p)
    my_v = ctx.freshen(tag, :_v)
    D = lvl.D

    my_i = ctx.freshen(tag, :_i)
    my_i_prev = ctx.freshen(tag, :_i_prev)
    my_v_prev = ctx.freshen(tag, :_v_prev)

    @assert isempty(idxs)

    function record_run(ctx, stop, v)
        quote
            while $my_i + 0xff < $(ctx(stop))
                $Finch.@regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q)
                $Finch.@regrow!($(lvl.ex).val, $(lvl.val_alloc), $my_q)
                $(lvl.ex).idx[$my_q] = 0xff
                $(lvl.ex).val[$my_q] = $v
                $my_i += 0xff
                $my_q += $(Tp(1))
            end
            $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q)
            $Finch.regrow!($(lvl.ex).val, $(lvl.val_alloc), $my_q)
            $(lvl.ex).idx[$my_q] = $(ctx(stop)) - $my_i
            $(lvl.ex).val[$my_q] = $v
            $my_q += $(Tp(1))
            $my_i = $stop
        end
    end
    
    push!(ctx.preamble, quote
        $my_q = $(lvl.ex).pos[$(lvl.pos_fill)]
        for $my_p = $(lvl.pos_fill) + 1:$(ctx(envposition(fbr.env)))
            $my_i = $(Ti(0))
            $(record_run(ctx, lvl.I, D))
            $(lvl.ex).pos[$(my_p)] = $my_q
        end
        $my_i = $(Ti(0))
        $my_i_prev = $(Ti(0))
        $my_v_prev = $D
    end)

    body = AcceptRun(
        val = D,
        body = (ctx, start, stop) -> Thunk(
            preamble = quote
                if $my_v_prev != $D && ($my_i_prev + $(Ti(1))) < $(ctx(start))
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
        $(lvl.pos_fill) = $(ctx(envposition(fbr.env))) + 1
    end)

    exfurl(body, ctx, mode, idx)
end