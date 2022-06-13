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
        i_start = 1
        i_step = min(A_lvl_i1, B_lvl_i1, A_lvl_I)
        if i_start <= i_step
            i_start_2 = i_start
            while i_start_2 <= i_step
                A_lvl_i = A_lvl.idx[A_lvl_q]
                B_lvl_i = B_lvl.idx[B_lvl_q]
                i_step_2 = min(A_lvl_i, B_lvl_i, i_step)
                if i_step_2 == A_lvl_i && i_step_2 == B_lvl_i
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    i = i_step_2
                    C[i] = C[i] + (A_lvl_2_val + B_lvl_2_val)
                    A_lvl_q += 1
                    B_lvl_q += 1
                elseif i_step_2 == B_lvl_i
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    i_2 = i_step_2
                    C[i_2] = C[i_2] + B_lvl_2_val
                    B_lvl_q += 1
                elseif i_step_2 == A_lvl_i
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    i_3 = i_step_2
                    C[i_3] = C[i_3] + A_lvl_2_val
                    A_lvl_q += 1
                else
                end
                i_start_2 = i_step_2 + 1
            end
            i_start = i_step + 1
        end
        i_step = min(A_lvl_i1, A_lvl_I)
        if i_start <= i_step
            i_start_3 = i_start
            while i_start_3 <= i_step
                A_lvl_i = A_lvl.idx[A_lvl_q]
                i_step_3 = min(A_lvl_i, i_step)
                if i_step_3 == A_lvl_i
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    i_4 = i_step_3
                    C[i_4] = C[i_4] + A_lvl_2_val
                    A_lvl_q += 1
                else
                end
                i_start_3 = i_step_3 + 1
            end
            i_start = i_step + 1
        end
        i_step = min(B_lvl_i1, A_lvl_I)
        if i_start <= i_step
            i_start_4 = i_start
            while i_start_4 <= i_step
                B_lvl_i = B_lvl.idx[B_lvl_q]
                i_step_4 = min(B_lvl_i, i_step)
                if i_step_4 == B_lvl_i
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    i_5 = i_step_4
                    C[i_5] = C[i_5] + B_lvl_2_val
                    B_lvl_q += 1
                else
                end
                i_start_4 = i_step_4 + 1
            end
            i_start = i_step + 1
        end
        i_step = min(A_lvl_I)
        if i_start <= i_step
            i_start = i_step + 1
        end
        (C = C,)
    end
