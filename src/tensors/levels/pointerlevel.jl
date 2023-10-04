"""
    PointerElementLevel{D, [Tv=typeof(D), Tp=Int, Vv]}()

A subfiber of an element level is a scalar of type `Tv`, initialized to `D`. `D`
may optionally be given as the first argument.

The data is stored in a vector
of type `Vv` with `eltype(Vv) = Tv`. The type `Ti` is the index type used to
access Vv.

```jldoctest
julia> Fiber!(Dense(PointerElement(0.0)), [1, 2, 3])
Dense [1:3]
├─[1]: 1.0
├─[2]: 2.0
├─[3]: 3.0
```
"""
struct PointerElementLevel{Tp, Vv<:AbstractVector, Lvl} <: AbstractLevel
    val::Vv
end
const PointerElement = PointerElementLevel

function cleanNothing(::Type{Union{A, B}}) where {A, B}
    if A == Nothing && B != Nothing
        return B
    end
    if A != Nothing && B == Nothing
        return A
    end
    error("Bad type for elements of a pointer level.")
end

function cleanNothing(::Type{A}) where {A}
    return A
end


PointerElementLevel(lvl::Lvl) where {Lvl <: AbstractLevel} = PointerElementLevel{postype(Lvl), Vector{Union{Nothing, Lvl}}, Lvl}(Union{Nothing, Lvl}[])
PointerElementLevel(val::Vv) where {Vv <: AbstractVector} = PointerElementLevel{postype(Vv), Vv, cleanNothing(eltype(Vv))}(val)
PointerElementLevel{Tp, Vv, Lvl}() where {Tp, Vv, Lvl} = PointerElementLevel{Tp, Vv, Lvl}(Union{Nothing, Lvl}[])

# PointerElementLevel{Tp, Vv, Lvl}(val::Vv) where {Tp, Vv <: AbstractVector, Lvl} = PointerElementLevel{Tp, Vv, Lvl}(val)

Base.summary(::PointerElement{Tp, Vv, Lvl}) where {Tp, Vv, Lvl} = "PointerElement($(Lvl))"

similar_level(::PointerElement{Tp, Vv, Lvl}) where {Tp, Vv, Lvl} = PointerElementLevel{Tp, Vv, Lvl}()

Memtype(::Type{PointerElement{Tp, Vv, Lvl}}) where {Tp, Vv, Lvl} =
    containertype(Vv)

postype(::Type{<:PointerElement{Tp, Vv, Lvl}}) where {Tp, Vv, Lvl} = Tp

function moveto(lvl::PointerElementLevel{Tp, Vv, Lvl}, ::Type{MemType}) where {Tp, Vv, Lvl,  MemType <: AbstractArray}
    valp = MemType(lvl.val)
    return PointerElementLevel{Tp, Vv, Lvl}(valp)
end

# pattern!(lvl::PointerElementLevel{Tp, Vv, Lvl}) where  {Tp, Vv, Lvl} =
#     Pattern{Tp, Vv}()
# redefault!(lvl::PointerElementLevel{Tp, Vv, Lvl}, init) where {Tp, Vv, Lvl} = 
#     PointerElementLevel{Tp, Vv, Lvl}(lvl.val)


function Base.show(io::IO, lvl::PointerElementLevel{Tp, Vv, Lvl}) where {Tp, Vv, Lvl}
    print(io, "PointerElement{")
    print(io, "$Tp, $Vv, $Lvl}(")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>Vv), lvl.val)
    end
    print(io, ")")
end 

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:PointerElementLevel}, depth)
    p = fbr.pos
    show(io, mime, fbr.lvl.val[p])
end

@inline level_ndims(::Type{<:PointerElementLevel{Tp, Vv, Lvl}}) where {Tp, Vv, Lvl} = level_ndims(Lvl)
@inline level_size(::PointerElementLevel{Tp, Vv, Lvl}) where {Tp, Vv, Lvl} = level_size(Lvl)
@inline level_axes(::PointerElementLevel{Tp, Vv, Lvl}) where {Tp, Vv, Lvl} = level_axes(Lvl)
@inline level_eltype(::Type{PointerElementLevel{Tp, Vv, Lvl}}) where {Tp, Vv, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:PointerElementLevel{Tp, Vv, Lvl}}) where {Tp, Vv, Lvl} = level_default(Lvl)
# data_rep_level(::Type{<:PointerElementLevel{D, Tv, Tp, Vv}}) where {D, Tv, Tp, Vv} = PointerElementData(D, Tv)

