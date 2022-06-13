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
        stop = min(A_lvl_I, A_lvl_i1)
        if stop >= start
            j = j
            j = start
            while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < start
                A_lvl_q += 1
            end
            while j <= stop
                j_start_2 = j
                A_lvl_i = A_lvl.idx[A_lvl_q]
                start_3 = max(j_start_2, j_start_2)
                stop_3 = min(stop, A_lvl_i)
                j_2 = j
                if A_lvl_i == stop_3
                    for j_3 = start_3:stop_3 - 1
                        cond = j_3 == 1
                        if cond
                        end
                    end
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    j_4 = stop_3
                    cond_2 = j_4 == 1
                    if cond_2
                        B_val = B_val + A_lvl_2_val
                    end
                    A_lvl_q += 1
                else
                    for j_5 = start_3:stop_3
                        cond_3 = j_5 == 1
                        if cond_3
                        end
                    end
                end
                j = stop_3 + 1
            end
            j = stop + 1
        end
        j_start = j
        j_6 = j
        for j_7 = j_start:A_lvl_I
            cond_4 = j_7 == 1
            if cond_4
            end
        end
        j = A_lvl_I + 1
        (B = (Scalar){0.0, Float64}(B_val),)
    end
