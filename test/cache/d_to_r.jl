@inbounds begin
        A_lvl = ex.body.lhs.tns.tns.lvl
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_val_alloc = length(A_lvl.val)
        C = ex.body.rhs.tns.tns
        (C_mode1_stop,) = size(C)
        i_stop = C_mode1_stop
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl.pos[1] = 1
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_val_alloc = length(A_lvl.val)
        A_lvl_pos_alloc < 1 + 1 && (A_lvl_pos_alloc = (Finch).regrow!(A_lvl.pos, A_lvl_pos_alloc, 1 + 1))
        A_lvl_q = A_lvl.pos[1]
        A_lvl_q_start = A_lvl_q
        A_lvl_i_prev = 0
        A_lvl_v_prev = 0.0
        for i = 1:i_stop
            if A_lvl_i_prev < i - 1
                if A_lvl_q == A_lvl_q_start || 0.0 != A_lvl_v_prev
                    A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
                    A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
                    A_lvl.idx[A_lvl_q] = i - 1
                    A_lvl.val[A_lvl_q] = 0.0
                    A_lvl_v_prev = 0.0
                    A_lvl_q += 1
                else
                    A_lvl.idx[A_lvl_q - 1] = i - 1
                end
            end
            A_lvl_v = C[i]
            if A_lvl_q == A_lvl_q_start || A_lvl_v != A_lvl_v_prev
                A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
                A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
                A_lvl.idx[A_lvl_q] = i
                A_lvl.val[A_lvl_q] = A_lvl_v
                A_lvl_v_prev = A_lvl_v
                A_lvl_q += 1
            else
                A_lvl.idx[A_lvl_q - 1] = i
            end
            A_lvl_i_prev = i
        end
        if A_lvl_q == A_lvl_q_start && C_mode1_stop > 1
            A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
            A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
            A_lvl.idx[A_lvl_q] = C_mode1_stop
            A_lvl.val[A_lvl_q] = 0.0
            A_lvl_q += 1
        elseif A_lvl_i_prev < C_mode1_stop
            if A_lvl_v_prev == 0.0
                A_lvl.idx[A_lvl_q - 1] = C_mode1_stop
            else
                A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
                A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
                A_lvl.idx[A_lvl_q] = C_mode1_stop
                A_lvl.val[A_lvl_q] = 0.0
                A_lvl_q += 1
            end
        end
        A_lvl.pos[1 + 1] = A_lvl_q
        A_lvl_pos_alloc = 1 + 1
        resize!(A_lvl.pos, A_lvl_pos_alloc)
        A_lvl_val_alloc = (A_lvl_idx_alloc = A_lvl.pos[A_lvl_pos_alloc] - 1)
        resize!(A_lvl.idx, A_lvl_idx_alloc)
        resize!(A_lvl.val, A_lvl_val_alloc)
        (A = Fiber((Finch.RepeatRLELevel){0.0, Int64, Float64}(C_mode1_stop, A_lvl.pos, A_lvl.idx, A_lvl.val), (Finch.Environment)(; )),)
    end
