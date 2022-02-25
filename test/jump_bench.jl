using MatrixDepot
using Finch
using BenchmarkTools
using SparseArrays
using LinearAlgebra
using Cthulhu
using Profile

function add_vec(n, p, q)
    @info "add vec" n p q

    A_ref = sprand(n, p)
    B_ref = sprand(n, q)
    I, V = findnz(A_ref)
    J, W = findnz(B_ref)
    A = Fiber(
        HollowList(n, [1, length(I) + 1], I,
        Element{0.0, Float64}(V))
    )
    B = Fiber(
        HollowList(n, [1, length(J) + 1], J,
        Element{0.0, Float64}(W))
    )
    C = Fiber(
        HollowList(
        Element{0.0, Float64}())
    )
    
    println("Finch:")
    @index @loop i C[i] = A[i] + B[i]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[i] = A[i] + B[i])))
    println()

    println("Finch (gallop):")
    @index @loop i C[i] = A[i::gallop] + B[i::gallop]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[i] = A[i::gallop] + B[i::gallop])))
    println()

    println("Finch (leader-follower):")
    @index @loop i C[i] = A[i::gallop] + B[i]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[i] = A[i::gallop] + B[i])))
    println()

    println("Julia:")
    display((@benchmark $A_ref + $B_ref))
    println()
end

function mul_vec(n, p, q)
    @info "mul vec" n p q

    A_ref = sprand(n, p)
    B_ref = sprand(n, q)
    I, V = findnz(A_ref)
    J, W = findnz(B_ref)
    A = Fiber(
        HollowList(n, [1, length(I) + 1], I,
        Element{0.0, Float64}(V))
    )
    B = Fiber(
        HollowList(n, [1, length(J) + 1], J,
        Element{0.0, Float64}(W))
    )
    C = Fiber(
        HollowList(
        Element{0.0, Float64}())
    )
    
    println("Finch:")
    @index @loop i C[i] = A[i] * B[i]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[i] = A[i] * B[i])))
    println()

    println("Finch (gallop):")
    @index @loop i C[i] = A[i::gallop] * B[i::gallop]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[i] = A[i::gallop] * B[i::gallop])))
    println()

    println("Finch (leader-follower):")
    @index @loop i C[i] = A[i::gallop] * B[i]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[i] = A[i::gallop] * B[i])))
    println()

    println("Julia:")
    display((@benchmark $A_ref .* $B_ref))
    println()
end

function fusesum(n, p, q)
    @info "fusesum" n p q

    A_ref = sprand(n, p)
    B_ref = sprand(n, q)
    I, V = findnz(A_ref)
    J, W = findnz(B_ref)
    A = Fiber(
        HollowList(n, [1, length(I) + 1], I,
        Element{0.0, Float64}(V))
    )
    B = Fiber(
        HollowList(n, [1, length(J) + 1], J,
        Element{0.0, Float64}(W))
    )
    C = Fiber(
        Element{0.0, Float64}()
    )
    
    println("Finch:")
    @index @loop i C[] += A[i] + B[i]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[] += A[i] + B[i])))
    println()

    println("Finch (gallop):")
    @index @loop i C[] += A[i::gallop] + B[i::gallop]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[] += A[i::gallop] + B[i::gallop])))
    println()

    println("Finch (leader-follower):")
    @index @loop i C[] += A[i::gallop] + B[i]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[] += A[i::gallop] + B[i])))
    println()
end

function dot(n, p, q)
    @info "dot" n p q

    A_ref = sprand(n, p)
    B_ref = sprand(n, q)
    I, V = findnz(A_ref)
    J, W = findnz(B_ref)
    A = Fiber(
        HollowList(n, [1, length(I) + 1], I,
        Element{0.0, Float64}(V))
    )
    B = Fiber(
        HollowList(n, [1, length(J) + 1], J,
        Element{0.0, Float64}(W))
    )
    C = Fiber(
        Element{0.0, Float64}()
    )
    
    println("Finch:")
    @index @loop i C[] += A[i] * B[i]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[] += A[i] * B[i])))
    println()

    println("Finch (gallop):")
    @index @loop i C[] += A[i::gallop] * B[i::gallop]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[] += A[i::gallop] * B[i::gallop])))
    println()

    println("Finch (leader-follower):")
    ex = Finch.@index_program_instance @loop i C[] += A[i::gallop] * B[i]
    display(Finch.execute_code_lowered(:ex, typeof(ex)))
    @index @loop i C[] += A[i::gallop] * B[i]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[] += A[i::gallop] * B[i])))
    println()

    println("Julia:")
    display((@benchmark $A_ref * transpose($B_ref)))
    println()
end

add_vec(100_000, 0.001, 0.1)
mul_vec(100_000, 0.001, 0.1)
fusesum(100_000, 0.001, 0.1)
dot(100_000, 0.001, 0.1)