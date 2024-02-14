"""
    SingleRLELevel{[Ti=Int], [Ptr, Left, Right]}(lvl, [dim])

The single RLE level represent runs of equivalent slices `A[:, ..., :, i]`
which are not entirely [`default`](@ref). A main difference compared to SparseRLE 
level is that SingleRLE level only stores a 'single' non-default run. It emits
an error if the program tries to write multiple (>=2) runs into SingleRLE. 

`Ti` is the type of the last tensor index. The types `Ptr`, `Left`, and 'Right' 
are the types of the arrays used to store positions and endpoints. 

```jldoctest
julia> Tensor(SingleRLE(Element(0)), [0, 10, 0]) 
SingleRLE (0) [1:3]
└─ [2:2]: 10

julia> Tensor(SingleRLE(Element(0)), [0, 10, 10])
ERROR: Finch.FinchProtocolError("SingleRLELevels can only be updated once")

julia> begin
         x = Tensor(SingleRLE(Element(0)), 10);
         @finch begin for i = extent(3,6); x[~i] = 1 end end
         x
       end
SingleRLE (0) [1:10]
└─ [3:6]: 1
```
"""
struct SingleRLELevel{Ti, Ptr<:AbstractVector, Left<:AbstractVector, Right<:AbstractVector, Lvl} <: AbstractLevel
    lvl::Lvl
    shape::Ti
    ptr::Ptr
    left::Left
    right::Right
end

const SingleRLE = SingleRLELevel
SingleRLELevel(lvl::Lvl) where {Lvl} = SingleRLELevel{Int}(lvl)
SingleRLELevel(lvl, shape::Ti, args...) where {Ti} = SingleRLELevel{Ti}(lvl, shape, args...)
SingleRLELevel{Ti}(lvl) where {Ti} = SingleRLELevel{Ti}(lvl, zero(Ti))
SingleRLELevel{Ti}(lvl, shape) where {Ti} = SingleRLELevel{Ti}(lvl, shape, postype(lvl)[1], Ti[], Ti[])

SingleRLELevel{Ti}(lvl::Lvl, shape, ptr::Ptr, left::Left, right::Right) where {Ti, Lvl, Ptr, Left, Right} =
    SingleRLELevel{Ti, Ptr, Left, Right, Lvl}(lvl, shape, ptr, left, right)
 
Base.summary(lvl::SingleRLELevel) = "SingleRLE($(summary(lvl.lvl)))"
similar_level(lvl::SingleRLELevel) = SingleRLE(similar_level(lvl.lvl))
similar_level(lvl::SingleRLELevel, dim, tail...) = SingleRLE(similar_level(lvl.lvl, tail...), dim)

function memtype(::Type{SingleRLELevel{Ti, Ptr, Left, Right, Lvl}}) where {Ti, Ptr, Left, Right, Lvl}
    return Ti 
end

function postype(::Type{SingleRLELevel{Ti, Ptr, Left, Right, Lvl}}) where {Ti, Ptr, Left, Right, Lvl}
    return postype(Lvl) 
end

function moveto(lvl::SingleRLELevel{Ti, Ptr, Left, Right, Lvl}, Tm) where {Ti, Ptr, Left, Right, Lvl}
    lvl_2 = moveto(lvl.lvl, Tm)
    ptr_2 = moveto(lvl.ptr, Tm)
    left_2 = moveto(lvl.left, Tm)
    right_2 = moveto(lvl.right, Tm)
    return SingleRLELevel{Ti}(lvl_2, lvl.shape, ptr_2, left_2, right_2)
end

function countstored_level(lvl::SingleRLELevel, pos)
    countstored_level(lvl.lvl, lvl.ptr[pos + 1] - 1)
end

pattern!(lvl::SingleRLELevel{Ti}) where {Ti} = 
    SingleRLELevel{Ti}(pattern!(lvl.lvl), lvl.shape, lvl.ptr, lvl.left, lvl.right)

redefault!(lvl::SingleRLELevel{Ti}, init) where {Ti} = 
    SingleRLELevel{Ti}(redefault!(lvl.lvl, init), lvl.shape, lvl.ptr, lvl.left, lvl.right)

Base.resize!(lvl::SingleRLELevel{Ti}, dims...) where {Ti} = 
    SingleRLELevel{Ti}(resize!(lvl.lvl, dims[1:end-1]...), dims[end], lvl.ptr, lvl.left, lvl.right)

