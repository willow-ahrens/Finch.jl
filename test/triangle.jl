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
    A = Finch.Fiber(
        Solid(m,
        HollowList(n, A_ref.colptr, A_ref.rowval,
        Element{0.0, Float64}(A_ref.nzval))))
    C = Finch.Fiber(
        Element{0.0, Float64}(zeros(1)))

    #@index @loop i j k C[] += A[i, k::gallop] * A[i, j] * A[j, k::gallop]
    #println(FiberArray(C)[])
    #@index @loop i j k C[] += A[i, k] * A[i, j] * A[j, k]
    #println(FiberArray(C)[])
    #println(sum(A_ref .* (A_ref * A_ref)))
    
    println("Finch:")
    @btime (A = $A; C = $C; @index @loop i j k C[] += A[i, k] * A[i, j] * A[j, k])

    println("foo:")
    @btime (A = $A; C = $C; $foo(Finch.@index_program_instance @loop i j k C[] += A[i, k] * A[i, j] * A[j, k]))

    println("Finch(gallop):")
    @btime (A = $A; C = $C; @index @loop i j k C[] += A[i, k::gallop] * A[i, j] * A[j, k::gallop])

    println("Julia:")
    @btime sum($A_ref .* ($A_ref * $(transpose(A_ref))))
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
