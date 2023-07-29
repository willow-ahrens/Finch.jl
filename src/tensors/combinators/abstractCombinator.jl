abstract type AbstractCombinator end
abstract type AbstractVirtualCombinator end

is_concurrent(lvl::AbstractVirtualCombinator, ctx, ::Union{::typeof(defaultread), ::typeof(walk), ::typeof(gallop), ::typeof(follow), typeof(defaultupdate), typeof(laminate), typeof(extrude)}, protos...) = false

is_concurrent(lvl::AbstractVirtualCombinator, ctx) = false

is_injective(lvl::AbstractVirtualCombinator, ctx, accs::Vararg{UInt}) = false
