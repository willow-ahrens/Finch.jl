using MatrixDepot
using Finch
using Finch.IndexNotation
using RewriteTools
using BenchmarkTools
using SparseArrays
using LinearAlgebra

@slots a b c d e i j Finch.add_rules!([
    (@rule @i(@chunk $i a (b[j...] <<min>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @i (b[j...] <<min>>= $d)
    end),
    (@rule @i(@chunk $i a @multi b... (c[j...] <<min>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @i @multi (c[j...] <<min>>= $d) @chunk $i a @i(@multi b... e...)
        end
    end),
    (@rule @i(@chunk $i a (b[j...] <<max>>= $d)) => if Finch.isliteral(d) && i ∉ j
        @i (b[j...] <<max>>= $d)
    end),
    (@rule @i(@chunk $i a @multi b... (c[j...] <<max>>= $d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            println(@i @multi (c[j...] <<max>>= $d) @chunk $i a @i(@multi b... e...))
            @i @multi (c[j...] <<max>>= $d) @chunk $i a @i(@multi b... e...)
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
    display(@index_code @loop i (begin
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
        @index @loop i (begin
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
        @index @loop i total[] += A[i]
        @index @loop i (total2[] += a[] * a[]) where (a[] = A[i])
        @index @loop i minim[] <<min>>= A[i]
        @index @loop i maxim[] <<max>>= A[i]
    end))
    println()
end

stats(100_000, 0.01)