function Base.show(io::IO, lvl::SingleRLELevel{Ti, Ptr, Left, Right, Lvl}) where {Ti, Lvl, Left, Right, Ptr}
    if get(io, :compact, false)
        print(io, "SingleRLE(")
    else
        print(io, "SingleRLE{$Ti}(")
    end
    show(io, lvl.lvl)
    print(io, ", ")
    show(IOContext(io, :typeinfo=>Ti), lvl.shape)
    print(io, ", ")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(io, lvl.ptr)
        print(io, ", ")
        show(io, lvl.left)
        print(io, ", ")
        show(io, lvl.right)
    end
    print(io, ")")
end

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:SingleRLELevel}, depth)
    p = fbr.pos
    lvl = fbr.lvl
    if p + 1 > length(lvl.ptr)
        print(io, "SingleRLE(undef...)")
        return
    end
    left_endpoints = @view(lvl.left[lvl.ptr[p]:lvl.ptr[p + 1] - 1])

    crds = []
    for l in left_endpoints 
        append!(crds, l)
    end

    print_coord(io, crd) = print(io, crd, ":", lvl.right[lvl.ptr[p]-1+searchsortedfirst(left_endpoints, crd)])  
    get_fbr(crd) = fbr(crd)

    print(io, "SingleRLE (", default(fbr), ") [", ":,"^(ndims(fbr) - 1), "1:", fbr.lvl.shape, "]")
    display_fiber_data(io, mime, fbr, depth, 1, crds, print_coord, get_fbr)
end

Base.show(io::IO, node::LabelledFiberTree{<:SubFiber{<:SingleRLELevel}}) =
    print(io, "SingleRLE (", default(node.fbr), ") [", ":,"^(ndims(node.fbr) - 1), "1:", size(node.fbr)[end], "]")

function AbstractTrees.children(node::LabelledFiberTree{<:SubFiber{<:SingleRLELevel}})
    fbr = node.fbr
    lvl = fbr.lvl
    pos = fbr.pos
    OrderedDict(map(lvl.ptr[pos]:lvl.ptr[pos + 1] - 1) do qos
        cartesian_fiber_label(lvl.left[qos]:lvl.right[qos]) =>
        LabelledFiberTree(SubFiber(lvl.lvl, qos))
    end)
end

@inline level_ndims(::Type{<:SingleRLELevel{Ti, Ptr, Left, Right, Lvl}}) where {Ti, Ptr, Left, Right, Lvl} = 1 + level_ndims(Lvl)
@inline level_size(lvl::SingleRLELevel) = (level_size(lvl.lvl)..., lvl.shape)
@inline level_axes(lvl::SingleRLELevel) = (level_axes(lvl.lvl)..., Base.OneTo(lvl.shape))
@inline level_eltype(::Type{<:SingleRLELevel{Ti, Ptr, Left, Right, Lvl}}) where {Ti, Ptr, Left, Right, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SingleRLELevel{Ti, Ptr, Left, Right, Lvl}}) where {Ti, Ptr, Left, Right, Lvl}= level_default(Lvl)
data_rep_level(::Type{<:SingleRLELevel{Ti, Ptr, Left, Right, Lvl}}) where {Ti, Ptr, Left, Right, Lvl} = SparseData(data_rep_level(Lvl))

