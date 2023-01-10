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
        C_lvl_pos_fill = 1
        C_lvl_pos_stop = 2
        C_lvl.pos[1] = 1
        C_lvl.pos[2] = 1
        C_lvl_idx_alloc = length(C_lvl.idx)
        C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, 0, 4)
        C_lvl_pos_stop = 1 + 1
        (Finch).@regrow! C_lvl.pos C_lvl_pos_alloc C_lvl_pos_stop
        C_lvl_q = C_lvl.pos[C_lvl_pos_fill]
        for C_lvl_p = C_lvl_pos_fill:1
            C_lvl.pos[C_lvl_p] = C_lvl_q
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
        phase_stop = (min)(A_lvl_i1, B_lvl_i1, i_stop)
        if phase_stop >= phase_start
            i = i
            i = phase_start
            while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < phase_start
                B_lvl_q += 1
            end
            while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start
                A_lvl_q += 1
            end
            while i <= phase_stop
                i_start_2 = i
                B_lvl_i = B_lvl.idx[B_lvl_q]
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_2 = (min)(A_lvl_i, B_lvl_i, phase_stop)
                i_2 = i
                if B_lvl_i == phase_stop_2 && A_lvl_i == phase_stop_2
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    i_3 = phase_stop_2
                    C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                    C_lvl_isdefault = true
                    C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                    C_lvl_isdefault = false
                    C_lvl_isdefault = false
                    C_lvl_2_val = (+)(B_lvl_2_val, C_lvl_2_val, A_lvl_2_val)
                    C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                    if !C_lvl_isdefault
                        (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                        C_lvl.idx[C_lvl_q] = i_3
                        C_lvl_q += 1
                    end
                    B_lvl_q += 1
                    A_lvl_q += 1
                elseif A_lvl_i == phase_stop_2
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    i_4 = phase_stop_2
                    C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                    C_lvl_isdefault = true
                    C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                    C_lvl_isdefault = false
                    C_lvl_isdefault = false
                    C_lvl_2_val = (+)(A_lvl_2_val, C_lvl_2_val)
                    C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                    if !C_lvl_isdefault
                        (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                        C_lvl.idx[C_lvl_q] = i_4
                        C_lvl_q += 1
                    end
                    A_lvl_q += 1
                elseif B_lvl_i == phase_stop_2
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    i_5 = phase_stop_2
                    C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                    C_lvl_isdefault = true
                    C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                    C_lvl_isdefault = false
                    C_lvl_isdefault = false
                    C_lvl_2_val = (+)(B_lvl_2_val, C_lvl_2_val)
                    C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                    if !C_lvl_isdefault
                        (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                        C_lvl.idx[C_lvl_q] = i_5
                        C_lvl_q += 1
                    end
                    B_lvl_q += 1
                else
                end
                i = phase_stop_2 + 1
            end
            i = phase_stop + 1
        end
        i_start = i
        phase_start_3 = i_start
        phase_stop_3 = (min)(B_lvl_i1, i_stop)
        if phase_stop_3 >= phase_start_3
            i_6 = i
            i = phase_start_3
            while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < phase_start_3
                B_lvl_q += 1
            end
            while i <= phase_stop_3
                i_start_3 = i
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_stop_4 = (min)(B_lvl_i, phase_stop_3)
                i_7 = i
                if B_lvl_i == phase_stop_4
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    i_8 = phase_stop_4
                    C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                    C_lvl_isdefault = true
                    C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                    C_lvl_isdefault = false
                    C_lvl_isdefault = false
                    C_lvl_2_val = (+)(B_lvl_2_val, C_lvl_2_val)
                    C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                    if !C_lvl_isdefault
                        (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                        C_lvl.idx[C_lvl_q] = i_8
                        C_lvl_q += 1
                    end
                    B_lvl_q += 1
                else
                end
                i = phase_stop_4 + 1
            end
            i = phase_stop_3 + 1
        end
        i_start = i
        phase_start_5 = i_start
        phase_stop_5 = (min)(A_lvl_i1, i_stop)
        if phase_stop_5 >= phase_start_5
            i_9 = i
            i = phase_start_5
            while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_5
                A_lvl_q += 1
            end
            while i <= phase_stop_5
                i_start_4 = i
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_6 = (min)(A_lvl_i, phase_stop_5)
                i_10 = i
                if A_lvl_i == phase_stop_6
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    i_11 = phase_stop_6
                    C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                    C_lvl_isdefault = true
                    C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                    C_lvl_isdefault = false
                    C_lvl_isdefault = false
                    C_lvl_2_val = (+)(A_lvl_2_val, C_lvl_2_val)
                    C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                    if !C_lvl_isdefault
                        (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                        C_lvl.idx[C_lvl_q] = i_11
                        C_lvl_q += 1
                    end
                    A_lvl_q += 1
                else
                end
                i = phase_stop_6 + 1
            end
            i = phase_stop_5 + 1
        end
        i_start = i
        phase_start_7 = i_start
        phase_stop_7 = i_stop
        if phase_stop_7 >= phase_start_7
            i_12 = i
            i = phase_stop_7 + 1
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
