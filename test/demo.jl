using MatrixDepot
using Finch
using Finch.IndexNotation
using RewriteTools
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

    println("Finch(gallop):")
    @btime (A = $A; C = $C; @index @loop i j k C[] += A[i, k::gallop] * A[i, j] * A[j, k::gallop])

    println("Julia:")
    @btime sum($A_ref .* ($A_ref * $(transpose(A_ref))))
end

#tri("Boeing/ct20stif")
#tri("SNAP/web-NotreDame")
#tri("SNAP/roadNet-PA")
#tri("VDOL/spaceStation_5")
#tri("DIMACS10/sd2010")
#tri("Bai/bfwb398")
#tri("SNAP/soc-Epinions1")
#tri("SNAP/email-EuAll")
#tri("SNAP/wiki-Talk")
##tri("SNAP/web-BerkStan")
#exit()

#println(@macroexpand(@i(@chunk i a @multi b... (c[j...] <min>= d) e...)))
@slots a b c d e i j Finch.add_rules!([
    (@rule @i(@chunk $i a (b[j...] <min>= d)) => if isliteral(d) && i ∉ j
        @i (b[j...] <min>= d)
    end),
    (@rule @i(@chunk $i a @multi b... (c[j...] <min>= d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @i @multi (c[j...] <min>= d) @chunk i a @i(@multi b... e...)
        end
    end),
    (@rule @i(@chunk $i a (b[j...] <max>= d)) => if isliteral(d) && i ∉ j
        @i (b[j...] <max>= d)
    end),
    (@rule @i(@chunk $i a @multi b... (c[j...] <max>= d) e...) => begin
        if Finch.isliteral(d) && i ∉ j
            @i @multi (c[j...] <max>= d) @chunk i a @i(@multi b... e...)
        end
    end),
])

Finch.register()

function stats(n, p)
    println("stats: n=$n p=$p")
    A_ref = sprand(n, p)
    I, V = findnz(A_ref)
    A = Fiber(
        HollowList(n, [1, length(I) + 1], I,
        Element{0.0}(V)))
    a = Finch.Fiber(Element{0.0}())
    total = Finch.Fiber(Element{0.0}())
    total2 = Finch.Fiber(Element{0.0}())
    minim = Finch.Fiber(Element{0.0}())
    maxim = Finch.Fiber(Element{0.0}())

    #=
    (@rule chunk(i, a, @i((b[i] <min>= d))) => if isliteral(d)
        @i @multi (c[i] <min>= d) @chunk(i, a, @i(@multi b... e...))
    end),
    (@rule chunk(i, a, @i(@multi b... (c[i] <min>= d) e...)) => if isliteral(d)
        @i @multi (c[i] <min>= d) @chunk(i, a, @i(@multi b... e...))
    end),
    (@rule chunk(i, a, @i(@multi b... (c[i] <min>= d) e...)) => if isliteral(d)
        @i @multi (c[i] <min>= d) @chunk(i, a, @i(@multi b... e...))
    end),
    =#

    display(@index_code_lowered @loop i (begin
        total[] += a[]
        total2[] += a[]*a[]
        minim[] <min>= a[]
        maxim[] <max>= a[]
    end) where (a[] = A[i]))

    #println("Finch:")
    #@btime (A = $A; C = $C; @index @loop i j k C[] += A[i, k] * A[i, j] * A[j, k])
#
#    println("Finch(gallop):")
#    @btime (A = $A; C = $C; @index @loop i j k C[] += A[i, k::gallop] * A[i, j] * A[j, k::gallop])
#
#    println("Julia:")
#    @btime sum($A_ref .* ($A_ref * $(transpose(A_ref))))
end

stats(10, 0.4)