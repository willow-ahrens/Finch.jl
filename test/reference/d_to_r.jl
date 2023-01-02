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
        A_lvl_pos_fill = 1
        A_lvl_pos_stop = 2
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_val_alloc = length(A_lvl.val)
        A_lvl_pos_alloc < 1 + 1 && (A_lvl_pos_alloc = (Finch).regrow!(A_lvl.pos, A_lvl_pos_alloc, 1 + 1))
        A_lvl_pos_stop = 1 + 1
        A_lvl_q = A_lvl.pos[A_lvl_pos_fill]
        for A_lvl_p = A_lvl_pos_fill + 1:1
            A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
            A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
            A_lvl.idx[A_lvl_q] = C_mode1_stop
            A_lvl.val[A_lvl_q] = 0.0
            A_lvl_q += 1
            A_lvl.pos[A_lvl_p] = A_lvl_q
        end
        A_lvl_i_prev = 0
        A_lvl_j_prev = 0
        A_lvl_v_prev = 0.0
        for i = 1:i_stop
            if A_lvl_v_prev != 0.0 && A_lvl_j_prev + 1 < i
                A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
                A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
                A_lvl.idx[A_lvl_q] = A_lvl_j_prev
                A_lvl.val[A_lvl_q] = A_lvl_v_prev
                A_lvl_q += 1
                A_lvl_v_prev = 0.0
                A_lvl_i_prev = A_lvl_j_prev + 1
            end
            A_lvl_j_prev = i - 1
            A_lvl_v = 0.0
            A_lvl_v = C[i]
            if A_lvl_v_prev != A_lvl_v
                A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
                A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
                A_lvl.idx[A_lvl_q] = A_lvl_j_prev
                A_lvl.val[A_lvl_q] = A_lvl_v_prev
                A_lvl_q += 1
                A_lvl_i_prev = i
            end
            A_lvl_v_prev = A_lvl_v
            A_lvl_j_prev = i
        end
        if A_lvl_v_prev == 0.0 || A_lvl_j_prev == C_mode1_stop
            A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
            A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
            A_lvl.idx[A_lvl_q] = C_mode1_stop
            A_lvl.val[A_lvl_q] = A_lvl_v_prev
            A_lvl_q += 1
        else
            A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
            A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
            A_lvl.idx[A_lvl_q] = A_lvl_j_prev
            A_lvl.val[A_lvl_q] = 0.0
            A_lvl_q += 1
            A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
            A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
            A_lvl.idx[A_lvl_q] = C_mode1_stop
            A_lvl.val[A_lvl_q] = A_lvl_v_prev
            A_lvl_q += 1
        end
        A_lvl.pos[1 + 1] = A_lvl_q
        A_lvl_pos_fill = 1 + 1
        q = A_lvl.pos[A_lvl_pos_fill]
        for p = A_lvl_pos_fill + 1:A_lvl_pos_stop
            A_lvl_idx_alloc < q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, q))
            A_lvl_val_alloc < q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, q))
            A_lvl.idx[q] = C_mode1_stop
            A_lvl.val[q] = 0.0
            q += 1
            A_lvl.pos[p] = q
        end
        A_lvl_pos_alloc = 1 + 1
        resize!(A_lvl.pos, A_lvl_pos_alloc)
        A_lvl_val_alloc = (A_lvl_idx_alloc = A_lvl.pos[A_lvl_pos_alloc] - 1)
        resize!(A_lvl.idx, A_lvl_idx_alloc)
        resize!(A_lvl.val, A_lvl_val_alloc)
        (A = Fiber((Finch.RepeatRLELevel){0.0, Int64, Int64, Float64}(C_mode1_stop, A_lvl.pos, A_lvl.idx, A_lvl.val), (Finch.Environment)(; )),)
    end
