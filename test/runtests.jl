using Finch
using Test
using MacroTools

include("data_matrices.jl")

function diff(name, body)
    global ARGS
    "diff" in ARGS || return true
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
        if success(`diff --strip-trailing-cr $cache_file $temp_file`)
            return true
        else
            if "verbose" in ARGS
                println("=== reference ===")
                open(cache_file, "r") do f
                    for line in eachline(f)
                        println(line)
                    end
                end
                println("=== test ===")
                println(body)
            end
            return false
        end
    end
end

reference_getindex(arr, inds...) = getindex(arr, inds...)
reference_getindex(arr::Fiber, inds...) = arr(inds...)

function reference_isequal(a,b)
    size(a) == size(b) || return false
    axes(a) == axes(b) || return false
    for i in Base.product(axes(a)...)
        reference_getindex(a, i...) == reference_getindex(b, i...) || return false
    end
    return true
end

using Finch: VirtualAbstractArray, Run, Spike, Extent, Scalar, Switch, Stepper, Jumper, Step, Jump, AcceptRun, AcceptSpike, Thunk, Phase, Pipeline, Lookup, Simplify, Shift
using Finch: @f, @finch_program_instance, execute, execute_code, getstart, getstop
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
    include("test_issues.jl")
    include("test_simple.jl")
    include("test_kernels.jl")
    include("test_print.jl")
end