abstract type AbstractFiber{Lvl} end
abstract type AbstractVirtualFiber{Lvl} end

"""
    Fiber(lvl)

`Fiber` represents the root of a level-tree tensor. To easily construct a valid
fiber, use [`@fiber`](@ref) or [`fiber`](@ref). Users should avoid calling
this constructor directly.

In particular, `Fiber` represents the tensor at position 1 of `lvl`. The
constructor `Fiber(lvl)` wraps a level assuming it is already in a valid state.
The constructor `Fiber!(lvl)` first initializes `lvl` assuming no positions are
valid.
"""
struct Fiber{Lvl} <: AbstractFiber{Lvl}
    lvl::Lvl
end

mutable struct VirtualFiber{Lvl} <: AbstractVirtualFiber{Lvl}
    lvl::Lvl
end
function virtualize(ex, ::Type{<:Fiber{Lvl}}, ctx, tag=ctx.freshen(:tns)) where {Lvl}
    lvl = virtualize(:($ex.lvl), Lvl, ctx, Symbol(tag, :_lvl))
    VirtualFiber(lvl)
end
(ctx::Finch.LowerJulia)(fbr::VirtualFiber) = :(Fiber($(ctx(fbr.lvl))))
FinchNotation.isliteral(::VirtualFiber) = false

"""
    SubFiber(lvl, pos)

`SubFiber` represents a fiber at position `pos` within `lvl`.
"""
struct SubFiber{Lvl, Pos} <: AbstractFiber{Lvl}
    lvl::Lvl
    pos::Pos
end

mutable struct VirtualSubFiber{Lvl} <: AbstractVirtualFiber{Lvl}
    lvl::Lvl
    pos
end
function virtualize(ex, ::Type{<:SubFiber{Lvl, Pos}}, ctx, tag=ctx.freshen(:tns)) where {Lvl, Pos}
    lvl = virtualize(:($ex.lvl), Lvl, ctx, Symbol(tag, :_lvl))
    pos = virtualize(:($ex.pos), Pos, ctx)
    VirtualSubFiber(lvl, pos)
end
(ctx::Finch.LowerJulia)(fbr::VirtualSubFiber) = :(SubFiber($(ctx(fbr.lvl)), $(ctx(fbr.pos))))
FinchNotation.isliteral(::VirtualSubFiber) =  false

"""
    level_ndims(::Type{Lvl})

The result of `level_ndims(Lvl)` defines [ndims](@ref) for all subfibers
in a level of type `Lvl`.
"""
function level_ndims end
@inline Base.ndims(::AbstractFiber{Lvl}) where {Lvl} = level_ndims(Lvl)
@inline Base.ndims(::Type{<:AbstractFiber{Lvl}}) where {Lvl} = level_ndims(Lvl)

"""
    level_size(lvl)

The result of `level_size(lvl)` defines the [size](@ref) of all subfibers in the
level `lvl`.
"""
function level_size end
@inline Base.size(fbr::AbstractFiber) = level_size(fbr.lvl)

"""
    level_axes(lvl)

The result of `level_axes(lvl)` defines the [axes](@ref) of all subfibers in the
level `lvl`.
"""
function level_axes end
@inline Base.axes(fbr::AbstractFiber) = level_axes(fbr.lvl)

"""
    level_eltype(::Type{Lvl})

The result of `level_eltype(Lvl)` defines [eltype](@ref) for all subfibers in a
level of type `Lvl`.
"""
function level_eltype end
@inline Base.eltype(::AbstractFiber{Lvl}) where {Lvl} = level_eltype(Lvl)
@inline Base.eltype(::Type{<:AbstractFiber{Lvl}}) where {Lvl} = level_eltype(Lvl)

"""
    level_default(::Type{Lvl})

The result of `level_default(Lvl)` defines [default](@ref) for all subfibers in a
level of type `Lvl`.
"""
function level_default end
@inline default(::AbstractFiber{Lvl}) where {Lvl} = level_default(Lvl)
@inline default(::Type{<:AbstractFiber{Lvl}}) where {Lvl} = level_default(Lvl)

virtual_size(tns::AbstractVirtualFiber, ctx) = virtual_level_size(tns.lvl, ctx)
function virtual_resize!(tns::AbstractVirtualFiber, ctx, dims...)
    tns.lvl = virtual_level_resize!(tns.lvl, ctx, dims...)
    (tns, nodim)