(fbr::AbstractFiber{<:SingleRLELevel})() = fbr
function (fbr::SubFiber{<:SingleRLELevel})(idxs...)
    isempty(idxs) && return fbr
    lvl = fbr.lvl
    p = fbr.pos
    r1 = searchsortedlast(@view(lvl.left[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), idxs[end])
    r2 = searchsortedfirst(@view(lvl.right[lvl.ptr[p]:lvl.ptr[p + 1] - 1]), idxs[end])
    q = lvl.ptr[p] + first(r1) - 1
    fbr_2 = SubFiber(lvl.lvl, q)
    r1 != r2 ? default(fbr_2) : fbr_2(idxs[1:end-1]...)
end


mutable struct VirtualSingleRLELevel <: AbstractVirtualLevel
    lvl
    ex
    Ti
    ptr
    left
    right
    shape
    qos_fill
    qos_stop
    prev_pos
end

is_level_injective(lvl::VirtualSingleRLELevel, ctx) = [false, is_level_injective(lvl.lvl, ctx)...]
is_level_concurrent(lvl::VirtualSingleRLELevel, ctx) = [false, is_level_concurrent(lvl.lvl, ctx)...]
is_level_atomic(lvl::VirtualSingleRLELevel, ctx) = false
  

function virtualize(ex, ::Type{SingleRLELevel{Ti, Ptr, Left, Right, Lvl}}, ctx, tag=:lvl) where {Ti, Ptr, Left, Right, Lvl}
    sym = freshen(ctx, tag)
    ptr = freshen(ctx, tag, :_ptr)
    left = freshen(ctx, tag, :_left)
    right = freshen(ctx, tag, :_right)
    push!(ctx.preamble, quote
        $sym = $ex
        $ptr = $sym.ptr
        $left = $sym.left
        $right = $sym.right
    end)
    lvl_2 = virtualize(:($sym.lvl), Lvl, ctx, sym)
    shape = value(:($sym.shape), Int)
    qos_fill = freshen(ctx, sym, :_qos_fill)
    qos_stop = freshen(ctx, sym, :_qos_stop)
    prev_pos = freshen(ctx, sym, :_prev_pos)
    VirtualSingleRLELevel(lvl_2, sym, Ti, ptr, left, right, shape, qos_fill, qos_stop, prev_pos)
end
function lower(lvl::VirtualSingleRLELevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SingleRLELevel{$(lvl.Ti)}(
            $(ctx(lvl.lvl)),
            $(ctx(lvl.shape)),
            $(lvl.ex).ptr,
            $(lvl.ex).left,
            $(lvl.ex).right,
        )
    end
end

Base.summary(lvl::VirtualSingleRLELevel) = "SingleRLE($(summary(lvl.lvl)))"

function virtual_level_size(lvl::VirtualSingleRLELevel, ctx)
    ext = make_extent(lvl.Ti, literal(lvl.Ti(1)), lvl.shape)
    (virtual_level_size(lvl.lvl, ctx)..., ext)
end

function virtual_level_resize!(lvl::VirtualSingleRLELevel, ctx, dims...)
    lvl.shape = getstop(dims[end])
    lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims[1:end-1]...)
    lvl
end


virtual_level_eltype(lvl::VirtualSingleRLELevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSingleRLELevel) = virtual_level_default(lvl.lvl)
postype(lvl::VirtualSingleRLELevel) = postype(lvl.lvl)

function declare_level!(lvl::VirtualSingleRLELevel, ctx::AbstractCompiler, pos, init)
    Ti = lvl.Ti
    Tp = postype(lvl) 
    push!(ctx.code.preamble, quote
        $(lvl.qos_fill) = $(Tp(0))
        $(lvl.qos_stop) = $(Tp(0))
    end)
    if issafe(ctx.mode)
        push!(ctx.code.preamble, quote
            $(lvl.prev_pos) = $(Tp(0))
        end)
    end
    lvl.lvl = declare_level!(lvl.lvl, ctx, literal(Tp(0)), init)
    return lvl
end

function trim_level!(lvl::VirtualSingleRLELevel, ctx::AbstractCompiler, pos)
    Tp = postype(lvl) 
    qos = freshen(ctx.code, :qos)
    push!(ctx.code.preamble, quote
        resize!($(lvl.ptr), $(ctx(pos)) + 1)
        $qos = $(lvl.ptr)[end] - $(Tp(1))
        resize!($(lvl.left), $qos)
        resize!($(lvl.right), $qos)
    end)
    lvl.lvl = trim_level!(lvl.lvl, ctx, value(qos, Tp))
    return lvl
end

function assemble_level!(lvl::VirtualSingleRLELevel, ctx, pos_start, pos_stop)
    pos_start = ctx(cache!(ctx, :p_start, pos_start))
    pos_stop = ctx(cache!(ctx, :p_start, pos_stop))
    return quote
        Finch.resize_if_smaller!($(lvl.ptr), $pos_stop + 1)
        Finch.fill_range!($(lvl.ptr), 0, $pos_start + 1, $pos_stop + 1)
    end
end

function freeze_level!(lvl::VirtualSingleRLELevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        for $p = 1:($pos_stop)
           $(lvl.ptr)[$p + 1] += $(lvl.ptr)[$p]
        end
        $qos_stop = $(lvl.ptr)[$pos_stop + 1] - 1
    end)
    lvl.lvl = freeze_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function thaw_level!(lvl::VirtualSingleRLELevel, ctx::AbstractCompiler, pos_stop)
    p = freshen(ctx.code, :p)
    pos_stop = ctx(cache!(ctx, :pos_stop, simplify(pos_stop, ctx)))
    qos_stop = freshen(ctx.code, :qos_stop)
    push!(ctx.code.preamble, quote
        $(lvl.qos_fill) = $(lvl.ptr)[$pos_stop + 1] - 1
        $(lvl.qos_stop) = $(lvl.qos_fill)
        $qos_stop = $(lvl.qos_fill)
        $(if issafe(ctx.mode)
            quote
                $(lvl.prev_pos) = Finch.scansearch($(lvl.ptr), $(lvl.qos_stop) + 1, 1, $pos_stop) - 1
            end
        end)
        for $p = $pos_stop:-1:1
            $(lvl.ptr)[$p + 1] -= $(lvl.ptr)[$p]
        end
    end)
    lvl.lvl = thaw_level!(lvl.lvl, ctx, value(qos_stop))
    return lvl
end

function instantiate(fbr::VirtualSubFiber{VirtualSingleRLELevel}, ctx, mode::Reader, subprotos, ::Union{typeof(defaultread), typeof(walk)})
    (lvl, pos) = (fbr.lvl, fbr.pos) 
    tag = lvl.ex
    Tp = postype(lvl) 
    Ti = lvl.Ti
    my_i_end = freshen(ctx.code, tag, :_i_end)
    my_i_stop = freshen(ctx.code, tag, :_i_stop)
    my_i_start = freshen(ctx.code, tag, :_i_start)
    my_q = freshen(ctx.code, tag, :_q)
    my_q_stop = freshen(ctx.code, tag, :_q_stop)

    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $my_q = $(lvl.ptr)[$(ctx(pos))]
                $my_q_stop = $(lvl.ptr)[$(ctx(pos)) + $(Tp(1))]
                if $my_q < $my_q_stop
                    $my_i_start = $(lvl.left)[$my_q]
                    $my_i_stop = $(lvl.right)[$my_q]
                else
                    $my_i_start= $(Ti(1))
                    $my_i_stop= $(Ti(0))
                end
            end,
            body = (ctx) -> Sequence([
                Phase(
                    start = (ctx, ext) -> literal(lvl.Ti(1)),
                    stop = (ctx, ext) -> call(-, value(my_i_start, lvl.Ti), getunit(ext)),
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl))),
                ),
                Phase(
                    stop = (ctx, ext) -> value(my_i_stop, lvl.Ti),
                    body = (ctx, ext) -> Run(Simplify(instantiate(VirtualSubFiber(lvl.lvl, value(my_q)), ctx, mode, subprotos))),
                ),
                Phase(
                    stop = (ctx, ext) -> lvl.shape,
                    body = (ctx, ext) -> Run(Fill(virtual_level_default(lvl)))
                )
            ])
        )
    )
