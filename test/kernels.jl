@testset "kernels" begin
    #=
    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        if m == n
            println("B[] += A[i,k] * A[i, j] * A[j, k] : $mtx")
            A = Finch.Fiber(
                Solid(m,
                HollowList(n, A_ref.colptr, A_ref.rowval,
                Element{0.0}(A_ref.nzval))))
            B = Finch.Fiber(Element{0.0}())
            @index @loop i j k B[] += A[i, k] * A[i, j] * A[j, k]
            @test FiberArray(B)[] ≈ sum(A_ref .* (A_ref * transpose(A_ref)))
        end
    end
    =#


    for trial = 1:10
        n = 100
        p = q = 0.1

        println("@loop i (C[i] = a[] - b[]; d[] += a[] * b[]) where (a[] = A[i]; b[] = B[i]) : n = $n p = $p q = $q")
        
        A_ref = sprand(n, p)
        B_ref = sprand(n, q)
        I, V = findnz(A_ref)
        J, W = findnz(B_ref)
        A = Fiber(
            HollowList(n, [1, length(I) + 1], I,
            Element{0.0}(V))
        )
        B = Fiber(
            HollowList(n, [1, length(J) + 1], J,
            Element{0.0}(W))
        )
        C = Fiber(
            HollowList(
            Element{0.0}())
        )
        d = Fiber(Element{0.0}())
        a = Fiber(Element{0.0}())
        b = Fiber(Element{0.0}())
        #display(@index_code_lowered @loop i (C[i] = a[] - b[]; d[] += a[] * b[]) where (a[] = A[i]; b[] = B[i]))

        foo(ex) = (@inbounds begin
            C_lvl = (ex.body.cons.bodies[1]).lhs.tns.tns.lvl
            C_lvl_I = C_lvl.I
            C_lvl_pos_q = length(C_lvl.pos)
            C_lvl_idx_q = length(C_lvl.idx)
            C_lvl_2 = C_lvl.lvl
            C_lvl_2_val_q = length(C_lvl.lvl.val)
            C_lvl_2_val = 0.0
            a_lvl = ((ex.body.cons.bodies[1]).rhs.args[1]).tns.tns.lvl
            a_lvl_val_q = length(((ex.body.cons.bodies[1]).rhs.args[1]).tns.tns.lvl.val)
            a_lvl_val = 0.0
            b_lvl = ((ex.body.cons.bodies[1]).rhs.args[2]).tns.tns.lvl
            b_lvl_val_q = length(((ex.body.cons.bodies[1]).rhs.args[2]).tns.tns.lvl.val)
            b_lvl_val = 0.0
            d_lvl = (ex.body.cons.bodies[2]).lhs.tns.tns.lvl
            d_lvl_val_q = length((ex.body.cons.bodies[2]).lhs.tns.tns.lvl.val)
            d_lvl_val = 0.0
            a_lvl_2 = ((ex.body.cons.bodies[2]).rhs.args[1]).tns.tns.lvl
            a_lvl_2_val_q = length(((ex.body.cons.bodies[2]).rhs.args[1]).tns.tns.lvl.val)
            a_lvl_2_val = 0.0
            b_lvl_2 = ((ex.body.cons.bodies[2]).rhs.args[2]).tns.tns.lvl
            b_lvl_2_val_q = length(((ex.body.cons.bodies[2]).rhs.args[2]).tns.tns.lvl.val)
            b_lvl_2_val = 0.0
            a_lvl_3 = (ex.body.prod.bodies[1]).lhs.tns.tns.lvl
            a_lvl_3_val_q = length((ex.body.prod.bodies[1]).lhs.tns.tns.lvl.val)
            a_lvl_3_val = 0.0
            A_lvl = (ex.body.prod.bodies[1]).rhs.tns.tns.lvl
            A_lvl_I = A_lvl.I
            A_lvl_pos_q = length(A_lvl.pos)
            A_lvl_idx_q = length(A_lvl.idx)
            A_lvl_2 = A_lvl.lvl
            A_lvl_2_val_q = length(A_lvl.lvl.val)
            A_lvl_2_val = 0.0
            b_lvl_3 = (ex.body.prod.bodies[2]).lhs.tns.tns.lvl
            b_lvl_3_val_q = length((ex.body.prod.bodies[2]).lhs.tns.tns.lvl.val)
            b_lvl_3_val = 0.0
            B_lvl = (ex.body.prod.bodies[2]).rhs.tns.tns.lvl
            B_lvl_I = B_lvl.I
            B_lvl_pos_q = length(B_lvl.pos)
            B_lvl_idx_q = length(B_lvl.idx)
            B_lvl_2 = B_lvl.lvl
            B_lvl_2_val_q = length(B_lvl.lvl.val)
            B_lvl_2_val = 0.0
            A_lvl_I == B_lvl_I || throw(DimensionMismatch("mismatched dimension starts"))
            B_lvl_I == A_lvl_I || throw(DimensionMismatch("mismatched dimension starts"))
            C_lvl_pos_q < 64 && (C_lvl_pos_q = 64; resize!(C_lvl.pos, 64))
            C_lvl.pos[1] = 1
            C_lvl_idx_q < 64 && (C_lvl_idx_q = 64; resize!(C_lvl.idx, 64))
            C_lvl_I = A_lvl_I
            if C_lvl_2_val_q < 4
                resize!(C_lvl_2.val, 4)
            end
            C_lvl_2_val_q = 4
            for C_lvl_2_q = 1:4
                C_lvl_2.val[C_lvl_2_q] = 0.0
            end
            C_lvl = (Finch.HollowListLevel){Int64}(C_lvl_I, C_lvl.pos, C_lvl.idx, C_lvl_2)
            C_lvl_pos_q < 1 + 1 && resize!(C_lvl.pos, C_lvl_pos_q *= 4)
            C_lvl_2_val_q < 1 && (C_lvl_2_val_q = Finch.regrow!(C_lvl_2.val, C_lvl_2_val_q, 1))
            if d_lvl_val_q < 4
                resize!(d_lvl.val, 4)
            end
            d_lvl_val_q = 4
            for d_lvl_q = 1:4
                d_lvl.val[d_lvl_q] = 0.0
            end
            d_lvl_val_q < 1 && (d_lvl_val_q = refill!(d_lvl.val, 0.0, d_lvl_val_q, 1))
            d_lvl_val = d_lvl.val[1]
            C_lvl_p = C_lvl.pos[1]
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
                    i_step_2 = min(A_lvl_i, B_lvl_i, i_step)
                    if i_step_2 == A_lvl_i && i_step_2 == B_lvl_i
                        A_lvl_2_val = A_lvl_2.val[A_lvl_p]
                        B_lvl_2_val = B_lvl_2.val[B_lvl_p]
                        i = i_step_2
                        C_lvl_2_val_q < C_lvl_p && (C_lvl_2_val_q = Finch.regrow!(C_lvl_2.val, C_lvl_2_val_q, C_lvl_p))
                        C_lvl_2_val = 0.0
                        if a_lvl_3_val_q < 4
                            resize!(a_lvl_3.val, 4)
                        end
                        a_lvl_3_val_q = 4
                        for a_lvl_3_q = 1:4
                            a_lvl_3.val[a_lvl_3_q] = 0.0
                        end
                        a_lvl_3_val_q < 1 && (a_lvl_3_val_q = Finch.regrow!(a_lvl_3.val, a_lvl_3_val_q, 1))
                        if b_lvl_3_val_q < 4
                            resize!(b_lvl_3.val, 4)
                        end
                        b_lvl_3_val_q = 4
                        for b_lvl_3_q = 1:4
                            b_lvl_3.val[b_lvl_3_q] = 0.0
                        end
                        b_lvl_3_val_q < 1 && (b_lvl_3_val_q = Finch.regrow!(b_lvl_3.val, b_lvl_3_val_q, 1))
                        a_lvl_3_val = 0.0
                        b_lvl_3_val = 0.0
                        a_lvl_3_val = A_lvl_2_val
                        b_lvl_3_val = B_lvl_2_val
                        a_lvl_3.val[1] = a_lvl_3_val
                        b_lvl_3.val[1] = b_lvl_3_val
                        C_lvl_2_val = a_lvl_val - b_lvl_val
                        d_lvl_val = d_lvl_val + a_lvl_2_val * b_lvl_2_val
                        @info "hmm" A_lvl_2_val B_lvl_2_val a_lvl_3_val b_lvl_3_val d_lvl_val
                        C_lvl_2.val[C_lvl_p] = C_lvl_2_val
                        C_lvl_idx_q < C_lvl_p && resize!(C_lvl.idx, C_lvl_idx_q *= 4)
                        C_lvl.idx[C_lvl_p] = i
                        C_lvl_p += 1
                        A_lvl_p += 1
                        B_lvl_p += 1
                    elseif i_step_2 == B_lvl_i
                        B_lvl_2_val = B_lvl_2.val[B_lvl_p]
                        i_2 = i_step_2
                        C_lvl_2_val_q < C_lvl_p && (C_lvl_2_val_q = Finch.regrow!(C_lvl_2.val, C_lvl_2_val_q, C_lvl_p))
                        C_lvl_2_val = 0.0
                        if b_lvl_3_val_q < 4
                            resize!(b_lvl_3.val, 4)
                        end
                        b_lvl_3_val_q = 4
                        for b_lvl_3_q_2 = 1:4
                            b_lvl_3.val[b_lvl_3_q_2] = 0.0
                        end
                        b_lvl_3_val_q < 1 && (b_lvl_3_val_q = Finch.regrow!(b_lvl_3.val, b_lvl_3_val_q, 1))
                        b_lvl_3_val = 0.0
                        b_lvl_3_val = B_lvl_2_val
                        b_lvl_3.val[1] = b_lvl_3_val
                        C_lvl_2_val = -b_lvl_val
                        C_lvl_2.val[C_lvl_p] = C_lvl_2_val
                        C_lvl_idx_q < C_lvl_p && resize!(C_lvl.idx, C_lvl_idx_q *= 4)
                        C_lvl.idx[C_lvl_p] = i_2
                        C_lvl_p += 1
                        B_lvl_p += 1
                    elseif i_step_2 == A_lvl_i
                        A_lvl_2_val = A_lvl_2.val[A_lvl_p]
                        i_3 = i_step_2
                        C_lvl_2_val_q < C_lvl_p && (C_lvl_2_val_q = Finch.regrow!(C_lvl_2.val, C_lvl_2_val_q, C_lvl_p))
                        C_lvl_2_val = 0.0
                        if a_lvl_3_val_q < 4
                            resize!(a_lvl_3.val, 4)
                        end
                        a_lvl_3_val_q = 4
                        for a_lvl_3_q_2 = 1:4
                            a_lvl_3.val[a_lvl_3_q_2] = 0.0
                        end
                        a_lvl_3_val_q < 1 && (a_lvl_3_val_q = Finch.regrow!(a_lvl_3.val, a_lvl_3_val_q, 1))
                        a_lvl_3_val = 0.0
                        a_lvl_3_val = A_lvl_2_val
                        a_lvl_3.val[1] = a_lvl_3_val
                        C_lvl_2_val = a_lvl_val + -0.0
                        C_lvl_2.val[C_lvl_p] = C_lvl_2_val
                        C_lvl_idx_q < C_lvl_p && resize!(C_lvl.idx, C_lvl_idx_q *= 4)
                        C_lvl.idx[C_lvl_p] = i_3
                        C_lvl_p += 1
                        A_lvl_p += 1
                    else
                    end
                    i_start_2 = i_step_2 + 1
                end
                i_start = i_step + 1
            end
            i_step = min(A_lvl_i1, A_lvl_I)
            if i_start <= i_step
                i_start_3 = i_start
                while A_lvl_p < A_lvl_p1
                    A_lvl_i = A_lvl.idx[A_lvl_p]
                    i_step_3 = min(A_lvl_i, i_step)
                    if i_step_3 == A_lvl_i
                        A_lvl_2_val = A_lvl_2.val[A_lvl_p]
                        i_4 = i_step_3
                        C_lvl_2_val_q < C_lvl_p && (C_lvl_2_val_q = Finch.regrow!(C_lvl_2.val, C_lvl_2_val_q, C_lvl_p))
                        C_lvl_2_val = 0.0
                        if a_lvl_3_val_q < 4
                            resize!(a_lvl_3.val, 4)
                        end
                        a_lvl_3_val_q = 4
                        for a_lvl_3_q_3 = 1:4
                            a_lvl_3.val[a_lvl_3_q_3] = 0.0
                        end
                        a_lvl_3_val_q < 1 && (a_lvl_3_val_q = Finch.regrow!(a_lvl_3.val, a_lvl_3_val_q, 1))
                        a_lvl_3_val = 0.0
                        a_lvl_3_val = A_lvl_2_val
                        a_lvl_3.val[1] = a_lvl_3_val
                        C_lvl_2_val = a_lvl_val + -0.0
                        C_lvl_2.val[C_lvl_p] = C_lvl_2_val
                        C_lvl_idx_q < C_lvl_p && resize!(C_lvl.idx, C_lvl_idx_q *= 4)
                        C_lvl.idx[C_lvl_p] = i_4
                        C_lvl_p += 1
                        A_lvl_p += 1
                    else
                    end
                    i_start_3 = i_step_3 + 1
                end
                i_start = i_step + 1
            end
            i_step = min(B_lvl_i1, A_lvl_I)
            if i_start <= i_step
                i_start_4 = i_start
                while B_lvl_p < B_lvl_p1
                    B_lvl_i = B_lvl.idx[B_lvl_p]
                    i_step_4 = min(B_lvl_i, i_step)
                    if i_step_4 == B_lvl_i
                        B_lvl_2_val = B_lvl_2.val[B_lvl_p]
                        i_5 = i_step_4
                        C_lvl_2_val_q < C_lvl_p && (C_lvl_2_val_q = Finch.regrow!(C_lvl_2.val, C_lvl_2_val_q, C_lvl_p))
                        C_lvl_2_val = 0.0
                        if b_lvl_3_val_q < 4
                            resize!(b_lvl_3.val, 4)
                        end
                        b_lvl_3_val_q = 4
                        for b_lvl_3_q_3 = 1:4
                            b_lvl_3.val[b_lvl_3_q_3] = 0.0
                        end
                        b_lvl_3_val_q < 1 && (b_lvl_3_val_q = Finch.regrow!(b_lvl_3.val, b_lvl_3_val_q, 1))
                        b_lvl_3_val = 0.0
                        b_lvl_3_val = B_lvl_2_val
                        b_lvl_3.val[1] = b_lvl_3_val
                        C_lvl_2_val = -b_lvl_val
                        C_lvl_2.val[C_lvl_p] = C_lvl_2_val
                        C_lvl_idx_q < C_lvl_p && resize!(C_lvl.idx, C_lvl_idx_q *= 4)
                        C_lvl.idx[C_lvl_p] = i_5
                        C_lvl_p += 1
                        B_lvl_p += 1
                    else
                    end
                    i_start_4 = i_step_4 + 1
                end
                i_start = i_step + 1
            end
            i_step = min(A_lvl_I)
            if i_start <= i_step
                i_start = i_step + 1
            end
            C_lvl.pos[1 + 1] = C_lvl_p
            d_lvl.val[1] = d_lvl_val
            (C = Fiber(C_lvl, Finch.RootEnvironment()), d = Finch.Fiber(d_lvl, Finch.RootEnvironment()))
        end)

        foo(Finch.@index_program_instance @loop i (C[i] = a[] - b[]; d[] += a[] * b[]) where (a[] = A[i]; b[] = B[i]))
        println(dot(A_ref, B_ref))
        println(d)
        exit()
        @index @loop i (C[i] = a[] - b[]; d[] += a[] * b[]) where (a[] = A[i]; b[] = B[i])

        exit()

        @test FiberArray(C) == A_ref .- B_ref
        refidx = (A_ref .- B_ref).nzind
        @test C.lvl.idx[1:length(refidx)] == refidx
        @test FiberArray(d)[] ≈ dot(A_ref, B_ref)

    end
end