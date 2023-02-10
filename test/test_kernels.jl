@testset "kernels" begin
    using SparseArrays

    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        println("B[i, j] += A[i,k] * A[j, k]: $mtx")
        B_ref = transpose(A_ref) * A_ref
        A = fiber(permutedims(A_ref))
        B = @fiber(d(sl(e(0.0),m),m))
        @finch @loop i j k B[i, j] += A[i, k] * A[j, k]
        @test B == B_ref
    end

    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        if m == n
            println("B[] += A[i,k] * A[i, j] * A[j, k] : $mtx")
            A = fiber(A_ref)
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
        A = fiber(A_ref)
        B = fiber(B_ref)
        C = @fiber(sl(e(0.0)))
        d = Scalar{0.0}()
        a = Scalar{0.0}()
        b = Scalar{0.0}()

        @finch @loop i (C[i] = a[] - b[]; d[] += a[] * b[]) where (a[] = A[i]; b[] = B[i])

        @test C == A_ref .- B_ref
        @test d[] ≈ dot(A_ref, B_ref)
    end

    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        if m == n
            println("B(ds)[i, j] = w[j] where w[j] += A(ds)[i, k] * A(ds)(k, j)")
            A = fiber(permutedims(A_ref))
            B = @fiber(d(sl(e(0.0))))
            w = @fiber(sm(e(0.0)))

            @finch @loop i ((@loop j B[i, j] = w[j]) where (@loop k j w[j] = A[i, k] * A[k, j]))
        end
    end
end