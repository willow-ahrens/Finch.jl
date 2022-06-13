@inbounds begin
        B_lvl = ex.body.lhs.tns.tns.lvl
        B_lvl_I = B_lvl.I
        B_lvl_P = length(B_lvl.pos)
        B_lvl_pos_alloc = B_lvl_P
        B_lvl_idx_alloc = length(B_lvl.tbl)
        B_lvl_2 = B_lvl.lvl
        B_lvl_2_val_alloc = length(B_lvl.lvl.val)
        B_lvl_2_val = 0.0
        A_lvl = ex.body.rhs.tns.tns.lvl
        A_lvl_I = A_lvl.I
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_val_alloc = length(A_lvl.lvl.val)
        A_lvl_2_val = 0.0
        B_lvl_I = (A_lvl_I,)
        B_lvl_idx_alloc = 0
        empty!(B_lvl.tbl)
        empty!(B_lvl.srt)
        B_lvl_pos_alloc = (Finch).refill!(B_lvl.pos, 0, 0, 5)
        B_lvl.pos[1] = 1
        B_lvl_P = 0
        B_lvl_2_val_alloc = (Finch).refill!(B_lvl_2.val, 0.0, 0, 4)
        B_lvl_p_stop_2 = 1
        B_lvl_P = max(B_lvl_p_stop_2, B_lvl_P)
        B_lvl_pos_alloc < B_lvl_P + 1 && (B_lvl_pos_alloc = Finch.refill!(B_lvl.pos, 0, B_lvl_pos_alloc, B_lvl_P + 1))
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
        i_start = 1
        i_step = min(A_lvl_i1, A_lvl_I)
        i_start_2 = i_start
        while i_start_2 <= i_step
            A_lvl_i = A_lvl.idx[A_lvl_q]
            i_step_2 = min(A_lvl_i, i_step)
            if i_step_2 == A_lvl_i
                A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                i = i_step_2
                B_lvl_guard = true
                B_lvl_key = (1, (i,))
                B_lvl_q = get(B_lvl.tbl, B_lvl_key, B_lvl_idx_alloc + 1)
                if B_lvl_idx_alloc < B_lvl_q
                    B_lvl_2_val_alloc < B_lvl_q && (B_lvl_2_val_alloc = (Finch).refill!(B_lvl_2.val, 0.0, B_lvl_2_val_alloc, B_lvl_q))
                end
                B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                B_lvl_guard = false
                B_lvl_guard = false
                B_lvl_2_val = B_lvl_2_val + A_lvl_2_val
                B_lvl_2.val[B_lvl_q] = B_lvl_2_val
                if !B_lvl_guard
                    B_lvl_idx_alloc = B_lvl_q
                    B_lvl.tbl[B_lvl_key] = B_lvl_idx_alloc
                    B_lvl.pos[1 + 1] += 1
                end
                A_lvl_q += 1
            else
            end
            i_start_2 = i_step_2 + 1
        end
        i_start = i_step + 1
        i_step = min(A_lvl_I)
        i_start = i_step + 1
        resize!(B_lvl.srt, length(B_lvl.tbl))
        copyto!(B_lvl.srt, pairs(B_lvl.tbl))
        sort!(B_lvl.srt)
        for B_lvl_p_2 = 1:B_lvl_P
            B_lvl.pos[B_lvl_p_2 + 1] += B_lvl.pos[B_lvl_p_2]
        end
        (B = Fiber((Finch.HollowHashLevel){1, Tuple{Int64}, Int64, Int64, Dict{Tuple{Int64, Tuple{Int64}}, Int64}}(B_lvl_I, B_lvl.tbl, B_lvl.srt, B_lvl.pos, B_lvl_2), (Finch.Environment)(; name = :B)),)
    end
