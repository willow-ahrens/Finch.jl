struct DenseLevel{Ti, Lvl}
    I::Ti
    lvl::Lvl
end
DenseLevel{Ti}(I, lvl::Lvl) where {Ti, Lvl} = DenseLevel{Ti, Lvl}(I, lvl)
DenseLevel{Ti}(lvl::Lvl) where {Ti, Lvl} = DenseLevel{Ti, Lvl}(zero(Ti), lvl)
DenseLevel(lvl) = DenseLevel(0, lvl)
const Dense = DenseLevel

"""
`f_code(d)` = [DenseLevel](@ref).
"""
f_code(::Val{:d}) = Dense
summary_f_code(lvl::Dense) = "d($(summary_f_code(lvl.lvl)))"
similar_level(lvl::DenseLevel) = Dense(similar_level(lvl.lvl))
similar_level(lvl::DenseLevel, dim, tail...) = Dense(dim, similar_level(lvl.lvl, tail...))

pattern!(lvl::DenseLevel{Ti}) where {Ti} = 
    DenseLevel{Ti}(lvl.I, pattern!(lvl.lvl))

@inline level_ndims(::Type{<:DenseLevel{Ti, Lvl}}) where {Ti, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::DenseLevel) = (lvl.I, level_size(lvl.lvl)...)
@inline level_axes(lvl::DenseLevel) = (Base.OneTo(lvl.I), level_axes(lvl.lvl)...)
@inline level_eltype(::Type{<:DenseLevel{Ti, Lvl}}) where {Ti, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:DenseLevel{Ti, Lvl}}) where {Ti, Lvl} = level_default(Lvl)

(fbr::Fiber{<:DenseLevel})() = fbr
function (fbr::Fiber{<:DenseLevel{Ti}})(i, tail...) where {Ti}
    lvl = fbr.lvl
    p = envposition(fbr.env)
    q = (p - 1) * lvl.I + i
    fbr_2 = Fiber(lvl.lvl, Environment(position=q, index=i, parent=fbr.env))
    fbr_2(tail...)
end

function Base.show(io::IO, lvl::DenseLevel{Ti}) where {Ti}
    if get(io, :compact, false)
        print(io, "Dense(")
    else
        print(io, "Dense{$Ti}(")
    end
    show(io, lvl.I)
    print(io, ", ")
    show(io, lvl.lvl)
    print(io, ")")
end 

function display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber{<:DenseLevel})
    crds = 1:fbr.lvl.I
    depth = envdepth(fbr.env)

    print_coord(io, crd) = (print(io, "["); show(io, crd); print(io, "]"))
    get_fbr(crd) = fbr(crd)
    print(io, "│ " ^ depth); print(io, "Dense ["); show(io, 1); print(io, ":"); show(io, fbr.lvl.I); println(io, "]")
    display_fiber_data(io, mime, fbr, 1, crds, print_coord, get_fbr)
end


mutable struct VirtualDenseLevel
    ex
    Ti
    I
    lvl
end
function virtualize(ex, ::Type{DenseLevel{Ti, Lvl}}, ctx, tag=:lvl) where {Ti, Lvl}
    sym = ctx.freshen(tag)
    I = value(:($sym.I), Int)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualDenseLevel(sym, Ti, I, lvl_2)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualDenseLevel)
    quote
        $DenseLevel{$(lvl.Ti)}(
            $(ctx(lvl.I)),
            $(ctx(lvl.lvl)),
        )
    end
end

summary_f_code(lvl::VirtualDenseLevel) = "d($(summary_f_code(lvl.lvl)))"

function virtual_level_size(lvl::VirtualDenseLevel, ctx)
    ext = Extent(literal(lvl.Ti(1)), lvl.I)
    (ext, virtual_level_size(lvl.lvl, ctx)...)
end

function virtual_level_resize!(lvl::VirtualDenseLevel, ctx, dim, dims...)
    lvl.I = getstop(dim)
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims...)
    lvl
end

virtual_level_eltype(lvl::VirtualDenseLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualDenseLevel) = virtual_level_default(lvl.lvl)

function initialize_level!(lvl::VirtualDenseLevel, ctx::LowerJulia, pos)
    lvl.lvl = initialize_level!(lvl.lvl, ctx, call(*, pos, lvl.I))
    return lvl
end

function trim_level!(lvl::VirtualDenseLevel, ctx::LowerJulia, pos)
    qos = ctx.freshen(:qos)
    push!(ctx.preamble, quote
        $qos = $(ctx(pos)) * $(ctx(lvl.I))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos))
    return lvl
end

function assemble_level!(lvl::VirtualDenseLevel, ctx, pos_start, pos_stop)
    qos_start = call(+, call(*, call(-, pos_start, lvl.Ti(1)), lvl.I), 1)
    qos_stop = call(*, pos_stop, lvl.I)
    assemble_level!(lvl.lvl, ctx, qos_start, qos_stop)
end

supports_reassembly(::VirtualDenseLevel) = true
function reassemble_level!(lvl::VirtualDenseLevel, ctx, pos_start, pos_stop)
qos_start = call(+, call(*, call(-, pos_start, lvl.Ti(1)), lvl.I), 1)
qos_stop = call(*, pos_stop, lvl.I)
reassemble_level!(lvl.lvl, ctx, qos_start, qos_stop)
lvl
end

function freeze_level!(lvl::VirtualDenseLevel, ctx::LowerJulia, pos)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, call(*, pos, lvl.I))
    return lvl
end
set_clean!(lvl::VirtualDenseLevel, ctx) = set_clean!(lvl.lvl, ctx)
get_dirty(lvl::VirtualDenseLevel, ctx) = get_dirty(lvl.lvl, ctx)


get_level_reader(lvl::VirtualDenseLevel, ctx, p, ::Union{Nothing, Follow}, protos...) = get_dense_level_nest(lvl, ctx, p, get_level_reader, protos...)
get_level_updater(lvl::VirtualDenseLevel, ctx, p, ::Union{Nothing, Laminate, Extrude}, protos...) = get_dense_level_nest(lvl, ctx, p, get_level_updater, protos...)
function get_dense_level_nest(lvl, ctx, p, get_sublevel_nest, protos...)
    tag = lvl.ex
    Ti = lvl.Ti

    q = ctx.freshen(tag, :_q)

    Furlable(
        val = virtual_level_default(lvl),
        size = virtual_level_size(lvl, ctx),
        body = (ctx, idx, ext) -> Lookup(
            val = virtual_level_default(lvl),
            body = (i) -> Thunk(
                preamble = quote
                    $q = ($(ctx(p)) - $(Ti(1))) * $(ctx(lvl.I)) + $(ctx(i))
                end,
                body = get_sublevel_nest(lvl.lvl, ctx, value(q, lvl.Ti), protos...)
            )
        )
    )
end