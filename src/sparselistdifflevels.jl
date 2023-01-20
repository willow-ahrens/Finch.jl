struct SparseListDiffLevel{Ti, Tp, Lvl}
    I::Ti
    pos::Vector{Tp}
    idx::Vector{UInt8}
    jdx::Vector{Ti}
    lvl::Lvl
end
const SparseListDiff = SparseListDiffLevel
SparseListDiffLevel(lvl) = SparseListDiffLevel(0, lvl)
SparseListDiffLevel{Ti}(lvl) where {Ti} = SparseListDiffLevel{Ti}(zero(Ti), lvl)
SparseListDiffLevel{Ti, Tp}(lvl) where {Ti, Tp} = SparseListDiffLevel{Ti, Tp}(zero(Ti), lvl)

SparseListDiffLevel(I::Ti, lvl) where {Ti} = SparseListDiffLevel{Ti}(I, lvl)
SparseListDiffLevel{Ti}(I, lvl) where {Ti} = SparseListDiffLevel{Ti, Int}(Ti(I), lvl)
SparseListDiffLevel{Ti, Tp}(I, lvl::Lvl) where {Ti, Tp, Lvl} = SparseListDiffLevel{Ti, Tp, Lvl}(Ti(I), Tp[1, 1], UInt8[0x00], Ti[0], lvl)

SparseListDiffLevel(I::Ti, pos::Vector{Tp}, idx, jdx, lvl) where {Ti, Tp} = SparseListDiffLevel{Ti}(I, pos, idx, jdx, lvl)
SparseListDiffLevel{Ti}(I, pos::Vector{Tp}, idx, jdx, lvl::Lvl) where {Ti, Tp, Lvl} = SparseListDiffLevel{Ti, Tp, Lvl}(Ti(I), pos, idx, jdx, lvl)
SparseListDiffLevel{Ti, Tp}(I, pos, idx, jdx, lvl::Lvl) where {Ti, Tp, Lvl} = SparseListDiffLevel{Ti, Tp, Lvl}(Ti(I), pos, idx, jdx, lvl)

"""
`f_code(l)` = [SparseListDiffLevel](@ref).
"""
f_code(::Val{:sld}) = SparseListDiff
summary_f_code(lvl::SparseListDiffLevel) = "sld($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SparseListDiffLevel) = SparseListDiff(similar_level(lvl.lvl))
similar_level(lvl::SparseListDiffLevel, dim, tail...) = SparseListDiff(dim, similar_level(lvl.lvl, tail...))

pattern!(lvl::SparseListDiffLevel{Ti}) where {Ti} = 
    SparseListDiffLevel{Ti}(lvl.I, lvl.pos, lvl.idx, pattern!(lvl.lvl))

