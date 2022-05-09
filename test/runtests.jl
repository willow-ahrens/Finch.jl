using Finch
using Test
using MacroTools

include("data_matrices.jl")

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Cases, Stepper, Jumper, AcceptRun, AcceptSpike, Thunk, Phase, Pipeline, Leaf, Simplify, Shift
using Finch: @i, @index_program_instance, execute, execute_code_lowered, start, stop
using Finch: getname, Virtual

@testset "Finch.jl" begin
    include("test_ssa.jl")
    include("test_parse.jl")
    include("test_fibers.jl")
    include("test_simple.jl")
    include("test_kernels.jl")
end