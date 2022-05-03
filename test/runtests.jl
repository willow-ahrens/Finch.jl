using Finch
using Test
using MacroTools

include("matrices.jl")

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Cases, Stepper, Jumper, AcceptRun, AcceptSpike, Thunk, Phase, Pipeline, Leaf, Simplify
using Finch: @i, @index_program_instance, execute, execute_code_lowered, start, stop
using Finch: getname, Virtual

@testset "Finch.jl" begin
    #include("test_ssa.jl")
    #include("parse.jl")
    #include("fibers.jl")
    #include("simplevectors.jl")
    include("kernels.jl")
end