(fbr::Fiber{<:PointerElementLevel})() = SubFiber(fbr.lvl, 1)()
function (fbr::SubFiber{<:PointerElementLevel})()
    q = fbr.pos
    return fbr.lvl.val[q]
end

countstored_level(lvl::PointerElementLevel, pos) = pos

struct VirtualPointerElementLevel <: AbstractVirtualLevel
    lvl  # stand in for the sublevel for virutal resize,e tc.
    ex
    Tv
    Vv
    Lvl
end

is_level_injective(::VirtualPointerElementLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., true]
is_level_concurrent(::VirtualPointerElementLevel, ctx) = [is_level_concurrent(lvl.lvl, ctx)..., true]
is_level_atomic(lvl::VirtualPointerElementLevel, ctx) = is_level_atomic(lvl.lvl, ctx)

lower(lvl::VirtualPointerElementLevel, ctx::AbstractCompiler, ::DefaultStyle) = lvl.ex

function virtualize(ex, ::Type{PointerElementLevel{Tp, Vv, Lvl}}, ctx, tag=:lvl) where {Tp, Vv, Lvl}
    sym = freshen(ctx, tag)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    # FIXME: Need to ensure that this virtualize dies....
    dummyCtx = JuliaContext()
    lvl_2 = virtualize(:(), Lvl, dummyCtx, sym)
    VirtualPointerElementLevel(lvl_2, sym, typeof(level_default(Lvl)), Vv, Lvl)
end

Base.summary(lvl::VirtualPointerElementLevel) = "PointerElement($(lvl.Lvl))"

virtual_level_resize!(lvl::VirtualPointerElementLevel, ctx) = virtual_level_resize!(lvl.lvl)
virtual_level_size(lvl::VirtualPointerElementLevel, ctx) = virtual_level_size(lvl.lvl)
virtual_level_eltype(lvl::VirtualPointerElementLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualPointerElementLevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualPointerElementLevel, ctx, pos, init)
    idx = freshen(ctx.code, :idx)
    sym = freshen(ctx.code, :pointer_to_lvl)
    fiber = VirtualFiber(virtualize(quote $(lvl.ex).val[$idx] end, lvl.Lvl, ctx.code, sym))
    subLevelDeclare = contain(ctx) do ctx
        declare!(fiber, ctx, init)
    end
        
    push!(ctx.code.preamble, quote
        for $idx in $(ctx(pos)):length($(lvl.ex).val)
            if !isnothing($(lvl.ex).val[$idx])
                $subLevelDeclare
            end
        end
    end
    )
    lvl
end