function Base.show(io::IO, lvl::SparseListDiffLevel{Ti, Tp}) where {Ti, Tp}
    if get(io, :compact, false)
        print(io, "SparseListDiff(")
    else
        print(io, "SparseListDiff{$Ti, $Tp}(")
    end
    show(IOContext(io, :typeinfo=>Ti), lvl.I)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>Vector{Tp}), lvl.pos)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{UInt8}), lvl.idx)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Vector{Ti}), lvl.jdx)
    end
    print(io, ", ")
    show(io, lvl.lvl)
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:SparseListDiffLevel})
    #TODO this is wrong
    p = envposition(fbr.env)
    crds = fbr.lvl.pos[p]:fbr.lvl.pos[p + 1] - 1
    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "[+"); show(io, fbr.lvl.idx[crd]); print(io, "]"))
    get_fbr(crd) = Fiber(fbr.lvl.lvl, Environment(position=crd, parent=fbr.env))()

    print(io, "│ " ^ depth); print(io, "SparseListDiff ("); show(IOContext(io, :compact=>true), default(fbr)); print(io, ") ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_fbr)
end

@inline level_ndims(::Type{<:SparseListDiffLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseListDiffLevel) = (lvl.I, level_size(lvl.lvl)...)
@inline level_axes(lvl::SparseListDiffLevel) = (Base.OneTo(lvl.I), level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:SparseListDiffLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseListDiffLevel{Ti, Tp, Lvl}}) where {Ti, Tp, Lvl} = level_default(Lvl)
(fbr::Fiber{<:SparseListDiffLevel})() = fbr
function (fbr::Fiber{<:SparseListDiffLevel{Ti}})(i, tail...) where {Ti}
    lvl = fbr.lvl
    p = envposition(fbr.env)
    q = lvl.pos[p] - 1
    j = 0
    while q + 1 < lvl.pos[p + 1] && j < i
        q += 1
        j += lvl.idx[q]
    end
    fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
    i == j ? default(fbr_2) : fbr_2(tail...)
end

mutable struct VirtualSparseListDiffLevel
    ex
    Ti
    Tp
    I
    pos_fill
    pos_stop
    pos_alloc
    idx_alloc
    jdx_alloc
    lvl
end
function virtualize(ex, ::Type{SparseListDiffLevel{Ti, Tp, Lvl}}, ctx, tag=:lvl) where {Ti, Tp, Lvl}
    sym = ctx.freshen(tag)
    I = value(:($sym.I), Int)
    pos_fill = ctx.freshen(sym, :_pos_fill)
    pos_stop = ctx.freshen(sym, :_pos_stop)
    pos_alloc = ctx.freshen(sym, :_pos_alloc)
    idx_alloc = ctx.freshen(sym, :_idx_alloc)
    jdx_alloc = ctx.freshen(sym, :_jdx_alloc)
    push!(ctx.preamble, quote
        $sym = $ex
        $pos_alloc = length($sym.pos)
        $idx_alloc = length($sym.idx)
        $jdx_alloc = length($sym.jdx)
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseListDiffLevel(sym, Ti, Tp, I, pos_fill, pos_stop, pos_alloc, idx_alloc, jdx_alloc, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSparseListDiffLevel)
    quote
        $SparseListDiffLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(lvl.ex).pos,
            $(lvl.ex).idx,
            $(lvl.ex).jdx,
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_code(lvl::VirtualSparseListDiffLevel) = "sld($(summary_f_code(lvl.lvl)))"

hasdefaultcheck(lvl::VirtualSparseListDiffLevel) = true

function virtual_level_size(lvl::VirtualSparseListDiffLevel, ctx)
    ext = Extent(literal(lvl.Ti(1)), lvl.I)
    (ext, virtual_level_size(lvl.lvl, ctx)...)
end

function virtual_level_resize!(lvl::VirtualSparseListDiffLevel, ctx, dim, dims...)
    lvl.I = getstop(dim)
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseListDiffLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseListDiffLevel) = virtual_level_default(lvl.lvl)

function initialize_level!(fbr::VirtualFiber{VirtualSparseListDiffLevel}, ctx::LowerJulia, mode)
    lvl = fbr.lvl
    Ti = lvl.Ti
    Tp = lvl.Tp
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = length($(lvl.ex).pos)
        $(lvl.pos_fill) = 1
        $(lvl.pos_stop) = 2
        $(lvl.ex).pos[1] = $(Tp(1))
        $(lvl.ex).pos[2] = $(Tp(1))
        $(lvl.idx_alloc) = length($(lvl.ex).idx)
        $(lvl.jdx_alloc) = length($(lvl.ex).jdx)
    end)
    lvl.lvl = initialize_level!(VirtualFiber(fbr.lvl.lvl, Environment(fbr.env)), ctx, mode)
    return lvl
end

function trim_level!(lvl::VirtualSparseListDiffLevel, ctx::LowerJulia, pos)
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) = $(ctx(pos)) + 1
        resize!($(lvl.ex).pos, $(lvl.pos_alloc))
        $(lvl.jdx_alloc) = $(lvl.pos_alloc) - 1
        resize!($(lvl.ex).jdx, $(lvl.jdx_alloc))
        $(lvl.idx_alloc) = $(lvl.ex).pos[$(lvl.pos_alloc)]
        resize!($(lvl.ex).idx, $(lvl.idx_alloc))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, lvl.idx_alloc)
    return lvl
end

interval_assembly_depth(lvl::VirtualSparseListDiffLevel) = Inf

#This function is quite simple, since SparseListDiffLevels don't support reassembly.
function assemble!(fbr::VirtualFiber{VirtualSparseListDiffLevel}, ctx, mode)
    lvl = fbr.lvl
    p_stop = ctx(cache!(ctx, ctx.freshen(lvl.ex, :_p_stop), getstop(envposition(fbr.env))))
    push!(ctx.preamble, quote
        $(lvl.pos_alloc) < ($p_stop + 1) && ($(lvl.pos_alloc) = $Finch.refill!($(lvl.ex).pos, 0, $(lvl.pos_alloc), $p_stop + 1))
        $(lvl.pos_stop) = $p_stop + 1
        $(lvl.jdx_alloc) < $p_stop && ($(lvl.jdx_alloc) = $Finch.refill!($(lvl.ex).jdx, 0, $(lvl.jdx_alloc), $p_stop))
    end)
