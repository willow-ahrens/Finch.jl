"""
    SparseTriangleLevel{[N], [Ti=Int]}(lvl, [dims])

The sparse triangle level stores the upper triangle of `N` indices in the
subfiber, so fibers in the sublevel are the slices `A[:, ..., :, i_1, ...,
i_n]`, where `i_1 <= ... <= i_n`.  A packed representation is used to encode the
subfiber. Optionally, `dims` are the sizes of the last dimensions.

`Ti` is the type of the last `N` fiber indices.

```jldoctest
julia> Fiber!(SparseTriangle{2}(Element(0.0)), [10 0 20; 30 0 0; 0 0 40])
SparseTriangle (0.0) [1:3]
├─├─[1, 1]: 10.0
├─├─[1, 2]: 0.0
│ ⋮
├─├─[2, 3]: 0.0
├─├─[3, 3]: 40.0
```
"""
struct SparseTriangleLevel{N, Ti, Lvl}
    lvl::Lvl
    shape::Ti
    # FUTURE: uplo (upper or lower) - trait 
    # shift/delta
end
SparseTriangleLevel(lvl) = throw(ArgumentError("You must specify the number of dimensions in a SparseTriangleLevel, e.g. Fiber!(SparseTriangle{2}(Element(0.0)))"))
SparseTriangleLevel{N}(lvl::Lvl, args...) where {Lvl, N} = SparseTriangleLevel{N, Int}(lvl, args...)
SparseTriangleLevel{N}(lvl, shape, args...) where {N} = SparseTriangleLevel{N, typeof(shape)}(lvl, shape, args...)
SparseTriangleLevel{N, Ti}(lvl, args...) where {N, Ti} = SparseTriangleLevel{N, Ti, typeof(lvl)}(lvl, args...)
SparseTriangleLevel{N, Ti, Lvl}(lvl) where {N, Ti, Lvl} = SparseTriangleLevel{N, Ti, Lvl}(lvl, zero(Ti))

const SparseTriangle = SparseTriangleLevel

Base.summary(lvl::SparseTriangle{N}) where {N} = "SparseTriangle{$N}($(summary(lvl.lvl)))"
similar_level(lvl::SparseTriangle{N}) where {N} = SparseTriangle(similar_level(lvl.lvl))
similar_level(lvl::SparseTriangle{N}, dims...) where {N} = SparseTriangle(similar_level(lvl.lvl, dims[1:end-1]...), dims[end])

function postype(::Type{SparseTriangleLevel{N, Ti, Lvl}}) where {N, Ti, Lvl}
    return postype(Lvl)
end

function moveto(lvl::SparseTriangleLevel{N, Ti, Lvl}, device) where {N, Ti, Lvl, MemType <: AbstractArray}
    lvl_2 = moveto(lvl.lvl, device)
    return SparseTriangleLevel{N, Ti}(lvl_2, lvl.shape)
end

pattern!(lvl::SparseTriangleLevel{N, Ti}) where {N, Ti} = 
    SparseTriangleLevel{N, Ti}(pattern!(lvl.lvl), lvl.shape)

@inline level_ndims(::Type{<:SparseTriangleLevel{N, Ti, Lvl}}) where {N, Ti, Lvl} = N + level_ndims(Lvl)
@inline level_size(lvl::SparseTriangleLevel{N}) where {N} = (level_size(lvl.lvl)..., repeat([lvl.shape], N)...) 
@inline level_axes(lvl::SparseTriangleLevel{N}) where {N} = (level_axes(lvl.lvl)..., repeat([Base.OneTo(lvl.shape)], N)...)
@inline level_eltype(::Type{<:SparseTriangleLevel{N, Ti, Lvl}}) where {N, Ti, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SparseTriangleLevel{N, Ti, Lvl}}) where {N, Ti, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:SparseTriangleLevel{N, Ti, Lvl}}) where {N, Ti, Lvl} = (SparseData^N)(data_rep_level(Lvl))

