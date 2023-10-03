abstract type AbstractLevel end
abstract type AbstractVirtualLevel end

#is_laminable_updater(lvl::AbstractVirtualLevel, ctx, ::Union{::typeof(defaultread), ::typeof(walk), ::typeof(gallop), ::typeof(follow), typeof(defaultupdate), typeof(laminate), typeof(extrude)}, protos...) = false

#is_laminable_updater(lvl::AbstractVirtualLevel, ctx) = false



#is_level_concurrent(lvl::AbstractVirtualLevel, ctx) = true

#is_level_injective(lvl::AbstractVirtualLevel, ctx) = false




# supports_reassembly(lvl::AbstractVirtualLevel) = false
"""
    level_ndims(::Type{Lvl})

The result of `level_ndims(Lvl)` defines [ndims](https://docs.julialang.org/en/v1/base/arrays/#Base.ndims) for all subfibers
in a level of type `Lvl`.
"""
function level_ndims end

"""
    level_size(lvl)

The result of `level_size(lvl)` defines the [size](https://docs.julialang.org/en/v1/base/arrays/#Base.size) of all subfibers in the
level `lvl`.
"""
function level_size end

"""
    level_axes(lvl)

The result of `level_axes(lvl)` defines the [axes](https://docs.julialang.org/en/v1/base/arrays/#Base.axes-Tuple{Any}) of all subfibers in the
level `lvl`.
"""
function level_axes end

"""
    level_eltype(::Type{Lvl})

The result of `level_eltype(Lvl)` defines
[`eltype`](https://docs.julialang.org/en/v1/base/collections/#Base.eltype) for
all subfibers in a level of type `Lvl`.
"""
function level_eltype end

"""
    level_default(::Type{Lvl})

The result of `level_default(Lvl)` defines [`default`](@ref) for all subfibers in a
level of type `Lvl`.
"""
function level_default end

"""
    declare_level!(lvl, ctx, pos, init)

Initialize and thaw all fibers within `lvl`, assuming positions `1:pos` were
previously assembled and frozen. The resulting level has no assembled positions.
"""
function declare_level! end

"""
    freeze_level!(lvl, ctx, pos, init)

"""
function freeze_level! end


"""
    thaw_level!(lvl, ctx, pos, init)

"""
function thaw_level! end


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

"""
    memtype(fbr)

The memory type of a fiber or a level. This is the vector type used to store arrays.
"""
function memtype(::Type{<:Fiber{Lvl}}) where {Lvl}
    memtype(Lvl)
end

"""
    postype(lvl)
Return a position type with the same flavor as those used to store the positions of the fibers contained in `lvl`.
The name position descends from the pos or position or pointer arrays found in many definitions of CSR or CSC.
In Finch, positions should be data used to access either a subfiber or some other similar auxiliary data. Thus,
we often end up iterating over positions.
"""
function postype end
