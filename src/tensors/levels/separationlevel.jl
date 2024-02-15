"""
    SeparationLevel{Lvl, [Val]}()

A subfiber of a Separation level is a separate tensor of type `Lvl`, in it's 
own memory space.

Each sublevel is stored in a vector of type `Val` with `eltype(Val) = Lvl`. 

```jldoctest
julia> print_tree(Tensor(Dense(Separation(Element(0.0))), [1, 2, 3]))
ERROR: UndefVarError: `print_tree` not defined
Stacktrace:
 [1] top-level scope
   @ none:1
```
"""
struct SeparationLevel{Val, Lvl} <: AbstractLevel
    val::Val
    lvl::Lvl
end
const Separation = SeparationLevel

SeparationLevel(lvl::Lvl) where {Lvl} = SeparationLevel([lvl], lvl)
SeparationLevel{Val, Lvl}(lvl::Lvl) where {Val, Lvl} =  SeparationLevel{Val, Lvl}([lvl], lvl)
Base.summary(::Separation{Val, Lvl}) where {Val, Lvl} = "Separation($(Lvl))"

similar_level(lvl::Separation{Val, Lvl}) where {Val, Lvl} = SeparationLevel{Val, Lvl}(similar_level(lvl.lvl))

postype(::Type{<:Separation{Val, Lvl}}) where {Val, Lvl} = postype(Lvl)

function moveto(lvl::SeparationLevel, device)
    lvl_2 = moveto(lvl.lvl, device)
    val_2 = moveto(lvl.val, device)
    return SeparationLevel(val_2, lvl_2)
end

pattern!(lvl::SeparationLevel) = SeparationLevel(map(pattern!, lvl.val), pattern!(lvl.lvl))
redefault!(lvl::SeparationLevel, init) = SeparationLevel(map(lvl_2->redefault!(lvl_2, init), lvl.val), redefault!(lvl.lvl, init))
Base.resize!(lvl::SeparationLevel, dims...) = SeparationLevel(map(lvl_2->resize!(lvl_2, dims...), lvl.val), resize!(lvl.lvl, dims...))


function Base.show(io::IO, lvl::SeparationLevel{Val, Lvl}) where {Val, Lvl}
    print(io, "Separation(")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>Val), lvl.val)
        print(io, ", ")
        show(IOContext(io, :typeinfo=>Val), lvl.lvl)
    end
    print(io, ")")
end 

labelled_show(io::IO, ::SubFiber{<:SeparationLevel}) =
    print(io, "Pointer -> ")

function labelled_children(fbr::SubFiber{<:SeparationLevel})
    lvl = fbr.lvl
    pos = fbr.pos
    pos > length(lvl.val) && return []
    [LabelledTree(SubFiber(lvl.val[pos], 1))]
end

@inline level_ndims(::Type{<:SeparationLevel{Val, Lvl}}) where {Val, Lvl} = level_ndims(Lvl)
@inline level_size(lvl::SeparationLevel{Val, Lvl}) where {Val, Lvl} = level_size(lvl.lvl)
@inline level_axes(lvl::SeparationLevel{Val, Lvl}) where {Val, Lvl} = level_axes(lvl.lvl)
@inline level_eltype(::Type{SeparationLevel{Val, Lvl}}) where {Val, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:SeparationLevel{Val, Lvl}}) where {Val, Lvl} = level_default(Lvl)

(fbr::Tensor{<:SeparationLevel})() = SubFiber(fbr.lvl, 1)()
(fbr::SubFiber{<:SeparationLevel})() = fbr #TODO this is not consistent somehow
function (fbr::SubFiber{<:SeparationLevel})(idxs...)
    q = fbr.pos
    return Tensor(fbr.lvl.val[q])(idxs...)
end

countstored_level(lvl::SeparationLevel, pos) = pos

mutable struct VirtualSeparationLevel <: AbstractVirtualLevel
    lvl  # stand in for the sublevel for virutal resize, etc.
    ex
    Tv
    Val
    Lvl
end

postype(lvl:: VirtualSeparationLevel) = postype(lvl.lvl)

is_level_injective(::VirtualSeparationLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., true]
is_level_concurrent(::VirtualSeparationLevel, ctx) = [is_level_concurrent(lvl.lvl, ctx)..., true]
is_level_atomic(lvl::VirtualSeparationLevel, ctx) = is_level_atomic(lvl.lvl, ctx)

