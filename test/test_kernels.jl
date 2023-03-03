@testset "kernels" begin
    using SparseArrays

    seen = false
    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        println("B[i, j] += A[i,k] * A[j, k]: $mtx")
        B_ref = transpose(A_ref) * A_ref 
        A = fiber(A_ref)
        B = @fiber(d(sl(e(0.0),m),m))

        if !seen
            check_output("innerprod.jl", @finch_code @loop j i k B[i, j] += A[k, i] * A[k, j])
            seen = true
        end
        @finch @loop j i k B[i, j] += A[k, i] * A[k, j]
        @test B == B_ref
    end

    seen = false
    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        if m == n
            println("B[] += A[i,k] * A[i, j] * A[j, k] : $mtx")
            A = fiber(A_ref)
            B = Finch.Scalar{0.0}()
            if !seen
                check_output("triangle.jl", @finch_code @loop i j k B[] += A[k, i] * A[j, i] * A[k, j])
                seen = true
            end
            @finch @loop i j k B[] += A[k, i] * A[j, i] * A[k, j]
            @test B() ≈ sum(A_ref .* (A_ref * transpose(A_ref)))
        end
    end

    for trial = 1:10
        n = 100
        p = q = 0.1

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

    seen = false
    for (mtx, A_ref) in matrices
        A_ref = SparseMatrixCSC(A_ref)
        m, n = size(A_ref)
        if m == n
            A = fiber(A_ref)
            B = @fiber(d(sl(e(0.0))))
            w = @fiber(sm(e(0.0)))

            if !seen
                check_output("gustavsons.jl", @finch_code @loop i ((@loop j B[j, i] = w[j]) where (@loop k j w[j] += A[k, i] * A[j, k])))
                seen = true
            end
            @finch @loop j begin
                @loop k i w[i] += A[i, k] * A[k, j]
                @loop i B[i, j] = w[i]
            end
            B_ref = A_ref * A_ref
            @test B == B_ref
        end
    end
end