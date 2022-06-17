@inbounds begin
        B = ex.body.body.lhs.tns.tns
        A_lvl = ex.body.body.rhs.tns.tns.lvl
        A_lvl_I = A_lvl.I
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_I = A_lvl_2.I
        A_lvl_2_pos_alloc = length(A_lvl_2.pos)
        A_lvl_2_idx_alloc = length(A_lvl_2.idx)
        A_lvl_3 = A_lvl_2.lvl
        A_lvl_3_val_alloc = length(A_lvl_2.lvl.val)
        A_lvl_3_val = 0.0
        (B_mode1_stop,) = size(B)
        j_stop = A_lvl_I
        i_stop = B_mode1_stop
        (B_mode1_stop,) = size(B)
        1 == 1 || throw(DimensionMismatch("mismatched dimension start"))
        B_mode1_stop == B_mode1_stop || throw(DimensionMismatch("mismatched dimension stop"))
        fill!(B, 0)
        for j = 1:j_stop
            A_lvl_q = (1 - 1) * A_lvl_I + j
            A_lvl_2_q = A_lvl_2.pos[A_lvl_q]
            A_lvl_2_q_stop = A_lvl_2.pos[A_lvl_q + 1]
            if A_lvl_2_q < A_lvl_2_q_stop
                A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
            else
                A_lvl_2_i = 1
                A_lvl_2_i1 = 0
            end
            i = 1
            i_start = i
            phase_start = max(i_start)
            phase_stop = min(i_stop, A_lvl_2_i1)
            if phase_stop >= phase_start
                i = i
                i = phase_start
                while A_lvl_2_q < A_lvl_2_q_stop && A_lvl_2.idx[A_lvl_2_q] < phase_start
                    A_lvl_2_q += 1
                end
                while i <= phase_stop
                    i_start_2 = i
                    A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                    phase_stop_2 = min(A_lvl_2_i, phase_stop)
                    i_2 = i
                    if A_lvl_2_i == phase_stop_2
                        A_lvl_3_val = A_lvl_3.val[A_lvl_2_q]
                        i_3 = phase_stop_2
                        B[i_3] = B[i_3] + A_lvl_3_val
                        A_lvl_2_q += 1
                    else
                    end
                    i = phase_stop_2 + 1
                end
                i = phase_stop + 1
            end
            i_start = i
            phase_stop_3 = i_stop
            i_4 = i
            i = phase_stop_3 + 1
        end
        (B = B,)
    end
