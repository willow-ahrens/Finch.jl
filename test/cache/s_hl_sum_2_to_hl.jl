@inbounds begin
        B_lvl = ex.body.body.lhs.tns.tns.lvl
        B_lvl_I = B_lvl.I
        B_lvl_pos_alloc = length(B_lvl.pos)
        B_lvl_idx_alloc = length(B_lvl.idx)
        B_lvl_2 = B_lvl.lvl
        B_lvl_2_val_alloc = length(B_lvl.lvl.val)
        B_lvl_2_val = 0.0
        A_lvl = ex.body.body.rhs.tns.tns.lvl
        A_lvl_I = A_lvl.I
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_I = A_lvl_2.I
        A_lvl_2_pos_alloc = length(A_lvl_2.pos)
        A_lvl_2_idx_alloc = length(A_lvl_2.idx)
        A_lvl_3 = A_lvl_2.lvl
        A_lvl_3_val_alloc = length(A_lvl_2.lvl.val)
        A_lvl_3_val = 0.0
        B_lvl_I = A_lvl_2_I
        B_lvl_pos_alloc = length(B_lvl.pos)
        B_lvl.pos[1] = 1
        B_lvl_idx_alloc = length(B_lvl.idx)
        B_lvl_2_val_alloc = (Finch).refill!(B_lvl_2.val, 0.0, 0, 4)
        B_lvl_p_stop_2 = 1
        B_lvl_pos_alloc < B_lvl_p_stop_2 + 1 && (B_lvl_pos_alloc = (Finch).regrow!(B_lvl.pos, B_lvl_pos_alloc, B_lvl_p_stop_2 + 1))
        for i = 1:A_lvl_I
            A_lvl_q = (1 - 1) * A_lvl.I + i
            B_lvl_q = B_lvl.pos[1]
            A_lvl_2_q = A_lvl_2.pos[A_lvl_q]
            A_lvl_2_q_stop = A_lvl_2.pos[A_lvl_q + 1]
            if A_lvl_2_q < A_lvl_2_q_stop
                A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
            else
                A_lvl_2_i = 1
                A_lvl_2_i1 = 0
            end
            j_start = 1
            j_step = min(A_lvl_2_i1, A_lvl_2_I)
            j_start_2 = j_start
            while j_start_2 <= j_step
                A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                j_step_2 = min(A_lvl_2_i, j_step)
                if j_step_2 == A_lvl_2_i
                    A_lvl_3_val = A_lvl_3.val[A_lvl_2_q]
                    j = j_step_2
                    B_lvl_2_val_alloc < B_lvl_q && (B_lvl_2_val_alloc = (Finch).refill!(B_lvl_2.val, 0.0, B_lvl_2_val_alloc, B_lvl_q))
                    B_lvl_isdefault = true
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    B_lvl_isdefault = false
                    B_lvl_isdefault = false
                    B_lvl_2_val = B_lvl_2_val + A_lvl_3_val
                    B_lvl_2.val[B_lvl_q] = B_lvl_2_val
                    if !B_lvl_isdefault
                        B_lvl_idx_alloc < B_lvl_q && (B_lvl_idx_alloc = (Finch).regrow!(B_lvl.idx, B_lvl_idx_alloc, B_lvl_q))
                        B_lvl.idx[B_lvl_q] = j
                        B_lvl_q += 1
                    end
                    A_lvl_2_q += 1
                else
                end
                j_start_2 = j_step_2 + 1
            end
            j_start = j_step + 1
            j_step = min(A_lvl_2_I)
            j_start = j_step + 1
            B_lvl.pos[1 + 1] = B_lvl_q
        end
        (B = Fiber((Finch.HollowListLevel){Int64}(B_lvl_I, B_lvl.pos, B_lvl.idx, B_lvl_2), (Finch.Environment)(; name = :B)),)
    end
