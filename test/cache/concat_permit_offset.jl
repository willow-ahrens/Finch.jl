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
        i_stop = (max)(A_lvl.I, (+)(B_lvl.I, 10))
        C_lvl_pos_alloc = length(C_lvl.pos)
        C_lvl.pos[1] = 1
        C_lvl.pos[2] = 1
        C_lvl_idx_alloc = length(C_lvl.idx)
        C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, 0, 4)
        C_lvl_pos_alloc < 1 + 1 && (C_lvl_pos_alloc = (Finch).regrow!(C_lvl.pos, C_lvl_pos_alloc, 1 + 1))
        C_lvl_q = C_lvl.pos[1]
        i = 1
        i_start = i
        phase_start = (max)(i_start)
        phase_stop = (min)(0, i_stop)
        if phase_stop >= phase_start
            i = i
            for i_2 = phase_start:phase_stop
                C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                C_lvl_isdefault = true
                C_lvl_2_val = 0.0
                C_lvl_isdefault = false
                C_lvl_2_val = missing
                C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                if !C_lvl_isdefault
                    C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                    C_lvl.idx[C_lvl_q] = i_2
                    C_lvl_q += 1
                end
            end
            i = phase_stop + 1
        end
        i_start = i
        phase_start_2 = (max)(i_start)
        phase_stop_2 = (min)(0, i_stop, (+)(B_lvl.I, 10))
        if phase_stop_2 >= phase_start_2
            i_3 = i
            B_lvl_q = B_lvl.pos[1]
            B_lvl_q_stop = B_lvl.pos[1 + 1]
            if B_lvl_q < B_lvl_q_stop
                B_lvl_i = B_lvl.idx[B_lvl_q]
                B_lvl_i1 = B_lvl.idx[B_lvl_q_stop - 1]
            else
                B_lvl_i = 1
                B_lvl_i1 = 0
            end
            i = phase_start_2
            i_start_2 = i
            phase_start_3 = (max)(i_start_2)
            phase_stop_3 = (min)(phase_stop_2, (+)(B_lvl_i1, 10))
            if phase_stop_3 >= phase_start_3
                i_4 = i
                i = phase_start_3
                while B_lvl_q < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < (+)(phase_start_3, (-)(10))
                    B_lvl_q += 1
                end
                while i <= phase_stop_3
                    i_start_3 = i
                    B_lvl_i = B_lvl.idx[B_lvl_q]
                    phase_start_4 = (max)(i_start_3)
                    phase_stop_4 = (min)(phase_stop_3, (+)(B_lvl_i, 10))
                    if phase_stop_4 >= phase_start_4
                        i_5 = i
                        if B_lvl_i == (+)(phase_stop_4, (-)(10))
                            B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                            i_6 = phase_stop_4
                            C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                            C_lvl_isdefault = true
                            C_lvl_2_val = 0.0
                            C_lvl_isdefault = false
                            C_lvl_2_val = B_lvl_2_val
                            C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                            if !C_lvl_isdefault
                                C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                                C_lvl.idx[C_lvl_q] = i_6
                                C_lvl_q += 1
                            end
                            B_lvl_q += 1
                        else
                        end
                        i = phase_stop_4 + 1
                    end
                end
                i = phase_stop_3 + 1
            end
            i_start_2 = i
            phase_start_5 = (max)(i_start_2)
            phase_stop_5 = (min)(phase_stop_2)
            if phase_stop_5 >= phase_start_5
                i_7 = i
                i = phase_stop_5 + 1
            end
            i = phase_stop_2 + 1
        end
        i_start = i
        phase_start_6 = (max)(i_start)
        phase_stop_6 = (min)(0, i_stop)
        if phase_stop_6 >= phase_start_6
            i_8 = i
            for i_9 = phase_start_6:phase_stop_6
                C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                C_lvl_isdefault = true
                C_lvl_2_val = 0.0
                C_lvl_isdefault = false
                C_lvl_2_val = missing
                C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                if !C_lvl_isdefault
                    C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                    C_lvl.idx[C_lvl_q] = i_9
                    C_lvl_q += 1
                end
            end
            i = phase_stop_6 + 1
        end
        i_start = i
        phase_start_7 = (max)(i_start)
        phase_stop_7 = (min)(10, A_lvl.I, i_stop)
        if phase_stop_7 >= phase_start_7
            i_10 = i
            A_lvl_q = A_lvl.pos[1]
            A_lvl_q_stop = A_lvl.pos[1 + 1]
            if A_lvl_q < A_lvl_q_stop
                A_lvl_i = A_lvl.idx[A_lvl_q]
                A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
            else
                A_lvl_i = 1
                A_lvl_i1 = 0
            end
            i = phase_start_7
            i_start_4 = i
            phase_start_8 = (max)(i_start_4)
            phase_stop_8 = (min)(A_lvl_i1, phase_stop_7)
            if phase_stop_8 >= phase_start_8
                i_11 = i
                i = phase_start_8
                while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_8
                    A_lvl_q += 1
                end
                while i <= phase_stop_8
                    i_start_5 = i
                    A_lvl_i = A_lvl.idx[A_lvl_q]
                    phase_stop_9 = (min)(A_lvl_i, phase_stop_8)
                    i_12 = i
                    if A_lvl_i == phase_stop_9
                        A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                        i_13 = phase_stop_9
                        C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                        C_lvl_isdefault = true
                        C_lvl_2_val = 0.0
                        C_lvl_isdefault = false
                        C_lvl_2_val = A_lvl_2_val
                        C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                        if !C_lvl_isdefault
                            C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                            C_lvl.idx[C_lvl_q] = i_13
                            C_lvl_q += 1
                        end
                        A_lvl_q += 1
                    else
                    end
                    i = phase_stop_9 + 1
                end
                i = phase_stop_8 + 1
            end
            i_start_4 = i
            phase_start_10 = (max)(i_start_4)
            phase_stop_10 = (min)(phase_stop_7)
            if phase_stop_10 >= phase_start_10
                i_14 = i
                i = phase_stop_10 + 1
            end
            i = phase_stop_7 + 1
        end
        i_start = i
        phase_start_11 = (max)(i_start)
        phase_stop_11 = (min)(A_lvl.I, i_stop, (+)(B_lvl.I, 10))
        if phase_stop_11 >= phase_start_11
            i_15 = i
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
            i = phase_start_11
            i_start_6 = i
            phase_start_12 = (max)(i_start_6)
            phase_stop_12 = (min)(A_lvl_i1, phase_stop_11, (+)(B_lvl_i1, 10))
            if phase_stop_12 >= phase_start_12
                i_16 = i
                i = phase_start_12
                while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_12
                    A_lvl_q += 1
                end
                while B_lvl_q < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < (+)(phase_start_12, (-)(10))
                    B_lvl_q += 1
                end
                while i <= phase_stop_12
                    i_start_7 = i
                    A_lvl_i = A_lvl.idx[A_lvl_q]
                    B_lvl_i = B_lvl.idx[B_lvl_q]
                    phase_start_13 = (max)(i_start_7)
                    phase_stop_13 = (min)(A_lvl_i, phase_stop_12, (+)(B_lvl_i, 10))
                    if phase_stop_13 >= phase_start_13
                        i_17 = i
                        if A_lvl_i == phase_stop_13 && B_lvl_i == (+)(phase_stop_13, (-)(10))
                            A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                            B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                            i_18 = phase_stop_13
                            C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                            C_lvl_isdefault = true
                            C_lvl_2_val = 0.0
                            C_lvl_isdefault = false
                            C_lvl_2_val = (coalesce)(A_lvl_2_val, B_lvl_2_val)
                            C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                            if !C_lvl_isdefault
                                C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                                C_lvl.idx[C_lvl_q] = i_18
                                C_lvl_q += 1
                            end
                            A_lvl_q += 1
                            B_lvl_q += 1
                        elseif B_lvl_i == (+)(phase_stop_13, (-)(10))
                            B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                            i_19 = phase_stop_13
                            C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                            C_lvl_isdefault = true
                            C_lvl_2_val = 0.0
                            C_lvl_isdefault = false
                            C_lvl_2_val = (coalesce)(0.0, B_lvl_2_val)
                            C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                            if !C_lvl_isdefault
                                C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                                C_lvl.idx[C_lvl_q] = i_19
                                C_lvl_q += 1
                            end
                            B_lvl_q += 1
                        elseif A_lvl_i == phase_stop_13
                            A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                            i_20 = phase_stop_13
                            C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                            C_lvl_isdefault = true
                            C_lvl_2_val = 0.0
                            C_lvl_isdefault = false
                            C_lvl_2_val = (coalesce)(A_lvl_2_val, 0.0)
                            C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                            if !C_lvl_isdefault
                                C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                                C_lvl.idx[C_lvl_q] = i_20
                                C_lvl_q += 1
                            end
                            A_lvl_q += 1
                        else
                        end
                        i = phase_stop_13 + 1
                    end
                end
                i = phase_stop_12 + 1
            end
            i_start_6 = i
            phase_start_14 = (max)(i_start_6)
            phase_stop_14 = (min)(A_lvl_i1, phase_stop_11)
            if phase_stop_14 >= phase_start_14
                i_21 = i
                i = phase_start_14
                while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_14
                    A_lvl_q += 1
                end
                while i <= phase_stop_14
                    i_start_8 = i
                    A_lvl_i = A_lvl.idx[A_lvl_q]
                    phase_stop_15 = (min)(A_lvl_i, phase_stop_14)
                    i_22 = i
                    if A_lvl_i == phase_stop_15
                        A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                        i_23 = phase_stop_15
                        C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                        C_lvl_isdefault = true
                        C_lvl_2_val = 0.0
                        C_lvl_isdefault = false
                        C_lvl_2_val = (coalesce)(A_lvl_2_val, 0.0)
                        C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                        if !C_lvl_isdefault
                            C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                            C_lvl.idx[C_lvl_q] = i_23
                            C_lvl_q += 1
                        end
                        A_lvl_q += 1
                    else
                    end
                    i = phase_stop_15 + 1
                end
                i = phase_stop_14 + 1
            end
            i_start_6 = i
            phase_start_16 = (max)(i_start_6)
            phase_stop_16 = (min)(phase_stop_11, (+)(B_lvl_i1, 10))
            if phase_stop_16 >= phase_start_16
                i_24 = i
                i = phase_start_16
                while B_lvl_q < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < (+)(phase_start_16, (-)(10))
                    B_lvl_q += 1
                end
                while i <= phase_stop_16
                    i_start_9 = i
                    B_lvl_i = B_lvl.idx[B_lvl_q]
                    phase_start_17 = (max)(i_start_9)
                    phase_stop_17 = (min)(phase_stop_16, (+)(B_lvl_i, 10))
                    if phase_stop_17 >= phase_start_17
                        i_25 = i
                        if B_lvl_i == (+)(phase_stop_17, (-)(10))
                            B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                            i_26 = phase_stop_17
                            C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                            C_lvl_isdefault = true
                            C_lvl_2_val = 0.0
                            C_lvl_isdefault = false
                            C_lvl_2_val = (coalesce)(0.0, B_lvl_2_val)
                            C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                            if !C_lvl_isdefault
                                C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                                C_lvl.idx[C_lvl_q] = i_26
                                C_lvl_q += 1
                            end
                            B_lvl_q += 1
                        else
                        end
                        i = phase_stop_17 + 1
                    end
                end
                i = phase_stop_16 + 1
            end
            i_start_6 = i
            phase_start_18 = (max)(i_start_6)
            phase_stop_18 = (min)(phase_stop_11)
            if phase_stop_18 >= phase_start_18
                i_27 = i
                i = phase_stop_18 + 1
            end
            i = phase_stop_11 + 1
        end
        i_start = i
        phase_start_19 = (max)(i_start)
        phase_stop_19 = (min)(A_lvl.I, i_stop)
        if phase_stop_19 >= phase_start_19
            i_28 = i
            A_lvl_q = A_lvl.pos[1]
            A_lvl_q_stop = A_lvl.pos[1 + 1]
            if A_lvl_q < A_lvl_q_stop
                A_lvl_i = A_lvl.idx[A_lvl_q]
                A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
            else
                A_lvl_i = 1
                A_lvl_i1 = 0
            end
            i = phase_start_19
            i_start_10 = i
            phase_start_20 = (max)(i_start_10)
            phase_stop_20 = (min)(A_lvl_i1, phase_stop_19)
            if phase_stop_20 >= phase_start_20
                i_29 = i
                i = phase_start_20
                while A_lvl_q < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_20
                    A_lvl_q += 1
                end
                while i <= phase_stop_20
                    i_start_11 = i
                    A_lvl_i = A_lvl.idx[A_lvl_q]
                    phase_stop_21 = (min)(A_lvl_i, phase_stop_20)
                    i_30 = i
                    if A_lvl_i == phase_stop_21
                        A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                        i_31 = phase_stop_21
                        C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                        C_lvl_isdefault = true
                        C_lvl_2_val = 0.0
                        C_lvl_isdefault = false
                        C_lvl_2_val = A_lvl_2_val
                        C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                        if !C_lvl_isdefault
                            C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                            C_lvl.idx[C_lvl_q] = i_31
                            C_lvl_q += 1
                        end
                        A_lvl_q += 1
                    else
                    end
                    i = phase_stop_21 + 1
                end
                i = phase_stop_20 + 1
            end
            i_start_10 = i
            phase_start_22 = (max)(i_start_10)
            phase_stop_22 = (min)(phase_stop_19)
            if phase_stop_22 >= phase_start_22
                i_32 = i
                i = phase_stop_22 + 1
            end
            i = phase_stop_19 + 1
        end
        i_start = i
        phase_start_23 = (max)(i_start)
        phase_stop_23 = (min)(10, i_stop)
        if phase_stop_23 >= phase_start_23
            i_33 = i
            for i_34 = phase_start_23:phase_stop_23
                C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                C_lvl_isdefault = true
                C_lvl_2_val = 0.0
                C_lvl_isdefault = false
                C_lvl_2_val = missing
                C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                if !C_lvl_isdefault
                    C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                    C_lvl.idx[C_lvl_q] = i_34
                    C_lvl_q += 1
                end
            end
            i = phase_stop_23 + 1
        end
        i_start = i
        phase_start_24 = (max)(i_start)
        phase_stop_24 = (min)(i_stop, (+)(B_lvl.I, 10))
        if phase_stop_24 >= phase_start_24
            i_35 = i
            B_lvl_q = B_lvl.pos[1]
            B_lvl_q_stop = B_lvl.pos[1 + 1]
            if B_lvl_q < B_lvl_q_stop
                B_lvl_i = B_lvl.idx[B_lvl_q]
                B_lvl_i1 = B_lvl.idx[B_lvl_q_stop - 1]
            else
                B_lvl_i = 1
                B_lvl_i1 = 0
            end
            i = phase_start_24
            i_start_12 = i
            phase_start_25 = (max)(i_start_12)
            phase_stop_25 = (min)(phase_stop_24, (+)(B_lvl_i1, 10))
            if phase_stop_25 >= phase_start_25
                i_36 = i
                i = phase_start_25
                while B_lvl_q < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < (+)(phase_start_25, (-)(10))
                    B_lvl_q += 1
                end
                while i <= phase_stop_25
                    i_start_13 = i
                    B_lvl_i = B_lvl.idx[B_lvl_q]
                    phase_start_26 = (max)(i_start_13)
                    phase_stop_26 = (min)(phase_stop_25, (+)(B_lvl_i, 10))
                    if phase_stop_26 >= phase_start_26
                        i_37 = i
                        if B_lvl_i == (+)(phase_stop_26, (-)(10))
                            B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                            i_38 = phase_stop_26
                            C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                            C_lvl_isdefault = true
                            C_lvl_2_val = 0.0
                            C_lvl_isdefault = false
                            C_lvl_2_val = B_lvl_2_val
                            C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                            if !C_lvl_isdefault
                                C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                                C_lvl.idx[C_lvl_q] = i_38
                                C_lvl_q += 1
                            end
                            B_lvl_q += 1
                        else
                        end
                        i = phase_stop_26 + 1
                    end
                end
                i = phase_stop_25 + 1
            end
            i_start_12 = i
            phase_start_27 = (max)(i_start_12)
            phase_stop_27 = (min)(phase_stop_24)
            if phase_stop_27 >= phase_start_27
                i_39 = i
                i = phase_stop_27 + 1
            end
            i = phase_stop_24 + 1
        end
        i_start = i
        phase_start_28 = (max)(i_start)
        phase_stop_28 = (min)(i_stop)
        if phase_stop_28 >= phase_start_28
            i_40 = i
            for i_41 = phase_start_28:phase_stop_28
                C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                C_lvl_isdefault = true
                C_lvl_2_val = 0.0
                C_lvl_isdefault = false
                C_lvl_2_val = missing
                C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                if !C_lvl_isdefault
                    C_lvl_idx_alloc < C_lvl_q && (C_lvl_idx_alloc = (Finch).regrow!(C_lvl.idx, C_lvl_idx_alloc, C_lvl_q))
                    C_lvl.idx[C_lvl_q] = i_41
                    C_lvl_q += 1
                end
            end
            i = phase_stop_28 + 1
        end
        C_lvl.pos[1 + 1] = C_lvl_q
        (C = Fiber((Finch.HollowListLevel){Int64}((max)(A_lvl.I, (+)(B_lvl.I, 10)), C_lvl.pos, C_lvl.idx, C_lvl_2), (Finch.Environment)(; name = :C)),)
    end
