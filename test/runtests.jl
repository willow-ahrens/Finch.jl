using Finch
using Test
using MacroTools

include("data_matrices.jl")

function diff(name, body)
    global ARGS
    cache_dir = mkpath(joinpath(@__DIR__, "cache"))
    temp_dir = mkpath(joinpath(@__DIR__, "temp"))
    cache_file = joinpath(cache_dir, name)
    temp_file = joinpath(temp_dir, name)
    open(temp_file, "w") do f
        println(f, body)
    end
    if "overwrite" in ARGS
        open(cache_file, "w") do f
            println(f, body)
        end
        true
    else
        success(`diff $cache_file $temp_file`)
    end
end

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Cases, Stepper, Jumper, Step, Jump, AcceptRun, AcceptSpike, Thunk, Phase, Pipeline, Leaf, Simplify, Shift
using Finch: @i, @index_program_instance, execute, execute_code_lowered, getstart, getstop
using Finch: getname, Virtual

verbose = "verbose" in ARGS

@testset "Finch.jl" begin
    include("test_util.jl")
    include("test_ssa.jl")
    include("test_parse.jl")
    include("test_repeat.jl")
    include("test_permit.jl")
    include("test_skips.jl")
    include("test_fibers.jl")
    include("test_simple.jl")
    include("test_kernels.jl")
    include("test_print.jl")
end