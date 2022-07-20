struct RepeatLevel{D, Ti, Tv}
    I::Ti
    pos::Vector{Ti}
    idx::Vector{Ti}
    val::Vector{Tv}
end
const Repeat = RepeatLevel
RepeatLevel{D}() where {D} = RepeatLevel(0)
RepeatLevel{D, Ti}() where {D, Ti} = RepeatLevel{D, Ti}(zero(Ti))
RepeatLevel{D, Ti}(I::Ti) where {D, Ti} = RepeatLevel{D, Ti, typeof(D)}(I)
RepeatLevel{D, Ti, Tv}(I::Ti) where {D, Ti, Tv} = RepeatLevel{Ti, Lvl}(I, Ti[1, fill(0, 16)...], Vector{Ti}(undef, 16), Vector{Tv}(undef, 16))
RepeatLevel{D}(I::Ti, pos, idx, val::Vector{Tv}) where {D, Ti, Tv} = RepeatLevel{D, Ti, Tv}(I, pos, idx, val)

parse_level((default,), ::Val{:r}) = Repeat{D}()
summary_f_str(lvl::RepeatLevel) = "r"
summary_f_str_args(::RepeatLevel{D}) where {D} = (D,)
similar_level(::RepeatLevel{D}) where {D} = Repeat{D}()
similar_level(::RepeatLevel{D}, dim, tail...) where {D} = Repeat{D}(dim)

function Base.show(io::IO, lvl::RepeatLevel{D}) where {D}
    print(io, "Repeat{")
    print(io, D)
    print(io, "}(")
    print(io, lvl.I)
    print(io, ", ")
    if get(io, :compact, true)
        print(io, "…")
    else
        show_region(io, lvl.pos)
        print(io, ", ")
        show_region(io, lvl.idx)
        print(io, ", ")
        show_region(io, lvl.val)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:RepeatLevel})
    p = envposition(fbr.env)
    crds = fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1
    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "["); show(io, crd == fbr.lvl.pos[p] ? 1 : fbr.lvl.idx[crd - 1] + 1); print(io, ":"); show(io, fbr.lvl.idx[crd]); print(io, "]"))
    get_coord(crd) = fbr.lvl.idx[crd]

    print(io, "│ " ^ depth); print(io, "Repeat ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_coord)
end


@inline arity(fbr::Fiber{<:RepeatLevel}) = 1
@inline shape(fbr::Fiber{<:RepeatLevel}) = (fbr.lvl.I,)
@inline domain(fbr::Fiber{<:RepeatLevel}) = (1:fbr.lvl.I,)
@inline image(::Fiber{<:RepeatLevel{D, Ti, Tv}}) where {D, Ti, Tv} = Tv
@inline default(::Fiber{<:RepeatLevel{D}}) where {D} = D

(fbr::Fiber{<:RepeatLevel})() = fbr
function (fbr::Fiber{<:RepeatLevel{Ti}})(i, tail...) where {D, Tv, Ti, N, R}
    lvl = fbr.lvl
    p = envposition(fbr.env)
    r = searchsortedfirst(@view(lvl.idx[lvl.pos[p]:lvl.pos[p + 1] - 1]), i)
    q = lvl.pos[p] + r - 1
    return lvl.val[q]
end

mutable struct VirtualRepeatLevel
    ex
    D
    Ti
    Tv
    I
    pos_alloc
    idx_alloc
    val_alloc
end
function virtualize(ex, ::Type{RepeatLevel{D, Ti, Tv}}, ctx, tag=:lvl) where {D, Ti, Tv}
    sym = ctx.freshen(tag)
    I = Virtual{Int}(:($sym.I))
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    idx_alloc = ctx.freshen(sym, :_idx_alloc)
    val_alloc = ctx.freshen(sym, :_val_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $pos_alloc = length($sym.pos)
        $idx_alloc = length($sym.idx)
        $val_alloc = length($sym.val)
    end)
    VirtualRepeatLevel(sym, D, Ti, Tv, I, pos_alloc, idx_alloc, val_alloc)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualRepeatLevel)
    quote
        $RepeatLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(lvl.ex).pos,
            $(lvl.ex).idx,
            $(lvl.ex).val
        )
    end
end

summary_f_str(lvl::VirtualRepeatLevel) = "r"
summary_f_str_args(lvl::VirtualRepeatLevel) = lvl.D

getsites(fbr::VirtualFiber{VirtualRepeatLevel}) =
    [envdepth(fbr.env) + 1, ]

function getdims(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode)
    ext = Extent(1, fbr.lvl.I)
    if mode != Read()
        ext = suggest(ext)
    end
    (ext,)
