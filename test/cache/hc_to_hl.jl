@inbounds begin
        A_lvl = ex.body.lhs.tns.tns.lvl
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_val_alloc = length(A_lvl.lvl.val)
        A_lvl_2_val = 0.0
        B_lvl = ex.body.rhs.tns.tns.lvl
        B_lvl_pos_alloc = length(B_lvl.pos)
        B_lvl_idx_alloc = length(B_lvl.tbl)
        B_lvl_2 = B_lvl.lvl
        B_lvl_2_val_alloc = length(B_lvl.lvl.val)
        B_lvl_2_val = 0.0
        i_stop = B_lvl.I[1]
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl.pos[1] = 1
        A_lvl.pos[2] = 1
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_2_val_alloc = (Finch).refill!(A_lvl_2.val, 0.0, 0, 4)
        A_lvl_pos_alloc < 1 + 1 && (A_lvl_pos_alloc = (Finch).regrow!(A_lvl.pos, A_lvl_pos_alloc, 1 + 1))
        A_lvl_q = A_lvl.pos[1]
        B_lvl_q = B_lvl.pos[1]
        B_lvl_q_stop = B_lvl.pos[1 + 1]
        if B_lvl_q < B_lvl_q_stop
            B_lvl_i = (B_lvl.tbl[1])[B_lvl_q]
            B_lvl_i_stop = (B_lvl.tbl[1])[B_lvl_q_stop - 1]
        else
            B_lvl_i = 1
            B_lvl_i_stop = 0
        end
        i = 1
        i_start = i
        phase_start = max(i_start)
        phase_stop = min(B_lvl_i_stop, i_stop)
        if phase_stop >= phase_start
            i = i
            i = phase_start
            B_lvl_q_step = B_lvl_q + 1
            while B_lvl_q_step < B_lvl_q_stop && (B_lvl.tbl[1])[B_lvl_q_step] < phase_start
                B_lvl_q_step += 1
            end
            while i <= phase_stop
                i_start_2 = i
                B_lvl_i = (B_lvl.tbl[1])[B_lvl_q]
                phase_stop_2 = min(B_lvl_i, phase_stop)
                i_2 = i
                if B_lvl_i == phase_stop_2
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    i_3 = phase_stop_2
                    A_lvl_2_val_alloc < A_lvl_q && (A_lvl_2_val_alloc = (Finch).refill!(A_lvl_2.val, 0.0, A_lvl_2_val_alloc, A_lvl_q))
                    A_lvl_isdefault = true
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    A_lvl_isdefault = false
                    A_lvl_isdefault = false
                    A_lvl_2_val = A_lvl_2_val + B_lvl_2_val
                    A_lvl_2.val[A_lvl_q] = A_lvl_2_val
                    if !A_lvl_isdefault
                        A_lvl_idx_alloc < A_lvl_q && (A_lvl_idx_alloc = (Finch).regrow!(A_lvl.idx, A_lvl_idx_alloc, A_lvl_q))
                        A_lvl.idx[A_lvl_q] = i_3
                        A_lvl_q += 1
                    end
                    B_lvl_q += 1
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
            i_4 = i
            i = phase_stop_3 + 1
        end
        A_lvl.pos[1 + 1] = A_lvl_q
        (A = Fiber((Finch.HollowListLevel){Int64}(B_lvl.I[1], A_lvl.pos, A_lvl.idx, A_lvl_2), (Finch.Environment)(; name = :A)),)
    end
