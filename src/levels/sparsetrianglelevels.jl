struct SparseTriangleLevel{N, Ti, Lvl}
    lvl::Lvl
    shape::Ti
    # FUTURE: uplo (upper or lower) - trait 
    # shift/delta
end
SparseTriangleLevel(lvl) = throw(ArgumentError("You must specify the number of dimensions in a SparseTriangleLevel, e.g. @fiber(st{2}(e(0.0)))"))
# SparseTriangleLevel(lvl, shape::Ti, args...) where {Ti} = SparseTriangleLevel{Ti}(lvl, shape, args...)
SparseTriangleLevel{N}(lvl) where {N} = SparseTriangleLevel{N, Int}(lvl)
# SparseTriangleLevel{Ti}(lvl, args...) where {Ti} = SparseTriangleLevel{N, Ti, typeof(lvl)}(lvl, args...)
SparseTriangleLevel{N, Ti}(lvl, args...) where {N, Ti} = SparseTriangleLevel{N, Ti, typeof(lvl)}(lvl, args...)
SparseTriangleLevel{N, Ti, Lvl}(lvl) where {N, Ti, Lvl} = SparseTriangleLevel{N, Ti, Lvl}(lvl, zero(Ti))

const SparseTriangle = SparseTriangleLevel

"""
`f_code(st)` = [SparseTriangleLevel](@ref).
"""
f_code(::Val{:st}) = SparseTriangle
summary_f_code(lvl::SparseTriangle{N}) where {N} = "st{$N}($(summary_f_code(lvl.lvl)))"
similar_level(lvl::SparseTriangle{N}) where {N} = SparseTriangle(similar_level(lvl.lvl))
similar_level(lvl::SparseTriangle{N}, dims...) where {N} = SparseTriangle(similar_level(lvl.lvl, dims[1:end-1]...), dims[end])

pattern!(lvl::SparseTriangleLevel{N, Ti}) where {N, Ti} = 
    SparseTriangleLevel{N, Ti}(pattern!(lvl.lvl), lvl.shape)

@inline level_ndims(::Type{<:SparseTriangleLevel{N, Ti, Lvl}}) where {N, Ti, Lvl} = N + level_ndims(Lvl)
@inline level_size(lvl::SparseTriangleLevel{N}) where {N} = (level_size(lvl.lvl)..., repeat([lvl.shape], N)...) 
@inline level_axes(lvl::SparseTriangleLevel{N}) where {N} = (level_axes(lvl.lvl)..., repeat([Base.OneTo(lvl.shape)], N)...)
@inline level_eltype(::Type{<:SparseTriangleLevel{N, Ti, Lvl}}) where {N, Ti, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseTriangleLevel{N, Ti, Lvl}}) where {N, Ti, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseTriangleLevel{N, Ti, Lvl}}) where {N, Ti, Lvl} = DenseData(data_rep_level(Lvl))

function sparsetrianglesize(shape, n)
    size = 0
    for dim in 1:n
        levelsize = 1 
        for i in 1:dim
            levelsize *= shape + dim - i - 1
        end
        size += fld(levelsize, factorial(dim))
    end
    return size + 1
end

(fbr::AbstractFiber{<:SparseTriangleLevel})() = fbr
function (fbr::SubFiber{<:SparseTriangleLevel{N, Ti}})(idxs...) where {N, Ti}
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    q = (p - 1) * lvl.shape + idxs[end]
    fbr_2 = SubFiber(lvl.lvl, q)
    fbr_2(idxs[1:end-1]...)
end

