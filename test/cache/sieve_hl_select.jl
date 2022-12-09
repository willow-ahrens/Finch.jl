@inbounds begin
        B = ex.body.body.lhs.tns.tns
        B_val = B.val
        A_lvl = ex.body.body.rhs.tns.tns.lvl
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_val_alloc = length(A_lvl.lvl.val)
        A_lvl_2_val = 0.0
        j_stop = A_lvl.I
        B_val = 0.0
        select_j = 3
        A_lvl_q = A_lvl.pos[1]
        A_lvl_q_stop = A_lvl.pos[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i = A_lvl.idx[A_lvl_q]
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i = 1
            A_lvl_i1 = 0
        end
        j = 1
        j_start = j
        phase_start = j_start
        phase_stop = (min)(A_lvl_i1, select_j - 1, j_stop)
        if phase_stop >= phase_start
            j = j
            j = phase_stop + 1
        end
        j_start = j
        phase_start_2 = j_start
        phase_stop_2 = (min)(select_j - 1, j_stop)
        if phase_stop_2 >= phase_start_2
            j_2 = j
            j = phase_stop_2 + 1
        end
        j_start = j
        phase_start_3 = j_start
        phase_stop_3 = (min)(A_lvl_i1, j_stop, select_j)
        if phase_stop_3 >= phase_start_3
            j_3 = j
            j = phase_start_3
            while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_3
                A_lvl_q += 1
            end
            while j <= phase_stop_3
                j_start_2 = j
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_4 = (min)(A_lvl_i, phase_stop_3)
                j_4 = j
                if A_lvl_i == phase_stop_4
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    j_5 = phase_stop_4
                    B_val = (+)(A_lvl_2_val, B_val)
                    A_lvl_q += 1
                else
                end
                j = phase_stop_4 + 1
            end
            j = phase_stop_3 + 1
        end
        j_start = j
        phase_start_5 = j_start
        phase_stop_5 = (min)(j_stop, select_j)
        if phase_stop_5 >= phase_start_5
            j_6 = j
            j = phase_stop_5 + 1
        end
        j_start = j
        phase_start_6 = j_start
        phase_stop_6 = (min)(A_lvl_i1, j_stop)
        if phase_stop_6 >= phase_start_6
            j_7 = j
            j = phase_stop_6 + 1
        end
        j_start = j
        phase_start_7 = j_start
        phase_stop_7 = j_stop
        if phase_stop_7 >= phase_start_7
            j_8 = j
            j = phase_stop_7 + 1
        end
        (B = (Scalar){0.0, Float64}(B_val),)
    end
