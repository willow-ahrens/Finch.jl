@inbounds begin
        B = ex.lhs.tns.tns
        B_val = B.val
        A_lvl = ex.rhs.tns.tns.lvl
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_val_alloc = length(A_lvl.lvl.val)
        A_lvl_2_val = 0.0
        B_val = 0.0
        A_lvl_q = A_lvl.pos[1]
        A_lvl_q_stop = A_lvl.pos[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i = A_lvl.idx[A_lvl_q]
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i = 1
            A_lvl_i1 = 0
        end
        s = 5
        s_start = s
        phase_start = s_start
        phase_stop = (min)(A_lvl_i1, 5)
        if phase_stop >= phase_start
            s_2 = s
            s = phase_start
            while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start
                A_lvl_q += 1
            end
            while s <= phase_stop
                s_start_2 = s
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_2 = (min)(A_lvl_i, phase_stop)
                s_3 = s
                if A_lvl_i == phase_stop_2
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    s_4 = phase_stop_2
                    B_val = (+)(A_lvl_2_val, B_val)
                    A_lvl_q += 1
                else
                end
                s = phase_stop_2 + 1
            end
            s = phase_stop + 1
        end
        s_start = s
        phase_start_3 = s_start
        if 5 >= phase_start_3
            s_5 = s
            s = 5 + 1
        end
        (B = (Scalar){0.0, Float64}(B_val),)
    end
