"""
    PointerLevel{D, [Tv=typeof(D), Tp=Int, Vv]}()

A subfiber of an element level is a scalar of type `Tv`, initialized to `D`. `D`
may optionally be given as the first argument.

The data is stored in a vector
of type `Vv` with `eltype(Vv) = Tv`. The type `Ti` is the index type used to
access Vv.

```jldoctest
julia> Fiber!(Dense(Pointer(0.0)), [1, 2, 3])
Dense [1:3]
├─[1]: 1.0
├─[2]: 2.0
├─[3]: 3.0
```
"""
struct PointerLevel{Tp, Vv<:AbstractVector, Lvl} <: AbstractLevel
    val::Vv
end
const Pointer = PointerLevel

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


PointerLevel(lvl::Lvl) where {Lvl <: AbstractLevel} = PointerLevel{postype(Lvl), Vector{Union{Nothing, Lvl}}, Lvl}(Union{Nothing, Lvl}[])
PointerLevel(val::Vv) where {Vv <: AbstractVector} = PointerLevel{postype(Vv), Vv, cleanNothing(eltype(Vv))}(val)
PointerLevel{Tp, Vv, Lvl}() where {Tp, Vv, Lvl} = PointerLevel{Tp, Vv, Lvl}(Union{Nothing, Lvl}[])

# PointerLevel{Tp, Vv, Lvl}(val::Vv) where {Tp, Vv <: AbstractVector, Lvl} = PointerLevel{Tp, Vv, Lvl}(val)

Base.summary(::Pointer{Tp, Vv, Lvl}) where {Tp, Vv, Lvl} = "Pointer($(Lvl))"

similar_level(::Pointer{Tp, Vv, Lvl}) where {Tp, Vv, Lvl} = PointerLevel{Tp, Vv, Lvl}()

Memtype(::Type{Pointer{Tp, Vv, Lvl}}) where {Tp, Vv, Lvl} =
    containertype(Vv)

postype(::Type{<:Pointer{Tp, Vv, Lvl}}) where {Tp, Vv, Lvl} = Tp

function moveto(lvl::PointerLevel{Tp, Vv, Lvl}, ::Type{MemType}) where {Tp, Vv, Lvl,  MemType <: AbstractArray}
    valp = MemType(lvl.val)
    return PointerLevel{Tp, Vv, Lvl}(valp)
end

# pattern!(lvl::PointerLevel{Tp, Vv, Lvl}) where  {Tp, Vv, Lvl} =
#     Pattern{Tp, Vv}()
# redefault!(lvl::PointerLevel{Tp, Vv, Lvl}, init) where {Tp, Vv, Lvl} = 
#     PointerLevel{Tp, Vv, Lvl}(lvl.val)


function Base.show(io::IO, lvl::PointerLevel{Tp, Vv, Lvl}) where {Tp, Vv, Lvl}
    print(io, "Pointer{")
    print(io, "$Tp, $Vv, $Lvl}(")
    if get(io, :compact, false)
        print(io, "…")
    else
        show(IOContext(io, :typeinfo=>Vv), lvl.val)
    end
    print(io, ")")
end 

function display_fiber(io::IO, mime::MIME"text/plain", fbr::SubFiber{<:PointerLevel}, depth)
    p = fbr.pos
    show(io, mime, fbr.lvl.val[p])
end

@inline level_ndims(::Type{<:PointerLevel{Tp, Vv, Lvl}}) where {Tp, Vv, Lvl} = level_ndims(Lvl)
@inline level_size(::PointerLevel{Tp, Vv, Lvl}) where {Tp, Vv, Lvl} = level_size(Lvl)
@inline level_axes(::PointerLevel{Tp, Vv, Lvl}) where {Tp, Vv, Lvl} = level_axes(Lvl)
@inline level_eltype(::Type{PointerLevel{Tp, Vv, Lvl}}) where {Tp, Vv, Lvl} = level_eltype(Lvl)
@inline level_default(::Type{<:PointerLevel{Tp, Vv, Lvl}}) where {Tp, Vv, Lvl} = level_default(Lvl)
# data_rep_level(::Type{<:PointerLevel{D, Tv, Tp, Vv}}) where {D, Tv, Tp, Vv} = PointerData(D, Tv)

(fbr::Fiber{<:PointerLevel})() = SubFiber(fbr.lvl, 1)()
function (fbr::SubFiber{<:PointerLevel})()
    q = fbr.pos
    return fbr.lvl.val[q]
