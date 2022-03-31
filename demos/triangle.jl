using MatrixDepot
using Finch
using BenchmarkTools
using SparseArrays
using LinearAlgebra
using Cthulhu
using Profile

function triangle(mtx)
    A_ref = SparseMatrixCSC(mdopen(mtx).A)
    (m, n) = size(A_ref)
    A = Finch.Fiber(
        Solid(m,
        HollowList(n, A_ref.colptr, A_ref.rowval,
        Element{0.0, Float64}(A_ref.nzval))))
    A2 = A
    A3 = A

    C = Finch.Fiber(
        Element{0.0, Float64}(zeros(1)))

    @index @loop i j k C[] += A[i, k::gallop] * A2[i, j] * A3[j, k::gallop]
    println(FiberArray(C)[])
    @index @loop i j k C[] += A[i, k] * A2[i, j] * A3[j, k]
    println(FiberArray(C)[])
    println(sum(A_ref .* (A_ref * A_ref)))
    #println(@descend execute(ex))

    foo(Finch.@index_program_instance @loop i j k C[] += A[i, k] * A2[i, j] * A3[j, k])
    
    #@profile @index @loop i j k C[] += A[i, k] * A2[i, j] * A3[j, k]
    #Profile.print()


    println("Finch:")
    @btime (A = $A; A2=$A; A3=$A; C = $C; @index @loop i j k C[] += A[i, k] * A2[i, j] * A3[j, k])

    println("foo:")
    @btime (A = $A; A2=$A; A3=$A; C = $C; $foo(Finch.@index_program_instance @loop i j k C[] += A[i, k] * A2[i, j] * A3[j, k]))

    println("Finch(gallop):")
    @btime (A = $A; A2=$A; A3=$A; C = $C; @index @loop i j k C[] += A[i, k::gallop] * A2[i, j] * A3[j, k::gallop])

    println("Julia:")
    @btime sum($A_ref .* ($A_ref * $(transpose(A_ref))))
end

function quad(mtx)
    println("quad: $mtx")
    A_ref = SparseMatrixCSC(mdopen(mtx).A)
    (m, n) = size(A_ref)
    A = Finch.Fiber(
        Solid(m,
        HollowList(n, A_ref.colptr, A_ref.rowval,
        Element{0.0, Float64}(A_ref.nzval))))
    A2 = A
    A3 = A
    A4 = A
    C = Finch.Fiber(
        Element{0.0, Float64}(zeros(1)))

    println("Finch:")
    @btime (A=A2=A3=A4=A5=A6=$A; C = $C; @index @loop i j k l C[] += A[i, j] * A2[i, k] * A3[i, l] * A4[j,k] * A5[j, l] * A6[k,l])

    println("Finch (gallop):")
    @btime (A=A2=A3=A4=A5=A6=$A; C = $C; @index @loop i j k l C[] += A[i, j] * A2[i, k] * A3[i, l::gallop] * A4[j,k] * A5[j, l::gallop] * A6[k,l::gallop])
end

quad("Bai/bfwb398")

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
