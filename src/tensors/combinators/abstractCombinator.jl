abstract type AbstractCombinator end
abstract type AbstractVirtualCombinator <: AbstractVirtualTensor end


is_concurrent(lvl::AbstractVirtualCombinator, ctx) = true

is_injective(lvl::AbstractVirtualCombinator, ctx, accs::Vararg{UInt}) = false
