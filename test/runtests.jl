using Finch
using Pigeon
using Test
using MacroTools

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Cases, Stream, AcceptRun, AcceptSpike, Thunk

@testset "Finch.jl" begin

    include("parse.jl")
    include("simplevectors.jl")

end