@inbounds begin
        C_lvl = ex.body.lhs.tns.tns.lvl
        C_lvl_pos_alloc = length(C_lvl.pos)
        C_lvl_idx_alloc = length(C_lvl.idx)
        C_lvl_2 = C_lvl.lvl
        C_lvl_2_val_alloc = length(C_lvl.lvl.val)
        C_lvl_2_val = 0.0
        A_lvl = (ex.body.rhs.args[1]).tns.tns.lvl
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_val_alloc = length(A_lvl.lvl.val)
        A_lvl_2_val = 0.0
        B_lvl = (ex.body.rhs.args[2]).tns.tns.lvl
        B_lvl_pos_alloc = length(B_lvl.pos)
        B_lvl_idx_alloc = length(B_lvl.idx)
        B_lvl_2 = B_lvl.lvl
        B_lvl_2_val_alloc = length(B_lvl.lvl.val)
        B_lvl_2_val = 0.0
        i_stop = A_lvl.I
        C_lvl_pos_alloc = length(C_lvl.pos)
        C_lvl.pos[1] = 1
        C_lvl_idx_alloc = length(C_lvl.idx)
        C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, 0, 4)
        C_lvl_pos_alloc < 1 + 1 && (C_lvl_pos_alloc = (Finch).regrow!(C_lvl.pos, C_lvl_pos_alloc, 1 + 1))
        C_lvl_q = C_lvl.pos[1]
        A_lvl_q = A_lvl.pos[1]
        A_lvl_q_stop = A_lvl.pos[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i = A_lvl.idx[A_lvl_q]
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i = 1
            A_lvl_i1 = 0
        end
        B_lvl_q = B_lvl.pos[1]
        B_lvl_q_stop = B_lvl.pos[1 + 1]
        if B_lvl_q < B_lvl_q_stop
            B_lvl_i = B_lvl.idx[B_lvl_q]
            B_lvl_i1 = B_lvl.idx[B_lvl_q_stop - 1]
        else
            B_lvl_i = 1
            B_lvl_i1 = 0
        end
        i = 1
        i_start = i
        phase_start = (max)(i_start)
        phase_stop = (min)(i_stop, B_lvl_i1, A_lvl_i1)
        if phase_stop >= phase_start
            i = i
            i = phase_start
            while i <= phase_stop
                i_start_2 = i
                while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < i_start_2
                    A_lvl_q += 1
                end
                A_lvl_i = A_lvl.idx[A_lvl_q]
                while B_lvl_q < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < i_start_2
                    B_lvl_q += 1
                end
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_start_2 = (max)(i_start_2, (min)(i_start_2))
                phase_stop_2 = (min)(phase_stop, (max)(A_lvl_i, B_lvl_i))
                if phase_stop_2 >= phase_start_2
                    i_2 = i
                    if phase_stop_2 == A_lvl_i && phase_stop_2 == B_lvl_i
                        A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                        B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                        i_3 = phase_stop_2
                        C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                        C_lvl_isdefault = true
                        C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                        C_lvl_isdefault = false
                        C_lvl_isdefault = false
                        C_lvl_2_val = (+)(C_lvl_2_val, (*)(A_lvl_2_val, B_lvl_2_val))
                        C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                        if !C_lvl_isdefault
                            C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                            C_lvl.idx[C_lvl_q] = i_3
                            C_lvl_q += 1
                        end
                        A_lvl_q += 1
                        B_lvl_q += 1
                    elseif phase_stop_2 == B_lvl_i
                        B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                        i = phase_stop_2
                        while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_stop_2
                            A_lvl_q += 1
                        end
                        i_start_3 = i
                        A_lvl_i = A_lvl.idx[A_lvl_q]
                        phase_stop_3 = (min)(phase_stop_2, A_lvl_i)
                        i_4 = i
                        if A_lvl_i == phase_stop_3
                            A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                            i_5 = phase_stop_3
                            C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                            C_lvl_isdefault = true
                            C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                            C_lvl_isdefault = false
                            C_lvl_isdefault = false
                            C_lvl_2_val = (+)(C_lvl_2_val, (*)(A_lvl_2_val, B_lvl_2_val))
                            C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                            if !C_lvl_isdefault
                                C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                                C_lvl.idx[C_lvl_q] = i_5
                                C_lvl_q += 1
                            end
                            A_lvl_q += 1
                        else
                        end
                        i = phase_stop_3 + 1
                        B_lvl_q += 1
                    elseif phase_stop_2 == A_lvl_i
                        A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                        i = phase_stop_2
                        while B_lvl_q < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < phase_stop_2
                            B_lvl_q += 1
                        end
                        i_start_4 = i
                        B_lvl_i = B_lvl.idx[B_lvl_q]
                        phase_stop_4 = (min)(phase_stop_2, B_lvl_i)
                        i_6 = i
                        if B_lvl_i == phase_stop_4
                            B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                            i_7 = phase_stop_4
                            C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                            C_lvl_isdefault = true
                            C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                            C_lvl_isdefault = false
                            C_lvl_isdefault = false
                            C_lvl_2_val = (+)(C_lvl_2_val, (*)(A_lvl_2_val, B_lvl_2_val))
                            C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                            if !C_lvl_isdefault
                                C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                                C_lvl.idx[C_lvl_q] = i_7
                                C_lvl_q += 1
                            end
                            B_lvl_q += 1
                        else
                        end
                        i = phase_stop_4 + 1
                        A_lvl_q += 1
                    else
                        i = phase_start_2
                        while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_2
                            A_lvl_q += 1
                        end
                        while B_lvl_q < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < phase_start_2
                            B_lvl_q += 1
                        end
                        while i <= phase_stop_2
                            i_start_5 = i
                            A_lvl_i = A_lvl.idx[A_lvl_q]
                            B_lvl_i = B_lvl.idx[B_lvl_q]
                            phase_start_5 = (max)(i_start_5)
                            phase_stop_5 = (min)(phase_stop_2, A_lvl_i, B_lvl_i)
                            if phase_stop_5 >= phase_start_5
                                i_8 = i
                                if A_lvl_i == phase_stop_5 && B_lvl_i == phase_stop_5
                                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                                    i_9 = phase_stop_5
                                    C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                                    C_lvl_isdefault = true
                                    C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                                    C_lvl_isdefault = false
                                    C_lvl_isdefault = false
                                    C_lvl_2_val = (+)(C_lvl_2_val, (*)(A_lvl_2_val, B_lvl_2_val))
                                    C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                                    if !C_lvl_isdefault
                                        C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                                        C_lvl.idx[C_lvl_q] = i_9
                                        C_lvl_q += 1
                                    end
                                    A_lvl_q += 1
                                    B_lvl_q += 1
                                elseif B_lvl_i == phase_stop_5
                                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                                    B_lvl_q += 1
                                elseif A_lvl_i == phase_stop_5
                                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                                    A_lvl_q += 1
                                else
                                end
                                i = phase_stop_5 + 1
                            end
                        end
                    end
                    i = phase_stop_2 + 1
                end
            end
            i = phase_stop + 1
        end
        i_start = i
        phase_start_6 = (max)(i_start)
        phase_stop_6 = (min)(i_stop, A_lvl_i1)
        if phase_stop_6 >= phase_start_6
            i_10 = i
            i = phase_stop_6 + 1
        end
        i_start = i
        phase_start_7 = (max)(i_start)
        phase_stop_7 = (min)(i_stop, B_lvl_i1)
        if phase_stop_7 >= phase_start_7
            i_11 = i
            i = phase_stop_7 + 1
        end
        i_start = i
        phase_stop_8 = i_stop
        i_12 = i
        i = phase_stop_8 + 1
        C_lvl.pos[1 + 1] = C_lvl_q
        (C = Fiber((Finch.HollowListLevel){Int64}(A_lvl.I, C_lvl.pos, C_lvl.idx, C_lvl_2), (Finch.Environment)(; name = :C)),)
    end
