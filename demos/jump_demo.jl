using MatrixDepot
using Finch
using BenchmarkTools
using SparseArrays
using LinearAlgebra
using Cthulhu
using Profile

function add_vec(n, p, q; verbose=false)
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
    
    println("C[i] = A[i] + B[i]")
    if verbose
        display(@index_code_lowered @loop i C[i] = A[i] + B[i])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[i] = A[i] + B[i])))
    println()

    println("C[i] = A[i] + B[i::gallop]")
    if verbose
        display(@index_code_lowered @loop i C[i] = A[i] + B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[i] = A[i] + B[i::gallop])))
    println()

    println("C[i] = A[i::gallop] + B[i::gallop]")
    if verbose
        display(@index_code_lowered @loop i C[i] = A[i::gallop] + B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[i] = A[i::gallop] + B[i::gallop])))
    println()

    #println("Julia:")
    #display((@benchmark $A_ref + $B_ref))
    #println()
end

function mul_vec(n, p, q; verbose=false)
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
    
    println("C[i] = A[i] + B[i]")
    if verbose
        display(@index_code_lowered @loop i C[i] = A[i] * B[i])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[i] = A[i] * B[i])))
    println()

    println("C[i] = A[i] * B[i::gallop]")
    if verbose
        display(@index_code_lowered @loop i C[i] = A[i] * B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[i] = A[i] * B[i::gallop])))
    println()

    println("C[i] = A[i::gallop] * B[i::gallop]")
    if verbose
        display(@index_code_lowered @loop i C[i] = A[i::gallop] * B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[i] = A[i::gallop] * B[i::gallop])))
    println()

    #println("Julia:")
    #display((@benchmark $A_ref * $B_ref))
    #println()
end

function dot(n, p, q; verbose=false)
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
    C = Scalar{0.0}()
    
    println("C[] += A[i] + B[i]")
    if verbose
        display(@index_code_lowered @loop i C[] += A[i] * B[i])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[] += A[i] * B[i])))
    println()

    println("C[] += A[i] * B[i::gallop]")
    if verbose
        display(@index_code_lowered @loop i C[] += A[i] * B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[] += A[i] * B[i::gallop])))
    println()

    println("C[] += A[i::gallop] * B[i::gallop]")
    if verbose
        display(@index_code_lowered @loop i C[] += A[i::gallop] * B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[] += A[i::gallop] * B[i::gallop])))
    println()

    #println("Julia:")
    #display((@benchmark $A_ref * $B_ref))
    #println()
end

dot(100_000, 0.1, 0.001, verbose=true)
add_vec(100_000, 0.1, 0.001)
mul_vec(100_000, 0.1, 0.001)