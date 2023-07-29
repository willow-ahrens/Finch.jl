abstract type AbstractLevel end
abstract type AbstractVirtualLevel end

is_laminable_updater(lvl::AbstractVirtualLevel, ctx, ::Union{::typeof(defaultread), ::typeof(walk), ::typeof(gallop), ::typeof(follow), typeof(defaultupdate), typeof(laminate), typeof(extrude)}, protos...) = false

is_laminable_updater(lvl::AbstractVirtualLevel, ctx) = false


is_concurrent(lvl::AbstractVirtualLevel, ctx, ::Union{::typeof(defaultread), ::typeof(walk), ::typeof(gallop), ::typeof(follow), typeof(defaultupdate), typeof(laminate), typeof(extrude)}, protos...) = false

is_concurrent(lvl::AbstractVirtualLevel, ctx) = false


# supports_reassembly(lvl::AbstractVirtualLevel) = false
