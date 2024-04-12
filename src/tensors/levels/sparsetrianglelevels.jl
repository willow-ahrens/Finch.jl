"""
    SparseTriangleLevel{[N], [Ti=Int]}(lvl, [dims])

The sparse triangle level stores the upper triangle of `N` indices in the
subfiber, so fibers in the sublevel are the slices `A[:, ..., :, i_1, ...,
i_n]`, where `i_1 <= ... <= i_n`.  A packed representation is used to encode the
subfiber. Optionally, `dims` are the sizes of the last dimensions.

`Ti` is the type of the last `N` tensor indices.

```jldoctest
julia> Tensor(SparseTriangle{2}(Element(0.0)), [10 0 20; 30 0 0; 0 0 40])
SparseTriangle{2} (0.0) [:,1:3]
├─ [1, 1]: 10.0
├─ [2, 1]: 0.0
├─ [2, 2]: 0.0
├─ [3, 1]: 20.0
├─ [3, 2]: 0.0
└─ [3, 3]: 40.0
```
"""
struct SparseTriangleLevel{N, Ti, Lvl} <: AbstractLevel
    lvl::Lvl
    shape::Ti
    # FUTURE: uplo (upper or lower) - trait 
    # shift/delta
end
SparseTriangleLevel(lvl) = throw(ArgumentError("You must specify the number of dimensions in a SparseTriangleLevel, e.g. Tensor(SparseTriangle{2}(Element(0.0)))"))
SparseTriangleLevel{N}(lvl::Lvl, args...) where {Lvl, N} = SparseTriangleLevel{N, Int}(lvl, args...)
SparseTriangleLevel{N}(lvl, shape, args...) where {N} = SparseTriangleLevel{N, typeof(shape)}(lvl, shape, args...)
SparseTriangleLevel{N, Ti}(lvl, args...) where {N, Ti} = SparseTriangleLevel{N, Ti, typeof(lvl)}(lvl, args...)
SparseTriangleLevel{N, Ti, Lvl}(lvl) where {N, Ti, Lvl} = SparseTriangleLevel{N, Ti, Lvl}(lvl, zero(Ti))

const SparseTriangle = SparseTriangleLevel

Base.summary(lvl::SparseTriangle{N}) where {N} = "SparseTriangle{$N}($(summary(lvl.lvl)))"
similar_level(lvl::SparseTriangle{N}, fill_value, eltype::Type, dims...) where {N} =
    SparseTriangle(similar_level(lvl.lvl, fill_value, eltype, dims[1:end-1]...), dims[end])

function postype(::Type{SparseTriangleLevel{N, Ti, Lvl}}) where {N, Ti, Lvl}
    return postype(Lvl)
end

function moveto(lvl::SparseTriangleLevel{N, Ti}, device) where {N, Ti}
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

labelled_show(io::IO, fbr::SubFiber{<:SparseTriangleLevel{N}}) where {N} =
    print(io, "SparseTriangle{", N, "} (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", size(fbr)[end], "]")

function labelled_children(fbr::SubFiber{<:SparseTriangleLevel{N}}) where {N}
    lvl = fbr.lvl
    pos = fbr.pos
    qos = simplex(fbr.lvl.shape, N) * (pos - 1) + 1
    res = []
    function walk(keys, stop, n)
        if n == 0
            push!(res, LabelledTree(cartesian_label([range_label() for _ = 1:ndims(fbr) - N]..., keys...), SubFiber(lvl.lvl, qos)))
            qos += 1
        else
            for i = 1:stop
                walk((keys..., i), i, n - 1)
            end
        end
    end
    walk((), fbr.lvl.shape, N)
    res
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

postype(lvl::VirtualSparseTriangleLevel) = postype(lvl.lvl)

function virtualize(ctx, ex, ::Type{SparseTriangleLevel{N, Ti, Lvl}}, tag=:lvl) where {N, Ti, Lvl}
    sym = freshen(ctx, tag)
    shape = value(:($sym.shape), Int)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(ctx, :($sym.lvl), Lvl, sym)
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

function virtual_moveto_level(lvl::VirtualSparseTriangleLevel, ctx::AbstractCompiler, arch)
    virtual_moveto_level(lvl.lvl, ctx, arch)
end

function declare_level!(lvl::VirtualSparseTriangleLevel, ctx::AbstractCompiler, pos, init)
    # qos = virtual_simplex(lvl.N, ctx, lvl.shape)
    qos = call(*, pos, virtual_simplex(lvl.N, ctx, lvl.shape))
    lvl.lvl = declare_level!(lvl.lvl, ctx, qos, init)
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

function instantiate(fbr::VirtualSubFiber{VirtualSparseTriangleLevel}, ctx, mode::Reader, protos)
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
        body = (ctx) -> instantiate(SparseTriangleFollowTraversal(lvl, lvl.N, lvl.shape, lvl.N, value(q)), ctx, mode, protos)
    )
end

function instantiate(trv::SparseTriangleFollowTraversal, ctx, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(follow)})
    (lvl, d, j, n, q) = (trv.lvl, trv.d, trv.j, trv.n, trv.q)
    s = freshen(ctx.code, lvl.ex, :_s)
    if d == 1
        Furlable(
            body = (ctx, ext) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> j,
                    body = (ctx, ext) -> Lookup(
                        body = (ctx, i) -> instantiate(VirtualSubFiber(lvl.lvl, call(+, q, -1, i)), ctx, mode, subprotos)
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
                            body = (ctx) -> instantiate(SparseTriangleFollowTraversal(lvl, d - 1, i, n, value(s)), ctx, mode, subprotos)
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

instantiate(fbr::VirtualSubFiber{VirtualSparseTriangleLevel}, ctx, mode::Updater, protos) =
    instantiate(VirtualHollowSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, mode, protos)
function instantiate(fbr::VirtualHollowSubFiber{VirtualSparseTriangleLevel}, ctx, mode::Updater, protos)
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
        body = (ctx) -> instantiate(SparseTriangleLaminateTraversal(lvl, lvl.N, lvl.shape, lvl.N, value(q), fbr.dirty), ctx, mode, protos)
    )
end

function instantiate(trv::SparseTriangleLaminateTraversal, ctx, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(laminate), typeof(extrude)})
    (lvl, d, j, n, q, dirty) = (trv.lvl, trv.d, trv.j, trv.n, trv.q, trv.dirty)
    s = freshen(ctx.code, lvl.ex, :_s)
    if d == 1
        Furlable(
            body = (ctx, ext) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> j,
                    body = (ctx, ext) -> Lookup(
                        body = (ctx, i) -> instantiate(VirtualHollowSubFiber(lvl.lvl, call(+, q, -1, i), dirty), ctx, mode, subprotos)
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
                            body = (ctx) -> instantiate(SparseTriangleLaminateTraversal(lvl, d - 1, i, n, value(s), dirty), ctx, mode, subprotos)
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
