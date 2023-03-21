using Pkg
#tempdir = mktempdir()
#Pkg.activate(tempdir)
#Pkg.develop(PackageSpec(path = joinpath(@__DIR__, "..")))
#Pkg.add(["BenchmarkTools", "PkgBenchmark", "MatrixDepot"])
#Pkg.resolve()

using Finch
using BenchmarkTools
using MatrixDepot
using SparseArrays

SUITE = BenchmarkGroup()

SUITE["compile"] = BenchmarkGroup()

code = """
using Finch
A = @fiber d(sl(e(0.0)))
B = @fiber d(sl(e(0.0)))
C = @fiber d(sl(e(0.0)))

@finch (C .= 0; @loop i j k C[j, i] += A[k, i] * B[k, i])
"""
cmd = pipeline(`$(Base.julia_cmd()) --project=$(Base.active_project()) --eval $code`, stdout = IOBuffer())

SUITE["compile"]["time_to_first_SpGeMM"] = @benchmarkable run(cmd)

let
    A = @fiber d(sl(e(0.0)))
    B = @fiber d(sl(e(0.0)))
    C = @fiber d(sl(e(0.0)))

    SUITE["compile"]["compile_SpGeMM"] = @benchmarkable begin   
        A, B, C = ($A, $B, $C)
        Finch.execute_code(:ex, typeof(Finch.@finch_program_instance (C .= 0; @loop i j k C[j, i] += A[k, i] * B[k, j])))
    end
end

SUITE["embed"] = BenchmarkGroup()

libembedbenchmarks_file = joinpath(@__DIR__, "libembedbenchmarks.so")
if isfile(libembedbenchmarks_file)
    Base.Libc.Libdl.dlopen(libembedbenchmarks_file)

    ccall((:benchmarks_initialize, "libembedbenchmarks.so"), Cvoid, ())

    function sample_spmv_tiny((), params::BenchmarkTools.Parameters)
        evals = params.evals
        sample_time = ccall((:benchmark_spmv_tiny, "libembedbenchmarks.so"), Clong, (Cint,), evals)
        time = max((sample_time / evals) - params.overhead, 0.001)
        gctime = memory = allocs = return_val = 0
        return time, gctime, memory, allocs, return_val
    end

    SUITE["embed"]["spmv_tiny"] = BenchmarkTools.Benchmark(sample_spmv_tiny, (), BenchmarkTools.Parameters())

    #TODO how to call this at the right time?
    #println(ccall((:benchmarks_finalize, "libembedbenchmarks.so"), Cvoid, ()))
end

SUITE["graphs"] = BenchmarkGroup()

function pagerank(edges; nsteps=20, damp = 0.85)
    (n, m) = size(edges)
    @assert n == m
    out_degree = @fiber d(e(0))
    @finch (out_degree .= 0; @loop j i out_degree[j] += edges[i, j])
    scaled_edges = @fiber d(sl(e(0.0)))
    @finch (scaled_edges .= 0; @loop j i scaled_edges[i, j] = ifelse(out_degree[i] != 0, edges[i, j] / out_degree[j], 0))
    r = @fiber d(e(0.0), n)
    @finch (r .= 0; @loop j r[j] = 1.0/n)
    rank = @fiber d(e(0.0), n)
    beta_score = (1 - damp)/n

    for step = 1:nsteps
        @finch (rank .= 0; @loop j i rank[i] += scaled_edges[i, j] * r[j])
        @finch (r .= 0; @loop i r[i] = beta_score + damp * rank[i])
    end
    return r
end

SUITE["graphs"]["pagerank"] = BenchmarkGroup()
for mtx in ["SNAP/soc-Epinions1", "SNAP/soc-LiveJournal1"]
    SUITE["graphs"]["pagerank"][mtx] = @benchmarkable pagerank($(fiber(SparseMatrixCSC(matrixdepot(mtx))))) 
end

function bfs(edges, source=5)
    (n, m) = size(edges)
    edges = pattern!(edges)

    @assert n == m
    F = @fiber sbm(p(), n)
    _F = @fiber sbm(p(), n)
    @finch F[source] = true

    V = @fiber d(e(false), n)
    @finch V[source] = true

    P = @fiber d(e(0), n)
    @finch P[source] = source

    v = Scalar(false)

    while countstored(F) > 0
        @finch begin
            _F .= false
            @loop j k begin
                v .= false
                v[] = F[j] && edges[k, j] && !(V[k])
                if v[]
                    _F[k] |= true
                    P[k] <<choose(0)>>= j #Only set the parent for this vertex
                end
            end
        end
        @finch @loop k V[k] |= _F[k]
        (F, _F) = (_F, F)
    end
    return F
