using Test
using ArgParse

s = ArgParseSettings("Run Finch.jl tests. All tests are run by default. Specific
test suites may be specified as positional arguments. Finch compares to
reference output which depends on the system word size (currently
$(Sys.WORD_SIZE)-bit). To overwrite $(Sys.WORD_SIZE==32 ? 64 : 32)-bit output,
run this with a $(Sys.WORD_SIZE==32 ? 64 : 32)-bit julia executable.")

@add_arg_table! s begin
    "--overwrite", "-w"
        action = :store_true
        help = "overwrite reference output for $(Sys.WORD_SIZE)-bit systems"
    "suites"
        nargs = '*'
        default = ["all"]
        help = "names of test suites to run"
end
parsed_args = parse_args(ARGS, s)

"""
    check_output(fname, arg)

Compare the output of `println(arg)` with standard reference output, stored
in a file named `fname`. Call `julia runtests.jl --help` for more information on
how to overwrite the reference output.
"""
function check_output(fname, arg)
    global parsed_args
    ref_dir = joinpath(@__DIR__, "reference$(Sys.WORD_SIZE)")
    ref_file = joinpath(ref_dir, fname)
    if parsed_args["overwrite"]
        mkpath(ref_dir)
        open(ref_file, "w") do f
            println(f, arg)
        end
        true
    else
        reference = read(ref_file, String)
        result = sprint(println, arg)
        if reference == result
            return true
        else
            @debug "disagreement with reference output" reference result
            return false
        end
    end
end

function should_run(name)
    global parsed_args
    return ("all" in parsed_args["suites"] || name in parsed_args["suites"])
end

using Finch

include("data_matrices.jl")

include("utils.jl")

@testset "Finch.jl" begin
    if should_run("print") include("test_print.jl") end
    if should_run("representation") include("test_representation.jl") end
    if should_run("constructors") include("test_constructors.jl") end
    if should_run("conversions") include("test_conversions.jl") end
    if should_run("merges") include("test_merges.jl") end
    if should_run("algebra") include("test_algebra.jl") end
    if should_run("permit") include("test_permit.jl") end
    if should_run("skips") include("test_skips.jl") end
    #if should_run("fibers") include("test_fibers.jl") end # maybe we should make a replacement but I think this file is very out of date.
    if should_run("kernels") include("test_kernels.jl") end
    if should_run("issues") include("test_issues.jl") end
    if should_run("meta") include("test_meta.jl") end
    if should_run("embed") include("embed/test_embed.jl") end
end