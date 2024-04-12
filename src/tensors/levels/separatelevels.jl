"""
    SeparateLevel{Lvl, [Val]}()

A subfiber of a Separate level is a separate tensor of type `Lvl`, in it's 
own memory space.

Each sublevel is stored in a vector of type `Val` with `eltype(Val) = Lvl`. 

```jldoctest
julia> Tensor(Dense(Separate(Element(0.0))), [1, 2, 3])
Dense [1:3]
├─ [1]: Pointer ->
│  └─ 1.0
├─ [2]: Pointer ->
│  └─ 2.0
└─ [3]: Pointer ->
   └─ 3.0
```
"""
struct SeparateLevel{Lvl, Val} <: AbstractLevel
    lvl::Lvl
    val::Val
end
const Separate = SeparateLevel

#similar_level(lvl, level_default(typeof(lvl)), level_eltype(typeof(lvl)), level_size(lvl)...)
SeparateLevel(lvl::Lvl) where {Lvl} = SeparateLevel(lvl, Lvl[])
Base.summary(::Separate{Lvl, Val}) where {Lvl, Val} = "Separate($(Lvl))"

similar_level(lvl::Separate{Lvl, Val}, fill_value, eltype::Type, dims...) where {Lvl, Val} =
    SeparateLevel(similar_level(lvl.lvl, fill_value, eltype, dims...))

postype(::Type{<:Separate{Lvl, Val}}) where {Lvl, Val} = postype(Lvl)

function moveto(lvl::SeparateLevel, device)
    lvl_2 = moveto(lvl.lvl, device)
    val_2 = moveto(lvl.val, device)
    return SeparateLevel(lvl_2, val_2)
end

pattern!(lvl::SeparateLevel) = SeparateLevel(pattern!(lvl.lvl), map(pattern!, lvl.val))
redefault!(lvl::SeparateLevel, init) = SeparateLevel(redefault!(lvl.lvl, init), map(lvl_2->redefault!(lvl_2, init), lvl.val))
Base.resize!(lvl::SeparateLevel, dims...) = SeparateLevel(resize!(lvl.lvl, dims...), map(lvl_2->resize!(lvl_2, dims...), lvl.val))


function Base.show(io::IO, lvl::SeparateLevel{Lvl, Val}) where {Lvl, Val}
    print(io, "Separate(")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(io, lvl.lvl)
        print(io, ", ")
        show(io, lvl.val)
    end
    print(io, ")")
end 

labelled_show(io::IO, ::SubFiber{<:SeparateLevel}) =
    print(io, "Pointer -> ")

function labelled_children(fbr::SubFiber{<:SeparateLevel})
    lvl = fbr.lvl
    pos = fbr.pos
    pos > length(lvl.val) && return []
    [LabelledTree(SubFiber(lvl.val[pos], 1))]
end

@inline level_ndims(::Type{<:SeparateLevel{Lvl, Val}}) where {Lvl, Val} = level_ndims(Lvl)
@inline level_size(lvl::SeparateLevel{Lvl, Val}) where {Lvl, Val} = level_size(lvl.lvl)
@inline level_axes(lvl::SeparateLevel{Lvl, Val}) where {Lvl, Val} = level_axes(lvl.lvl)
@inline level_eltype(::Type{SeparateLevel{Lvl, Val}}) where {Lvl, Val} = level_eltype(Lvl)
@inline level_default(::Type{<:SeparateLevel{Lvl, Val}}) where {Lvl, Val} = level_default(Lvl)

function (fbr::SubFiber{<:SeparateLevel})(idxs...)
    q = fbr.pos
    return SubFiber(fbr.lvl.val[q], 1)(idxs...)
end

countstored_level(lvl::SeparateLevel, pos) = pos

mutable struct VirtualSeparateLevel <: AbstractVirtualLevel
    lvl  # stand in for the sublevel for virutal resize, etc.
    ex
    Tv
    Lvl
    Val
end

postype(lvl:: VirtualSeparateLevel) = postype(lvl.lvl)

is_level_injective(ctx, ::VirtualSeparateLevel) = [is_level_injective(ctx, lvl.lvl)..., true]
is_level_concurrent(::VirtualSeparateLevel, ctx) = [is_level_concurrent(lvl.lvl, ctx)..., true]
is_level_atomic(ctx, lvl::VirtualSeparateLevel) = is_level_atomic(ctx, lvl.lvl)

function lower(ctx::AbstractCompiler, lvl::VirtualSeparateLevel, ::DefaultStyle)
    quote
        $SeparateLevel{$(lvl.Lvl), $(lvl.Val)}($(ctx(lvl.lvl)), $(lvl.ex).val)
    end
end

function virtualize(ctx, ex, ::Type{SeparateLevel{Lvl, Val}}, tag=:lvl) where {Lvl, Val}
    sym = freshen(ctx, tag)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(ctx, :($ex.lvl), Lvl, sym)
    VirtualSeparateLevel(lvl_2, sym, typeof(level_default(Lvl)), Lvl, Val)
end

Base.summary(lvl::VirtualSeparateLevel) = "Separate($(lvl.Lvl))"

virtual_level_resize!(ctx, lvl::VirtualSeparateLevel, dims...) = (lvl.lvl = virtual_level_resize!(ctx, lvl.lvl, dims...); lvl)
virtual_level_size(ctx, lvl::VirtualSeparateLevel) = virtual_level_size(ctx, lvl.lvl)
virtual_level_eltype(lvl::VirtualSeparateLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSeparateLevel) = virtual_level_default(lvl.lvl)