end
virtual_eltype(tns::AbstractVirtualFiber) = virtual_level_eltype(tns.lvl)
virtual_elaxis(tns::AbstractVirtualFiber) = nodim
virtual_default(tns::AbstractVirtualFiber) = Some(virtual_level_default(tns.lvl))

"""
    default(fbr)

The default for a fiber is the value that each element of the fiber will have
after initialization. This value is most often zero, and defaults to nothing.

See also: [`declare!`](@ref)
"""
function default end

"""
    declare_level!(lvl, ctx, pos, init)

Initialize and thaw all fibers within `lvl`, assuming positions `1:pos` were
previously assembled and frozen. The resulting level has no assembled positions.
"""
function declare_level! end

"""
    assemble_level!(lvl, ctx, pos, new_pos)

Assemble and positions `pos+1:new_pos` in `lvl`, assuming positions `1:pos` were
previously assembled.
"""
function assemble_level! end

"""
    reassemble_level!(lvl, ctx, pos_start, pos_end) 

Set the previously assempled positions from `pos_start` to `pos_end` to
`level_default(lvl)`.
"""
function reassemble_level! end

"""
    freeze_level!(lvl, ctx, pos) 

Freeze all fibers in `lvl`. Positions `1:pos` need freezing.
"""
freeze_level!(fbr, ctx, mode) = fbr.lvl

function declare!(fbr::VirtualFiber, ctx::LowerJulia, init)
    lvl = declare_level!(fbr.lvl, ctx, literal(1), init)
    push!(ctx.preamble, assemble_level!(lvl, ctx, literal(1), literal(1))) #TODO this feels unnecessary?
    fbr = VirtualFiber(lvl)
end

function get_reader(fbr::VirtualFiber, ctx::LowerJulia, protos...)
    return get_reader(VirtualSubFiber(fbr.lvl, literal(1)), ctx, reverse(protos)...)
end

function get_updater(fbr::VirtualFiber, ctx::LowerJulia, protos...)
    return get_updater(VirtualSubFiber(fbr.lvl, literal(1)), ctx, reverse(protos)...)
end

struct TrackedSubFiber{Lvl, Pos, Dirty} <: AbstractFiber{Lvl}
    lvl::Lvl
    pos::Pos
    dirty::Dirty
end

mutable struct VirtualTrackedSubFiber{Lvl}
    lvl::Lvl
    pos
    dirty
end
function virtualize(ex, ::Type{<:TrackedSubFiber{Lvl, Pos, Dirty}}, ctx, tag=ctx.freshen(:tns)) where {Lvl, Pos, Dirty}
    lvl = virtualize(:($ex.lvl), Lvl, ctx, Symbol(tag, :_lvl))
    pos = virtualize(:($ex.pos), Pos, ctx)
    dirty = virtualize(:($ex.dirty), Dirty, ctx)
    VirtualTrackedSubFiber(lvl, pos, dirty)
end
(ctx::Finch.LowerJulia)(fbr::VirtualTrackedSubFiber) = :(TrackedSubFiber($(ctx(fbr.lvl)), $(ctx(fbr.pos))))
FinchNotation.isliteral(::VirtualTrackedSubFiber) = false

function get_updater(fbr::VirtualTrackedSubFiber, ctx, protos...)
    Thunk(
        preamble = quote
            $(fbr.dirty) = true
        end,
        body = get_updater(VirtualSubFiber(fbr.lvl, fbr.pos))
    )
end

"""
    redefault!(fbr, init)

Return a fiber which is equal to `fbr`, but with the default (implicit) value
set to `init`.  May reuse memory and render the original fiber unusable when
modified.

```jldoctest
julia> A = @fiber(sl(e(0.0), 10), [2.0, 0.0, 3.0, 0.0, 4.0, 0.0, 5.0, 0.0, 6.0, 0.0])
SparseList (0.0) [1:10]
├─[1]: 2.0
├─[3]: 3.0
├─[5]: 4.0
├─[7]: 5.0
├─[9]: 6.0

julia> redefault!(A, Inf)
SparseList (Inf) [1:10]
├─[1]: 2.0
├─[3]: 3.0
├─[5]: 4.0
├─[7]: 5.0
├─[9]: 6.0
```
"""
redefault!(fbr::Fiber, init) = Fiber(redefault!(fbr.lvl, init))
redefault!(fbr::SubFiber, init) = SubFiber(redefault!(fbr.lvl, init), fbr.pos)