function Base.show(io::IO, lvl::SparseTriangleLevel{N, Ti}) where {N, Ti}
    if get(io, :compact, false)
        print(io, "SparseTriangle{$N}(")
    else
        print(io, "SparseTriangle{$N, $Ti}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(io, lvl.shape)
    print(io, ")")
end 

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:SparseTriangleLevel{N}}, depth) where {N}
    qos = (fbr.lvl.shape * (fbr.lvl.shape + 1)) >>> 1
    crds = 1:qos

    function print_coord(io, q)
        j = ceil(sqrt(2 * q + 0.25) - 0.5)
        i = q - (j-1) * j / 2
        print(io, i, ", ", j)
    end 

    get_fbr(crd) = fbr(crd)
    print(io, "SparseTriangle [", ":,"^(ndims(fbr) - 1), "1:", qos, "]")
    display_fiber_data(io, mime, fbr, depth, 2, crds, print_coord, get_fbr)
end

mutable struct VirtualSparseTriangleLevel
    lvl
    ex
    N
    Ti
    shape
end
function virtualize(ex, ::Type{SparseTriangleLevel{N, Ti, Lvl}}, ctx, tag=:lvl) where {N, Ti, Lvl}
    sym = ctx.freshen(tag)
    shape = value(:($sym.shape), Int)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseTriangleLevel(lvl_2, sym, N, Ti, shape)
end
function (ctx::Finch.LowerJulia)(lvl::VirtualSparseTriangleLevel)
    quote
        $SparseTriangleLevel{$(lvl.N), $(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
        )
    end
end

summary_f_code(lvl::VirtualSparseTriangleLevel) = "st{$(lvl.N)}($(summary_f_code(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSparseTriangleLevel, ctx)
    ext = map((i) -> Extent(literal(lvl.Ti(1)), lvl.shape), 1:lvl.N)
    (virtual_level_size(lvl.lvl, ctx)..., ext...)
end

function virtual_level_resize!(lvl::VirtualSparseTriangleLevel, ctx, dims...)
    lvl.shape = getstop(dims[end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-lvl.N]...)
    lvl
end

virtual_level_eltype(lvl::VirtualSparseTriangleLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSparseTriangleLevel) = virtual_level_default(lvl.lvl)

function sparsetrianglesize2(shape, n)
    size = 0
    for dim in 1:n
        levelsize = 1 
        for i in 1:dim
            levelsize = call(*, levelsize, call(+, shape, dim - i - 1))
        end
        # size += fld(levelsize, factorial(dim))
        size = call(+, size, call(fld, levelsize, factorial(dim)))
    end
    return call(+, size, 1)
end

function declare_level!(lvl::VirtualSparseTriangleLevel, ctx::LowerJulia, pos, init)
    # qos = call(>>>, call(*, call(*, pos, lvl.shape), call(+, lvl.shape, lvl.Ti(1))), lvl.Ti(1))
    qos = sparsetrianglesize2(lvl.shape, lvl.N)
    lvl.lvl = declare_level!(lvl.lvl, ctx, qos, init)
    return lvl
end

function trim_level!(lvl::VirtualSparseTriangleLevel, ctx::LowerJulia, pos)
    qos = ctx.freshen(:qos)
    size = ctx.freshen(:size)
    dim = ctx.freshen(:dim)
    levelsize = ctx.freshen(:levelsize)
    i = ctx.freshen(:i)

    push!(ctx.preamble, quote
        # $qos = (($(ctx(lvl.shape)) * ($(ctx(lvl.shape)) + $(lvl.Ti(1)))) >>> 0x01)
        # $qos = sparsetrianglesize2($(ctx(lvl.shape)), $(ctx(lvl.N)))
        $size = 0
        for $dim in 1:$(ctx(lvl.N))
            $levelsize = 1 
            for $i in 1:$dim
                $levelsize *= $(ctx(lvl.shape)) + $dim - $i - 1
            end
            $size += fld($levelsize, factorial($dim))
        end
        $qos = $size + 1
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos))
    return lvl
end

function assemble_level!(lvl::VirtualSparseTriangleLevel, ctx, pos_start, pos_stop)
    # qos_start = call(+, call(*, call(-, pos_start, lvl.Ti(1)), lvl.shape), 1)
    # qos_stop = call(>>>, call(*, call(*, pos_stop, lvl.shape), call(+, lvl.shape, lvl.Ti(1))), lvl.Ti(1))
    lvl_size = sparsetrianglesize2(lvl.shape, lvl.N)
    qos_start = call(+, call(*, call(-, pos_start, lvl.Ti(1)), lvl_size), 1)
    qos_stop = call(>>>, call(*, call(*, pos_stop, lvl_size), call(+, lvl_size, lvl.Ti(1))), lvl.Ti(1))
    assemble_level!(lvl.lvl, ctx, qos_start, qos_stop)
