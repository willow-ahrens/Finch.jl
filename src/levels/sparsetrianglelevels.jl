struct SparseTriangleLevel{Ti, Lvl}
    lvl::Lvl
    I::Ti
    J::Ti
    # FUTURE: uplo (upper or lower) - trait 
    # shift/delta
end
SparseTriangleLevel(lvl) = SparseTriangleLevel{Int}(lvl)
SparseTriangleLevel(lvl, I::Ti, J::Ti, args...) where {Ti} = SparseTriangleLevel{Ti}(lvl, I, J, args...)
SparseTriangleLevel{Ti}(lvl, args...) where {Ti} = SparseTriangleLevel{Ti, typeof(lvl)}(lvl, args...)

SparseTriangleLevel{Ti, Lvl}(lvl) where {Ti, Lvl} = SparseTriangleLevel{Ti, Lvl}(lvl, zero(Ti), zero(Ti))

const SparseTriangle = SparseTriangleLevel

"""
`f_code(st)` = [SparseTriangleLevel](@ref).
"""
f_code(::Val{:st}) = SparseTriangle
summary_f_code(lvl::SparseTriangle) = "st($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SparseTriangle) = SparseTriangle(similar_level(lvl.lvl))
similar_level(lvl::SparseTriangle, dims...) = SparseTriangle(similar_level(lvl.lvl, dims[1:end-1]...), dims[end])

pattern!(lvl::SparseTriangleLevel{Ti}) where {Ti} = 
    SparseTriangleLevel{Ti}(pattern!(lvl.lvl), lvl.I, lvl.J)

@inline level_ndims(::Type{<:SparseTriangleLevel{Ti, Lvl}}) where {Ti, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SparseTriangleLevel) = (level_size(lvl.lvl)..., lvl.J * (lvl.J + 1)/2) 
@inline level_axes(lvl::SparseTriangleLevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.I))
@inline level_eltype(::Type{<:SparseTriangleLevel{Ti, Lvl}}) where {Ti, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseTriangleLevel{Ti, Lvl}}) where {Ti, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseTriangleLevel{Ti, Lvl}}) where {Ti, Lvl} = DenseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SparseTriangleLevel})() = fbr
function (fbr::SubFiber{<:SparseTriangleLevel{Ti}})(idxs...) where {Ti}
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    q = (p - 1) * lvl.I + idxs[end]
    fbr_2 = SubFiber(lvl.lvl, q)
    fbr_2(idxs[1:end-1]...)
end

function Base.show(io::IO, lvl::SparseTriangleLevel{Ti}) where {Ti}
    if get(io, :compact, false)
        print(io, "SparseTriangle(")
    else
        print(io, "SparseTriangle{$Ti}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(io, lvl.I)
    print(io, ")")
end 

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:SparseTriangleLevel}, depth)
    crds = 1:fbr.lvl.I

    get_fbr(crd) = fbr(crd)
    print(io, "SparseTriangle [", ":,"^(ndims(fbr) - 1), "1:", fbr.lvl.I, "]")
    display_fiber_data(io, mime, fbr, depth, 1, crds, show, get_fbr)
end

mutable struct VirtualSparseTriangleLevel
    lvl
    ex
    Ti
    I
    J
end
function virtualize(ex, ::Type{SparseTriangleLevel{Ti, Lvl}}, ctx, tag=:lvl) where {Ti, Lvl}
    sym = ctx.freshen(tag)
    I = value(:($sym.I), Int)
    J = value(:($sym.J), Int)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseTriangleLevel(lvl_2, sym, Ti, I, J)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSparseTriangleLevel)
    quote
        $SparseTriangleLevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.I)),
            $(ctx(lvl.J)),
        )
    end
end

summary_f_code(lvl::VirtualSparseTriangleLevel) = "st($(summary_f_code(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseTriangleLevel, ctx)
    ext_1 = Extent(literal(lvl.Ti(1)), lvl.I)
    ext_2 = Extent(literal(lvl.Ti(1)), lvl.J)
    (virtual_level_size(lvl.lvl, ctx)..., ext_1, ext_2)
end

