using MatrixDepot
using Finch
using BenchmarkTools
using SparseArrays
using LinearAlgebra
using Cthulhu
using Profile

function triangle(mtx)
    @info "triangle" mtx
    A_ref = SparseMatrixCSC(mdopen(mtx).A)
    (m, n) = size(A_ref)
    A = Finch.Fiber(
        Dense(m,
        SparseList(n, A_ref.colptr, A_ref.rowval,
        Element{0.0, Float64}(A_ref.nzval))))

    C = Finch.Fiber(
        Element{0.0, Float64}(zeros(1)))

    #@finch @loop i j k C[] += A[i, k::gallop] * A2[i, j] * A3[j, k::gallop]
    #println(C())
    #@finch @loop i j k C[] += A[i, k] * A2[i, j] * A3[j, k]
    #println(C())
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

triangle("Boeing/ct20stif")
triangle("SNAP/web-NotreDame")
triangle("SNAP/roadNet-PA")
triangle("VDOL/spaceStation_5")
triangle("DIMACS10/sd2010")
triangle("Bai/bfwb398")
triangle("SNAP/soc-Epinions1")
triangle("SNAP/email-EuAll")
triangle("SNAP/wiki-Talk")
#triangle("SNAP/web-BerkStan")