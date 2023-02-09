@testset "permit" begin

    #=
    v = Array{Any}(zeros(5, 10))
    a = Fiber(Dense(5, Element(0, [1, 2, 3, 4, 5])))
    println(@finch_code @loop i j v[i, j] = a[offset[i, j]])
    @finch @loop i j v[i, j] = a[offset[i, j]]
    display(v)
    =#

    #TODO all these tests need to be overhauled

    A_ref = sprand(10, 0.5); B_ref = sprand(10, 0.5); C_ref = vcat(A_ref, B_ref)
    A = fiber(SparseVector{Float64, Int64}(A_ref)); B = fiber(SparseVector{Float64, Int64}(B_ref)); C = @fiber(sl{Int64}(e(0.0)))
    off = staticoffset(10)
    @test diff("concat_offset_permit.jl", @finch_code @loop i C[i] = coalesce(A[permit[i]], B[off[i]]))
    @finch @loop i C[i] = coalesce(A[permit[i]], B[off[i]])
    @test reference_isequal(C, C_ref)

    F = fiber(Int64[1,1,1,1,1])

    @test diff("sparse_conv.jl", @finch_code @loop i j C[i] += (A[i] != 0) * coalesce(A[offset[i - 3, j]], 0) * F[j])
    @finch @loop i j C[i] += (A[i] != 0) * coalesce(A[offset[i - 3, j]], 0) * F[j]
    C_ref = zeros(10)
    for i = 1:10
        if A_ref[i] != 0
            for j = 1:5
                k = (j - (i - 3))
                if 1 <= k <= 10
                    C_ref[i] += A_ref[k]
                end
            end
        end
    end
    @test reference_isequal(C, C_ref)
    @test diff("sparse_conv_guarded.jl", @finch_code @loop i j C[i] += (A[i] != 0) * coalesce(A[offset[i - 3, j]], 0) * coalesce(F[permit[j]], 0))
    @finch @loop i j C[i] += (A[i] != 0) * coalesce(A[offset[i - 3, j]], 0) * coalesce(F[permit[j]], 0)
    @test reference_isequal(C, C_ref)

    #=
    win = window(2, 4)
    @test diff("sparse_window.jl", @finch_code @loop i C[i] = A[win[i]])
    println(@finch_code @loop i C[i] = A[win[i]])
    @finch @loop i C[i] = A[win[i]]
    @test reference_isequal(C, [A(2), A(3), A(4)])
    =#
end