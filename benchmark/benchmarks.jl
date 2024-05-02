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

include(joinpath(@__DIR__, "../docs/examples/bfs.jl"))
include(joinpath(@__DIR__, "../docs/examples/pagerank.jl"))
include(joinpath(@__DIR__, "../docs/examples/shortest_paths.jl"))
include(joinpath(@__DIR__, "../docs/examples/spgemm.jl"))
include(joinpath(@__DIR__, "../docs/examples/triangle_counting.jl"))

SUITE = BenchmarkGroup()

SUITE["high-level"] = BenchmarkGroup()

let
    k = Ref(0.0)
    x = rand(1)
    y = rand(1)
    SUITE["high-level"]["compile_spmv"] = @benchmarkable(
        begin
            A, x, y = (A, $x, $y)
            @einsum y[i] += A[i, j] * x[j]
        end,
        setup = (A = Tensor(Dense(SparseList(Element($k[] += 1))), fsprand(1, 1, 1)))
    )
end

let
    A = Tensor(Dense(SparseList(Element(0.0))), fsprand(1, 1, 1))
    x = rand(1)
    y = lazy(rand(1))
    res = @einsum y[i] += A[i, j] * x[j]
    compute(res, Finch.FinchCompiler)
end

let
    A = Tensor(Dense(SparseList(Element(0.0))), fsprand(1, 1, 1))
    x = rand(1)
    y = rand(1)
    SUITE["high-level"]["run_spmv"] = @benchmarkable(
        begin
            A, x, y = ($A, $x, $y)
            @einsum y[i] += A[i, j] * x[j]
        end,
    )
end

eval(let
    A = Tensor(Dense(SparseList(Element(0.0))), fsprand(1, 1, 1))
    x = rand(1)
    y = rand(1)
    @finch_kernel function spmv(y, A, x)
        for j=_, i=_
            y[i] += A[i, j] * x[j]
        end
    end
end)

let
    (m, n, nnz) = (1000, 1000, 20_000)
    A = Tensor(Dense(SparseList(Element(0.0))), fsprand(m, n, nnz))
    x = rand(n)
    y = rand(m)
    SUITE["high-level"]["run_baremetal_filled"] = @benchmarkable(
        begin
            A, x, y = ($A, $x, $y)
            spmv(y, A, x)
        end,
        evals = 1000
    )
end

let
    A = Tensor(Dense(SparseList(Element(0.0))), fsprand(1, 1, 1))
    x = rand(1)
    y = rand(1)
    SUITE["high-level"]["run_baremetal"] = @benchmarkable(
        begin
            A, x, y = ($A, $x, $y)
            spmv(y, A, x)
        end,
        evals = 1000
    )
end

SUITE["compile"] = BenchmarkGroup()

code = """
using Finch
A = Tensor(Dense(SparseList(Element(0.0))))
B = Tensor(Dense(SparseList(Element(0.0))))
C = Tensor(Dense(SparseList(Element(0.0))))

@finch (C .= 0; for i=_, j=_, k=_; C[j, i] += A[k, i] * B[k, i] end)
"""
cmd = pipeline(`$(Base.julia_cmd()) --project=$(Base.active_project()) --eval $code`, stdout = IOBuffer())

SUITE["compile"]["time_to_first_SpGeMM"] = @benchmarkable run(cmd)

let
    A = Tensor(Dense(SparseList(Element(0.0))))
    B = Tensor(Dense(SparseList(Element(0.0))))
    C = Tensor(Dense(SparseList(Element(0.0))))

    SUITE["compile"]["compile_SpGeMM"] = @benchmarkable begin   
        A, B, C = ($A, $B, $C)
        Finch.execute_code(:ex, typeof(Finch.@finch_program_instance (C .= 0; for i=_, j=_, k=_; C[j, i] += A[k, i] * B[k, j] end; return C)))
    end
end

let
    A = Tensor(SparseList(SparseList(Element(0.0))))
    c = Scalar(0.0)

    SUITE["compile"]["compile_pretty_triangle"] = @benchmarkable begin   
        A, c = ($A, $c)
        @finch_code (c .= 0; for i=_, j=_, k=_; c[] += A[i, j] * A[j, k] * A[i, k] end; return c)
    end