end

countstored_level(lvl::PointerLevel, pos) = pos

struct VirtualPointerLevel <: AbstractVirtualLevel
    lvl  # stand in for the sublevel for virutal resize,e tc.
    ex
    Tv
    Vv
    Tp
    Lvl
end

is_level_injective(::VirtualPointerLevel, ctx) = [is_level_injective(lvl.lvl, ctx)..., true]
is_level_concurrent(::VirtualPointerLevel, ctx) = [is_level_concurrent(lvl.lvl, ctx)..., true]
is_level_atomic(lvl::VirtualPointerLevel, ctx) = is_level_atomic(lvl.lvl, ctx)

function lower(lvl::VirtualPointerLevel, ctx::AbstractCompiler, ::DefaultStyle)
    quote
        $PointerLevel{$(lvl.Tp), $(lvl.Vv), $(lvl.Lvl)}($(lvl.ex).val)
    end
end

function virtualize(ex, ::Type{PointerLevel{Tp, Vv, Lvl}}, ctx, tag=:lvl) where {Tp, Vv, Lvl}
    sym = freshen(ctx, tag)
    push!(ctx.preamble, quote
        $sym = $ex
    end)
    # FIXME: Need to ensure that this virtualize dies....
    println("calling virtualize on pointer...")
    dummyCtx = JuliaContext()
    lvl_2 = virtualize(:(), Lvl, dummyCtx, sym)
    println("Virtualized stuff below pointer...")
    VirtualPointerLevel(lvl_2, sym, typeof(level_default(Lvl)), Vv, Tp, Lvl)
end

Base.summary(lvl::VirtualPointerLevel) = "Pointer($(lvl.Lvl))"

virtual_level_resize!(lvl::VirtualPointerLevel, ctx, dims...) = virtual_level_resize!(lvl.lvl, ctx, dims...)
virtual_level_size(lvl::VirtualPointerLevel, ctx) = virtual_level_size(lvl.lvl, ctx)
virtual_level_eltype(lvl::VirtualPointerLevel) = virtual_level_eltype(lvl.lvl)
virtual_level_default(lvl::VirtualPointerLevel) = virtual_level_default(lvl.lvl)

function declare_level!(lvl::VirtualPointerLevel, ctx, pos, init)
    idx = freshen(ctx.code, :idx)
    sym = freshen(ctx.code, :pointer_to_lvl)
    
    subLevelDeclare = contain(ctx) do ctx
        virtualLevel = virtualize(quote $(lvl.ex).val[$idx] end, lvl.Lvl, ctx.code, sym)
        fiber = VirtualFiber(virtualLevel)
        declare!(fiber, ctx, init)
    end
        
    push!(ctx.code.preamble, quote
        for $idx in ($(ctx(pos))+1):length($(lvl.ex).val)
            if !isnothing($(lvl.ex).val[$idx])
                $subLevelDeclare
            end
        end
    end
    )
    return lvl
end

