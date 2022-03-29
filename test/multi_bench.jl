using MatrixDepot
using Finch
using BenchmarkTools
using SparseArrays
using LinearAlgebra
using Cthulhu
using Profile

function stats(n, p)
    @info "stats" n p

    A_ref = sprand(n, p)
    I, V = findnz(A_ref)
    A = Fiber(
        HollowList(n, [1, length(I) + 1], I,
        Element{0.0, Float64}(V))
    )
    tot = Fiber(Element{0.0, Float64}(zeros(1)))
    tot2 = Fiber(Element{0.0, Float64}(zeros(1)))
    a = Fiber(Element{0.0, Float64}(zeros(1)))
    
    println("Finch (fused):")
    display(@benchmark begin
        A = $A
        a = $a
        tot = $tot
        tot2 = $tot2
        @index @loop i ((tot[] += a[]; tot2[] += a[] * a[]) where (a[] = A[i]))
    end)
    println()
    println("Finch (unfused):")
    display(@benchmark begin
        A = $A
        a = $a
        tot = $tot
        tot2 = $tot2
        @index @loop i tot[] += A[i]
        @index @loop i (tot2[] += a[] * a[]) where (a[] = A[i])
    end)
    println()
end

stats(100_000, 0.1)