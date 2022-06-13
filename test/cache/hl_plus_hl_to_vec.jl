@inbounds begin
        C = ex.body.lhs.tns.tns
        A_lvl = (ex.body.rhs.args[1]).tns.tns.lvl
        A_lvl_I = A_lvl.I
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_val_alloc = length(A_lvl.lvl.val)
        A_lvl_2_val = 0.0
        B_lvl = (ex.body.rhs.args[2]).tns.tns.lvl
        B_lvl_I = B_lvl.I
        B_lvl_pos_alloc = length(B_lvl.pos)
        B_lvl_idx_alloc = length(B_lvl.idx)
        B_lvl_2 = B_lvl.lvl
        B_lvl_2_val_alloc = length(B_lvl.lvl.val)
        B_lvl_2_val = 0.0
        (C_mode1_stop,) = size(C)
        (C_mode1_stop_2,) = size(C)
        (C_mode1_stop_3,) = size(C)
        (C_mode1_stop_4,) = size(C)
        (C_mode1_stop_5,) = size(C)
        A_lvl_I == C_mode1_stop_5 || throw(DimensionMismatch("mismatched dimension limits"))
        A_lvl_I == B_lvl_I || throw(DimensionMismatch("mismatched dimension limits"))
        fill!(C, 0)
        A_lvl_q = A_lvl.pos[1]
        A_lvl_q_stop = A_lvl.pos[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i = A_lvl.idx[A_lvl_q]
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i = 1
            A_lvl_i1 = 0
        end
        B_lvl_q = B_lvl.pos[1]
        B_lvl_q_stop = B_lvl.pos[1 + 1]
        if B_lvl_q < B_lvl_q_stop
            B_lvl_i = B_lvl.idx[B_lvl_q]
            B_lvl_i1 = B_lvl.idx[B_lvl_q_stop - 1]
        else
            B_lvl_i = 1
            B_lvl_i1 = 0
        end
        i = 1
        i_start = i
        start = max(i_start, i_start)
        stop = min(A_lvl_i1, B_lvl_i1)
        start_3 = max(i_start, start)
        stop_3 = min(A_lvl_I, stop)
        if stop_3 >= start_3
            i = i
            i = start_3
            while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < start_3
                A_lvl_q += 1
            end
            while B_lvl_q < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < start_3
                B_lvl_q += 1
            end
            while i <= stop_3
                i_start_2 = i
                A_lvl_i = A_lvl.idx[A_lvl_q]
                B_lvl_i = B_lvl.idx[B_lvl_q]
                start_5 = max(i_start_2, i_start_2)
                stop_5 = min(A_lvl_i, B_lvl_i)
                start_7 = max(i_start_2, start_5)
                stop_7 = min(stop_3, stop_5)
                if stop_7 >= start_7
                    i_2 = i
                    if A_lvl_i == stop_7 && B_lvl_i == stop_7
                        A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                        B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                        i_3 = stop_7
                        C[i_3] = C[i_3] + (A_lvl_2_val + B_lvl_2_val)
                        A_lvl_q += 1
                        B_lvl_q += 1
                    elseif B_lvl_i == stop_7
                        B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                        i_4 = stop_7
                        C[i_4] = C[i_4] + B_lvl_2_val
                        B_lvl_q += 1
                    elseif A_lvl_i == stop_7
                        A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                        i_5 = stop_7
                        C[i_5] = C[i_5] + A_lvl_2_val
                        A_lvl_q += 1
                    else
                    end
                    i = stop_7 + 1
                end
            end
            i = stop_3 + 1
        end
        i_start = i
        start_9 = max(i_start, i_start)
        stop_9 = min(A_lvl_I, A_lvl_i1)
        if stop_9 >= start_9
            i_6 = i
            i = start_9
            while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < start_9
                A_lvl_q += 1
            end
            while i <= stop_9
                i_start_3 = i
                A_lvl_i = A_lvl.idx[A_lvl_q]
                stop_11 = min(stop_9, A_lvl_i)
                i_7 = i
                if A_lvl_i == stop_11
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    i_8 = stop_11
                    C[i_8] = C[i_8] + A_lvl_2_val
                    A_lvl_q += 1
                else
                end
                i = stop_11 + 1
            end
            i = stop_9 + 1
        end
        i_start = i
        start_13 = max(i_start, i_start)
        stop_13 = min(A_lvl_I, B_lvl_i1)
        if stop_13 >= start_13
            i_9 = i
            i = start_13
            while B_lvl_q < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < start_13
                B_lvl_q += 1
            end
            while i <= stop_13
                i_start_4 = i
                B_lvl_i = B_lvl.idx[B_lvl_q]
                stop_15 = min(stop_13, B_lvl_i)
                i_10 = i
                if B_lvl_i == stop_15
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    i_11 = stop_15
                    C[i_11] = C[i_11] + B_lvl_2_val
                    B_lvl_q += 1
                else
                end
                i = stop_15 + 1
            end
            i = stop_13 + 1
        end
        i_start = i
        i_12 = i
        i = A_lvl_I + 1
        (C = C,)
    end
