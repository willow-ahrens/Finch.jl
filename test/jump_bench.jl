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

    #=
    println("Finch (leader-follower):")
    ex = Finch.@index_program_instance @loop i C[i] = A[i::gallop] + B[i::gallop]
    display(Finch.execute_code_lowered(:ex, typeof(ex)))
    println()
    @index @loop i C[i] = A[i::gallop] + B[i]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[i] = A[i::gallop] + B[i])))
    println()
    =#

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
end

foo(ex) = (@inbounds begin
    C_lvl = ex.body.lhs.tns.tns.lvl
    C_lvl_val_q = length(ex.body.lhs.tns.tns.lvl.val)
    A_lvl = (ex.body.rhs.args[1]).tns.tns.lvl
    A_lvl_I = A_lvl.I
    A_lvl_pos_q = length(A_lvl.pos)
    A_lvl_idx_q = length(A_lvl.idx)
    A_lvl_2 = A_lvl.lvl
    A_lvl_2_val_q = length(A_lvl.lvl.val)
    B_lvl = (ex.body.rhs.args[2]).tns.tns.lvl
    B_lvl_I = B_lvl.I
    B_lvl_pos_q = length(B_lvl.pos)
    B_lvl_idx_q = length(B_lvl.idx)
    B_lvl_2 = B_lvl.lvl
    B_lvl_2_val_q = length(B_lvl.lvl.val)
    A_lvl_I == B_lvl_I || throw(DimensionMismatch("mismatched dimension starts"))
    B_lvl_I == A_lvl_I || throw(DimensionMismatch("mismatched dimension starts"))
    if C_lvl_val_q < 4
        resize!(C_lvl.val, 4)
    end
    C_lvl_val_q = 4
    for C_lvl_q = 1:4
        C_lvl.val[C_lvl_q] = 0.0
    end
    C_lvl_val_q < 1 && (C_lvl_val_q = Finch.refill!(C_lvl.val, 0.0, C_lvl_val_q, 1))
    C_lvl_val = C_lvl.val[1]
    A_lvl_p = A_lvl.pos[1]
    A_lvl_p1 = A_lvl.pos[1 + 1]
    if A_lvl_p < A_lvl_p1
        A_lvl_i = A_lvl.idx[A_lvl_p]
        A_lvl_i1 = A_lvl.idx[A_lvl_p1 - 1]
    else
        A_lvl_i = 1
        A_lvl_i1 = 0
    end
    B_lvl_p = B_lvl.pos[1]
    B_lvl_p1 = B_lvl.pos[1 + 1]
    if B_lvl_p < B_lvl_p1
        B_lvl_i = B_lvl.idx[B_lvl_p]
        B_lvl_i1 = B_lvl.idx[B_lvl_p1 - 1]
    else
        B_lvl_i = 1
        B_lvl_i1 = 0
    end
    i_start = 1
    i_step = min(A_lvl_i1, B_lvl_i1, A_lvl_I)
    if i_start <= i_step
        i_start_2 = i_start
        while i_start_2 <= i_step
            A_lvl_i = A_lvl.idx[A_lvl_p]
            B_lvl_i = B_lvl.idx[B_lvl_p]
            i_step_2 = min(A_lvl_i, B_lvl_i)
            if i_step_2 > i_step
                i_step_2 = i_step
                break
            elseif i_step_2 == A_lvl_i && i_step_2 == B_lvl_i
                A_lvl_2_val = A_lvl_2.val[A_lvl_p]
                B_lvl_2_val = B_lvl_2.val[B_lvl_p]
                i = i_step_2
                C_lvl_val = C_lvl_val + A_lvl_2_val * B_lvl_2_val
                A_lvl_p += 1
                B_lvl_p += 1
            elseif i_step_2 == B_lvl_i
                B_lvl_p += 1
            elseif i_step_2 == A_lvl_i
                A_lvl_p += 1
            end
            i_start_2 = i_step_2 + 1
        end
        i_start = i_step + 1
    end
    i_step = min(A_lvl_i1, A_lvl_I)
    if i_start <= i_step
        i_start = i_step + 1
    end
    i_step = min(B_lvl_i1, A_lvl_I)
    if i_start <= i_step
        i_start = i_step + 1
    end
    i_step = min(A_lvl_I)
    if i_start <= i_step
        i_start = i_step + 1
    end
    C_lvl.val[1] = C_lvl_val
    (C = Fiber(C_lvl, Finch.RootEnvironment()),)
end)


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
    ex = Finch.@index_program_instance @loop i C[] += A[i] * B[i]
    #display(Finch.execute_code_lowered(:ex, typeof(ex)))
    #println()
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[] += A[i] * B[i])))
    println()

    println("foo:")
    display(@benchmark foo($ex))
    println()

    println("Finch (gallop):")
    @index @loop i C[] += A[i::gallop] * B[i::gallop]
    display((@benchmark (A = $A; B = $B; C = $C; @index @loop i C[] += A[i::gallop] * B[i::gallop])))
    println()

    println("Julia:")
    display((@benchmark transpose($A_ref) * $B_ref))
    println()
end

#add_vec(100_000, 0.001, 0.1)
#mul_vec(100_000, 0.001, 0.1)
#fusesum(100_000, 0.001, 0.1)
dot(100_000, 0.1, 0.1)
dot(100_000, 0.001, 0.1)