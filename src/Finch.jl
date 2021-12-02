module Finch

using Pigeon
using Pigeon: Dimensions, dimensionalize!, DefaultStyle, getname
using Pigeon: visit!
using SymbolicUtils
using SymbolicUtils: istree, arguments, operation, similarterm
using SymbolicUtils: Postwalk, Prewalk
using TermInterface
using MacroTools
using DataStructures

using Pigeon: Read, Write, Update

export Virtual, Scalar, Chunk
export lower_julia

include("lower.jl")
include("virtuals.jl")
include("chunks.jl")
include("runs.jl")
include("spikes.jl")

end