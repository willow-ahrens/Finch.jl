@testset "kernels" begin
    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        println("B[i, j] += A[i,k] * A[j, k]: $mtx")
        B_ref = transpose(A_ref) * A_ref
        A = Finch.Fiber(
            Solid(n,
            HollowList(m, A_ref.colptr, A_ref.rowval,
            Element{0.0}(A_ref.nzval))))
        B = Finch.Fiber(
            Solid(m,
            HollowList(m,
            Element{0.0}())))
        @index @loop i j k B[i, j] += A[i, k] * A[j, k]
        @test B.lvl.lvl.pos[1:length(B_ref.colptr)] == B_ref.colptr
        @test B.lvl.lvl.idx[1:length(B_ref.rowval)] == B_ref.rowval
    end

    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        if m == n
            println("B[] += A[i,k] * A[i, j] * A[j, k] : $mtx")
            A = Finch.Fiber(
                Solid(n,
                HollowList(m, A_ref.colptr, A_ref.rowval,
                Element{0.0}(A_ref.nzval))))
            B = Finch.Fiber(Element{0.0}())
            @index @loop i j k B[] += A[i, k] * A[i, j] * A[j, k]
            @test FiberArray(B)[] ≈ sum(A_ref .* (A_ref * transpose(A_ref)))
        end
    end

    for trial = 1:10
        n = 100
        p = q = 0.1

        println("(C[i] = a[] - b[]; d[] += a[] * b[]) where (a[] = A[i]; b[] = B[i]) : n = $n p = $p q = $q")
        
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

        @index @loop i (C[i] = a[] - b[]; d[] += a[] * b[]) where (a[] = A[i]; b[] = B[i])

        @test FiberArray(C) == A_ref .- B_ref
        refidx = (A_ref .- B_ref).nzind
        @test C.lvl.idx[1:length(refidx)] == refidx
        @test FiberArray(d)[] ≈ dot(A_ref, B_ref)
    end

    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        if m == n
            println("B(ds)[i, j] = w[j] where w[j] += A(ds)[i, k] * A(ds)(k, j)")
            A = Finch.Fiber(
                Solid(n,
                HollowList(m, A_ref.colptr, A_ref.rowval,
                Element{0.0}(A_ref.nzval))))
            B = Fiber(
                Solid(0,
                HollowList(0,
                Element{0.0}())))
            w = Fiber(
                HollowByte(m, #TODO
                Element{0.0}()))

            ex = @index_program_instance @loop i ((@loop j B[i, j] = w[j]) where (@loop k j w[j] = A[i, k] * A[k, j]))
            display(execute_code_lowered(:ex, typeof(ex)))
            println()

            @index @loop i ((@loop j B[i, j] = w[j]) where (@loop k j w[j] = A[i, k] * A[k, j]))
        end
    end
end