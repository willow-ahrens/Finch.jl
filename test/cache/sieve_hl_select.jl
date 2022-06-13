@inbounds begin
        B = ex.body.body.lhs.tns.tns
        B_val = B.val
        A_lvl = ex.body.body.rhs.tns.tns.lvl
        A_lvl_I = A_lvl.I
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_val_alloc = length(A_lvl.lvl.val)
        A_lvl_2_val = 0.0
        B_val = 0.0
        selectj = 3
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
        start = max(j_start, j_start)
        stop = min(selectj - 1, A_lvl_i1)
        start_3 = max(j_start, start)
        stop_3 = min(A_lvl_I, stop)
        if stop_3 >= start_3
            j = j
            j = stop_3 + 1
        end
        j_start = j
        start_5 = max(j_start, j_start)
        stop_5 = min(A_lvl_I, selectj - 1)
        if stop_5 >= start_5
            j_2 = j
            j = stop_5 + 1
        end
        j_start = j
        start_7 = max(j_start, j_start)
        stop_7 = min(selectj, A_lvl_i1)
        start_9 = max(j_start, start_7)
        stop_9 = min(A_lvl_I, stop_7)
        if stop_9 >= start_9
            j_3 = j
            j = start_9
            while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < start_9
                A_lvl_q += 1
            end
            while j <= stop_9
                j_start_2 = j
                A_lvl_i = A_lvl.idx[A_lvl_q]
                stop_11 = min(stop_9, A_lvl_i)
                j_4 = j
                if A_lvl_i == stop_11
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    j_5 = stop_11
                    B_val = B_val + A_lvl_2_val
                    A_lvl_q += 1
                else
                end
                j = stop_11 + 1
            end
            j = stop_9 + 1
        end
        j_start = j
        start_13 = max(j_start, j_start)
        stop_13 = min(A_lvl_I, selectj)
        if stop_13 >= start_13
            j_6 = j
            j = stop_13 + 1
        end
        j_start = j
        start_15 = max(j_start, j_start)
        stop_15 = min(A_lvl_I, A_lvl_i1)
        if stop_15 >= start_15
            j_7 = j
            j = stop_15 + 1
        end
        j_start = j
        j_8 = j
        j = A_lvl_I + 1
        (B = (Scalar){0.0, Float64}(B_val),)
    end