data_rep(fbr::Fiber) = data_rep(typeof(fbr))
data_rep(::Type{<:AbstractFiber{Lvl}}) where {Lvl} = data_rep_level(Lvl)


function freeze!(fbr::VirtualFiber, ctx::LowerJulia)
    return VirtualFiber(freeze_level!(fbr.lvl, ctx, literal(1)))
end

thaw_level!(lvl, ctx, pos) = throw(FormatLimitation("cannot modify $(typeof(lvl)) in place (forgot to declare with .= ?)"))
function thaw!(fbr::VirtualFiber, ctx::LowerJulia)
    return VirtualFiber(thaw_level!(fbr.lvl, ctx, literal(1)))
end

function trim!(fbr::VirtualFiber, ctx)
    VirtualFiber(trim_level!(fbr.lvl, ctx, literal(1)))
end


get_furl_root(idx) = nothing
function get_furl_root(idx::FinchNode)
    if idx.kind === index
        return idx
    elseif idx.kind === access && idx.tns.kind === virtual
        get_furl_root_access(idx, idx.tns.val)
    elseif idx.kind === protocol
        return get_furl_root(idx.idx)
    else
        return nothing
    end
end
get_furl_root_access(idx, tns) = nothing
#These are also good examples of where modifiers might be great.

supports_reassembly(lvl) = false

function Base.show(io::IO, fbr::Fiber)
    print(io, "Fiber(", fbr.lvl, ")")
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::Fiber)
    if get(io, :compact, false)
        print(io, "@fiber($(summary_f_code(fbr.lvl)))")
    else
        display_fiber(io, mime, fbr, 0)
    end
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::VirtualFiber)
    if get(io, :compact, false)
        print(io, "VirtualFiber($(summary_f_code(fbr.lvl)))")
    else
        show(io, fbr)
    end
end

function Base.show(io::IO, fbr::SubFiber)
    print(io, "SubFiber(", fbr.lvl, ", ", fbr.pos, ")")
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::SubFiber)
    if get(io, :compact, false)
        print(io, "SubFiber($(summary_f_code(fbr.lvl)), $(fbr.pos))")
    else
        display_fiber(io, mime, fbr, 0)
    end
end

function Base.show(io::IO, mime::MIME"text/plain", fbr::VirtualSubFiber)
    if get(io, :compact, false)
        print(io, "VirtualSubFiber($(summary_f_code(fbr.lvl)))")
    else
        show(io, fbr)
    end
end

(fbr::Fiber)(idx...) = SubFiber(fbr.lvl, 1)(idx...)

display_fiber(io::IO, mime::MIME"text/plain", fbr::Fiber, depth) = display_fiber(io, mime, SubFiber(fbr.lvl, 1), depth)
function display_fiber_data(io::IO, mime::MIME"text/plain", fbr, depth, N, crds, print_coord, get_fbr)
    function helper(crd)
        println(io)
        print(io, "│ " ^ depth, "├─"^N, "[", ":,"^(ndims(fbr) - N))
        print_coord(io, crd)
        print(io, "]: ")
        display_fiber(io, mime, get_fbr(crd), depth + N)
    end
    cap = 2
    if length(crds) > 2cap + 1
        foreach(helper, crds[1:cap])
        println(io)
        print(io, "│ " ^ depth, "│ ⋮")
        foreach(helper, crds[end - cap + 1:end])
    else
        foreach(helper, crds)
    end
end
display_fiber(io::IO, mime::MIME"text/plain", fbr, depth) = show(io, mime, fbr)

function f_decode(ex)
    if ex isa Expr && ex.head == :$
        return esc(ex.args[1])
    elseif ex isa Expr
        return Expr(ex.head, map(f_decode, ex.args)...)
    elseif ex isa Symbol
        return :(@something($f_code($(Val(ex))), Some($(esc(ex)))))
    else
        return esc(ex)
    end
end

