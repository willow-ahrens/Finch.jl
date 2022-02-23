using Finch
using Test
using MacroTools

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Cases, Stepper, Jumper, AcceptRun, AcceptSpike, Thunk, Phase, Pipeline, Leaf
using Finch: @i, @index_program_instance, execute, execute_code_lowered, start, stop
using Finch: getname, Virtual

@testset "Finch.jl" begin

    include("test_ssa.jl")
    include("parse.jl")
    include("simplevectors.jl")
    include("fibers.jl")

end