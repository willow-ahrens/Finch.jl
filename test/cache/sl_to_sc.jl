@inbounds begin
        B_lvl = ex.body.lhs.tns.tns.lvl
        B_lvl_pos_alloc = length(B_lvl.pos)
        B_lvl_idx_alloc = length(B_lvl.tbl)
        B_lvl_2 = B_lvl.lvl
        B_lvl_2_val_alloc = length(B_lvl.lvl.val)
        B_lvl_2_val = 0.0
        A_lvl = ex.body.rhs.tns.tns.lvl
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_val_alloc = length(A_lvl.lvl.val)
        A_lvl_2_val = 0.0
        i_stop = A_lvl.I
        B_lvl_pos_alloc = length(B_lvl.pos) - 1
        B_lvl.pos[1] = 1
        B_lvl_idx_alloc = length(B_lvl.tbl[1])
        B_lvl_2_val_alloc = (Finch).refill!(B_lvl_2.val, 0.0, 0, 4)
        B_lvl_pos_alloc < 1 + 1 && (B_lvl_pos_alloc = (Finch).regrow!(B_lvl.pos, B_lvl_pos_alloc, 1 + 1))
        B_lvl_q = B_lvl.pos[1]
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
        phase_start = i_start
        phase_stop = (min)(A_lvl_i1, i_stop)
        if phase_stop >= phase_start
            i = i
            i = phase_start
            while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start
                A_lvl_q += 1
            end
            while i <= phase_stop
                i_start_2 = i
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_2 = (min)(A_lvl_i, phase_stop)
                i_2 = i
                if A_lvl_i == phase_stop_2
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    i_3 = phase_stop_2
                    B_lvl_guard = true
                    B_lvl_2_val_alloc < B_lvl_q && (B_lvl_2_val_alloc = (Finch).refill!(B_lvl_2.val, 0.0, B_lvl_2_val_alloc, B_lvl_q))
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    B_lvl_guard = false
                    B_lvl_guard = false
                    B_lvl_2_val = (+)(A_lvl_2_val, B_lvl_2_val)
                    B_lvl_2.val[B_lvl_q] = B_lvl_2_val
                    if !B_lvl_guard
                        if B_lvl_idx_alloc < B_lvl_q
                            B_lvl_idx_alloc = (Finch).regrow!(B_lvl.tbl[1], B_lvl_idx_alloc, B_lvl_q)
                        end
                        (B_lvl.tbl[1])[B_lvl_q] = i_3
                        B_lvl_q += 1
                    end
                    A_lvl_q += 1
                else
                end
                i = phase_stop_2 + 1
            end
            i = phase_stop + 1
        end
        i_start = i
        phase_start_3 = i_start
        phase_stop_3 = i_stop
        if phase_stop_3 >= phase_start_3
            i_4 = i
            i = phase_stop_3 + 1
        end
        B_lvl.pos[1 + 1] = B_lvl_q
        B_lvl_pos_alloc = 1 + 1
        resize!(B_lvl.pos, B_lvl_pos_alloc)
        B_lvl_idx_alloc = B_lvl.pos[B_lvl_pos_alloc] - 1
        for idx = B_lvl.tbl
            resize!(idx, B_lvl_idx_alloc)
        end
        resize!(B_lvl_2.val, B_lvl_idx_alloc)
        (B = Fiber((Finch.SparseCooLevel){1, Tuple{Int64}, Int64, Tuple{Vector{Int64}}}((A_lvl.I,), B_lvl.tbl, B_lvl.pos, B_lvl_2), (Finch.Environment)(; name = :B)),)
    end
