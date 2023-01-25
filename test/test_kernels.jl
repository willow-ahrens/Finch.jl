@testset "kernels" begin
    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        println("B[i, j] += A[i,k] * A[j, k]: $mtx")
        B_ref = transpose(A_ref) * A_ref
        A = Finch.Fiber(
            Dense(n,
            SparseList(m, A_ref.colptr, A_ref.rowval,
            Element{0.0}(A_ref.nzval))), Environment())
        B = Finch.Fiber(
            Dense(m,
            SparseList(m,
            Element{0.0}())), Environment())
        @finch @loop i j k B[i, j] += A[i, k] * A[j, k]
        @test B.lvl.lvl.pos[1:length(B_ref.colptr)] == B_ref.colptr
        @test B.lvl.lvl.idx[1:length(B_ref.rowval)] == B_ref.rowval
    end

    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        if m == n
            println("B[] += A[i,k] * A[i, j] * A[j, k] : $mtx")
            A = Finch.Fiber(
                Dense(n,
                SparseList(m, A_ref.colptr, A_ref.rowval,
                Element{0.0}(A_ref.nzval))), Environment())
            B = Finch.Scalar{0.0}()
            @finch @loop i j k B[] += A[i, k] * A[i, j] * A[j, k]
            @test B() ≈ sum(A_ref .* (A_ref * transpose(A_ref)))
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
            SparseList(n, [1, length(I) + 1], I,
            Element{0.0}(V)), Environment()
        )
        B = Fiber(
            SparseList(n, [1, length(J) + 1], J,
            Element{0.0}(W)), Environment()
        )
        C = Fiber(
            SparseList(
            Element{0.0}()), Environment()
        )
        d = Scalar{0.0}()
        a = Scalar{0.0}()
        b = Scalar{0.0}()

        @finch @loop i (C[i] = a[] - b[]; d[] += a[] * b[]) where (a[] = A[i]; b[] = B[i])

        @test reference_isequal(C, A_ref .- B_ref)
        refidx = (A_ref .- B_ref).nzind
        @test C.lvl.idx[1:length(refidx)] == refidx
        @test d[] ≈ dot(A_ref, B_ref)
    end

    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        if m == n
            println("B(ds)[i, j] = w[j] where w[j] += A(ds)[i, k] * A(ds)(k, j)")
            A = Finch.Fiber(
                Dense(n,
                SparseList(m, A_ref.colptr, A_ref.rowval,
                Element{0.0}(A_ref.nzval))), Environment())
            B = Fiber(
                Dense(0,
                SparseList(0,
                Element{0.0}()), Environment()))
            w = Fiber(
                SparseBytemap(m, #TODO
                Element{0.0}(), Environment()))

            ex = @finch_program_instance @loop i ((@loop j B[i, j] = w[j]) where (@loop k j w[j] = A[i, k] * A[k, j]))
            #println(typeof(ex))
            #display(execute_code(:ex, typeof(ex)))
            #println()

            @finch @loop i ((@loop j B[i, j] = w[j]) where (@loop k j w[j] = A[i, k] * A[k, j]))
        end
    end
end