end

SUITE["graphs"]["bfs"] = BenchmarkGroup()
for mtx in ["SNAP/soc-Epinions1", "SNAP/soc-LiveJournal1"]
    SUITE["graphs"]["bfs"][mtx] = @benchmarkable bfs($(fiber(SparseMatrixCSC(matrixdepot(mtx))))) 
end

SUITE["matrices"] = BenchmarkGroup()

function spgemm_inner(A, B)
    C = @fiber d(sl(e(0.0)))
    w = @fiber sh{2}(e(0.0))
    AT = @fiber d(sl(e(0.0)))
    @finch @loop k i w[k, i] = A[i, k]
    @finch (AT .= 0; @loop i k AT[k, i] = w[k, i])
    @finch (C .= 0; @loop j i k C[i, j] += AT[k, i] * B[k, j])
    return C
end

SUITE["matrices"]["ATA_spgemm_inner"] = BenchmarkGroup()
for mtx in []#"SNAP/soc-Epinions1", "SNAP/soc-LiveJournal1"]
    A = fiber(permutedims(SparseMatrixCSC(matrixdepot(mtx))))
    SUITE["matrices"]["ATA_spgemm_inner"][mtx] = @benchmarkable spgemm_inner($A, $A) 
end

function spgemm_gustavsons(A, B)
    C = @fiber d(sl(e(0.0)))
    w = @fiber sbm(e(0.0))
    @finch begin
        C .= 0
        @loop j begin
            w .= 0
            @loop k i w[i] += A[i, k] * B[k, j]
            @loop i C[i, j] = w[i]
        end
    end
    return C
end

SUITE["matrices"]["ATA_spgemm_gustavsons"] = BenchmarkGroup()
for mtx in ["SNAP/soc-Epinions1"]#], "SNAP/soc-LiveJournal1"]
    A = fiber(SparseMatrixCSC(matrixdepot(mtx)))
    SUITE["matrices"]["ATA_spgemm_gustavsons"][mtx] = @benchmarkable spgemm_gustavsons($A, $A) 
end

function spgemm_outer(A, B)
    C = @fiber d(sl(e(0.0)))
    w = @fiber sh{2}(e(0.0))
    BT = @fiber d(sl(e(0.0)))
    @finch (w .= 0; @loop j k w[j, k] = B[k, j])
    @finch (BT .= 0; @loop k j BT[j, k] = w[j, k])
    @finch (w .= 0; @loop k i j w[i, j] += A[i, k] * BT[j, k])
    @finch (C .= 0; @loop j i C[i, j] = w[i, j])
    return C
end

SUITE["matrices"]["ATA_spgemm_outer"] = BenchmarkGroup()
for mtx in ["SNAP/soc-Epinions1"]#, "SNAP/soc-LiveJournal1"]
    A = fiber(SparseMatrixCSC(matrixdepot(mtx)))
    SUITE["matrices"]["ATA_spgemm_outer"][mtx] = @benchmarkable spgemm_outer($A, $A) 
end

SUITE["indices"] = BenchmarkGroup()

function spmv32(A, x)
    y = @fiber d{Int32}(e(0.0))
    @finch (y .= 0; @loop i j y[i] += A[j, i] * x[j])
    return y
end

SUITE["indices"]["SpMV_32"] = BenchmarkGroup()
for mtx in ["SNAP/soc-Epinions1"]#, "SNAP/soc-LiveJournal1"]
    A = fiber(SparseMatrixCSC(matrixdepot(mtx)))
    A = copyto!(@fiber(d{Int32}(sl{Int32, Int32}(e(0.0)))), A)
    x = copyto!(@fiber(d{Int32}(e(0.0))), rand(size(A)[2]))
    SUITE["indices"]["SpMV_32"][mtx] = @benchmarkable spmv32($A, $x) 
end

function spmv64(A, x)
    y = @fiber d{Int64}(e(0.0))
    @finch (y .= 0; @loop i j y[i] += A[j, i] * x[j])
    return y
end

SUITE["indices"]["SpMV_64"] = BenchmarkGroup()
for mtx in ["SNAP/soc-Epinions1"]#, "SNAP/soc-LiveJournal1"]
    A = fiber(SparseMatrixCSC(matrixdepot(mtx)))
    A = copyto!(@fiber(d{Int64}(sl{Int64, Int64}(e(0.0)))), A)
    x = copyto!(@fiber(d{Int64}(e(0.0))), rand(size(A)[2]))
    SUITE["indices"]["SpMV_64"][mtx] = @benchmarkable spmv64($A, $x) 
end

foreach(((k, v),) -> BenchmarkTools.warmup(v), SUITE)