end

function finalize_level!(fbr::VirtualFiber{VirtualSparseListDiffLevel}, ctx::LowerJulia, mode)
    lvl = fbr.lvl
    my_p = ctx.freshen(:p)
    my_q = ctx.freshen(:q)
    push!(ctx.preamble, quote
        $my_q = $(lvl.ex).pos[$(lvl.pos_fill)]
        for $my_p = $(lvl.pos_fill):$(lvl.pos_stop)
            $(lvl.ex).pos[$(my_p)] = $my_q
        end
        #add a dummy value to the end so we can access out of bounds sometimes.
        $(lvl.idx_alloc) < $my_q && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q))
        $(lvl.ex).idx[$my_q] = 0x00
    end)
    fbr.lvl.lvl = finalize_level!(VirtualFiber(fbr.lvl.lvl, VirtualEnvironment(fbr.env)), ctx, mode)
    return fbr.lvl
end

function unfurl(fbr::VirtualFiber{VirtualSparseListDiffLevel}, ctx, mode, ::Nothing, idx, idxs...)
    if idx.kind === protocol
        @assert idx.mode.kind === literal
        unfurl(fbr, ctx, mode, idx.mode.val, idx.idx, idxs...)
    elseif mode.kind === reader
        unfurl(fbr, ctx, mode, walk, idx, idxs...)
    else
        unfurl(fbr, ctx, mode, extrude, idx, idxs...)
    end
end

function unfurl(fbr::VirtualFiber{VirtualSparseListDiffLevel}, ctx, mode, ::Walk, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    Ti = lvl.Ti
    Tp = lvl.Tp
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)

    body = Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))] - $(Tp(1))
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + $(Tp(1))]
            $my_i = $(lvl.Ti)(0)
            $my_i1 = $(lvl.ex).jdx[$(ctx(envposition(fbr.env)))]
        end,
        body = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> value(my_i1),
                body = (start, step) -> Stepper(
                    seek = (ctx, ext) -> quote
                        while $my_q + $(Tp(1)) < $my_q_stop && $my_i < $(ctx(getstart(ext)))
                            $my_q += $(Tp(1))
                            $my_i += $(lvl.ex).idx[$my_q]
                        end
                    end,
                    body = Step(
                        stride = (ctx, idx, ext) -> value(my_i),
                        chunk = Spike(
                            body = Simplify(Fill(virtual_default(fbr))),
                            tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=value(my_i, lvl.Ti), parent=fbr.env)), ctx, mode),
                        ),
                        next = (ctx, idx, ext) -> quote
                            $my_q += $(Tp(1))
                            $my_i += $(lvl.ex).idx[$my_q] #The last read is garbage
                        end
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(Fill(virtual_default(fbr))))
            )
        ])
    )

    exfurl(body, ctx, mode, idx)
end

#=
function unfurl(fbr::VirtualFiber{VirtualSparseListDiffLevel}, ctx, mode, ::Gallop, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)

    body = Thunk(
        preamble = quote
            $my_q = $(lvl.ex).pos[$(ctx(envposition(fbr.env)))]
            $my_q_stop = $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + 1]
            if $my_q < $my_q_stop
                $my_i = $(lvl.ex).idx[$my_q]
                $my_i1 = $(lvl.ex).idx[$my_q_stop - 1]
            else
                $my_i = 1
                $my_i1 = 0
            end
        end,
        body = Pipeline([
            Phase(
                stride = (ctx, idx, ext) -> value(my_i1),
                body = (start, step) -> Jumper(
                    body = Thunk(
                        body = Jump(
                            seek = (ctx, ext) -> quote
                                while $my_q + 1 < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                                    $my_q += 1
                                end
                                $my_i = $(lvl.ex).idx[$my_q]
                            end,
                            stride = (ctx, ext) -> value(my_i),
                            body = (ctx, ext, ext_2) -> Switch([
                                value(:($(ctx(getstop(ext_2))) == $my_i)) => Thunk(
                                    body = Spike(
                                        body = Simplify(Fill(virtual_default(fbr))),
                                        tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=value(my_i, lvl.Ti), parent=fbr.env)), ctx, mode),
                                    ),
                                    epilogue = quote
                                        $my_q += 1
                                    end
                                ),
                                literal(true) => Stepper(
                                    seek = (ctx, ext) -> quote
                                        while $my_q + 1 < $my_q_stop && $(lvl.ex).idx[$my_q] < $(ctx(getstart(ext)))
                                            $my_q += 1
                                        end
                                    end,
                                    body = Thunk(
                                        preamble = :(
                                            $my_i = $(lvl.ex).idx[$my_q]
                                        ),
                                        body = Step(
                                            stride = (ctx, idx, ext) -> value(my_i),
                                            chunk = Spike(
                                                body = Simplify(Fill(virtual_default(fbr))),
                                                tail = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=value(my_i, lvl.Ti), parent=fbr.env)), ctx, mode),
                                            ),
                                            next = (ctx, idx, ext) -> quote
                                                $my_q += 1
                                            end
                                        )
                                    )
                                ),
                            ])
                        )
                    )
                )
            ),
            Phase(
                body = (start, step) -> Run(Simplify(Fill(virtual_default(fbr))))
            )
        ])
    )

    exfurl(body, ctx, mode, idx)
