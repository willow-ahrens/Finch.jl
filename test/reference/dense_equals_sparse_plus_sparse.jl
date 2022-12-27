@inbounds begin
        C = ex.body.lhs.tns.tns
        A = (ex.body.rhs.args[1]).tns.tns
        B = (ex.body.rhs.args[2]).tns.tns
        (C_mode1_stop,) = size(C)
        A_stop = ((size)(A))[1]
        B_stop = ((size)(B))[1]
        (C_mode1_stop,) = size(C)
        (C_mode1_stop,) = size(C)
        1 == 1 || throw(DimensionMismatch("mismatched dimension start"))
        C_mode1_stop == C_mode1_stop || throw(DimensionMismatch("mismatched dimension stop"))
        i_stop = C_mode1_stop
        fill!(C, 0)
        B_p = 1
        B_i0 = 1
        B_i1 = B.idx[B_p]
        A_p = 1
        A_i0 = 1
        A_i1 = A.idx[A_p]
        i = 1
        B_p = searchsortedfirst(B.idx, 1, B_p, length(B.idx), Base.Forward)
        B_i0 = 1
        B_i1 = B.idx[B_p]
        A_p = searchsortedfirst(A.idx, 1, A_p, length(A.idx), Base.Forward)
        A_i0 = 1
        A_i1 = A.idx[A_p]
        while i <= i_stop
            i_start = i
            phase_stop = (min)(A_i1, B_i1, i_stop)
            i = i
            if B_i1 == phase_stop && A_i1 == phase_stop
                i_2 = phase_stop
                C[i_2] = (+)(B.val[B_p], C[i_2], A.val[A_p])
                B_p += 1
                B_i0 = B_i1 + 1
                B_i1 = B.idx[B_p]
                A_p += 1
                A_i0 = A_i1 + 1
                A_i1 = A.idx[A_p]
            elseif A_i1 == phase_stop
                i_3 = phase_stop
                C[i_3] = (+)(C[i_3], A.val[A_p])
                A_p += 1
                A_i0 = A_i1 + 1
                A_i1 = A.idx[A_p]
            elseif B_i1 == phase_stop
                i_4 = phase_stop
                C[i_4] = (+)(B.val[B_p], C[i_4])
                B_p += 1
                B_i0 = B_i1 + 1
                B_i1 = B.idx[B_p]
            else
            end
            i = phase_stop + 1
        end
        (C = C,)
    end
