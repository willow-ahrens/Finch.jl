@testset "fibers" begin
    println("fiber(h) = fiber(s)")
    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowHash{1}((10,),
        Element{0.0}()))

    ex = @index_program_instance @loop i B[i] += A[i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i B[i] += A[i]

    print(FiberArray(B))

    println("fiber(s) = fiber(h)")

    ex = @index_program_instance @loop i A[i] += B[i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    foo(ex) = (@inbounds begin
        A_lvl = ex.body.lhs.tns.tns.lvl
        A_lvl_I = A_lvl.I
        A_lvl_pos_q = length(A_lvl.pos)
        A_lvl_idx_q = length(A_lvl.idx)
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_val_q = length(A_lvl.lvl.val)
        B_lvl = ex.body.rhs.tns.tns.lvl
        B_lvl_I = B_lvl.I
        B_lvl_pos_q = length(B_lvl.pos)
        B_lvl_pos_q_alloc = B_lvl_pos_q
        B_lvl_idx_q = length(B_lvl.tbl)
        B_lvl_2 = B_lvl.lvl
        B_lvl_2_val_q = length(B_lvl.lvl.val)
        if A_lvl_pos_q < 4
            resize!(A_lvl.pos, 4)
        end
        A_lvl_pos_q = 4
        A_lvl.pos[1] = 1
        if A_lvl_idx_q < 4
            resize!(A_lvl.idx, 4)
        end
        A_lvl_idx_q = 4
        A_lvl_I = B_lvl_I[1]
        if A_lvl_2_val_q < 4
            resize!(A_lvl_2.val, 4)
        end
        A_lvl_2_val_q = 4
        for A_lvl_2_q = 1:4
            A_lvl_2.val[A_lvl_2_q] = 0.0
        end
        A_lvl = Finch.HollowListLevel{Int64}(A_lvl_I, A_lvl.pos, A_lvl.idx, A_lvl_2)
        A_lvl_p = A_lvl.pos[1]
        B_lvl_p = B_lvl.pos[1]
        B_lvl_p_stop = B_lvl.pos[1 + 1]
        if B_lvl_p < B_lvl_p_stop
            B_lvl_i = (B_lvl.srt[B_lvl_p])[1]
            B_lvl_i_stop = (B_lvl.srt[B_lvl_p_stop - 1])[1]
        else
            B_lvl_i = 1
            B_lvl_i_stop = 0
        end
        i_start = 1
        i_step = min(B_lvl_i_stop, B_lvl_I[1])
        i_start_2 = i_start
        while B_lvl_p < B_lvl_p_stop
            i_step_2 = min(B_lvl_i, i_step)
            if i_step_2 < B_lvl_i
            else
                if A_lvl_2_val_q < A_lvl_p
                    resize!(A_lvl_2.val, A_lvl_2_val_q * 4)
                    @simd for A_lvl_2_q_2 = A_lvl_2_val_q + 1:A_lvl_2_val_q * 4
                            A_lvl_2.val[A_lvl_2_q_2] = 0.0
                        end
                    A_lvl_2_val_q *= 4
                end
                A_lvl_2_val = A_lvl_2.val[A_lvl_p]
                B_lvl_2_val = B_lvl_2.val[B_lvl_p]
                A_lvl_2_val = A_lvl_2_val + B_lvl_2_val
                A_lvl_2.val[A_lvl_p] = A_lvl_2_val
                if A_lvl_idx_q < A_lvl_p
                    resize!(A_lvl.idx, A_lvl_idx_q * 4)
                    A_lvl_idx_q *= 4
                end
                A_lvl.idx[A_lvl_p] = i_step_2
                A_lvl_p += 1
                B_lvl_p += 1
                B_lvl_i = (B_lvl.srt[B_lvl_p])[1]
            end
            i_start_2 = i_step_2 + 1
        end
        i_start = i_step + 1
        i_step = min(B_lvl_I[1])
        i_start = i_step + 1
        A_lvl.pos[1 + 1] = A_lvl_p
        if A_lvl_2_val_q < 4
            resize!(A_lvl_2.val, 4)
        end
        A_lvl_2_val_q = 4
        for A_lvl_2_q_3 = 1:4
            A_lvl_2.val[A_lvl_2_q_3] = 0.0
        end
        (A = Fiber(A_lvl, RootEnvironment()),)
    end)

    foo(ex)

    @index @loop i A[i] += B[i]

    print(FiberArray(A))

    exit()

    println("fiber(d, s)")

    A = Finch.FiberArray(Fiber(
        Solid(3, 
        HollowList(5, [1, 4, 6, 8], [1, 2, 5, 2, 4, 3, 5],
        Element{0.0}([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0])))))
    @test ndims(A) == 2
    @test size(A) == (3, 5)
    @test axes(A) == (1:3, 1:5)
    @test eltype(A) == Float64
    @test A == [
        1.0  1.0  0.0  0.0  1.0;
        0.0  1.0  0.0  1.0  0.0;
        0.0  0.0  1.0  0.0  1.0;
    ]

    println("fiber(s) = fiber(s) + fiber(s)")

    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowList(10, [1, 4], [2, 5, 8],
        Element{0.0}([1.0, 1.0, 1.0])))
    C = Finch.Fiber(HollowList(10, Element{0.0}()))

    display(@macroexpand @index @loop i C[i] += A[i] + B[i])
    println()

    ex = @index_program_instance @loop i C[i] += A[i] + B[i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i C[i] += A[i] + B[i]

    println(A)
    println(B)
    println(C)

    @test Finch.FiberArray(C) == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()


    println("dense = fiber(s) + fiber(s)")
    A = Finch.Fiber(
        HollowList(10, [1, 6], [1, 3, 5, 7, 9],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0])))
    B = Finch.Fiber(
        HollowList(10, [1, 4], [2, 5, 8],
        Element{0.0}([1.0, 1.0, 1.0])))
    C = zeros(10)
    ex = @index_program_instance @loop i C[i] += A[i] + B[i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop i C[i] += A[i] + B[i]

    println(A)
    println(B)
    println(C)

    @test C == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()

    println("dense[i] = fiber(d, s)[j, i]")
    A = Fiber(
        Solid(2,
        HollowList(10, [1, 6, 9], [1, 3, 5, 7, 9, 2, 5, 8],
        Element{0.0}([2.0, 3.0, 4.0, 5.0, 6.0, 1.0, 1.0, 1.0]))))
    B = zeros(10)
    ex = @index_program_instance @loop j i B[i] += A[j, i]
    display(execute_code_lowered(:ex, typeof(ex)))
    println()

    @index @loop j i B[i] += A[j, i]

    println(A)
    println(B)

    @test B == [2.0, 1.0, 3.0, 0.0, 5.0, 0.0, 5.0, 1.0, 6.0, 0.0]
    println()
end