simplex(shape, n) = fld(prod(shape .+ n .- (1:n)), factorial(n))

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
    qos = simplex(fbr.lvl.shape, N)
    crds = 1:qos

    #when n = 3, this is the qth element of [(i, j, k) for k = 1:3 for j = 1:k for i = 1:j]
    function get_coord(q, n, k)
        if n == 1
            return (q,)
        else
            j = findfirst(j -> simplex(j, n) >= q, 1:k)
            return (get_coord(q - simplex(j - 1, n), n - 1, j)..., j)
        end
    end

    print_coord(io, q) = join(io, get_coord(q, N, fbr.lvl.shape), ", ")
    get_fbr(crd) = fbr(crd)
    print(io, "SparseTriangle (", default(fbr), ") [", ":,"^(ndims(fbr) - N), "1:")
    join(io, fbr.lvl.shape, ",1:") 
    print(io, "]")
    display_fiber_data(io, mime, fbr, depth, N, crds, print_coord, get_fbr)
end

mutable struct VirtualSparseTriangleLevel <: AbstractVirtualLevel
    lvl
    ex
    N
    Ti
    shape
end

is_level_injective(lvl::VirtualSparseTriangleLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., (true for _ in 1:lvl.N)...]
is_level_atomic(lvl::VirtualSparseTriangleLevel, ctx) = is_level_atomic(lvl.lvl, ctx)

memtype(lvl::VirtualSparseTriangleLevel) = memtype(lvl.lvl)
postype(lvl::VirtualSparseTriangleLevel) = postype(lvl.lvl)

function virtualize(ex, ::Type{SparseTriangleLevel{N, Ti, Lvl}}, ctx, tag=:lvl) where {N, Ti, Lvl}
    sym = freshen(ctx, tag)
    shape = value(:($sym.shape), Int)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualSparseTriangleLevel(lvl_2, sym, N, Ti, shape)
