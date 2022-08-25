@inbounds begin
        A_lvl = ex.body.lhs.tns.tns.lvl
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_val_alloc = length(A_lvl.val)
        D_lvl = ex.body.rhs.tns.tns.lvl
        D_lvl_pos_alloc = length(D_lvl.pos)
        D_lvl_idx_alloc = length(D_lvl.idx)
        D_lvl_2 = D_lvl.lvl
        D_lvl_2_val_alloc = length(D_lvl.lvl.val)
        D_lvl_2_val = 0
        i_stop = D_lvl.I
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl.pos[1] = 1
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_val_alloc = length(A_lvl.val)
        A_lvl_pos_alloc < 1 + 1 && (A_lvl_pos_alloc = (Finch).regrow!(A_lvl.pos, A_lvl_pos_alloc, 1 + 1))
        A_lvl_q = A_lvl.pos[1]
        A_lvl_q_start = A_lvl_q
        A_lvl_i_prev = 0
        A_lvl_v_prev = 0.0
        D_lvl_q = D_lvl.pos[1]
        D_lvl_q_stop = D_lvl.pos[1 + 1]
        if D_lvl_q < D_lvl_q_stop
            D_lvl_i = D_lvl.idx[D_lvl_q]
            D_lvl_i1 = D_lvl.idx[D_lvl_q_stop - 1]
        else
            D_lvl_i = 1
            D_lvl_i1 = 0
        end
        i = 1
        i_start = i
        phase_start = max(i_start)
        phase_stop = min(D_lvl_i1, i_stop)
        if phase_stop >= phase_start
            i = i
            i = phase_start
            while D_lvl_q < D_lvl_q_stop && D_lvl.idx[D_lvl_q] < phase_start
                D_lvl_q += 1
            end
            while i <= phase_stop
                i_start_2 = i
                D_lvl_i = D_lvl.idx[D_lvl_q]
                phase_stop_2 = min(D_lvl_i, phase_stop)
                i_2 = i
                if D_lvl_i == phase_stop_2
                    D_lvl_2_val = D_lvl_2.val[D_lvl_q]
                    if A_lvl_i_prev < phase_stop_2 - 1
                        if A_lvl_q == A_lvl_q_start || 0.0 != A_lvl_v_prev
                            A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
                            A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
                            A_lvl.idx[A_lvl_q] = phase_stop_2 - 1
                            A_lvl.val[A_lvl_q] = 0.0
                            A_lvl_v_prev = 0.0
                            A_lvl_q += 1
                        else
                            A_lvl.idx[A_lvl_q - 1] = phase_stop_2 - 1
                        end
                    end
                    A_lvl_v = D_lvl_2_val
                    if A_lvl_q == A_lvl_q_start || A_lvl_v != A_lvl_v_prev
                        A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
                        A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
                        A_lvl.idx[A_lvl_q] = phase_stop_2
                        A_lvl.val[A_lvl_q] = A_lvl_v
                        A_lvl_v_prev = A_lvl_v
                        A_lvl_q += 1
                    else
                        A_lvl.idx[A_lvl_q - 1] = phase_stop_2
                    end
                    A_lvl_i_prev = phase_stop_2
                    D_lvl_q += 1
                else
                end
                i = phase_stop_2 + 1
            end
            i = phase_stop + 1
        end
        i_start = i
        phase_start_3 = max(i_start)
        phase_stop_3 = min(i_stop)
        if phase_stop_3 >= phase_start_3
            i_3 = i
            i = phase_stop_3 + 1
        end
        if A_lvl_q == A_lvl_q_start && D_lvl.I > 1
            A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
            A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
            A_lvl.idx[A_lvl_q] = D_lvl.I
            A_lvl.val[A_lvl_q] = 0.0
            A_lvl_q += 1
        elseif A_lvl_i_prev < D_lvl.I
            if A_lvl_v_prev == 0.0
                A_lvl.idx[A_lvl_q - 1] = D_lvl.I
            else
                A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
                A_lvl_val_alloc < A_lvl_q && (A_lvl_val_alloc = (Finch).regrow!(A_lvl.val, A_lvl_val_alloc, A_lvl_q))
                A_lvl.idx[A_lvl_q] = D_lvl.I
                A_lvl.val[A_lvl_q] = 0.0
                A_lvl_q += 1
            end
        end
        A_lvl.pos[1 + 1] = A_lvl_q
        (A = Fiber((Finch.RepeatRLELevel){0.0, Int64, Float64}(D_lvl.I, A_lvl.pos, A_lvl.idx, A_lvl.val), (Finch.Environment)(; name = :A)),)
    end
