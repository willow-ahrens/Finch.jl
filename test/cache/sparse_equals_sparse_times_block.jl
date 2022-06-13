@inbounds begin
        C = ex.body.lhs.tns.tns
        A = (ex.body.rhs.args[1]).tns.tns
        B = (ex.body.rhs.args[2]).tns.tns
        C_stop = (size(C))[1]
        A_stop = (size(A))[1]
        B_stop = (size(B))[1]
        C_stop_2 = (size(C))[1]
        A_stop_2 = (size(A))[1]
        B_stop_2 = (size(B))[1]
        C_stop_3 = (size(C))[1]
        A_stop_3 = (size(A))[1]
        B_stop_3 = (size(B))[1]
        C_stop_4 = (size(C))[1]
        A_stop_4 = (size(A))[1]
        A_stop_2 == A_stop_4 || throw(DimensionMismatch("mismatched dimension limits"))
        B_stop_4 = (size(B))[1]
        A_stop_2 == B_stop_4 || throw(DimensionMismatch("mismatched dimension limits"))
        C.idx = [C.idx[end]]
        C.val = (Int64)[]
        C_p = 0
        C_I = A_stop + 1
        C.idx = (Int64)[C_I]
        C.val = (Float64)[]
        B_p = 1
        B_i0 = 1
        B_i1 = B.idx[B_p]
        i_start = 1
        i_step = min(A.start - 1, A_stop)
        i_start = i_step + 1
        i_step = min(A.stop, A_stop)
        i_start_2 = i_start
        B_p = searchsortedfirst(B.idx, i_start_2, B_p, length(B.idx), Base.Forward)
        B_i0 = i_start_2
        B_i1 = B.idx[B_p]
        while i_start_2 <= i_step
            i_step_2 = min(B_i1, i_step)
            if i_step_2 < B_i1
            else
                i = i_step_2
                push!(C.idx, C_I)
                push!(C.val, zero(Float64))
                C_p += 1
                C.val[C_p] = C.val[C_p] + A.val[(i - A.start) + 1] * B.val[B_p]
                C.idx[C_p] = i
                B_p += 1
                B_i0 = B_i1 + 1
                B_i1 = B.idx[B_p]
            end
            i_start_2 = i_step_2 + 1
        end
        i_start = i_step + 1
        i_step = min(A_stop)
        i_start = i_step + 1
        (C = C,)
    end