end

instantiate(fbr::VirtualSubFiber{VirtualSingleRLELevel}, ctx, mode::Updater, protos) = 
    instantiate(VirtualHollowSubFiber(fbr.lvl, fbr.pos, freshen(ctx.code, :null)), ctx, mode, protos)

function instantiate(fbr::VirtualHollowSubFiber{VirtualSingleRLELevel}, ctx, mode::Updater, subprotos, ::Union{typeof(defaultupdate), typeof(extrude)})
    (lvl, pos) = (fbr.lvl, fbr.pos) 
    tag = lvl.ex
    Tp = postype(lvl) 
    Ti = lvl.Ti
    qos = freshen(ctx.code, tag, :_qos)
    qos_fill = lvl.qos_fill
    qos_stop = lvl.qos_stop
    dirty = freshen(ctx.code, tag, :dirty)
    
    Furlable(
        body = (ctx, ext) -> Thunk(
            preamble = quote
                $qos = $qos_fill + 1
                $(lvl.ptr)[$(ctx(pos)) + 1] == 0 ||
                  throw(FinchProtocolError("SingleRLELevels can only be updated once"))
            end,

            body = (ctx) -> AcceptRun(
                body = (ctx, ext) -> Thunk(
                    preamble = quote
                        if $qos > $qos_stop
                            $qos_stop = max($qos_stop << 1, 1)
                            Finch.resize_if_smaller!($(lvl.left), $qos_stop)
                            Finch.resize_if_smaller!($(lvl.right), $qos_stop)
                            $(contain(ctx_2->assemble_level!(lvl.lvl, ctx_2, value(qos, Tp), value(qos_stop, Tp)), ctx))
                        end
                        $dirty = false
                    end,
                    body = (ctx) -> instantiate(VirtualHollowSubFiber(lvl.lvl, value(qos, Tp), dirty), ctx, mode, subprotos),
                    epilogue = quote
                        if $dirty
                            $(fbr.dirty) = true
                            $qos == $qos_fill + 1 || throw(FinchProtocolError("SingleRLELevels can only be updated once"))
                            $(lvl.left)[$qos] = $(ctx(getstart(ext)))
                            $(lvl.right)[$qos] = $(ctx(getstop(ext)))
                            $(qos) += $(Tp(1))
                            $(if issafe(ctx.mode)
                                quote
                                    $(lvl.prev_pos) = $(ctx(pos))
                                end
                            end)
                        end
                    end
                )
            ),
            epilogue = quote
                $(lvl.ptr)[$(ctx(pos)) + 1] = $qos - $qos_fill - 1
                $qos_fill = $qos - 1
            end
        )
    )
end
