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
        (B_mode1_stop_2,) = size(B)
        (B_mode1_stop_3,) = size(B)
        (B_mode1_stop_4,) = size(B)
        (B_mode1_stop_5,) = size(B)
        A_lvl_2_I == B_mode1_stop_5 || throw(DimensionMismatch("mismatched dimension limits"))
        fill!(B, 0)
        for j = 1:A_lvl_I
            A_lvl_q = (1 - 1) * A_lvl.I + j
            A_lvl_2_q = A_lvl_2.pos[A_lvl_q]
            A_lvl_2_q_stop = A_lvl_2.pos[A_lvl_q + 1]
            if A_lvl_2_q < A_lvl_2_q_stop
                A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
            else
                A_lvl_2_i = 1
                A_lvl_2_i1 = 0
            end
            i_start = 1
            i_step = min(A_lvl_2_i1, A_lvl_2_I)
            i_start_2 = i_start
            while i_start_2 <= i_step
                A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                i_step_2 = min(A_lvl_2_i, i_step)
                if i_step_2 == A_lvl_2_i
                    A_lvl_3_val = A_lvl_3.val[A_lvl_2_q]
                    i = i_step_2
                    B[i] = B[i] + A_lvl_3_val
                    A_lvl_2_q += 1
                else
                end
                i_start_2 = i_step_2 + 1
            end
            i_start = i_step + 1
            i_step = min(A_lvl_2_I)
            i_start = i_step + 1
        end
        (B = B,)
    end
