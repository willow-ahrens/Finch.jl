using MatrixDepot
using Finch
using BenchmarkTools
using SparseArrays
using LinearAlgebra
using Cthulhu
using Profile

function tri(mtx)
    println("tri: $mtx")
    A_ref = SparseMatrixCSC(mdopen(mtx).A)
    (m, n) = size(A_ref)
    A = Fiber(
        Dense(m,
        SparseList(n, A_ref.colptr, A_ref.rowval,
        Element{0.0, Float64}(A_ref.nzval))))
    C = Fiber(
        Element{0.0, Float64}(zeros(1)))

    #@finch @loop i j k C[] += A[i, k::gallop] * A[i, j] * A[j, k::gallop]
    #println(C[])
    #@finch @loop i j k C[] += A[i, k] * A[i, j] * A[j, k]
    #println(C[])
    #println(sum(A_ref .* (A_ref * A_ref)))
    
    println("Finch:")
    display(@benchmark (A = $A; C = $C; @finch @loop i j k C[] += A[i, k] * A[i, j] * A[j, k]))
    #println()

    println("Finch(gallop):")
    display(@benchmark (A = $A; C = $C; @finch @loop i j k C[] += A[i, k::gallop] * A[i, j] * A[j, k::gallop]))
    #println()

    #println("Julia:")
    #display(@benchmark sum($A_ref .* ($A_ref * $(transpose(A_ref)))))
    println()
end

tri("Boeing/ct20stif")
tri("SNAP/web-NotreDame")
tri("SNAP/roadNet-PA")
tri("VDOL/spaceStation_5")
tri("DIMACS10/sd2010")
tri("Bai/bfwb398")
tri("SNAP/soc-Epinions1")
tri("SNAP/email-EuAll")
tri("SNAP/wiki-Talk")
#tri("SNAP/web-BerkStan")
exit()
