using Finch
using Test
using MacroTools

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Cases, Stepper, AcceptRun, AcceptSpike, Thunk
using Finch: @i, @index_program_instance, execute, execute_code_lowered
using Finch: getname, Virtual

@testset "Finch.jl" begin

    include("test_ssa.jl")
    include("fibers.jl")
    include("parse.jl")
    include("simplevectors.jl")

end