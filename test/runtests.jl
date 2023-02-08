using Finch
using Test
using SyntaxInterface
using Base.Iterators
using Finch: SubFiber

include("data_matrices.jl")

include("utils.jl")


using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Switch, Stepper, Jumper, Step, Jump, AcceptRun, AcceptSpike, Thunk, Phase, Pipeline, Lookup, Simplify, Shift
using Finch: @f, @finch_program_instance, execute, execute_code, getstart, getstop
using Finch: getname, value
using Finch.IndexNotation
using Finch.IndexNotation: call_instance, assign_instance, access_instance, value_instance, index_instance, loop_instance, with_instance, variable_instance, protocol_instance



verbose = "verbose" in ARGS

@testset "Finch.jl" begin
    include("test_print.jl")

    include("test_fiber_representation.jl")
    include("test_fiber_constructors.jl")

    include("test_conversions.jl")
    include("test_merges.jl")
    include("test_algebra.jl")
    include("test_repeat.jl")
    include("test_permit.jl")
    include("test_skips.jl")
    include("test_fibers.jl")
    include("test_kernels.jl")
    include("test_issues.jl")
    include("test_meta.jl")
end