function virtual_level_resize!(lvl::VirtualSparseTriangleLevel, ctx, dims...)
    lvl.I = getstop(dims[end])
    lvl.J = getstop(dims[end - 1])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-2]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseTriangleLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseTriangleLevel) = virtual_level_default(lvl.lvl)

function initialize_level!(lvl::VirtualSparseTriangleLevel, ctx::LowerJulia, pos)
    lvl.lvl = initialize_level!(lvl.lvl, ctx, call(*, pos, lvl.I))
    return lvl
end

function trim_level!(lvl::VirtualSparseTriangleLevel, ctx::LowerJulia, pos)
    qos = ctx.freshen(:qos)
    push!(ctx.preamble, quote
        $qos = $(ctx(pos)) * $(ctx(lvl.I))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos))
    return lvl
end

function assemble_level!(lvl::VirtualSparseTriangleLevel, ctx, pos_start, pos_stop)
    qos_start = call(+, call(*, call(-, pos_start, lvl.Ti(1)), lvl.I), 1)
    qos_stop = call(*, pos_stop, lvl.I)
    assemble_level!(lvl.lvl, ctx, qos_start, qos_stop)
end

supports_reassembly(::VirtualSparseTriangleLevel) = true
function reassemble_level!(lvl::VirtualSparseTriangleLevel, ctx, pos_start, pos_stop)
    qos_start = call(+, call(*, call(-, pos_start, lvl.Ti(1)), lvl.I), 1)
    qos_stop = call(*, pos_stop, lvl.I)
    reassemble_level!(lvl.lvl, ctx, qos_start, qos_stop)
    lvl
end

function freeze_level!(lvl::VirtualSparseTriangleLevel, ctx::LowerJulia, pos)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, call(*, pos, lvl.I))
    return lvl
end

is_laminable_updater(lvl::VirtualSparseTriangleLevel, ctx, ::Union{Nothing, Laminate, Extrude}, protos...) =
    is_laminable_updater(lvl.lvl, ctx, protos...)

get_reader(fbr::VirtualSubFiber{VirtualSparseTriangleLevel}, ctx, ::Union{Nothing, Follow}, ::Union{Nothing, Follow}, protos...) = get_readerupdater_triangular_dense_helper(fbr, ctx, get_reader, VirtualSubFiber, protos...)
get_updater(fbr::VirtualSubFiber{VirtualSparseTriangleLevel}, ctx, ::Union{Nothing, Laminate, Extrude}, protos...) = get_readerupdater_triangular_dense_helper(fbr, ctx, get_updater, VirtualSubFiber, protos...)
get_updater(fbr::VirtualTrackedSubFiber{VirtualSparseTriangleLevel}, ctx, ::Union{Nothing, Laminate, Extrude}, protos...) = get_readerupdater_triangular_dense_helper(fbr, ctx, get_updater, (lvl, pos) -> VirtualTrackedSubFiber(lvl, pos, fbr.dirty), protos...)
function get_readerupdater_triangular_dense_helper(fbr, ctx, get_readerupdater, subfiber_ctr, protos...)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti


    q = ctx.freshen(tag, :_q)


    Furlable(
        val = virtual_level_default(lvl),
        size = virtual_level_size(lvl, ctx),
        body = (ctx, idx, ext) -> Lookup(
            val = virtual_level_default(lvl),
            body = (j) -> Thunk(
                preamble = quote
                    $q = (($(ctx(j)) * ($(ctx(j)) - $(Ti(1)))) >>> 0x01)
                end,
                body = Furlable(
                    val = virtual_level_default(lvl),
                    size = virtual_level_size(lvl, ctx)[1:end-1],
                    body = (ctx, idx, ext) -> Pipeline([
                        Phase(
                            stride = (ctx, idx, ext) -> j,
                            body = (start, step) -> Lookup(
                                val = virtual_level_default(lvl),
                                body = (i) -> get_readerupdater(subfiber_ctr(lvl.lvl, call(+, value(q, lvl.Ti), i)), ctx, protos...)
                            )
                        ),
                        Phase(
                            body = (start, step) -> Run(0)
                        )
                    ])
                )
            )
        )
    )
end