end
function lower(lvl::VirtualSparseTriangleLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SparseTriangleLevel{$(lvl.N), $(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
        )
    end
end

Base.summary(lvl::VirtualSparseTriangleLevel) = "SparseTriangle$(lvl.N)}($(summary(lvl.lvl)))"

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

function declare_level!(lvl::VirtualSparseTriangleLevel, ctx::AbstractCompiler, pos, init)
    # qos = virtual_simplex(lvl.N, ctx, lvl.shape)
    qos = call(*, pos, virtual_simplex(lvl.N, ctx, lvl.shape))
    lvl.lvl = declare_level!(lvl.lvl, ctx, qos, init)
    return lvl
end

function trim_level!(lvl::VirtualSparseTriangleLevel, ctx::AbstractCompiler, pos)
    qos = call(*, pos, virtual_simplex(lvl.N, ctx, lvl.shape))
    lvl.lvl = trim_level!(lvl.lvl, ctx, qos)
    return lvl
end

function assemble_level!(lvl::VirtualSparseTriangleLevel, ctx, pos_start, pos_stop)
    fbr_count = virtual_simplex(lvl.N, ctx, lvl.shape)
    qos_start = call(+, call(*, call(-, pos_start, lvl.Ti(1)), fbr_count), 1)
    qos_stop = call(*, pos_stop, fbr_count)
    qos_stop = call(*, pos_stop, fbr_count)
    assemble_level!(lvl.lvl, ctx, qos_start, qos_stop)
end

supports_reassembly(::VirtualSparseTriangleLevel) = true
function reassemble_level!(lvl::VirtualSparseTriangleLevel, ctx, pos_start, pos_stop)
    fbr_count = virtual_simplex(lvl.N, ctx, lvl.shape)
    qos_start = call(+, call(*, call(-, pos_start, lvl.Ti(1)), fbr_count), 1)
    qos_stop = call(*, pos_stop, fbr_count)
    reassemble_level!(lvl.lvl, ctx, qos_start, qos_stop)
    lvl
end

function freeze_level!(lvl::VirtualSparseTriangleLevel, ctx::AbstractCompiler, pos)
    qos = call(*, pos, virtual_simplex(lvl.N, ctx, lvl.shape))
    lvl.lvl = freeze_level!(lvl.lvl, ctx, qos)
    return lvl
end

function virtual_simplex(d, ctx, n)
    res = 1 
    for i in 1:d
        res = call(*, call(+, n, d - i), res)
    end
    return simplify(call(fld, res, factorial(d)), ctx)
end

struct SparseTriangleFollowTraversal
    lvl
    d
    j
    n
    q
end

function instantiate_reader(fbr::VirtualSubFiber{VirtualSparseTriangleLevel}, ctx, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti

    q = freshen(ctx.code, tag, :_q)

    # d is the dimension we are on 
    # j is coordinate of previous dimension
    # n is the total number of dimensions
    # q is index value from previous recursive call
    fbr_count = virtual_simplex(lvl.N, ctx, lvl.shape)
    Thunk(
        preamble = quote
            $q = $(ctx(call(+, call(*, call(-, pos, lvl.Ti(1)), fbr_count), 1)))
        end,
        body = (ctx) -> instantiate_reader(SparseTriangleFollowTraversal(lvl, lvl.N, lvl.shape, lvl.N, value(q)), ctx, protos)
    )
end

function instantiate_reader(trv::SparseTriangleFollowTraversal, ctx, subprotos, ::Union{typeof(defaultread), typeof(follow)})
    (lvl, d, j, n, q) = (trv.lvl, trv.d, trv.j, trv.n, trv.q)
    s = freshen(ctx.code, lvl.ex, :_s)
    if d == 1
        Furlable(
            body = (ctx, ext) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> j,
                    body = (ctx, ext) -> Lookup(
                        body = (ctx, i) -> instantiate_reader(VirtualSubFiber(lvl.lvl, call(+, q, -1, i)), ctx, subprotos)
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    else
        Furlable(
            body = (ctx, ext) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> j,
                    body = (ctx, ext) -> Lookup(
                        body = (ctx, i) -> Thunk(
                            preamble = :(
                                $s = $(ctx(call(+, q, virtual_simplex(d, ctx, call(-, i, 1)))))
                            ),
                            body = (ctx) -> instantiate_reader(SparseTriangleFollowTraversal(lvl, d - 1, i, n, value(s)), ctx, subprotos)
                        )
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    end
end

struct SparseTriangleLaminateTraversal
    lvl
    d
    j
    n
    q
    dirty
end

instantiate_updater(fbr::VirtualSubFiber{VirtualSparseTriangleLevel}, ctx, protos) =
    instantiate_updater(VirtualTrackedSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, protos)
function instantiate_updater(fbr::VirtualTrackedSubFiber{VirtualSparseTriangleLevel}, ctx, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti

    q = freshen(ctx.code, tag, :_q)

    # d is the dimension we are on 
    # j is coordinate of previous dimension
    # n is the total number of dimensions
    # q is index value from previous recursive call
    fbr_count = virtual_simplex(lvl.N, ctx, lvl.shape)
    Thunk(
        preamble = quote
            $q = $(ctx(call(+, call(*, call(-, pos, lvl.Ti(1)), fbr_count), 1)))
        end,
        body = (ctx) -> instantiate_updater(SparseTriangleLaminateTraversal(lvl, lvl.N, lvl.shape, lvl.N, value(q), fbr.dirty), ctx, protos)
    )
end

function instantiate_updater(trv::SparseTriangleLaminateTraversal, ctx, subprotos, ::Union{typeof(defaultupdate), typeof(laminate), typeof(extrude)})
    (lvl, d, j, n, q, dirty) = (trv.lvl, trv.d, trv.j, trv.n, trv.q, trv.dirty)
    s = freshen(ctx.code, lvl.ex, :_s)
    if d == 1
        Furlable(
            body = (ctx, ext) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> j,
                    body = (ctx, ext) -> Lookup(
                        body = (ctx, i) -> instantiate_updater(VirtualTrackedSubFiber(lvl.lvl, call(+, q, -1, i), dirty), ctx, subprotos)
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Fill(Null())
                )
            ])
        )
    else
        Furlable(
            body = (ctx, ext) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> j,
                    body = (ctx, ext) -> Lookup(
                        body = (ctx, i) -> Thunk(
                            preamble = :(
                                $s = $(ctx(call(+, q, virtual_simplex(d, ctx, call(-, i, 1)))))
                            ),
                            body = (ctx) -> instantiate_updater(SparseTriangleLaminateTraversal(lvl, d - 1, i, n, value(s), dirty), ctx, subprotos)
                        )
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Fill(Null())
                )
            ])
        )
    end
end