end

supports_reassembly(::VirtualSparseTriangleLevel) = true
function reassemble_level!(lvl::VirtualSparseTriangleLevel, ctx, pos_start, pos_stop)
    qos_start = call(+, call(*, call(-, pos_start, lvl.Ti(1)), lvl.shape), 1)
    qos_stop = call(*, pos_stop, lvl.shape)
    reassemble_level!(lvl.lvl, ctx, qos_start, qos_stop)
    lvl
end

function freeze_level!(lvl::VirtualSparseTriangleLevel, ctx::LowerJulia, pos)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, call(*, pos, lvl.shape))
    return lvl
end

is_laminable_updater(lvl::VirtualSparseTriangleLevel, ctx, ::Union{Nothing, Laminate, Extrude}, protos...) =
    is_laminable_updater(lvl.lvl, ctx, protos...)

get_reader(fbr::VirtualSubFiber{VirtualSparseTriangleLevel}, ctx, ::Union{Nothing, Follow}, ::Union{Nothing, Follow}, protos...) = get_reader_triangular_dense_helper(fbr, ctx, get_reader, VirtualSubFiber, protos...)
get_updater(fbr::VirtualSubFiber{VirtualSparseTriangleLevel}, ctx, ::Union{Nothing, Laminate, Extrude}, ::Union{Nothing, Laminate, Extrude}, protos...) = get_updater_triangular_dense_helper(fbr, ctx, get_updater, VirtualSubFiber, protos...)
get_updater(fbr::VirtualTrackedSubFiber{VirtualSparseTriangleLevel}, ctx, ::Union{Nothing, Laminate, Extrude}, ::Union{Nothing, Laminate, Extrude}, protos...) = get_updater_triangular_dense_helper(fbr, ctx, get_updater, (lvl, pos) -> VirtualTrackedSubFiber(lvl, pos, fbr.dirty), protos...)
function get_reader_triangular_dense_helper(fbr, ctx, get_readerupdater, subfiber_ctr, protos...)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti

    q = ctx.freshen(tag, :_q)

    function get_simplex(n, d)
        res = 1 
        for i in 1:d
            res = call(*, call(+, call(-, n, 1), d - i), res)
            # res = call(*, call(+, n, d - i - 1), res)
        end
        return simplify(call(+, call(fld, res, factorial(d)), 1), ctx)
    end
    # d is the dimension we are on 
    # j is coordinate of previous dimension
    # n is the total number of dimension
    # q is index value from previous recursive call
    function simplex_helper(d, j, n, q)
        if d == 1
            Furlable(
                size = virtual_level_size(lvl, ctx)[end - n + 1:end - (n - d)],
                body = (ctx, ext) -> Pipeline([
                    Phase(
                        stride = (ctx, ext) -> j,
                        body = (ctx, ext) -> Lookup(
                            body = (ctx, i) -> get_readerupdater(subfiber_ctr(lvl.lvl, call(+, q, i)), ctx, protos[n-1:end]...) # hack -> fix later
                        )
                    ),
                    Phase(
                        body = (ctx, ext) -> Run(0.0)
                    )
                ])
            )
        else
            Furlable(
                size = virtual_level_size(lvl, ctx)[end - n + 1:end - (n - d)],
                body = (ctx, ext) -> Pipeline([
                    Phase(
                        stride = (ctx, ext) -> j,
                        body = (ctx, ext) -> Lookup(
                            body = (ctx, i) -> simplex_helper(d - 1, i, n, call(+, q, get_simplex(i, d)))
                        )
                    ),
                    Phase(
                        body = (ctx, ext) -> Run(0.0)
                    )
                ])
            )
        end
    end
    simplex_helper(lvl.N, lvl.shape, lvl.N, 0)

    # Furlable(
    #     size = virtual_level_size(lvl, ctx),
    #     body = (ctx, ext) -> Lookup(
    #         body = (ctx, j) -> Thunk(
    #             preamble = quote
    #                 $q = (($(ctx(j)) * ($(ctx(j)) - $(Ti(1)))) >>> 0x01)
    #             end,
    #             body = Furlable(
    #                 size = virtual_level_size(lvl, ctx)[1:end-1],
    #                 body = (ctx, ext) -> Pipeline([
    #                     Phase(
    #                         stride = (ctx, ext) -> j,
    #                         body = (ctx, ext) -> Lookup(
    #                             body = (ctx, i) -> get_readerupdater(subfiber_ctr(lvl.lvl, call(+, value(q, lvl.Ti), i)), ctx, protos...)
    #                         )
    #                     ),
    #                     Phase(
    #                         body = (ctx, ext) -> Run(0.0)
    #                     )
    #                 ])
    #             )
    #         )
    #     )
    # )
