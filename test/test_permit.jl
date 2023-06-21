@testset "permit" begin
    @info "Testing Shifted Looplets"
    using SparseArrays

    A_ref = sprand(10, 0.5); B_ref = sprand(10, 0.5); C_ref = vcat(A_ref, B_ref)
    A = fiber(SparseVector{Float64, Int64}(A_ref)); B = fiber(SparseVector{Float64, Int64}(B_ref)); C = @fiber(sl{Int64}(e(0.0), 20))
    @test check_output("concat_offset_permit.jl", @finch_code (C .= 0; @loop i C[i] = coalesce(A[~i], B[i + 10])))
    @finch (C .= 0; @loop i C[i] = coalesce(A[~i], B[~(i + -10)]))
    @test reference_isequal(C, C_ref)

    #=

    F = fiber(Int64[1,1,1,1,1])

    @test check_output("sparse_conv.jl", @finch_code (C .= 0; @loop i j C[i] += (A[i] != 0) * coalesce(A[offset[j, i - 3]], 0) * F[j]))
    @finch (C .= 0; @loop i j C[i] += (A[i] != 0) * coalesce(A[offset[j, i - 3]], 0) * F[j])
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
    @test check_output("sparse_conv_guarded.jl", @finch_code (C .= 0; @loop i j C[i] += (A[i] != 0) * coalesce(A[offset[j, i - 3]], 0) * coalesce(F[permit[j]], 0)))
    @finch (C .= 0; @loop i j C[i] += (A[i] != 0) * coalesce(A[offset[j, i - 3]], 0) * coalesce(F[permit[j]], 0))
    @test reference_isequal(C, C_ref)

    win = window(2, 4)
    @test check_output("sparse_window.jl", @finch_code (C .= 0; @loop i C[i] = A[win[i]]))
    @finch (C .= 0; @loop i C[i] = A[win[i]])
    @test reference_isequal(C, [A(2), A(3), A(4)])

    win = 2:4
    @test check_output("sparse_range.jl", @finch_code (C .= 0; @loop i C[i] = A[win[i]]))
    @finch (C .= 0; @loop i C[i] = A[win[i]])
    @test reference_isequal(C, [A(2), A(3), A(4)])

    @finch (C .= 0; @loop i C[i] = win[i])
    @test reference_isequal(C, [2, 3, 4])
    =#
end