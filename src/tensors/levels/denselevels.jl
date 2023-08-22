"""
    DenseLevel{[Ti=Int]}(lvl, [dim])

A subfiber of a dense level is an array which stores every slice `A[:, ..., :,
i]` as a distinct subfiber in `lvl`. Optionally, `dim` is the size of the last
dimension. `Ti` is the type of the indices used to index the level.

In the [`Fiber!`](@ref) constructor, `d` is an alias for `DenseLevel`.

```jldoctest
julia> ndims(Fiber!(Dense(Element(0.0))))
1

julia> ndims(Fiber!(Dense(Dense(Element(0.0)))))
2

julia> Fiber!(Dense(Dense(Element(0.0))), [1 2; 3 4])
Dense [:,1:2]
├─[:,1]: Dense [1:2]
│ ├─[1]: 1.0
│ ├─[2]: 3.0
├─[:,2]: Dense [1:2]
│ ├─[1]: 2.0
│ ├─[2]: 4.0
```
"""
struct DenseLevel{Ti, Lvl}
    lvl::Lvl
    shape::Ti
end
DenseLevel(lvl) = DenseLevel{Int}(lvl)
DenseLevel(lvl, shape::Ti, args...) where {Ti} = DenseLevel{Ti}(lvl, shape, args...)
DenseLevel{Ti}(lvl, args...) where {Ti} = DenseLevel{Ti, typeof(lvl)}(lvl, args...)

DenseLevel{Ti, Lvl}(lvl) where {Ti, Lvl} = DenseLevel{Ti, Lvl}(lvl, zero(Ti))

const Dense = DenseLevel

Base.summary(lvl::Dense) = "Dense($(summary(lvl.lvl)))"
similar_level(lvl::DenseLevel) = Dense(similar_level(lvl.lvl))
similar_level(lvl::DenseLevel, dims...) = Dense(similar_level(lvl.lvl, dims[1:end-1]...), dims[end])

pattern!(lvl::DenseLevel{Ti}) where {Ti} = 
    DenseLevel{Ti}(pattern!(lvl.lvl), lvl.shape)

redefault!(lvl::DenseLevel{Ti}, init) where {Ti} = 
    DenseLevel{Ti}(redefault!(lvl.lvl, init), lvl.shape)

@inline level_ndims(::Type{<:DenseLevel{Ti, Lvl}}) where {Ti, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::DenseLevel) = (level_size(lvl.lvl)..., lvl.shape)
@inline level_axes(lvl::DenseLevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.shape))
@inline level_eltype(::Type{<:DenseLevel{Ti, Lvl}}) where {Ti, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:DenseLevel{Ti, Lvl}}) where {Ti, Lvl} = level_default(Lvl)
data_rep_level(::Type{<:DenseLevel{Ti, Lvl}}) where {Ti, Lvl} = DenseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:DenseLevel})() = fbr
function (fbr::SubFiber{<:DenseLevel{Ti}})(idxs...) where {Ti}
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    q = (p - 1) * lvl.shape + idxs[end]
    fbr_2 = SubFiber(lvl.lvl, q)
    fbr_2(idxs[1:end-1]...)
end

function countstored_level(lvl::DenseLevel, pos)
    countstored_level(lvl.lvl, pos * lvl.shape)
end

function Base.show(io::IO, lvl::DenseLevel{Ti}) where {Ti}
    if get(io, :compact, false)
        print(io, "Dense(")
    else
        print(io, "Dense{$Ti}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(io, lvl.shape)
    print(io, ")")
end 

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:DenseLevel}, depth)
    crds = 1:fbr.lvl.shape

    get_fbr(crd) = fbr(crd)
    print(io, "Dense [", ":,"^(ndims(fbr) - 1), "1:", fbr.lvl.shape, "]")
    display_fiber_data(io, mime, fbr, depth, 1, crds, show, get_fbr)
end

mutable struct VirtualDenseLevel
    lvl
    ex
    Ti
    shape