end

function get_updater_triangular_dense_helper(fbr, ctx, get_readerupdater, subfiber_ctr, protos...)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti

    q = ctx.freshen(tag, :_q)

    function get_simplex(n, d)
        res = 1 
        for i in 1:d
            res = call(*, call(+, call(-, n, 1), d - i), res)
            # res = call(*, call(+, n, d - i - 1), res)
        end
        return simplify(call(+, call(fld, res, factorial(d)), 1), ctx)
    end

    # d is the dimension we are on 
    # j is coordinate of previous dimension
    # n is the total number of dimension
    # q is index value from previous recursive call
    function simplex_helper(d, j, n, q)
        if d == 1
            Furlable(
                size = virtual_level_size(lvl, ctx)[end - n + 1:end - (n - d)],
                body = (ctx, ext) -> Pipeline([
                    Phase(
                        stride = (ctx, ext) -> j,
                        body = (ctx, ext) -> Lookup(
                            body = (ctx, i) -> get_readerupdater(subfiber_ctr(lvl.lvl, call(+, q, i)), ctx, protos[n-1:end]...) # hack -> fix later
                        )
                    ),
                    Phase(
                        body = (ctx, ext) -> Null()
                    )
                ])
            )
        else
            Furlable(
                size = virtual_level_size(lvl, ctx)[end - n + 1:end - (n - d)],
                body = (ctx, ext) -> Pipeline([
                    Phase(
                        stride = (ctx, ext) -> j,
                        body = (ctx, ext) -> Lookup(
                            body = (ctx, i) -> simplex_helper(d - 1, i, n, call(+, q, get_simplex(i, d)))
                        )
                    ),
                    Phase(
                        body = (ctx, ext) -> Null()
                    )
                ])
            )
        end
    end
    simplex_helper(lvl.N, lvl.shape, lvl.N, 0)

    # Furlable(
    #     size = virtual_level_size(lvl, ctx),
    #     body = (ctx, ext) -> Lookup(
    #         body = (ctx, j) -> Thunk(
    #             preamble = quote
    #                 $q = (($(ctx(j)) * ($(ctx(j)) - $(Ti(1)))) >>> 0x01)
    #             end,
    #             body = Furlable(
    #                 size = virtual_level_size(lvl, ctx)[1:end-1],
    #                 body = (ctx, ext) -> Pipeline([
    #                     Phase(
    #                         stride = (ctx, ext) -> j,
    #                         body = (ctx, ext) -> Lookup(
    #                             body = (ctx, i) -> get_readerupdater(subfiber_ctr(lvl.lvl, call(+, value(q, lvl.Ti), i)), ctx, protos...)
    #                         )
    #                     ),
    #                     Phase(
    #                         body = (ctx, ext) -> Null()
    #                     )
    #                 ])
    #             )
    #         )
    #     )
    # )
end