# Why do these not recurse?
function assemble_level!(lvl::VirtualPointerLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    quote
        Finch.resize_if_smaller!($(lvl.ex).val, $(ctx(pos_stop)))
        Finch.fill_range!($(lvl.ex).val, nothing, $(ctx(pos_start)), $(ctx(pos_stop)))
    end
end

supports_reassembly(::VirtualPointerLevel) = true
function reassemble_level!(lvl::VirtualPointerLevel, ctx, pos_start, pos_stop)
    pos_start = cache!(ctx, :pos_start, simplify(pos_start, ctx))
    pos_stop = cache!(ctx, :pos_stop, simplify(pos_stop, ctx))
    push!(ctx.code.preamble, quote
        Finch.fill_range!($(lvl.ex).val, nothing, $(ctx(pos_start)), $(ctx(pos_stop)))
    end)
    lvl
end



function freeze_level!(lvl::VirtualPointerLevel, ctx, pos)
    idx = freshen(ctx.code, :idx)
    sym = freshen(ctx.code, :pointer_to_lvl)
    
    subLevelFreeze = contain(ctx) do ctx
        fiber = VirtualFiber(virtualize(quote $(lvl.ex).val[$idx] end, lvl.Lvl, ctx.code, sym))
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
    return lvl
end

function thaw_level!(lvl::VirtualPointerLevel, ctx::AbstractCompiler, pos)
    idx = freshen(ctx.code, :idx)
    sym = freshen(ctx.code, :pointer_to_lvl)

    subLevelThaw = contain(ctx) do ctx
        fiber = VirtualFiber(virtualize(quote $(lvl.ex).val[$idx] end, lvl.Lvl, ctx.code, sym))
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
    return lvl
end

function trim_level!(lvl::VirtualPointerLevel, ctx::AbstractCompiler, pos)
    idx = freshen(ctx.code, :idx)
    sym = freshen(ctx.code, :pointer_to_lvl)
    
    subLevelTrim = contain(ctx) do ctx
        fiber = VirtualFiber(virtualize(quote $(lvl.ex).val[$idx] end, lvl.Lvl, ctx.code, sym))
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
    return lvl
end



function instantiate_reader(fbr::VirtualSubFiber{VirtualPointerLevel}, ctx, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    isnulltest = freshen(ctx.code, tag, :_nulltest)
    D = level_default(lvl.Lvl)
    sym = freshen(ctx, :pointer_to_lvl)
    println("pickme!read!")
    val = freshen(ctx.code, lvl.ex, :_val)
    return  Furlable(body = (ctx, ext) -> Thunk(
        preamble = quote
            $isnulltest = !isnothing($(lvl.ex).val[$(ctx(pos))])
            
        end,
        body = (ctx) -> switch([value(:($isnulltest)) => instantiate_reader(VirtualSubFiber(virtualize(quote $(lvl.ex).val[$(ctx(pos))] end, lvl.Lvl, ctx, sym), value(1, lvl.Tv)), ctx, protos),
            literal(true) => literal(D)])
    ))
end


function instantiate_updater(fbr::VirtualSubFiber{VirtualPointerLevel}, ctx, protos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
   
    D = level_default(lvl.Lvl)


    symNew = freshen(ctx.code, tag, :pointer_to_nev_lvl)
    createNewLevelAndUse = Thunk(preamble = quote
        $symNew = similar_level($(lvl.Lvl))
        $(lvl.ex).val[$(ctx(pos))] = $symNew
    end,
        body = (ctx) -> instantiate_updater(VirtualTrackedSubFiber(virtualize(quote $(lvl.ex).val[$(ctx(pos))] end, lvl.Lvl, ctx, freshen(ctx.code, :pointer_to_lvl)), value(1, lvl.Tv)), ctx, protos))
        
    val = freshen(ctx.code, lvl.ex, :_val)
    return  Furlable(body = (ctx, ext) -> let isnulltest = freshen(ctx, tag, :_nulltest);
    Thunk(
        preamble = quote
            $isnulltest = !isnothing($(lvl.ex).val[$(ctx(pos))])
            
        end,
        body = (ctx) -> switch([value(:($isnulltest)) => instantiate_updater(
            VirtualTrackedSubFiber(virtualize(quote $(lvl.ex).val[$(ctx(pos))] end, lvl.Lvl, ctx, sym), value(1, lvl.Tv)), ctx, protos),
            literal(true) => createNewLevelAndUse]))
    end)
end

function instantiate_updater(fbr::VirtualTrackedSubFiber{VirtualPointerLevel}, ctx, subprotos)
    (lvl, pos) = (fbr.lvl, fbr.pos)
    tag = lvl.ex
    isnulltest = freshen(ctx.code, tag, :_nulltest)
    D = level_default(lvl.Lvl)
    sym = freshen(ctx.code, tag, :pointer_to_lvl)

    symNew = freshen(ctx.code, tag, :pointer_to_nev_lvl)
    createNewLevelAndUse = Thunk(preamble = quote
        $symNew = similar_level($(lvl.Lvl))
        $(lvl.ex).val[$(ctx(pos))] = $symNew
    end,
        body = (ctx) -> instantiate_updater(VirtualTrackedSubFiber(virtualize(quote $(lvl.ex).val[$(ctx(pos))] end, lvl.Lvl, ctx, sym), value(1, lvl.Tv)), ctx, protos))
        
    val = freshen(ctx.code, lvl.ex, :_val)
    return Furlable(body = (ctx, ext) -> Thunk(
        preamble = quote
            $isnulltest = !isnothing($(lvl.ex).val[$(ctx(pos))])
            
        end,
        body = (ctx) -> switch([value(:($isnulltest)) => instantiate_updater(VirtualTrackedSubFiber(virtualize(quote $(lvl.ex).val[$(ctx(pos))] end, lvl.Lvl, ctx, sym), value(1, lvl.Tv)), ctx, subprotos),
            literal(true) => createNewLevelAndUse])
    ))
end
