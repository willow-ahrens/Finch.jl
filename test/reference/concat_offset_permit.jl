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
        i_stop = (max)(A_lvl.I, (+)(10, B_lvl.I))
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
        i = 1
        i_start = i
        phase_start = i_start
        phase_stop = (min)(0, i_stop)
        if phase_stop >= phase_start
            i = i
            for i_2 = phase_start:phase_stop
                C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                C_lvl_isdefault = true
                C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                C_lvl_isdefault = false
                C_lvl_2_val = missing
                C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                if !C_lvl_isdefault
                    (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                    C_lvl.idx[C_lvl_q] = i_2
                    C_lvl_q += 1
                end
            end
            i = phase_stop + 1
        end
        i_start = i
        phase_start_2 = i_start
        phase_stop_2 = (min)((+)(10, B_lvl.I), 0, i_stop)
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
            phase_start_3 = i_start_2
            phase_stop_3 = (min)(phase_stop_2, (+)(10, B_lvl_i1))
            if phase_stop_3 >= phase_start_3
                i_4 = i
                i = phase_start_3
                while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < (+)(phase_start_3, (-)(10))
                    B_lvl_q += 1
                end
                while i <= phase_stop_3
                    i_start_3 = i
                    B_lvl_i = B_lvl.idx[B_lvl_q]
                    phase_start_4 = i_start_3
                    phase_stop_4 = (min)(phase_stop_3, (+)(10, B_lvl_i))
                    if phase_stop_4 >= phase_start_4
                        i_5 = i
                        if B_lvl_i == (+)(phase_stop_4, (-)(10))
                            B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                            i_6 = phase_stop_4
                            C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                            C_lvl_isdefault = true
                            C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                            C_lvl_isdefault = false
                            C_lvl_2_val = B_lvl_2_val
                            C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                            if !C_lvl_isdefault
                                (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
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
            phase_start_5 = i_start_2
            phase_stop_5 = phase_stop_2
            if phase_stop_5 >= phase_start_5
                i_7 = i
                i = phase_stop_5 + 1
            end
            i = phase_stop_2 + 1
        end
        i_start = i
        phase_start_6 = i_start
        phase_stop_6 = (min)(0, i_stop)
        if phase_stop_6 >= phase_start_6
            i_8 = i
            for i_9 = phase_start_6:phase_stop_6
                C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                C_lvl_isdefault = true
                C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                C_lvl_isdefault = false
                C_lvl_2_val = missing
                C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                if !C_lvl_isdefault
                    (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                    C_lvl.idx[C_lvl_q] = i_9
                    C_lvl_q += 1
                end
            end
            i = phase_stop_6 + 1
        end
        i_start = i
        phase_start_7 = i_start
        phase_stop_7 = (min)(A_lvl.I, 10, i_stop)
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
            phase_start_8 = i_start_4
            phase_stop_8 = (min)(A_lvl_i1, phase_stop_7)
            if phase_stop_8 >= phase_start_8
                i_11 = i
                i = phase_start_8
                while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_8
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
                        C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                        C_lvl_isdefault = false
                        C_lvl_2_val = A_lvl_2_val
                        C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                        if !C_lvl_isdefault
                            (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
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
            phase_start_10 = i_start_4
            phase_stop_10 = phase_stop_7
            if phase_stop_10 >= phase_start_10
                i_14 = i
                i = phase_stop_10 + 1
            end
            i = phase_stop_7 + 1
        end
        i_start = i
        phase_start_11 = i_start
        phase_stop_11 = (min)(A_lvl.I, (+)(10, B_lvl.I), i_stop)
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
            phase_start_12 = i_start_6
            phase_stop_12 = (min)((+)(10, B_lvl_i1), A_lvl_i1, phase_stop_11)
            if phase_stop_12 >= phase_start_12
                i_16 = i
                i = phase_start_12
                while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_12
                    A_lvl_q += 1
                end
                while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < (+)(phase_start_12, (-)(10))
                    B_lvl_q += 1
                end
                while i <= phase_stop_12
                    i_start_7 = i
                    A_lvl_i = A_lvl.idx[A_lvl_q]
                    B_lvl_i = B_lvl.idx[B_lvl_q]
                    phase_start_13 = i_start_7
                    phase_stop_13 = (min)((+)(10, B_lvl_i), A_lvl_i, phase_stop_12)
                    if phase_stop_13 >= phase_start_13
                        i_17 = i
                        if A_lvl_i == phase_stop_13 && B_lvl_i == (+)(phase_stop_13, (-)(10))
                            A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                            B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                            i_18 = phase_stop_13
                            C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                            C_lvl_isdefault = true
                            C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                            C_lvl_isdefault = false
                            C_lvl_2_val = (coalesce)(A_lvl_2_val, B_lvl_2_val)
                            C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                            if !C_lvl_isdefault
                                (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                                C_lvl.idx[C_lvl_q] = i_18
                                C_lvl_q += 1
                            end
                            A_lvl_q += 1
                            B_lvl_q += 1
                        elseif B_lvl_i == (+)(phase_stop_13, (-)(10))
                            B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                            B_lvl_q += 1
                        elseif A_lvl_i == phase_stop_13
                            A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                            i_19 = phase_stop_13
                            C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                            C_lvl_isdefault = true
                            C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                            C_lvl_isdefault = false
                            C_lvl_2_val = (coalesce)(A_lvl_2_val, 0.0)
                            C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                            if !C_lvl_isdefault
                                (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                                C_lvl.idx[C_lvl_q] = i_19
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
            phase_start_14 = i_start_6
            phase_stop_14 = (min)(A_lvl_i1, phase_stop_11)
            if phase_stop_14 >= phase_start_14
                i_20 = i
                i = phase_start_14
                while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_14
                    A_lvl_q += 1
                end
                while i <= phase_stop_14
                    i_start_8 = i
                    A_lvl_i = A_lvl.idx[A_lvl_q]
                    phase_stop_15 = (min)(A_lvl_i, phase_stop_14)
                    i_21 = i
                    if A_lvl_i == phase_stop_15
                        A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                        i_22 = phase_stop_15
                        C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                        C_lvl_isdefault = true
                        C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                        C_lvl_isdefault = false
                        C_lvl_2_val = (coalesce)(A_lvl_2_val, 0.0)
                        C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                        if !C_lvl_isdefault
                            (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                            C_lvl.idx[C_lvl_q] = i_22
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
            phase_start_16 = i_start_6
            phase_stop_16 = (min)((+)(10, B_lvl_i1), phase_stop_11)
            if phase_stop_16 >= phase_start_16
                i_23 = i
                i = phase_stop_16 + 1
            end
            i_start_6 = i
            phase_start_17 = i_start_6
            phase_stop_17 = phase_stop_11
            if phase_stop_17 >= phase_start_17
                i_24 = i
                i = phase_stop_17 + 1
            end
            i = phase_stop_11 + 1
        end
        i_start = i
        phase_start_18 = i_start
        phase_stop_18 = (min)(A_lvl.I, i_stop)
        if phase_stop_18 >= phase_start_18
            i_25 = i
            A_lvl_q = A_lvl.pos[1]
            A_lvl_q_stop = A_lvl.pos[1 + 1]
            if A_lvl_q < A_lvl_q_stop
                A_lvl_i = A_lvl.idx[A_lvl_q]
                A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
            else
                A_lvl_i = 1
                A_lvl_i1 = 0
            end
            i = phase_start_18
            i_start_9 = i
            phase_start_19 = i_start_9
            phase_stop_19 = (min)(A_lvl_i1, phase_stop_18)
            if phase_stop_19 >= phase_start_19
                i_26 = i
                i = phase_start_19
                while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_19
                    A_lvl_q += 1
                end
                while i <= phase_stop_19
                    i_start_10 = i
                    A_lvl_i = A_lvl.idx[A_lvl_q]
                    phase_stop_20 = (min)(A_lvl_i, phase_stop_19)
                    i_27 = i
                    if A_lvl_i == phase_stop_20
                        A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                        i_28 = phase_stop_20
                        C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                        C_lvl_isdefault = true
                        C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                        C_lvl_isdefault = false
                        C_lvl_2_val = A_lvl_2_val
                        C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                        if !C_lvl_isdefault
                            (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                            C_lvl.idx[C_lvl_q] = i_28
                            C_lvl_q += 1
                        end
                        A_lvl_q += 1
                    else
                    end
                    i = phase_stop_20 + 1
                end
                i = phase_stop_19 + 1
            end
            i_start_9 = i
            phase_start_21 = i_start_9
            phase_stop_21 = phase_stop_18
            if phase_stop_21 >= phase_start_21
                i_29 = i
                i = phase_stop_21 + 1
            end
            i = phase_stop_18 + 1
        end
        i_start = i
        phase_start_22 = i_start
        phase_stop_22 = (min)(10, i_stop)
        if phase_stop_22 >= phase_start_22
            i_30 = i
            for i_31 = phase_start_22:phase_stop_22
                C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                C_lvl_isdefault = true
                C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                C_lvl_isdefault = false
                C_lvl_2_val = missing
                C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                if !C_lvl_isdefault
                    (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                    C_lvl.idx[C_lvl_q] = i_31
                    C_lvl_q += 1
                end
            end
            i = phase_stop_22 + 1
        end
        i_start = i
        phase_start_23 = i_start
        phase_stop_23 = (min)((+)(10, B_lvl.I), i_stop)
        if phase_stop_23 >= phase_start_23
            i_32 = i
            B_lvl_q = B_lvl.pos[1]
            B_lvl_q_stop = B_lvl.pos[1 + 1]
            if B_lvl_q < B_lvl_q_stop
                B_lvl_i = B_lvl.idx[B_lvl_q]
                B_lvl_i1 = B_lvl.idx[B_lvl_q_stop - 1]
            else
                B_lvl_i = 1
                B_lvl_i1 = 0
            end
            i = phase_start_23
            i_start_11 = i
            phase_start_24 = i_start_11
            phase_stop_24 = (min)((+)(10, B_lvl_i1), phase_stop_23)
            if phase_stop_24 >= phase_start_24
                i_33 = i
                i = phase_start_24
                while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < (+)(phase_start_24, (-)(10))
                    B_lvl_q += 1
                end
                while i <= phase_stop_24
                    i_start_12 = i
                    B_lvl_i = B_lvl.idx[B_lvl_q]
                    phase_start_25 = i_start_12
                    phase_stop_25 = (min)((+)(10, B_lvl_i), phase_stop_24)
                    if phase_stop_25 >= phase_start_25
                        i_34 = i
                        if B_lvl_i == (+)(phase_stop_25, (-)(10))
                            B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                            i_35 = phase_stop_25
                            C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                            C_lvl_isdefault = true
                            C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                            C_lvl_isdefault = false
                            C_lvl_2_val = B_lvl_2_val
                            C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                            if !C_lvl_isdefault
                                (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                                C_lvl.idx[C_lvl_q] = i_35
                                C_lvl_q += 1
                            end
                            B_lvl_q += 1
                        else
                        end
                        i = phase_stop_25 + 1
                    end
                end
                i = phase_stop_24 + 1
            end
            i_start_11 = i
            phase_start_26 = i_start_11
            phase_stop_26 = phase_stop_23
            if phase_stop_26 >= phase_start_26
                i_36 = i
                i = phase_stop_26 + 1
            end
            i = phase_stop_23 + 1
        end
        i_start = i
        phase_start_27 = i_start
        phase_stop_27 = i_stop
        if phase_stop_27 >= phase_start_27
            i_37 = i
            for i_38 = phase_start_27:phase_stop_27
                C_lvl_2_val_alloc < C_lvl_q && (C_lvl_2_val_alloc = (Finch).refill!(C_lvl_2.val, 0.0, C_lvl_2_val_alloc, C_lvl_q))
                C_lvl_isdefault = true
                C_lvl_2_val = C_lvl_2.val[C_lvl_q]
                C_lvl_isdefault = false
                C_lvl_2_val = missing
                C_lvl_2.val[C_lvl_q] = C_lvl_2_val
                if !C_lvl_isdefault
                    (Finch).@regrow! C_lvl.idx C_lvl_idx_alloc C_lvl_q
                    C_lvl.idx[C_lvl_q] = i_38
                    C_lvl_q += 1
                end
            end
            i = phase_stop_27 + 1
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
        (C = Fiber((Finch.SparseListLevel){Int64}((max)(A_lvl.I, (+)(10, B_lvl.I)), C_lvl.pos, C_lvl.idx, C_lvl_2), (Finch.Environment)(; )),)
    end
