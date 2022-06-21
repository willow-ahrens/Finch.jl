@inbounds begin
        B_lvl = ex.body.body.lhs.tns.tns.lvl
        B_lvl_P = length(B_lvl.pos)
        B_lvl_pos_alloc = B_lvl_P
        B_lvl_idx_alloc = length(B_lvl.tbl)
        B_lvl_2 = B_lvl.lvl
        B_lvl_2_val_alloc = length(B_lvl.lvl.val)
        B_lvl_2_val = 0.0
        A_lvl = ex.body.body.rhs.tns.tns.lvl
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_pos_alloc = length(A_lvl_2.pos)
        A_lvl_2_idx_alloc = length(A_lvl_2.idx)
        A_lvl_3 = A_lvl_2.lvl
        A_lvl_3_val_alloc = length(A_lvl_2.lvl.val)
        A_lvl_3_val = 0.0
        j_stop = A_lvl_2.I
        i_stop = A_lvl.I
        B_lvl_idx_alloc = 0
        empty!(B_lvl.tbl)
        empty!(B_lvl.srt)
        B_lvl_pos_alloc = (Finch).refill!(B_lvl.pos, 0, 0, 5)
        B_lvl.pos[1] = 1
        B_lvl_P = 0
        B_lvl_2_val_alloc = (Finch).refill!(B_lvl_2.val, 0.0, 0, 4)
        B_lvl_P = max(1, B_lvl_P)
        B_lvl_pos_alloc < B_lvl_P + 1 && (B_lvl_pos_alloc = Finch.refill!(B_lvl.pos, 0, B_lvl_pos_alloc, B_lvl_P + 1))
        for i = 1:i_stop
            A_lvl_q = (1 - 1) * A_lvl.I + i
            B_lvl_q_2 = B_lvl.pos[1]
            A_lvl_2_q = A_lvl_2.pos[A_lvl_q]
            A_lvl_2_q_stop = A_lvl_2.pos[A_lvl_q + 1]
            if A_lvl_2_q < A_lvl_2_q_stop
                A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
            else
                A_lvl_2_i = 1
                A_lvl_2_i1 = 0
            end
            j = 1
            j_start = j
            phase_start = max(j_start)
            phase_stop = min(A_lvl_2_i1, j_stop)
            if phase_stop >= phase_start
                j = j
                j = phase_start
                while A_lvl_2_q < A_lvl_2_q_stop && A_lvl_2.idx[A_lvl_2_q] < phase_start
                    A_lvl_2_q += 1
                end
                while j <= phase_stop
                    j_start_2 = j
                    A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                    phase_stop_2 = min(A_lvl_2_i, phase_stop)
                    j_2 = j
                    if A_lvl_2_i == phase_stop_2
                        A_lvl_3_val = A_lvl_3.val[A_lvl_2_q]
                        j_3 = phase_stop_2
                        B_lvl_guard_2 = true
                        B_lvl_key_2 = (1, (i, j_3))
                        B_lvl_q_2 = get(B_lvl.tbl, B_lvl_key_2, B_lvl_idx_alloc + 1)
                        if B_lvl_idx_alloc < B_lvl_q_2
                            B_lvl_2_val_alloc < B_lvl_q_2 && (B_lvl_2_val_alloc = (Finch).refill!(B_lvl_2.val, 0.0, B_lvl_2_val_alloc, B_lvl_q_2))
                        end
                        B_lvl_2_val = B_lvl_2.val[B_lvl_q_2]
                        B_lvl_guard_2 = false
                        B_lvl_guard_2 = false
                        B_lvl_2_val = B_lvl_2_val + A_lvl_3_val
                        B_lvl_2.val[B_lvl_q_2] = B_lvl_2_val
                        if !B_lvl_guard_2
                            B_lvl_idx_alloc = B_lvl_q_2
                            B_lvl.tbl[B_lvl_key_2] = B_lvl_idx_alloc
                            B_lvl.pos[1 + 1] += 1
                        end
                        A_lvl_2_q += 1
                    else
                    end
                    j = phase_stop_2 + 1
                end
                j = phase_stop + 1
            end
            j_start = j
            phase_stop_3 = j_stop
            j_4 = j
            j = phase_stop_3 + 1
        end
        resize!(B_lvl.srt, length(B_lvl.tbl))
        copyto!(B_lvl.srt, pairs(B_lvl.tbl))
        sort!(B_lvl.srt)
        for B_lvl_p_2 = 1:B_lvl_P
            B_lvl.pos[B_lvl_p_2 + 1] += B_lvl.pos[B_lvl_p_2]
        end
        (B = Fiber((Finch.HollowHashLevel){2, Tuple{Int64, Int64}, Int64, Int64, Dict{Tuple{Int64, Tuple{Int64, Int64}}, Int64}}((A_lvl.I, A_lvl_2.I), B_lvl.tbl, B_lvl.srt, B_lvl.pos, B_lvl_2), (Finch.Environment)(; name = :B)),)
    end
