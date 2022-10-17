using Pkg
tempdir = mktempdir()
Pkg.activate(tempdir)
Pkg.develop(PackageSpec(path = joinpath(@__DIR__, "..")))
Pkg.add(["BenchmarkTools", "PkgBenchmark", "MatrixDepot"])
Pkg.resolve()

using Finch
using BenchmarkTools

const SUITE = BenchmarkGroup()

#=
SUITE["compile"] = BenchmarkGroup()

code = """
using Finch
y = @fiber d(e(0.0))
A = @fiber d(sl(e(0.0)))
x = @fiber sl(e(0.0))

@finch @loop i j y[i] += A[i, j] * x[i]
"""
cmd = pipeline(`$(Base.julia_cmd()) --project=$(Base.active_project()) --eval $code`, stdout = IOBuffer())

SUITE["compile"]["time_to_first_SpMV"] = @benchmarkable run($cmd)

let
    y = @fiber d(e(0.0))
    A = @fiber d(sl(e(0.0)))
    x = @fiber sl(e(0.0))

    SUITE["compile"]["compile_SpMV"] = @benchmarkable begin
        y, A, x = ($y, $A, $x)
        Finch.execute_code(:ex, typeof(Finch.@finch_program_instance @loop i j y[i] += A[i, j] * x[i]))
    end
end

code = """
using Finch
A = @fiber d(sl(e(0.0)))
B = @fiber d(sl(e(0.0)))
C = @fiber d(sl(e(0.0)))

@finch @loop i j k C[i, j] += A[i, k] * B[j, k]
"""
cmd = pipeline(`$(Base.julia_cmd()) --project=$(Base.active_project()) --eval $code`, stdout = IOBuffer())

SUITE["compile"]["time_to_first_SpGeMM"] = @benchmarkable run(cmd)

let
    A = @fiber d(sl(e(0.0)))
    B = @fiber d(sl(e(0.0)))
    C = @fiber d(sl(e(0.0)))

    SUITE["compile"]["compile_SpGeMM"] = @benchmarkable begin   
        A, B, C = ($A, $B, $C)
        Finch.execute_code(:ex, typeof(Finch.@finch_program_instance @loop i j k C[i, j] += A[i, k] * B[j, k]))
    end
end
=#

SUITE["embed"] = BenchmarkGroup()

f() = 1
function mysample((), params::BenchmarkTools.Parameters)
    evals = params.evals
    start_time = time_ns()
    return_val = f()
    for _ in 2:evals
        f()
    end
    stop_time = time_ns()
    sample_time = stop_time - start_time
    time = max((sample_time / evals) - params.overhead, 0.001)
    gctime = 0
    memory = 0
    return time, gctime, 0, 0, return_val
end
SUITE["embed"]["test"] = BenchmarkTools.Benchmark(mysample, (), BenchmarkTools.Parameters())

Base.Libc.Libdl.dlopen(joinpath(@__DIR__, "libembedbenchmarks.so"))

println(ccall((:hello, "libembedbenchmarks.so"), Cint, (Cint,), 1))

foreach(((k, v),) -> BenchmarkTools.warmup(v), SUITE)