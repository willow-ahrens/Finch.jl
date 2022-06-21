@inbounds begin
        C_lvl = ex.cons.body.lhs.tns.tns.lvl
        C_lvl_pos_alloc = length(C_lvl.pos)
        C_lvl_idx_alloc = length(C_lvl.idx)
        C_lvl_2 = C_lvl.lvl
        C_lvl_2_val_alloc = length(C_lvl.lvl.val)
        C_lvl_2_val = 0.0
        B_lvl = ex.cons.body.rhs.tns.tns.lvl
        B_lvl_pos_alloc = length(B_lvl.pos)
        B_lvl_idx_alloc = length(B_lvl.tbl)
        B_lvl_2 = B_lvl.lvl
        B_lvl_2_val_alloc = length(B_lvl.lvl.val)
        B_lvl_2_val = 0.0
        B_lvl_3 = ex.prod.body.lhs.tns.tns.lvl
        B_lvl_3_pos_alloc = length(B_lvl_3.pos)
        B_lvl_3_idx_alloc = length(B_lvl_3.tbl)
        B_lvl_4 = B_lvl_3.lvl
        B_lvl_4_val_alloc = length(B_lvl_3.lvl.val)
        B_lvl_4_val = 0.0
        A_lvl = ex.prod.body.rhs.tns.tns.lvl
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_val_alloc = length(A_lvl.lvl.val)
        A_lvl_2_val = 0.0
        i_2_stop = A_lvl.I
        i_stop = A_lvl.I
        C_lvl_pos_alloc = length(C_lvl.pos)
        C_lvl.pos[1] = 1
        C_lvl_idx_alloc = length(C_lvl.idx)
        C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, 0, 4)
        C_lvl_pos_alloc < 1 + 1 && (C_lvl_pos_alloc = (Finch).regrow!(C_lvl.pos, C_lvl_pos_alloc, 1 + 1))
        B_lvl_3_pos_alloc = length(B_lvl_3.pos) - 1
        B_lvl_3.pos[1] = 1
        B_lvl_3_idx_alloc = length(B_lvl_3.tbl[1])
        B_lvl_4_val_alloc = (Finch).refill!(B_lvl_4.val, 0.0, 0, 4)
        B_lvl_3_pos_alloc < 1 + 1 && (B_lvl_3_pos_alloc = (Finch).regrow!(B_lvl_3.pos, B_lvl_3_pos_alloc, 1 + 1))
        B_lvl_3_q = B_lvl_3.pos[1]
        A_lvl_q = A_lvl.pos[1]
        A_lvl_q_stop = A_lvl.pos[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i = A_lvl.idx[A_lvl_q]
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i = 1
            A_lvl_i1 = 0
        end
        i = 1
        i_start = i
        phase_start = max(i_start)
        phase_stop = min(A_lvl_i1, i_stop)
        if phase_stop >= phase_start
            i = i
            i = phase_start
            while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start
                A_lvl_q += 1
            end
            while i <= phase_stop
                i_start_2 = i
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_2 = min(A_lvl_i, phase_stop)
                i_2 = i
                if A_lvl_i == phase_stop_2
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    i_3 = phase_stop_2
                    B_lvl_3_guard = true
                    B_lvl_4_val_alloc < B_lvl_3_q && (B_lvl_4_val_alloc = (Finch).refill!(B_lvl_4.val, 0.0, B_lvl_4_val_alloc, B_lvl_3_q))
                    B_lvl_4_val = B_lvl_4.val[B_lvl_3_q]
                    B_lvl_3_guard = false
                    B_lvl_3_guard = false
                    B_lvl_4_val = B_lvl_4_val + A_lvl_2_val
                    B_lvl_4.val[B_lvl_3_q] = B_lvl_4_val
                    if !B_lvl_3_guard
                        if B_lvl_3_idx_alloc < B_lvl_3_q
                            B_lvl_3_idx_alloc = (Finch).regrow!(B_lvl_3.tbl[1], B_lvl_3_idx_alloc, B_lvl_3_q)
                        end
                        (B_lvl_3.tbl[1])[B_lvl_3_q] = i_3
                        B_lvl_3_q += 1
                    end
                    A_lvl_q += 1
                else
                end
                i = phase_stop_2 + 1
            end
            i = phase_stop + 1
        end
        i_start = i
        phase_stop_3 = i_stop
        i_4 = i
        i = phase_stop_3 + 1
        B_lvl_3.pos[1 + 1] = B_lvl_3_q
        C_lvl_q = C_lvl.pos[1]
        B_lvl_q = B_lvl.pos[1]
        B_lvl_q_stop = B_lvl.pos[1 + 1]
        if B_lvl_q < B_lvl_q_stop
            B_lvl_i = (B_lvl.tbl[1])[B_lvl_q]
            B_lvl_i_stop = (B_lvl.tbl[1])[B_lvl_q_stop - 1]
        else
            B_lvl_i = 1
            B_lvl_i_stop = 0
        end
        i_2 = 1
        i_2_start = i_2
        phase_start_4 = max(i_2_start)
        phase_stop_4 = min(B_lvl_i_stop, i_2_stop)
        if phase_stop_4 >= phase_start_4
            i_5 = i_2
            i_2 = phase_start_4
            B_lvl_q_step = B_lvl_q + 1
            while B_lvl_q_step < B_lvl_q_stop && (B_lvl.tbl[1])[B_lvl_q_step] < phase_start_4
                B_lvl_q_step += 1
            end
            while i_2 <= phase_stop_4
                i_2_start_2 = i_2
                B_lvl_i = (B_lvl.tbl[1])[B_lvl_q]
                phase_stop_5 = min(phase_stop_4, B_lvl_i)
                i_6 = i_2
                if B_lvl_i == phase_stop_5
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    i_7 = phase_stop_5
                    C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                    C_lvl_isdefault = true
                    C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                    C_lvl_isdefault = false
                    C_lvl_isdefault = false
                    C_lvl_2_val = C_lvl_2_val + B_lvl_2_val
                    C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                    if !C_lvl_isdefault
                        C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                        C_lvl.idx[C_lvl_q] = i_7
                        C_lvl_q += 1
                    end
                    B_lvl_q += 1
                else
                end
                i_2 = phase_stop_5 + 1
            end
            i_2 = phase_stop_4 + 1
        end
        i_2_start = i_2
        phase_stop_6 = i_2_stop
        i_8 = i_2
        i_2 = phase_stop_6 + 1
        C_lvl.pos[1 + 1] = C_lvl_q
        (C = Fiber((Finch.HollowListLevel){Int64}(A_lvl.I, C_lvl.pos, C_lvl.idx, C_lvl_2), (Finch.Environment)(; name = :C)),)
    end