function lower(lvl::VirtualSeparationLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $SeparationLevel{$(lvl.Val), $(lvl.Lvl)}($(lvl.ex).val, $(ctx(lvl.lvl)))
    end
end

function virtualize(ex, ::Type{SeparationLevel{Val, Lvl}}, ctx, tag=:lvl) where {Val, Lvl}
    sym = freshen(ctx, tag)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    lvl_2 = virtualize(:($ex.lvl), Lvl, ctx, sym)
    VirtualSeparationLevel(lvl_2, sym, typeof(level_default(Lvl)), Val, Lvl)
end

Base.summary(lvl::VirtualSeparationLevel) = "Separation($(lvl.Lvl))"

virtual_level_resize!(lvl::VirtualSeparationLevel, ctx, dims...) = (lvl.lvl = virtual_level_resize!(lvl.lvl, ctx, dims...); lvl)
virtual_level_size(lvl::VirtualSeparationLevel, ctx) = virtual_level_size(lvl.lvl, ctx)
virtual_level_eltype(lvl::VirtualSeparationLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualSeparationLevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualSeparationLevel, ctx, pos, init)
    #declare_level!(lvl.lvl, ctx_2, literal(1), init)
    return lvl
end

function assemble_level!(lvl::VirtualSeparationLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    idx = freshen(ctx.code, :idx)
    sym = freshen(ctx.code, :pointer_to_lvl)
    push!(ctx.code.preamble, quote
        Finch.resize_if_smaller!($(lvl.ex).val, $(ctx(pos_stop)))
        for $idx in $(ctx(pos_start)):$(ctx(pos_stop))
            $sym = similar_level($(lvl.ex).lvl)
            $(contain(ctx) do ctx_2
                lvl_2 = virtualize(sym, lvl.Lvl, ctx_2.code, sym)
                lvl_2 = declare_level!(lvl_2, ctx_2, literal(0), literal(virtual_level_default(lvl_2)))
                lvl_2 = virtual_level_resize!(lvl_2, ctx_2, virtual_level_size(lvl.lvl, ctx_2)...)
                push!(ctx_2.code.preamble, assemble_level!(lvl_2, ctx_2, literal(1), literal(1)))
                lvl_2 = freeze_level!(lvl_2, ctx_2, literal(1))
                :($(lvl.ex).val[$idx] = $(ctx_2(lvl_2)))
            end)
        end
    end)
    lvl
end

supports_reassembly(::VirtualSeparationLevel) = true
function reassemble_level!(lvl::VirtualSeparationLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    idx = freshen(ctx.code, :idx)
    push!(ctx.code.preamble, quote
        for $idx in $(ctx(pos_start)):$(ctx(pos_stop))
            $(contain(ctx) do ctx_2
                lvl_2 = virtualize(:($(lvl.ex).val[$idx]), lvl.Lvl, ctx_2.code, sym)
                push!(ctx_2.code.preamble, assemble_level!(lvl_2, ctx_2, literal(1), literal(1)))
                lvl_2 = declare_level!(lvl_2, ctx_2, literal(1), init)
                lvl_2 = freeze_level!(lvl_2, ctx, literal(1))
                :($(lvl.ex).val[$idx] = $(ctx_2(lvl_2)))
            end)
        end
    end)
    lvl
end

function freeze_level!(lvl::VirtualSeparationLevel, ctx, pos)
    return lvl
end

function thaw_level!(lvl::VirtualSeparationLevel, ctx::AbstractCompiler, pos)
    return lvl
end

function instantiate(fbr::VirtualSubFiber{VirtualSeparationLevel}, ctx, mode::Reader, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    isnulltest = freshen(ctx.code, tag, :_nulltest)
    D = level_default(lvl.Lvl)
    sym = freshen(ctx.code, :pointer_to_lvl)
    val = freshen(ctx.code, lvl.ex, :_val)
    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = virtualize(:($(lvl.ex).val[$(ctx(pos))]), lvl.Lvl, ctx.code, sym)
            instantiate(VirtualSubFiber(lvl_2, literal(1)), ctx, mode, protos)
        end,
    )
end

function instantiate(fbr::VirtualSubFiber{VirtualSeparationLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    sym = freshen(ctx.code, :pointer_to_lvl)

    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = virtualize(:($(lvl.ex).val[$(ctx(pos))]), lvl.Lvl, ctx.code, sym)
            lvl_2 = thaw_level!(lvl_2, ctx, literal(1))
            push!(ctx.code.preamble, assemble_level!(lvl_2, ctx, literal(1), literal(1)))
            res = instantiate(VirtualSubFiber(lvl_2, literal(1)), ctx, mode, protos)
            lvl_2 = freeze_level!(lvl_2, ctx, literal(1))
            push!(ctx.code.epilogue, :($(lvl.ex).val[$(ctx(pos))] = $(ctx(lvl_2))))
            res
        end
    )
end
function instantiate(fbr::VirtualHollowSubFiber{VirtualSeparationLevel}, ctx, mode::Updater, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    sym = freshen(ctx.code, :pointer_to_lvl)

    return body = Thunk(
        body = (ctx) -> begin
            lvl_2 = virtualize(:($(lvl.ex).val[$(ctx(pos))]), lvl.Lvl, ctx.code, sym)
            lvl_2 = thaw_level!(lvl_2, ctx, literal(1))
            push!(ctx.code.preamble, assemble_level!(lvl_2, ctx, literal(1), literal(1)))
            res = instantiate(VirtualHollowSubFiber(lvl_2, literal(1), fbr.dirty), ctx, mode, protos)
            lvl_2 = freeze_level!(lvl_2, ctx, literal(1))
            push!(ctx.code.epilogue, :($(lvl.ex).val[$(ctx(pos))] = $(ctx(lvl_2))))
            res
        end
    )
end
