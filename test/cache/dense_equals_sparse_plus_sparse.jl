@inbounds begin
        C = ex.body.lhs.tns.tns
        A = (ex.body.rhs.args[1]).tns.tns
        B = (ex.body.rhs.args[2]).tns.tns
        (C_mode1_stop,) = size(C)
        A_stop = (size(A))[1]
        B_stop = (size(B))[1]
        (C_mode1_stop,) = size(C)
        1 == 1 || throw(DimensionMismatch("mismatched dimension start"))
        C_mode1_stop == C_mode1_stop || throw(DimensionMismatch("mismatched dimension stop"))
        i_stop = C_mode1_stop
        fill!(C, 0)
        A_p = 1
        A_i0 = 1
        A_i1 = A.idx[A_p]
        B_p = 1
        B_i0 = 1
        B_i1 = B.idx[B_p]
        i = 1
        A_p = searchsortedfirst(A.idx, 1, A_p, length(A.idx), Base.Forward)
        A_i0 = 1
        A_i1 = A.idx[A_p]
        B_p = searchsortedfirst(B.idx, 1, B_p, length(B.idx), Base.Forward)
        B_i0 = 1
        B_i1 = B.idx[B_p]
        while i <= i_stop
            i_start = i
            phase_start = max(i_start)
            phase_stop = min(A_i1, B_i1, i_stop)
            if phase_stop >= phase_start
                i = i
                if A_i1 == phase_stop && B_i1 == phase_stop
                    i_2 = phase_stop
                    C[i_2] = C[i_2] + (A.val[A_p] + B.val[B_p])
                    A_p += 1
                    A_i0 = A_i1 + 1
                    A_i1 = A.idx[A_p]
                    B_p += 1
                    B_i0 = B_i1 + 1
                    B_i1 = B.idx[B_p]
                elseif B_i1 == phase_stop
                    i_3 = phase_stop
                    C[i_3] = C[i_3] + B.val[B_p]
                    B_p += 1
                    B_i0 = B_i1 + 1
                    B_i1 = B.idx[B_p]
                elseif A_i1 == phase_stop
                    i_4 = phase_stop
                    C[i_4] = C[i_4] + A.val[A_p]
                    A_p += 1
                    A_i0 = A_i1 + 1
                    A_i1 = A.idx[A_p]
                else
                end
                i = phase_stop + 1
            end
        end
        (C = C,)
    end
