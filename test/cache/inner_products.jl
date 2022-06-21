@inbounds begin
        B_lvl = ex.body.body.body.lhs.tns.tns.lvl
        B_lvl_2 = B_lvl.lvl
        B_lvl_2_pos_alloc = length(B_lvl_2.pos)
        B_lvl_2_idx_alloc = length(B_lvl_2.idx)
        B_lvl_3 = B_lvl_2.lvl
        B_lvl_3_val_alloc = length(B_lvl_2.lvl.val)
        B_lvl_3_val = 0.0
        A_lvl = (ex.body.body.body.rhs.args[1]).tns.tns.lvl
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_pos_alloc = length(A_lvl_2.pos)
        A_lvl_2_idx_alloc = length(A_lvl_2.idx)
        A_lvl_3 = A_lvl_2.lvl
        A_lvl_3_val_alloc = length(A_lvl_2.lvl.val)
        A_lvl_3_val = 0.0
        A_lvl_4 = (ex.body.body.body.rhs.args[2]).tns.tns.lvl
        A_lvl_5 = A_lvl_4.lvl
        A_lvl_5_pos_alloc = length(A_lvl_5.pos)
        A_lvl_5_idx_alloc = length(A_lvl_5.idx)
        A_lvl_6 = A_lvl_5.lvl
        A_lvl_6_val_alloc = length(A_lvl_5.lvl.val)
        A_lvl_6_val = 0.0
        j_stop = A_lvl_4.I
        k_stop = A_lvl_2.I
        i_stop = A_lvl.I
        B_lvl_2_pos_alloc = length(B_lvl_2.pos)
        B_lvl_2.pos[1] = 1
        B_lvl_2_idx_alloc = length(B_lvl_2.idx)
        B_lvl_3_val_alloc = (Finch).refill!(B_lvl_3.val, 0.0, 0, 4)
        B_lvl_2_p_stop_2 = 1 * A_lvl.I
        B_lvl_2_pos_alloc < B_lvl_2_p_stop_2 + 1 && (B_lvl_2_pos_alloc = (Finch).regrow!(B_lvl_2.pos, B_lvl_2_pos_alloc, B_lvl_2_p_stop_2 + 1))
        for i = 1:i_stop
            B_lvl_q = (1 - 1) * A_lvl.I + i
            A_lvl_q = (1 - 1) * A_lvl.I + i
            B_lvl_2_q = B_lvl_2.pos[B_lvl_q]
            for j = 1:j_stop
                B_lvl_3_val_alloc < B_lvl_2_q && (B_lvl_3_val_alloc = (Finch).refill!(B_lvl_3.val, 0.0, B_lvl_3_val_alloc, B_lvl_2_q))
                B_lvl_2_isdefault = true
                A_lvl_4_q = (1 - 1) * A_lvl_4.I + j
                B_lvl_3_val = B_lvl_3.val[B_lvl_2_q]
                A_lvl_2_q = A_lvl_2.pos[A_lvl_q]
                A_lvl_2_q_stop = A_lvl_2.pos[A_lvl_q + 1]
                if A_lvl_2_q < A_lvl_2_q_stop
                    A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                    A_lvl_2_i1 = A_lvl_2.idx[A_lvl_2_q_stop - 1]
                else
                    A_lvl_2_i = 1
                    A_lvl_2_i1 = 0
                end
                A_lvl_5_q = A_lvl_5.pos[A_lvl_4_q]
                A_lvl_5_q_stop = A_lvl_5.pos[A_lvl_4_q + 1]
                if A_lvl_5_q < A_lvl_5_q_stop
                    A_lvl_5_i = A_lvl_5.idx[A_lvl_5_q]
                    A_lvl_5_i1 = A_lvl_5.idx[A_lvl_5_q_stop - 1]
                else
                    A_lvl_5_i = 1
                    A_lvl_5_i1 = 0
                end
                k = 1
                k_start = k
                phase_start = max(k_start)
                phase_stop = min(A_lvl_2_i1, A_lvl_5_i1, k_stop)
                if phase_stop >= phase_start
                    k = k
                    k = phase_start
                    while A_lvl_2_q < A_lvl_2_q_stop && A_lvl_2.idx[A_lvl_2_q] < phase_start
                        A_lvl_2_q += 1
                    end
                    while A_lvl_5_q < A_lvl_5_q_stop && A_lvl_5.idx[A_lvl_5_q] < phase_start
                        A_lvl_5_q += 1
                    end
                    while k <= phase_stop
                        k_start_2 = k
                        A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                        A_lvl_5_i = A_lvl_5.idx[A_lvl_5_q]
                        phase_start_2 = max(k_start_2)
                        phase_stop_2 = min(A_lvl_5_i, A_lvl_2_i, phase_stop)
                        if phase_stop_2 >= phase_start_2
                            k_2 = k
                            if A_lvl_2_i == phase_stop_2 && A_lvl_5_i == phase_stop_2
                                A_lvl_3_val = A_lvl_3.val[A_lvl_2_q]
                                A_lvl_6_val = A_lvl_6.val[A_lvl_5_q]
                                k_3 = phase_stop_2
                                B_lvl_2_isdefault = false
                                B_lvl_2_isdefault = false
                                B_lvl_3_val = B_lvl_3_val + A_lvl_3_val * A_lvl_6_val
                                A_lvl_2_q += 1
                                A_lvl_5_q += 1
                            elseif A_lvl_5_i == phase_stop_2
                                A_lvl_6_val = A_lvl_6.val[A_lvl_5_q]
                                A_lvl_5_q += 1
                            elseif A_lvl_2_i == phase_stop_2
                                A_lvl_3_val = A_lvl_3.val[A_lvl_2_q]
                                A_lvl_2_q += 1
                            else
                            end
                            k = phase_stop_2 + 1
                        end
                    end
                    k = phase_stop + 1
                end
                k_start = k
                phase_start_3 = max(k_start)
                phase_stop_3 = min(A_lvl_2_i1, k_stop)
                if phase_stop_3 >= phase_start_3
                    k_4 = k
                    k = phase_stop_3 + 1
                end
                k_start = k
                phase_start_4 = max(k_start)
                phase_stop_4 = min(A_lvl_5_i1, k_stop)
                if phase_stop_4 >= phase_start_4
                    k_5 = k
                    k = phase_stop_4 + 1
                end
                k_start = k
                phase_stop_5 = k_stop
                k_6 = k
                k = phase_stop_5 + 1
                B_lvl_3.val[B_lvl_2_q] = B_lvl_3_val
                if !B_lvl_2_isdefault
                    B_lvl_2_idx_alloc < B_lvl_2_q && (B_lvl_2_idx_alloc = (Finch).regrow!(B_lvl_2.idx, B_lvl_2_idx_alloc, B_lvl_2_q))
                    B_lvl_2.idx[B_lvl_2_q] = j
                    B_lvl_2_q += 1
                end
            end
            B_lvl_2.pos[B_lvl_q + 1] = B_lvl_2_q
        end
        (B = Fiber(B_lvl, (Finch.Environment)(; name = :B)),)
    end
