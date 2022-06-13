@inbounds begin
        C = ex.body.lhs.tns.tns
        A = (ex.body.rhs.args[1]).tns.tns
        B = (ex.body.rhs.args[2]).tns.tns
        (C_mode1_stop,) = size(C)
        A_stop = (size(A))[1]
        B_stop = (size(B))[1]
        (C_mode1_stop_2,) = size(C)
        A_stop_2 = (size(A))[1]
        B_stop_2 = (size(B))[1]
        (C_mode1_stop_3,) = size(C)
        A_stop_3 = (size(A))[1]
        B_stop_3 = (size(B))[1]
        (C_mode1_stop_4,) = size(C)
        (C_mode1_stop_5,) = size(C)
        A_stop_2 == C_mode1_stop_5 || throw(DimensionMismatch("mismatched dimension limits"))
        A_stop_4 = (size(A))[1]
        A_stop_2 == A_stop_4 || throw(DimensionMismatch("mismatched dimension limits"))
        B_stop_4 = (size(B))[1]
        A_stop_2 == B_stop_4 || throw(DimensionMismatch("mismatched dimension limits"))
        fill!(C, 0)
        A_p = 1
        A_i0 = 1
        A_i1 = A.idx[A_p]
        B_p = 1
        B_i0 = 1
        B_i1 = B.idx[B_p]
        i_start = 1
        while i_start <= A_stop
            i_step = min(A_i1, B_i1, A_stop)
            if i_step < A_i1 && i_step < B_i1
            elseif i_step < B_i1
                i = i_step
                C[i] = C[i] + A.val[A_p]
                A_p += 1
                A_i0 = A_i1 + 1
                A_i1 = A.idx[A_p]
            elseif i_step < A_i1
                i_2 = i_step
                C[i_2] = C[i_2] + B.val[B_p]
                B_p += 1
                B_i0 = B_i1 + 1
                B_i1 = B.idx[B_p]
            else
                i_3 = i_step
                C[i_3] = C[i_3] + (A.val[A_p] + B.val[B_p])
                A_p += 1
                A_i0 = A_i1 + 1
                A_i1 = A.idx[A_p]
                B_p += 1
                B_i0 = B_i1 + 1
                B_i1 = B.idx[B_p]
            end
            i_start = i_step + 1
        end
        (C = C,)
    end