end

function setdims!(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode, dim)
    fbr.lvl.I = getstop(dim)
    fbr
end

@inline default(fbr::VirtualFiber{<:VirtualRepeatLevel}) = fbr.lvl.D

function initialize_level!(fbr::VirtualFiber{VirtualRepeatLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    lvl = fbr.lvl
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = length($(lvl.ex).pos)
        $(lvl.ex).pos[1] = 1
        $(lvl.idx_alloc) = length($(lvl.ex).idx)
        $(lvl.val_alloc) = length($(lvl.ex).val)
    end)
    return lvl
end

interval_assembly_depth(::VirtualRepeatLevel) = Inf

#This function is quite simple, since RepeatLevels don't support reassembly.
function assemble!(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = $Finch.regrow!($(lvl.ex).pos, $(lvl.pos_alloc), $p_stop + 1))
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualRepeatLevel}, ctx::LowerJulia, mode::Union{Write, Update})
    return fbr.lvl
end

unfurl(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode::Read, idx, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, walk))

function unfurl(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode::Read, idx::Protocol{<:Any, Walk}, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)

    body = Thunk(
        preamble = (quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_q < $my_q_stop
                $my_i = $(lvl.ex).idx[$my_q]
                $my_i1 = $(lvl.ex).idx[$my_q_stop - 1]
            else
                $my_i = 1
                $my_i1 = 0
            end
        end),
        body = Stepper(
            seek = (ctx, ext) -> quote
                #$my_q = searchsortedfirst($(lvl.ex).idx, $start, $my_q, $my_q_stop, Base.Forward)
                while $my_q < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                    $my_q += 1
                end
            end,
            body = Thunk(
                preamble = :(
                    $my_i = $(lvl.ex).idx[$my_q]
                ),
                body = Step(
                    stride = (ctx, idx, ext) -> my_i,
                    chunk = Run(
                        body = Virtual{lvl.Tv}(:($(lvl.ex).val[$my_q]))
                    ),
                    next = (ctx, idx, ext) -> quote
                        $my_q += 1
                    end
                )
            )
        )
    )

    exfurl(body, ctx, mode, idx.idx)
end

unfurl(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode::Union{Write, Update}, idx, idxs...) =
    unfurl(fbr, ctx, mode, protocol(idx, extrude), idxs...)

function unfurl(fbr::VirtualFiber{VirtualRepeatLevel}, ctx, mode::Union{Write, Update}, idx::Protocol{<:Any, Extrude}, tail...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_q = ctx.freshen(tag, :_q)
    my_q_start = ctx.freshen(tag, :_q_start)
    my_v = ctx.freshen(tag, :_v)
    D = lvl.D
    my_i_prev = ctx.freshen(tag, :_i_prev)
    my_v_prev = ctx.freshen(tag, :_v_prev)

    @assert isempty(tail)

    body = Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_start = $my_q
            $my_i_prev = 0
            $my_v_prev = $D
        end,
        body = AcceptRun(
            val = D,
            body = (ctx, start, stop) -> Thunk(
                preamble = quote
                    if $start != $my_i_prev + 1 
                        if $my_q == $my_q_start || $D != $my_v_prev
                        $(lvl.idx_alloc) < $my_q && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q))
                        $(lvl.val_alloc) < $my_q && ($(lvl.val_alloc) = $Finch.regrow!($(lvl.ex).val, $(lvl.val_alloc), $my_q))
                        $(lvl.ex).idx[$my_q] = $(ctx(start)) - 1
                        $(lvl.ex).val[$my_q] = $(lvl.Tv)($D)
                        $my_v_prev = $D
                        $my_q += 1
                        else
                            $(lvl.ex).idx[$my_q] = $(ctx(stop))
                        end
                    end
                end,
                body = Virtual{lvl.Tv}(my_v),
                epilogue = begin
                    body = quote
                        if $my_q == $my_q_start || $my_v != $my_v_prev
                            $(lvl.idx_alloc) < $my_q && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q))
                            $(lvl.val_alloc) < $my_q && ($(lvl.val_alloc) = $Finch.regrow!($(lvl.ex).val, $(lvl.val_alloc), $my_q))
                            $(lvl.ex).idx[$my_q] = $(ctx(stop))
                            $(lvl.ex).val[$my_q] = $(lvl.Tv)($my_v)
                            $my_v_prev = $my_v
                            $my_q += 1
                        else
                            $(lvl.ex).idx[$my_q] = $(ctx(stop))
                        end
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
        ),
        epilogue = quote
            $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1] = $my_q
        end
    )

    exfurl(body, ctx, mode, idx.idx)
end