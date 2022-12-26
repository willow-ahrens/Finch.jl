using Finch
using Test
using SyntaxInterface
using Base.Iterators

include("data_matrices.jl")

function diff(name, body)
    global ARGS
    "nodiff" in ARGS && return true
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
using Finch: getname, value
using Finch.IndexNotation
using Finch.IndexNotation: call_instance, assign_instance, access_instance, value_instance, index_instance, loop_instance, with_instance, label_instance, protocol_instance

isstructequal(a, b) = a === b

isstructequal(a::T, b::T) where {T <: Fiber} = 
    isstructequal(a.lvl, b.lvl) &&
    isstructequal(a.env, b.env)

isstructequal(a::T, b::T)  where {T <: Pattern} = true

isstructequal(a::T, b::T) where {T <: Element} =
    a.val == b.val

isstructequal(a::T, b::T) where {T <: RepeatRLE} =
    a.I == b.I &&
    a.pos == b.pos &&
    a.idx == b.idx &&
    a.val == b.val

isstructequal(a::T, b::T) where {T <: Dense} =
    a.I == b.I &&
    isstructequal(a.lvl, b.lvl)

isstructequal(a::T, b::T) where {T <: SparseList} =
    a.I == b.I &&
    a.pos == b.pos &&
    a.idx == b.idx &&
    isstructequal(a.lvl, b.lvl)

isstructequal(a::T, b::T) where {T <: SparseHash} =
    a.I == b.I &&
    a.pos == b.pos &&
    a.tbl == b.tbl &&
    a.srt == b.srt &&
    isstructequal(a.lvl, b.lvl)

isstructequal(a::T, b::T) where {T <: SparseCoo} =
    a.I == b.I &&
    a.pos == b.pos &&
    a.tbl == b.tbl &&
    isstructequal(a.lvl, b.lvl)

isstructequal(a::T, b::T) where {T <: SparseVBL} =
    a.I == b.I &&
    a.pos == b.pos &&
    a.idx == b.idx &&
    a.ofs == b.ofs &&
    isstructequal(a.lvl, b.lvl)

isstructequal(a::T, b::T) where {T <: SparseBytemap} =
    a.I == b.I &&
    a.pos == b.pos &&
    a.tbl == b.tbl &&
    a.srt == b.srt &&
    a.srt_stop[] == b.srt_stop[] &&
    isstructequal(a.lvl, b.lvl)

verbose = "verbose" in ARGS

@testset "Finch.jl" begin
    include("test_util.jl")
    include("test_ssa.jl")
    include("test_print.jl")
    #include("test_parse.jl")
    include("test_merges.jl")
    include("test_constructors.jl")
    include("test_conversions.jl")
    include("test_formats.jl")
    include("test_algebra.jl")
    include("test_repeat.jl")
    include("test_permit.jl")
    include("test_skips.jl")
    include("test_fibers.jl")
    include("test_issues.jl")
    include("test_kernels.jl")
end