"""
    @fiber ctr [arg]

Construct a fiber using abbreviated level constructor names. To override
abbreviations, expressions may be interpolated with `\$`. For example,
`Fiber(DenseLevel(SparseListLevel(Element(0.0))))` can also be constructed as
`@fiber(sl(d(e(0.0))))`. Consult the documentation for the helper function
[f_code](@ref) for a full listing of level format codes.

Optionally, an argument may be specified to copy into the fiber. This expression
allocates. Use `fiber(arg)` for a zero-cost copy, if available.
"""
macro fiber(ex)
    return :($Fiber!($(f_decode(ex))))
end

macro fiber(ex, arg)
    return :($dropdefaults!($Fiber!($(f_decode(ex))), $(esc(arg))))
end

push!(registry, (algebra) -> quote
    @generated function Fiber!(lvl)
        contain(LowerJulia()) do ctx
            lvl = virtualize(:lvl, lvl, ctx)
            lvl = resolve(lvl, ctx)
            lvl = declare_level!(lvl, ctx, literal(0), literal(virtual_level_default(lvl)))
            push!(ctx.preamble, assemble_level!(lvl, ctx, literal(1), literal(1)))
            lvl = freeze_level!(lvl, ctx, literal(1))
            :(Fiber($(ctx(lvl))))
        end |> lower_caches |> lower_cleanup
    end
end)

@inline f_code(@nospecialize ::Any) = nothing

Base.summary(fbr::Fiber) = "$(join(size(fbr), "×")) @fiber($(summary_f_code(fbr.lvl)))"
Base.summary(fbr::SubFiber) = "$(join(size(fbr), "×")) SubFiber($(summary_f_code(fbr.lvl)))"

Base.similar(fbr::AbstractFiber) = Fiber(similar_level(fbr.lvl))
Base.similar(fbr::AbstractFiber, dims::Tuple) = Fiber(similar_level(fbr.lvl, dims...))

function base_rules(alg, ctx::LowerJulia, a, tns::VirtualFiber)
    return [
        #=
        (@rule loop(~i, assign(access(~a, ~m), $(literal(+)), ~b::isliteral)) =>
            assign(access(a, m), +, call(*, b, extent(ctx.dims[i])))
        ),

        (@rule loop(~i, sequence(~s1::ortho(a)..., assign(access(~a, ~m), $(literal(+)), ~b::isliteral), ~s2::ortho(a)...)) =>
            sequence(assign(access(a, m), +, call(*, b, extent(ctx.dims[i]))), loop(i, sequence(s1..., s2...)))
        ),
        (@rule loop(~i, assign(access(~a, ~m), ~f::isidempotent(alg), ~b::isliteral)) =>
            assign(access(a, m), f, b)
        ),
        (@rule loop(~i, sequence(~s1::ortho(a)..., assign(access(~a, ~m), ~f::isidempotent(alg), ~b::isliteral), ~s2::ortho(a)...)) =>
            sequence(assign(access(a, m), f, b), loop(i, sequence(s1..., s2...)))
        ),
        (@rule sequence(~s1..., assign(access(a, ~m), ~f::isabelian(alg), ~b), ~s2::ortho(a)..., assign(access(a, ~m), ~f, ~c), ~s3...) =>
            sequence(s1..., assign(access(a, m), f, call(f, b, c)))
        ),
        =#

        (@rule sequence(~s1..., declare(a, ~z), ~s2::ortho(a)..., freeze(a), ~s3...) =>
            sequence(s1..., s2..., declare(a, z), freeze(a), s3...)
        ),
        (@rule sequence(~s1..., declare(a, ~z), freeze(a), ~s2::ortho(a)..., ~s3, ~s4...) =>
            if (s3 = Postwalk(@rule access(a, reader(), ~i...) => z)(s3)) !== nothing
                sequence(s1..., declare(a, ~z), freeze(a), s2..., s3, s4...)
            end
        ),
        (@rule sequence(~s1..., thaw(a, ~z), ~s2::ortho(a)..., freeze(a), ~s3...) =>
            sequence(s1..., s2..., s3...)
        ),
        #=
        (@rule sequence(~s1..., declare(a, ~z), ~s2..., freeze(a), ~s3::ortho(a)...) =>
            sequence(s1..., s2..., s3...)
        ),
        =#
    ]
end