@inbounds begin
        C_lvl = ex.body.body.lhs.tns.tns.lvl
        C_lvl_pos_alloc = length(C_lvl.pos)
        C_lvl_idx_alloc = length(C_lvl.idx)
        C_lvl_2 = C_lvl.lvl
        C_lvl_2_val_alloc = length(C_lvl.lvl.val)
        C_lvl_2_val = 0.0
        A_lvl = ((ex.body.body.rhs.args[1]).args[1]).tns.tns.lvl
        A_lvl_pos_alloc = length(A_lvl.pos)
        A_lvl_idx_alloc = length(A_lvl.idx)
        A_lvl_2 = A_lvl.lvl
        A_lvl_2_val_alloc = length(A_lvl.lvl.val)
        A_lvl_2_val = 0.0
        A_lvl_3 = ((ex.body.body.rhs.args[2]).args[1]).tns.tns.lvl
        A_lvl_3_pos_alloc = length(A_lvl_3.pos)
        A_lvl_3_idx_alloc = length(A_lvl_3.idx)
        A_lvl_4 = A_lvl_3.lvl
        A_lvl_4_val_alloc = length(A_lvl_3.lvl.val)
        A_lvl_4_val = 0.0
        F_lvl = (ex.body.body.rhs.args[3]).tns.tns.lvl
        F_lvl_2 = F_lvl.lvl
        F_lvl_2_val_alloc = length(F_lvl.lvl.val)
        F_lvl_2_val = 0
        i_stop = A_lvl.I
        C_lvl_pos_alloc = length(C_lvl.pos)
        C_lvl_pos_fill = 1
        C_lvl_pos_stop = 2
        C_lvl.pos[1] = 1
        C_lvl.pos[2] = 1
        C_lvl_idx_alloc = length(C_lvl.idx)
        C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, 0, 4)
        C_lvl_pos_alloc < 1 + 1 && (C_lvl_pos_alloc = (Finch).refill!(C_lvl.pos, 0, C_lvl_pos_alloc, 1 + 1))
        C_lvl_pos_stop = 1 + 1
        C_lvl_q = C_lvl.pos[C_lvl_pos_fill]
        for C_lvl_p = C_lvl_pos_fill:1
            C_lvl.pos[C_lvl_p] = C_lvl_q
        end
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
                    C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                    C_lvl_isdefault = true
                    delta = (+)(-3, i_3)
                    C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                    j_stop = F_lvl.I
                    j = 1
                    j_start = j
                    phase_start_3 = (max)(j_start, (+)(j_start, (-)(delta), delta))
                    phase_stop_3 = (min)(delta, j_stop)
                    if phase_stop_3 >= phase_start_3
                        j = j
                        j = phase_stop_3 + 1
                    end
                    j_start = j
                    phase_start_4 = (max)(j_start, (+)(j_start, (-)(delta), delta))
                    phase_stop_4 = (min)(j_stop, (+)(delta, A_lvl_3.I))
                    if phase_stop_4 >= phase_start_4
                        j_2 = j
                        A_lvl_3_q = A_lvl_3.pos[1]
                        A_lvl_3_q_stop = A_lvl_3.pos[1 + 1]
                        if A_lvl_3_q < A_lvl_3_q_stop
                            A_lvl_3_i = A_lvl_3.idx[A_lvl_3_q]
                            A_lvl_3_i1 = A_lvl_3.idx[A_lvl_3_q_stop - 1]
                        else
                            A_lvl_3_i = 1
                            A_lvl_3_i1 = 0
                        end
                        j = phase_start_4
                        j_start_2 = j
                        phase_start_5 = (max)(j_start_2, (+)((-)(delta), delta, j_start_2))
                        phase_stop_5 = (min)(phase_stop_4, (+)(delta, A_lvl_3_i1))
                        if phase_stop_5 >= phase_start_5
                            j_3 = j
                            j = phase_start_5
                            while A_lvl_3_q < A_lvl_3_q_stop && A_lvl_3.idx[A_lvl_3_q] < (+)(phase_start_5, (-)(delta))
                                A_lvl_3_q += 1
                            end
                            while j <= phase_stop_5
                                j_start_3 = j
                                A_lvl_3_i = A_lvl_3.idx[A_lvl_3_q]
                                phase_start_6 = (max)(j_start_3, (+)((-)(delta), delta, j_start_3))
                                phase_stop_6 = (min)(phase_stop_5, (+)(delta, A_lvl_3_i))
                                if phase_stop_6 >= phase_start_6
                                    j_4 = j
                                    if A_lvl_3_i == (+)(phase_stop_6, (-)(delta))
                                        A_lvl_4_val = A_lvl_4.val[A_lvl_3_q]
                                        j_5 = phase_stop_6
                                        F_lvl_q = (1 - 1) * F_lvl.I + j_5
                                        F_lvl_2_val = F_lvl_2.val[F_lvl_q]
                                        C_lvl_isdefault = false
                                        C_lvl_isdefault = false
                                        C_lvl_2_val = (+)((*)((!=)(A_lvl_2_val, 0), F_lvl_2_val, (coalesce)(A_lvl_4_val, 0)), C_lvl_2_val)
                                        A_lvl_3_q += 1
                                    else
                                    end
                                    j = phase_stop_6 + 1
                                end
                            end
                            j = phase_stop_5 + 1
                        end
                        j_start_2 = j
                        phase_start_7 = (max)(j_start_2, (+)((-)(delta), delta, j_start_2))
                        phase_stop_7 = (min)(phase_stop_4, (+)((-)(delta), delta, phase_stop_4))
                        if phase_stop_7 >= phase_start_7
                            j_6 = j
                            j = phase_stop_7 + 1
                        end
                        j = phase_stop_4 + 1
                    end
                    j_start = j
                    phase_start_8 = (max)(j_start, (+)(j_start, (-)(delta), delta))
                    phase_stop_8 = (min)(j_stop, (+)((-)(delta), delta, j_stop))
                    if phase_stop_8 >= phase_start_8
                        j_7 = j
                        j = phase_stop_8 + 1
                    end
                    C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                    if !C_lvl_isdefault
                        C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                        C_lvl.idx[C_lvl_q] = i_3
                        C_lvl_q += 1
                    end
                    A_lvl_q += 1
                else
                end
                i = phase_stop_2 + 1
            end
            i = phase_stop + 1
        end
        i_start = i
        phase_start_9 = i_start
        phase_stop_9 = i_stop
        if phase_stop_9 >= phase_start_9
            i_4 = i
            i = phase_stop_9 + 1
        end
        C_lvl.pos[1 + 1] = C_lvl_q
        C_lvl_pos_fill = 1 + 1
        q = C_lvl.pos[C_lvl_pos_fill]
        for p = C_lvl_pos_fill:C_lvl_pos_stop
            C_lvl.pos[p] = q
        end
        C_lvl_pos_alloc = 1 + 1
        resize!(C_lvl.pos, C_lvl_pos_alloc)
        C_lvl_idx_alloc = C_lvl.pos[C_lvl_pos_alloc] - 1
        resize!(C_lvl.idx, C_lvl_idx_alloc)
        resize!(C_lvl_2.val, C_lvl_idx_alloc)
        (C = Fiber((Finch.SparseListLevel){Int64}(A_lvl.I, C_lvl.pos, C_lvl.idx, C_lvl_2), (Finch.Environment)(; )),)
    end