end

SUITE["graphs"] = BenchmarkGroup()

SUITE["graphs"]["pagerank"] = BenchmarkGroup()
for mtx in ["SNAP/soc-Epinions1", "SNAP/soc-LiveJournal1"]
    SUITE["graphs"]["pagerank"][mtx] = @benchmarkable pagerank($(pattern!(Tensor(SparseMatrixCSC(matrixdepot(mtx)))))) 
end

SUITE["graphs"]["bfs"] = BenchmarkGroup()
for mtx in ["SNAP/soc-Epinions1", "SNAP/soc-LiveJournal1"]
    SUITE["graphs"]["bfs"][mtx] = @benchmarkable bfs($(Tensor(SparseMatrixCSC(matrixdepot(mtx))))) 
end

SUITE["graphs"]["bellmanford"] = BenchmarkGroup()
for mtx in ["Newman/netscience", "SNAP/roadNet-CA"]
    A = redefault!(Tensor(SparseMatrixCSC(matrixdepot(mtx))), Inf)
    SUITE["graphs"]["bellmanford"][mtx] = @benchmarkable bellmanford($A)
end

SUITE["matrices"] = BenchmarkGroup()

SUITE["matrices"]["ATA_spgemm_inner"] = BenchmarkGroup()
for mtx in []#"SNAP/soc-Epinions1", "SNAP/soc-LiveJournal1"]
    A = Tensor(permutedims(SparseMatrixCSC(matrixdepot(mtx))))
    SUITE["matrices"]["ATA_spgemm_inner"][mtx] = @benchmarkable spgemm_inner($A, $A) 
end

SUITE["matrices"]["ATA_spgemm_gustavson"] = BenchmarkGroup()
for mtx in ["SNAP/soc-Epinions1"]#], "SNAP/soc-LiveJournal1"]
    A = Tensor(SparseMatrixCSC(matrixdepot(mtx)))
    SUITE["matrices"]["ATA_spgemm_gustavson"][mtx] = @benchmarkable spgemm_gustavson($A, $A) 
end

SUITE["matrices"]["ATA_spgemm_outer"] = BenchmarkGroup()
for mtx in ["SNAP/soc-Epinions1"]#, "SNAP/soc-LiveJournal1"]
    A = Tensor(SparseMatrixCSC(matrixdepot(mtx)))
    SUITE["matrices"]["ATA_spgemm_outer"][mtx] = @benchmarkable spgemm_outer($A, $A) 
end

SUITE["indices"] = BenchmarkGroup()

function spmv32(A, x)
    y = Tensor(Dense{Int32}(Element{0.0, Float64, Int32}()))
    @finch (y .= 0; for i=_, j=_; y[i] += A[j, i] * x[j] end)
    return y
end

SUITE["indices"]["SpMV_32"] = BenchmarkGroup()
for mtx in ["SNAP/soc-Epinions1"]#, "SNAP/soc-LiveJournal1"]
    A = SparseMatrixCSC(matrixdepot(mtx))
    A = Tensor(Dense{Int32}(SparseList{Int32}(Element{0.0, Float64, Int32}())), A)
    x = Tensor(Dense{Int32}(Element{0.0, Float64, Int32}()), rand(size(A)[2]))
    SUITE["indices"]["SpMV_32"][mtx] = @benchmarkable spmv32($A, $x) 
end

function spmv64(A, x)
    y = Tensor(Dense{Int64}(Element{0.0, Float64, Int64}()))
    @finch (y .= 0; for i=_, j=_; y[i] += A[j, i] * x[j] end)
    return y
end

SUITE["indices"]["SpMV_64"] = BenchmarkGroup()
for mtx in ["SNAP/soc-Epinions1"]#, "SNAP/soc-LiveJournal1"]
    A = SparseMatrixCSC(matrixdepot(mtx))
    A = Tensor(Dense{Int64}(SparseList{Int64}(Element{0.0, Float64, Int64}())), A)
    x = Tensor(Dense{Int64}(Element{0.0, Float64, Int64}()), rand(size(A)[2]))
    SUITE["indices"]["SpMV_64"][mtx] = @benchmarkable spmv64($A, $x) 
end

SUITE = SUITE["high-level"]