function declare_level!(ctx, lvl::VirtualSeparateLevel, pos, init)
    #declare_level!(ctx_2, lvl.lvl, literal(1), init)
    return lvl
end

function assemble_level!(ctx, lvl::VirtualSeparateLevel, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(ctx, pos_start))
    pos_stop = cache!(ctx, :pos_stop, simplify(ctx, pos_stop))
    pos = freshen(ctx.code, :pos)
    sym = freshen(ctx.code, :pointer_to_lvl)
    push!(ctx.code.preamble, quote
        Finch.resize_if_smaller!($(lvl.ex).val, $(ctx(pos_stop)))
        for $pos in $(ctx(pos_start)):$(ctx(pos_stop))
            $sym = similar_level(
                $(lvl.ex).lvl,
                level_default(typeof($(lvl.ex).lvl)),
                level_eltype(typeof($(lvl.ex).lvl)),
                $(map(ctx, map(getstop, virtual_level_size(ctx, lvl)))...)
            )
            $(contain(ctx) do ctx_2
                lvl_2 = virtualize(ctx_2.code, sym, lvl.Lvl, sym)
                lvl_2 = declare_level!(ctx_2, lvl_2, literal(0), literal(virtual_level_default(lvl_2)))
                lvl_2 = virtual_level_resize!(ctx_2, lvl_2, virtual_level_size(ctx_2, lvl.lvl)...)
                push!(ctx_2.code.preamble, assemble_level!(ctx_2, lvl_2, literal(1), literal(1)))
                contain(ctx_2) do ctx_3
                    lvl_2 = freeze_level!(ctx_3, lvl_2, literal(1))
                    :($(lvl.ex).val[$(ctx_3(pos))] = $(ctx_3(lvl_2)))
                end
            end)
        end
    end)
    lvl
end

supports_reassembly(::VirtualSeparateLevel) = true
function reassemble_level!(ctx, lvl::VirtualSeparateLevel, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(ctx, pos_start))
    pos_stop = cache!(ctx, :pos_stop, simplify(ctx, pos_stop))
    pos = freshen(ctx.code, :pos)
    push!(ctx.code.preamble, quote
        for $idx in $(ctx(pos_start)):$(ctx(pos_stop))
            $(contain(ctx) do ctx_2
                lvl_2 = virtualize(ctx_2.code, :($(lvl.ex).val[$idx]), lvl.Lvl, sym)
                push!(ctx_2.code.preamble, assemble_level!(ctx_2, lvl_2, literal(1), literal(1)))
                lvl_2 = declare_level!(ctx_2, lvl_2, literal(1), init)
                contain(ctx_2) do ctx_3
                    lvl_2 = freeze_level!(ctx_3, lvl_2, literal(1))
                    :($(lvl.ex).val[$(ctx_3(pos))] = $(ctx_3(lvl_2)))
                end
            end)
        end
    end)
    lvl
end

function freeze_level!(ctx, lvl::VirtualSeparateLevel, pos)
    return lvl
end

function thaw_level!(ctx::AbstractCompiler, lvl::VirtualSeparateLevel, pos)
    return lvl
end

function instantiate(ctx, fbr::VirtualSubFiber{VirtualSeparateLevel}, mode::Reader, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    isnulltest = freshen(ctx.code, tag, :_nulltest)
    D = level_default(lvl.Lvl)
    sym = freshen(ctx.code, :pointer_to_lvl)
    val = freshen(ctx.code, lvl.ex, :_val)
    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = virtualize(ctx.code, :($(lvl.ex).val[$(ctx(pos))]), lvl.Lvl, sym)
            instantiate(ctx, VirtualSubFiber(lvl_2, literal(1)), mode, protos)
        end,
    )
end

function instantiate(ctx, fbr::VirtualSubFiber{VirtualSeparateLevel}, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    sym = freshen(ctx.code, :pointer_to_lvl)

    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = virtualize(ctx.code, :($(lvl.ex).val[$(ctx(pos))]), lvl.Lvl, sym)
            lvl_2 = thaw_level!(ctx, lvl_2, literal(1))
            push!(ctx.code.preamble, assemble_level!(ctx, lvl_2, literal(1), literal(1)))
            res = instantiate(ctx, VirtualSubFiber(lvl_2, literal(1)), mode, protos)
            push!(ctx.code.epilogue, 
                contain(ctx) do ctx_2
                    lvl_2 = freeze_level!(ctx_2, lvl_2, literal(1))
                    :($(lvl.ex).val[$(ctx_2(pos))] = $(ctx_2(lvl_2)))
                end
            )
            res
        end
    )
end
function instantiate(ctx, fbr::VirtualHollowSubFiber{VirtualSeparateLevel}, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    sym = freshen(ctx.code, :pointer_to_lvl)

    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = virtualize(ctx.code, :($(lvl.ex).val[$(ctx(pos))]), lvl.Lvl, sym)
            lvl_2 = thaw_level!(ctx, lvl_2, literal(1))
            push!(ctx.code.preamble, assemble_level!(ctx, lvl_2, literal(1), literal(1)))
            res = instantiate(ctx, VirtualHollowSubFiber(lvl_2, literal(1), fbr.dirty), mode, protos)
            push!(ctx.code.epilogue, 
                contain(ctx) do ctx_2
                    lvl_2 = freeze_level!(ctx_2, lvl_2, literal(1))
                    :($(lvl.ex).val[$(ctx_2(pos))] = $(ctx_2(lvl_2)))
                end
            )
            res
            end
        )
    end
