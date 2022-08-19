using MatrixDepot
using Finch
using Finch.IndexNotation
using RewriteTools
using BenchmarkTools
using SparseArrays
using LinearAlgebra

@slots a b c d e i j Finch.add_rules!([
    (@rule @f(@chunk $i a (b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<min>>= $d)
    end),
    (@rule @f(@chunk $i a @multi b... (c[j...] <<min>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @f @multi (c[j...] <<min>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),
    (@rule @f(@chunk $i a (b[j...] <<max>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @f (b[j...] <<max>>= $d)
    end),
    (@rule @f(@chunk $i a @multi b... (c[j...] <<max>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            println(@f @multi (c[j...] <<max>>= $d) @chunk $i a @f(@multi b... e...))
            @f @multi (c[j...] <<max>>= $d) @chunk $i a @f(@multi b... e...)
        end
    end),
])

Finch.register()

function stats(n, p)
    println("stats: n=$n p=$p")
    A_ref = sprand(n, p)
    I, V = findnz(A_ref)
    A = Fiber(
        SparseList(n, [1, length(I) + 1], I,
        Element{0.0}(V)))
    a = Scalar{0.0}()
    total = Scalar{0.0}()
    total2 = Scalar{0.0}()
    minim = Scalar{Inf}()
    maxim = Scalar{-Inf}()

    println("fused stats")
    display(@finch_code @loop i (begin
        total[] += a[]
        total2[] += a[]*a[]
        minim[] <<min>>= a[]
        maxim[] <<max>>= a[]
    end) where (a[] = A[i]))
    println()
    display((@benchmark begin
        total = $total
        total2 = $total2
        minim = $minim
        maxim = $maxim
        A = $A
        a = $a
        @finch @loop i (begin
            total[] += a[]
            total2[] += a[]*a[]
            minim[] <<min>>= a[]
            maxim[] <<max>>= a[]
        end) where (a[] = A[i])
    end))
    println()

    println("unfused stats")
    display((@benchmark begin
        total = $total
        total2 = $total2
        minim = $minim
        maxim = $maxim
        A = $A
        a = $a
        @finch @loop i total[] += A[i]
        @finch @loop i (total2[] += a[] * a[]) where (a[] = A[i])
        @finch @loop i minim[] <<min>>= A[i]
        @finch @loop i maxim[] <<max>>= A[i]
    end))
    println()
end

stats(100_000, 0.01)