end
=#

function unfurl(fbr::VirtualFiber{VirtualSparseListDiffLevel}, ctx, mode, ::Extrude, idx, idxs...)
    lvl = fbr.lvl
    tag = lvl.ex
    my_i = ctx.freshen(tag, :_i)
    my_q = ctx.freshen(tag, :_q)
    Ti = lvl.Ti
    Tp = lvl.Tp
    my_q_stop = ctx.freshen(tag, :_q_stop)
    my_i1 = ctx.freshen(tag, :_i1)
    my_guard = if hasdefaultcheck(lvl.lvl)
        ctx.freshen(tag, :_isdefault)
    end

    my_p = ctx.freshen(tag, :_p)


    push!(ctx.preamble, quote
        $my_q = $(lvl.ex).pos[$(lvl.pos_fill)]
        $my_q_stop = $my_q
        for $my_p = $(lvl.pos_fill):$(ctx(envposition(fbr.env)))
            $(lvl.ex).pos[$(my_p)] = $my_q
        end
        $my_i = $(Ti(0))
        $my_i1 = $my_i
    end)

    body = AcceptSpike(
        val = virtual_default(fbr),
        tail = (ctx, idx) -> Thunk(
            preamble = quote
                while $(ctx(idx)) - $my_i > 0xff
                    $(lvl.idx_alloc) < $my_q && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q))
                    $(lvl.ex).idx[$my_q] = 0xff
                    $my_i += 0xff
                    $my_q += $(Tp(1))
                end
                $(begin
                    assemble!(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), parent=fbr.env)), ctx, mode)
                    quote end
                end)
                $(
                    if hasdefaultcheck(lvl.lvl)
                        :($my_guard = true)
                    else
                        quote end
                    end
                )
            end,
            body = refurl(VirtualFiber(lvl.lvl, VirtualEnvironment(position=value(my_q, lvl.Ti), index=idx, guard=my_guard, parent=fbr.env)), ctx, mode),
            epilogue = begin
                #We should be careful here. Presumably, we haven't modified the subfiber because it is still default. Is this always true? Should strict assembly happen every time?
                body = quote
                    $(lvl.idx_alloc) < $my_q && ($(lvl.idx_alloc) = $Finch.regrow!($(lvl.ex).idx, $(lvl.idx_alloc), $my_q))
                    $(lvl.ex).idx[$my_q] = $(ctx(idx)) - $my_i
                    $my_i = $(ctx(idx))
                    $my_i1 = $(ctx(idx))
                    $my_q += $(Tp(1))
                    $my_q_stop = $my_q
                end
                if envdefaultcheck(fbr.env) !== nothing
                    body = quote
                        $body
                        $(envdefaultcheck(fbr.env)) = false
                    end
                end
                if hasdefaultcheck(lvl.lvl)
                    body = quote
                        if !$(my_guard)
                            $body
                        end
                    end
                end
                body
            end
        )
    )

    push!(ctx.epilogue, quote
        $(lvl.ex).pos[$(ctx(envposition(fbr.env))) + $(Tp(1))] = $my_q_stop
        $(lvl.ex).jdx[$(ctx(envposition(fbr.env)))] = $my_i1
        $(lvl.pos_fill) = $(ctx(envposition(fbr.env))) + 1
    end)

    exfurl(body, ctx, mode, idx)
end