end
function virtualize(ex, ::Type{DenseLevel{Ti, Lvl}}, ctx, tag=:lvl) where {Ti, Lvl}
    sym = ctx.code.freshen(tag)
    shape = value(:($sym.shape), Ti)
    push!(ctx.code.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    VirtualDenseLevel(lvl_2, sym, Ti, shape)
end
function lower(lvl::VirtualDenseLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $DenseLevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
        )
    end
end

Base.summary(lvl::VirtualDenseLevel) = "Dense($(summary(lvl.lvl)))"

function virtual_level_size(lvl::VirtualDenseLevel, ctx)
    ext = Extent(literal(lvl.Ti(1)), lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext)
end

function virtual_level_resize!(lvl::VirtualDenseLevel, ctx, dims...)
    lvl.shape = getstop(dims[end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-1]...)
    lvl
end

virtual_level_eltype(lvl::VirtualDenseLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualDenseLevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualDenseLevel, ctx::AbstractCompiler, pos, init)
    lvl.lvl = declare_level!(lvl.lvl, ctx, call(*, pos, lvl.shape), init)
    return lvl
end

function trim_level!(lvl::VirtualDenseLevel, ctx::AbstractCompiler, pos)
    qos = ctx.code.freshen(:qos)
    push!(ctx.code.preamble, quote
        $qos = $(ctx(pos)) * $(ctx(lvl.shape))
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos))
    return lvl
end

function assemble_level!(lvl::VirtualDenseLevel, ctx, pos_start, pos_stop)
    qos_start = call(+, call(*, call(-, pos_start, lvl.Ti(1)), lvl.shape), 1)
    qos_stop = call(*, pos_stop, lvl.shape)
    assemble_level!(lvl.lvl, ctx, qos_start, qos_stop)
end

supports_reassembly(::VirtualDenseLevel) = true
function reassemble_level!(lvl::VirtualDenseLevel, ctx, pos_start, pos_stop)
    qos_start = call(+, call(*, call(-, pos_start, lvl.Ti(1)), lvl.shape), 1)
    qos_stop = call(*, pos_stop, lvl.shape)
    reassemble_level!(lvl.lvl, ctx, qos_start, qos_stop)
    lvl
end

function thaw_level!(lvl::VirtualDenseLevel, ctx::AbstractCompiler, pos)
    lvl.lvl = thaw_level!(lvl.lvl, ctx, call(*, pos, lvl.shape))
    return lvl
end

function freeze_level!(lvl::VirtualDenseLevel, ctx::AbstractCompiler, pos)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, call(*, pos, lvl.shape))
    return lvl
end

is_laminable_updater(lvl::VirtualDenseLevel, ctx, ::Union{typeof(defaultupdate), typeof(laminate), typeof(extrude)}, protos...) =
    is_laminable_updater(lvl.lvl, ctx, protos...)
    
struct DenseTraversal
    fbr
    subunfurl
    subfiber_ctr
end

instantiate_reader(fbr::VirtualSubFiber{VirtualDenseLevel}, ctx, protos) =
    instantiate_reader(DenseTraversal(fbr, instantiate_reader, VirtualSubFiber), ctx, protos)
instantiate_updater(fbr::VirtualSubFiber{VirtualDenseLevel}, ctx, protos) =
    instantiate_updater(DenseTraversal(fbr, instantiate_updater, VirtualSubFiber), ctx, protos)
instantiate_updater(fbr::VirtualTrackedSubFiber{VirtualDenseLevel}, ctx, protos) =
    instantiate_updater(DenseTraversal(fbr, instantiate_updater, (lvl, pos) -> VirtualTrackedSubFiber(lvl, pos, fbr.dirty)), ctx, protos)

function instantiate_reader(trv::DenseTraversal, ctx, subprotos, ::Union{typeof(defaultread), typeof(follow)})
    (lvl, pos) = (trv.fbr.lvl, trv.fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti

    q = ctx.code.freshen(tag, :_q)

    Furlable(
        tight = nothing,
        body = (ctx, ext) -> Lookup(
            body = (ctx, i) -> Thunk(
                preamble = quote
                    $q = ($(ctx(pos)) - $(Ti(1))) * $(ctx(lvl.shape)) + $(ctx(i))
                end,
                body = (ctx) -> trv.subunfurl(trv.subfiber_ctr(lvl.lvl, value(q, lvl.Ti)), ctx, subprotos)
            )
        )
    )
end

function instantiate_updater(trv::DenseTraversal, ctx, subprotos, ::Union{typeof(defaultupdate), typeof(laminate), typeof(extrude)})
    (lvl, pos) = (trv.fbr.lvl, trv.fbr.pos)
    tag = lvl.ex
    Ti = lvl.Ti

    q = ctx.code.freshen(tag, :_q)

    Furlable(
        tight = !is_laminable_updater(lvl.lvl, ctx, subprotos...) ? lvl : nothing,
        body = (ctx, ext) -> Lookup(
            body = (ctx, i) -> Thunk(
                preamble = quote
                    $q = ($(ctx(pos)) - $(Ti(1))) * $(ctx(lvl.shape)) + $(ctx(i))
                end,
                body = (ctx) -> trv.subunfurl(trv.subfiber_ctr(lvl.lvl, value(q, lvl.Ti)), ctx, subprotos)
            )
        )
    )
end