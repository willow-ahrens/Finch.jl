using MatrixDepot
using Finch
using BenchmarkTools
using SparseArrays
using LinearAlgebra
using Cthulhu
using Profile
using RewriteTools
using Finch.IndexNotation

function add_vec(n, p, q; verbose=false)
    @info "add vec" n p q

    A_ref = sprand(n, p)
    B_ref = sprand(n, q)
    I, V = findnz(A_ref)
    J, W = findnz(B_ref)
    A = Fiber(
        SparseList(n, [1, length(I) + 1], I,
        Element{0.0, Float64}(V))
    )
    B = Fiber(
        SparseList(n, [1, length(J) + 1], J,
        Element{0.0, Float64}(W))
    )
    C = Fiber(
        SparseList(
        Element{0.0, Float64}())
    )
    
    println("C[i] = A[i] + B[i]")
    if verbose
        display(@finch_code @loop i C[i] = A[i] + B[i])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @finch @loop i C[i] = A[i] + B[i])))
    println()

    println("C[i] = A[i] + B[i::gallop]")
    if verbose
        display(@finch_code @loop i C[i] = A[i] + B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @finch @loop i C[i] = A[i] + B[i::gallop])))
    println()

    println("C[i] = A[i::gallop] + B[i::gallop]")
    if verbose
        display(@finch_code @loop i C[i] = A[i::gallop] + B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @finch @loop i C[i] = A[i::gallop] + B[i::gallop])))
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
        SparseList(n, [1, length(I) + 1], I,
        Element{0.0, Float64}(V))
    )
    B = Fiber(
        SparseList(n, [1, length(J) + 1], J,
        Element{0.0, Float64}(W))
    )
    C = Fiber(
        SparseList(
        Element{0.0, Float64}())
    )
    
    println("C[i] = A[i] * B[i]")
    if verbose
        display(@finch_code @loop i C[i] = A[i] * B[i])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @finch @loop i C[i] = A[i] * B[i])))
    println()

    println("C[i] = A[i] * B[i::gallop]")
    if verbose
        display(@finch_code @loop i C[i] = A[i] * B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @finch @loop i C[i] = A[i] * B[i::gallop])))
    println()

    println("C[i] = A[i::gallop] * B[i::gallop]")
    if verbose
        display(@finch_code @loop i C[i] = A[i::gallop] * B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @finch @loop i C[i] = A[i::gallop] * B[i::gallop])))
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
        SparseList(n, [1, length(I) + 1], I,
        Element{0.0, Float64}(V))
    )
    B = Fiber(
        SparseList(n, [1, length(J) + 1], J,
        Element{0.0, Float64}(W))
    )
    C = Scalar{0.0}()
    
    println("C[] += A[i] * B[i]")
    if verbose
        display(@finch_code @loop i C[] += A[i] * B[i])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @finch @loop i C[] += A[i] * B[i])))
    println()

    println("C[] += A[i] * B[i::gallop]")
    if verbose
        display(@finch_code @loop i C[] += A[i] * B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @finch @loop i C[] += A[i] * B[i::gallop])))
    println()

    println("C[] += A[i::gallop] * B[i::gallop]")
    if verbose
        display(@finch_code @loop i C[] += A[i::gallop] * B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @finch @loop i C[] += A[i::gallop] * B[i::gallop])))
    println()

    #println("Julia:")
    #display((@benchmark $A_ref * $B_ref))
    #println()
end

function minplus(n, p, q; verbose=false)
    @info "minplus" n p q

    A_ref = sprand(n, p)
    B_ref = sprand(n, q)
    I, V = findnz(A_ref)
    J, W = findnz(B_ref)
    A = Fiber(
        SparseList(n, [1, length(I) + 1], I,
        Element{0.0, Float64}(V))
    )
    B = Fiber(
        SparseList(n, [1, length(J) + 1], J,
        Element{0.0, Float64}(W))
    )
    C = Scalar{0.0}()
    
    println("C[] <<min>>= A[i] + B[i]")
    if verbose
        display(@finch_code @loop i C[] <<min>>= A[i] + B[i])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @finch @loop i C[] <<min>>= A[i] + B[i])))
    println()

    println("C[] += A[i] * B[i::gallop]")
    if verbose
        display(@finch_code @loop i C[] <<min>>= A[i] + B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @finch @loop i C[] <<min>>= A[i] + B[i::gallop])))
    println()

    println("C[] += A[i::gallop] * B[i::gallop]")
    if verbose
        display(@finch_code @loop i C[] <<min>>= A[i::gallop] + B[i::gallop])
        println()
    end
    display((@benchmark (A = $A; B = $B; C = $C; @finch @loop i C[] <<min>>= A[i::gallop] + B[i::gallop])))
    println()

    #println("Julia:")
    #display((@benchmark $A_ref * $B_ref))
    #println()
end

# dot(100_000, 0.1, 0.001, verbose=true)
# add_vec(100_000, 0.1, 0.001, verbose=true)
# mul_vec(100_000, 0.1, 0.001)

function test()

ctx = Finch.LowerJulia()
code = Finch.contain(ctx) do ctx_2
t_A = typeof(@fiber d(e(0)))
A = Finch.virtualize(:A, t_A, ctx_2)
t_B = typeof(@fiber d(d(e(0))))
B = Finch.virtualize(:B, t_B, ctx_2)
t_C = typeof(@fiber d(e(0)))
C = Finch.virtualize(:C, t_C, ctx_2)
w_0 = Finch.virtualize(:w_0, typeof(Scalar{0, Int64}()), ctx_2, :w_0)
kernel = @finch_program (@loop i A[i] = w_0[] where (@loop j w_0[] += B[i,j] * C[j]))
kernel_code = Finch.execute_code_virtualized(kernel, ctx_2)
end
return quote
function def_0(C, B, A)
    $code
end
end
end

println(test())