# Why do these not recurse?
function assemble_level!(lvl::VirtualPointerElementLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    quote
        Finch.resize_if_smaller!($(lvl.ex).val, $(ctx(pos_stop)))
        Finch.fill_range!($(lvl.ex).val, nothing, $(ctx(pos_start)), $(ctx(pos_stop)))
    end
end

supports_reassembly(::VirtualPointerElementLevel) = true
function reassemble_level!(lvl::VirtualPointerElementLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    push!(ctx.code.preamble, quote
        Finch.fill_range!($(lvl.ex).val, nothing, $(ctx(pos_start)), $(ctx(pos_stop)))
    end)
    lvl
end



function freeze_level!(lvl::VirtualPointerElementLevel, ctx, pos)
    idx = freshen(ctx.code, :idx)
    sym = freshen(ctx.code, :pointer_to_lvl)
    fiber = VirtualFiber(virtualize(quote $(lvl.ex).val[$idx] end, lvl.Lvl, ctx.code, sym))
    subLevelFreeze = contain(ctx) do ctx
        freeze!(fiber, ctx)
    end
        
    push!(ctx.code.preamble, quote
        for $idx in 1:$(ctx(pos))
            if !isnothing($(lvl.ex).val[$idx])
                $subLevelFreeze
            end
        end
    end
    )
    lvl
end

function thaw_level!(lvl::VirtualPointerElementLevel, ctx::AbstractCompiler, pos)
    idx = freshen(ctx.code, :idx)
    sym = freshen(ctx.code, :pointer_to_lvl)
    fiber = VirtualFiber(virtualize(quote $(lvl.ex).val[$idx] end, lvl.Lvl, ctx.code, sym))
    subLevelThaw = contain(ctx) do ctx
        thaw!(fiber, ctx)
    end
        
    push!(ctx.code.preamble, quote
        for $idx in 1:$(ctx(pos))
            if !isnothing($(lvl.ex).val[$idx])
                $subLevelThaw
            end
        end
    end
    )
    lvl
end

function trim_level!(lvl::VirtualPointerElementLevel, ctx::AbstractCompiler, pos)
    idx = freshen(ctx.code, :idx)
    sym = freshen(ctx.code, :pointer_to_lvl)
    fiber = VirtualFiber(virtualize(quote $(lvl.ex).val[$idx] end, lvl.Lvl, ctx.code, sym))
    subLevelTrim = contain(ctx) do ctx
        trim!(fiber, ctx)
    end
        
    push!(ctx.code.preamble, quote
        for $idx in 1:$(ctx(pos))
            if !isnothing($(lvl.ex).val[$idx])
                $subLevelTrim
            end
        end
        resize!($(lvl.ex).val, $(ctx(pos)) + 1)
    end
    )
    lvl
end



function instantiate_reader(fbr::VirtualSubFiber{VirtualPointerElementLevel}, ctx, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    isnulltest = freshen(ctx.code, tag, :_nulltest)
    D = level_default(lvl)
    sym = freshen(ctx, :pointer_to_lvl)
    lvlp = virtualize(quote $(lvl.ex).val[$(ctx(pos))] end, Lvl, ctx, sym)

    lvlpAsSubfiber = VirtualSubFiber(lvlp, value(1, lvl.Tv))
    val = freshen(ctx.code, lvl.ex, :_val)
    return Thunk(
        preamble = quote
            $isnulltest = !isnothing($(lvl.ex).val[$(ctx(pos))])
            
        end,
        body = (ctx) -> switch([value(:($isnulltest)) => instantiate_reader(lvlpAsSubfiber, ctx, protos),
            literal(true) => literal(D)])
    )
end


function instantiate_updater(fbr::VirtualSubFiber{VirtualPointerElementLevel}, ctx, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    isnulltest = freshen(ctx.code, tag, :_nulltest)
    D = level_default(lvl)
    sym = freshen(ctx, :pointer_to_lvl)
    lvlp = virtualize(quote $(lvl.ex).val[$(ctx(pos))] end, lvl.Lvl, ctx, sym)

    lvlpAsSubfiber = VirtualTrackedSubFiber(lvlp, value(1, lvl.Tv))
    symNew = freshen(ctx, :pointer_to_nev_lvl)
    createNewLevelAndUse = Thunk(preamble = quote
        $symNew = similar_level($(lvl.Lvl))
        $(lvl.ex).val[$(ctx(pos))] = $symNew
    end,
        body = (ctx) -> instantiate_updater(lvlpAsSubfiber, ctx, protos))
        
    val = freshen(ctx.code, lvl.ex, :_val)
    return Thunk(
        preamble = quote
            $isnulltest = !isnothing($(lvl.ex).val[$(ctx(pos))])
            
        end,
        body = (ctx) -> switch([value(:($isnulltest)) => instantiate_updater(lvlpAsSubfiber, ctx, protos),
            literal(true) => createNewLevelAndUse])
    )
end

function instantiate_updater(fbr::VirtualTrackedSubFiber{VirtualPointerElementLevel}, ctx, subprotos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    isnulltest = freshen(ctx.code, tag, :_nulltest)
    D = level_default(lvl)
    sym = freshen(ctx, :pointer_to_lvl)
    lvlp = virtualize(quote $(lvl.ex).val[$(ctx(pos))] end, lvl.Lvl, ctx, sym)

    lvlpAsSubfiber = VirtualTrackedSubFiber(lvlp, value(1, lvl.Tv))
    symNew = freshen(ctx, :pointer_to_nev_lvl)
    createNewLevelAndUse = Thunk(preamble = quote
        $symNew = similar_level($(lvl.Lvl))
        $(lvl.ex).val[$(ctx(pos))] = $symNew
    end,
        body = (ctx) -> instantiate_updater(lvlpAsSubfiber, ctx, protos))
        
    val = freshen(ctx.code, lvl.ex, :_val)
    return Thunk(
        preamble = quote
            $isnulltest = !isnothing($(lvl.ex).val[$(ctx(pos))])
            
        end,
        body = (ctx) -> switch([value(:($isnulltest)) => instantiate_updater(lvlpAsSubfiber, ctx, subprotos),
            literal(true) => createNewLevelAndUse])
    )
end
