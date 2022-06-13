@inbounds begin
        B = ex.lhs.tns.tns
        B_val = B.val
        A_lvl = ex.rhs.tns.tns.lvl
        A_lvl_I = A_lvl.I
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_val_alloc = length(A_lvl.lvl.val)
        A_lvl_2_val = 0.0
        B_val = 0.0
        selects = 5
        A_lvl_q = A_lvl.pos[1]
        A_lvl_q_stop = A_lvl.pos[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i = A_lvl.idx[A_lvl_q]
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i = 1
            A_lvl_i1 = 0
        end
        s = 1
        s_start = s
        start = max(s_start, s_start)
        stop = min(selects - 1, A_lvl_i1)
        start_3 = max(s_start, start)
        stop_3 = min(A_lvl_I, stop)
        if stop_3 >= start_3
            s_2 = s
            s = stop_3 + 1
        end
        s_start = s
        start_5 = max(s_start, s_start)
        stop_5 = min(A_lvl_I, selects - 1)
        if stop_5 >= start_5
            s_3 = s
            s = stop_5 + 1
        end
        s_start = s
        start_7 = max(s_start, s_start)
        stop_7 = min(selects, A_lvl_i1)
        start_9 = max(s_start, start_7)
        stop_9 = min(A_lvl_I, stop_7)
        if stop_9 >= start_9
            s_4 = s
            s = start_9
            while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < start_9
                A_lvl_q += 1
            end
            while s <= stop_9
                s_start_2 = s
                A_lvl_i = A_lvl.idx[A_lvl_q]
                stop_11 = min(stop_9, A_lvl_i)
                s_5 = s
                if A_lvl_i == stop_11
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    s_6 = stop_11
                    B_val = B_val + A_lvl_2_val
                    A_lvl_q += 1
                else
                end
                s = stop_11 + 1
            end
            s = stop_9 + 1
        end
        s_start = s
        start_13 = max(s_start, s_start)
        stop_13 = min(A_lvl_I, selects)
        if stop_13 >= start_13
            s_7 = s
            s = stop_13 + 1
        end
        s_start = s
        start_15 = max(s_start, s_start)
        stop_15 = min(A_lvl_I, A_lvl_i1)
        if stop_15 >= start_15
            s_8 = s
            s = stop_15 + 1
        end
        s_start = s
        s_9 = s
        s = A_lvl_I + 1
        (B = (Scalar){0.0, Float64}(B_val),)
    end
