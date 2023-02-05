begin
    C_lvl = ex.body.lhs.tns.tns.lvl
    C_lvl_2 = C_lvl.lvl
    A_lvl = (ex.body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    B_lvl = (ex.body.rhs.args[2]).tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    i_start = (min)((+)(1, ((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), 1)
    i_stop = (max)(A_lvl.I, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, B_lvl.I))
    C_lvl_qos_fill = 0
    C_lvl_qos_stop = 0
    (Finch.resize_if_smaller!)(C_lvl.pos, 1 + 1)
    (Finch.fill_range!)(C_lvl.pos, 0, 1 + 1, 1 + 1)
    C_lvl_qos = C_lvl_qos_fill + 1
    i = i_start
    i_start_2 = i
    phase_stop = (min)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, 0, i_stop)
    if phase_stop >= i_start_2
        i = i
        for i_2 = i_start_2:phase_stop
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2_dirty = false
            C_lvl_2_val_2 = C_lvl_2.val[C_lvl_qos]
            C_lvl_2_dirty = true
            C_lvl_2_val_2 = missing
            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_2
            if C_lvl_2_dirty
                C_lvl_dirty = true
                C_lvl.idx[C_lvl_qos] = i_2
                C_lvl_qos += 1
            end
        end
        i = phase_stop + 1
    end
    i_start_2 = i
    phase_stop_2 = (min)((+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, B_lvl.I), 0, i_stop)
    if phase_stop_2 >= i_start_2
        i_3 = i
        B_lvl_q = B_lvl.pos[1]
        B_lvl_q_stop = B_lvl.pos[1 + 1]
        B_lvl_i = if B_lvl_q < B_lvl_q_stop
                B_lvl.idx[B_lvl_q]
            else
                1
            end
        B_lvl_i1 = if B_lvl_q < B_lvl_q_stop
                B_lvl.idx[B_lvl_q_stop - 1]
            else
                0
            end
        i = i_start_2
        i_start_3 = i
        phase_start = (max)(i_start_3, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, i_start_3, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta)))
        phase_stop_3 = (min)(phase_stop_2, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, B_lvl_i1))
        if phase_stop_3 >= phase_start
            i_4 = i
            i = phase_start
            while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < (+)(phase_start, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta))
                B_lvl_q += 1
            end
            while i <= phase_stop_3
                i_start_4 = i
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_start_2 = (max)(i_start_4, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), i_start_4))
                phase_stop_4 = (min)(phase_stop_3, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, B_lvl_i))
                if phase_stop_4 >= phase_start_2
                    i_5 = i
                    if B_lvl_i == (+)(phase_stop_4, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta))
                        B_lvl_2_val_2 = B_lvl_2.val[B_lvl_q]
                        i_6 = phase_stop_4
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2_dirty = false
                        C_lvl_2_val_3 = C_lvl_2.val[C_lvl_qos]
                        C_lvl_2_dirty = true
                        C_lvl_2_val_3 = B_lvl_2_val_2
                        C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_3
                        if C_lvl_2_dirty
                            C_lvl_dirty = true
                            C_lvl.idx[C_lvl_qos] = i_6
                            C_lvl_qos += 1
                        end
                        B_lvl_q += 1
                    else
                    end
                    i = phase_stop_4 + 1
                end
            end
            i = phase_stop_3 + 1
        end
        i_start_3 = i
        phase_start_3 = (max)(i_start_3, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, i_start_3, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta)))
        phase_stop_5 = (min)(phase_stop_2, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), phase_stop_2))
        if phase_stop_5 >= phase_start_3
            i_7 = i
            i = phase_stop_5 + 1
        end
        i = phase_stop_2 + 1
    end
    i_start_2 = i
    phase_stop_6 = (min)(0, i_stop)
    if phase_stop_6 >= i_start_2
        i_8 = i
        for i_9 = i_start_2:phase_stop_6
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2_dirty = false
            C_lvl_2_val_4 = C_lvl_2.val[C_lvl_qos]
            C_lvl_2_dirty = true
            C_lvl_2_val_4 = missing
            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_4
            if C_lvl_2_dirty
                C_lvl_dirty = true
                C_lvl.idx[C_lvl_qos] = i_9
                C_lvl_qos += 1
            end
        end
        i = phase_stop_6 + 1
    end
    i_start_2 = i
    phase_stop_7 = (min)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, A_lvl.I, i_stop)
    if phase_stop_7 >= i_start_2
        i_10 = i
        A_lvl_q = A_lvl.pos[1]
        A_lvl_q_stop = A_lvl.pos[1 + 1]
        A_lvl_i = if A_lvl_q < A_lvl_q_stop
                A_lvl.idx[A_lvl_q]
            else
                1
            end
        A_lvl_i1 = if A_lvl_q < A_lvl_q_stop
                A_lvl.idx[A_lvl_q_stop - 1]
            else
                0
            end
        i = i_start_2
        i_start_5 = i
        phase_stop_8 = (min)(A_lvl_i1, phase_stop_7)
        if phase_stop_8 >= i_start_5
            i_11 = i
            i = i_start_5
            while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < i_start_5
                A_lvl_q += 1
            end
            while i <= phase_stop_8
                i_start_6 = i
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_9 = (min)(A_lvl_i, phase_stop_8)
                i_12 = i
                if A_lvl_i == phase_stop_9
                    A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                    i_13 = phase_stop_9
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                        resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2_dirty = false
                    C_lvl_2_val_5 = C_lvl_2.val[C_lvl_qos]
                    C_lvl_2_dirty = true
                    C_lvl_2_val_5 = A_lvl_2_val_2
                    C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_5
                    if C_lvl_2_dirty
                        C_lvl_dirty = true
                        C_lvl.idx[C_lvl_qos] = i_13
                        C_lvl_qos += 1
                    end
                    A_lvl_q += 1
                else
                end
                i = phase_stop_9 + 1
            end
            i = phase_stop_8 + 1
        end
        i_start_5 = i
        if phase_stop_7 >= i_start_5
            i_14 = i
            i = phase_stop_7 + 1
        end
        i = phase_stop_7 + 1
    end
    i_start_2 = i
    phase_stop_10 = (min)(A_lvl.I, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, B_lvl.I), i_stop)
    if phase_stop_10 >= i_start_2
        i_15 = i
        A_lvl_q = A_lvl.pos[1]
        A_lvl_q_stop = A_lvl.pos[1 + 1]
        A_lvl_i = if A_lvl_q < A_lvl_q_stop
                A_lvl.idx[A_lvl_q]
            else
                1
            end
        A_lvl_i1 = if A_lvl_q < A_lvl_q_stop
                A_lvl.idx[A_lvl_q_stop - 1]
            else
                0
            end
        B_lvl_q = B_lvl.pos[1]
        B_lvl_q_stop = B_lvl.pos[1 + 1]
        B_lvl_i = if B_lvl_q < B_lvl_q_stop
                B_lvl.idx[B_lvl_q]
            else
                1
            end
        B_lvl_i1 = if B_lvl_q < B_lvl_q_stop
                B_lvl.idx[B_lvl_q_stop - 1]
            else
                0
            end
        i = i_start_2
        i_start_7 = i
        phase_start_4 = (max)(i_start_7, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), i_start_7))
        phase_stop_11 = (min)((+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, B_lvl_i1), A_lvl_i1, phase_stop_10)
        if phase_stop_11 >= phase_start_4
            i_16 = i
            i = phase_start_4
            while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_4
                A_lvl_q += 1
            end
            while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < (+)(phase_start_4, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta))
                B_lvl_q += 1
            end
            while i <= phase_stop_11
                i_start_8 = i
                A_lvl_i = A_lvl.idx[A_lvl_q]
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_start_5 = (max)(i_start_8, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), i_start_8))
                phase_stop_12 = (min)((+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, B_lvl_i), A_lvl_i, phase_stop_11)
                if phase_stop_12 >= phase_start_5
                    i_17 = i
                    if A_lvl_i == phase_stop_12 && B_lvl_i == (+)(phase_stop_12, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta))
                        A_lvl_2_val_3 = A_lvl_2.val[A_lvl_q]
                        B_lvl_2_val_3 = B_lvl_2.val[B_lvl_q]
                        i_18 = phase_stop_12
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2_dirty = false
                        C_lvl_2_val_6 = C_lvl_2.val[C_lvl_qos]
                        C_lvl_2_dirty = true
                        C_lvl_2_val_6 = (coalesce)(A_lvl_2_val_3, B_lvl_2_val_3)
                        C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_6
                        if C_lvl_2_dirty
                            C_lvl_dirty = true
                            C_lvl.idx[C_lvl_qos] = i_18
                            C_lvl_qos += 1
                        end
                        A_lvl_q += 1
                        B_lvl_q += 1
                    elseif B_lvl_i == (+)(phase_stop_12, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta))
                        B_lvl_2_val_3 = B_lvl_2.val[B_lvl_q]
                        B_lvl_q += 1
                    elseif A_lvl_i == phase_stop_12
                        A_lvl_2_val_3 = A_lvl_2.val[A_lvl_q]
                        i_19 = phase_stop_12
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2_dirty = false
                        C_lvl_2_val_7 = C_lvl_2.val[C_lvl_qos]
                        C_lvl_2_dirty = true
                        C_lvl_2_val_7 = (coalesce)(A_lvl_2_val_3, 0.0)
                        C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_7
                        if C_lvl_2_dirty
                            C_lvl_dirty = true
                            C_lvl.idx[C_lvl_qos] = i_19
                            C_lvl_qos += 1
                        end
                        A_lvl_q += 1
                    else
                    end
                    i = phase_stop_12 + 1
                end
            end
            i = phase_stop_11 + 1
        end
        i_start_7 = i
        phase_start_6 = (max)(i_start_7, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), i_start_7))
        phase_stop_13 = (min)(A_lvl_i1, phase_stop_10, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), phase_stop_10))
        if phase_stop_13 >= phase_start_6
            i_20 = i
            i = phase_start_6
            while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_start_6
                A_lvl_q += 1
            end
            while i <= phase_stop_13
                i_start_9 = i
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_14 = (min)(A_lvl_i, phase_stop_13)
                i_21 = i
                if A_lvl_i == phase_stop_14
                    A_lvl_2_val_4 = A_lvl_2.val[A_lvl_q]
                    i_22 = phase_stop_14
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                        resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2_dirty = false
                    C_lvl_2_val_8 = C_lvl_2.val[C_lvl_qos]
                    C_lvl_2_dirty = true
                    C_lvl_2_val_8 = (coalesce)(A_lvl_2_val_4, 0.0)
                    C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_8
                    if C_lvl_2_dirty
                        C_lvl_dirty = true
                        C_lvl.idx[C_lvl_qos] = i_22
                        C_lvl_qos += 1
                    end
                    A_lvl_q += 1
                else
                end
                i = phase_stop_14 + 1
            end
            i = phase_stop_13 + 1
        end
        i_start_7 = i
        phase_start_7 = (max)(i_start_7, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), i_start_7))
        phase_stop_15 = (min)((+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, B_lvl_i1), phase_stop_10)
        if phase_stop_15 >= phase_start_7
            i_23 = i
            i = phase_stop_15 + 1
        end
        i_start_7 = i
        phase_start_8 = (max)(i_start_7, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), i_start_7))
        phase_stop_16 = (min)(phase_stop_10, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), phase_stop_10))
        if phase_stop_16 >= phase_start_8
            i_24 = i
            i = phase_stop_16 + 1
        end
        i = phase_stop_10 + 1
    end
    i_start_2 = i
    phase_stop_17 = (min)(A_lvl.I, i_stop)
    if phase_stop_17 >= i_start_2
        i_25 = i
        A_lvl_q = A_lvl.pos[1]
        A_lvl_q_stop = A_lvl.pos[1 + 1]
        A_lvl_i = if A_lvl_q < A_lvl_q_stop
                A_lvl.idx[A_lvl_q]
            else
                1
            end
        A_lvl_i1 = if A_lvl_q < A_lvl_q_stop
                A_lvl.idx[A_lvl_q_stop - 1]
            else
                0
            end
        i = i_start_2
        i_start_10 = i
        phase_stop_18 = (min)(A_lvl_i1, phase_stop_17)
        if phase_stop_18 >= i_start_10
            i_26 = i
            i = i_start_10
            while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < i_start_10
                A_lvl_q += 1
            end
            while i <= phase_stop_18
                i_start_11 = i
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_19 = (min)(A_lvl_i, phase_stop_18)
                i_27 = i
                if A_lvl_i == phase_stop_19
                    A_lvl_2_val_5 = A_lvl_2.val[A_lvl_q]
                    i_28 = phase_stop_19
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                        resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2_dirty = false
                    C_lvl_2_val_9 = C_lvl_2.val[C_lvl_qos]
                    C_lvl_2_dirty = true
                    C_lvl_2_val_9 = A_lvl_2_val_5
                    C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_9
                    if C_lvl_2_dirty
                        C_lvl_dirty = true
                        C_lvl.idx[C_lvl_qos] = i_28
                        C_lvl_qos += 1
                    end
                    A_lvl_q += 1
                else
                end
                i = phase_stop_19 + 1
            end
            i = phase_stop_18 + 1
        end
        i_start_10 = i
        if phase_stop_17 >= i_start_10
            i_29 = i
            i = phase_stop_17 + 1
        end
        i = phase_stop_17 + 1
    end
    i_start_2 = i
    phase_stop_20 = (min)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, i_stop)
    if phase_stop_20 >= i_start_2
        i_30 = i
        for i_31 = i_start_2:phase_stop_20
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2_dirty = false
            C_lvl_2_val_10 = C_lvl_2.val[C_lvl_qos]
            C_lvl_2_dirty = true
            C_lvl_2_val_10 = missing
            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_10
            if C_lvl_2_dirty
                C_lvl_dirty = true
                C_lvl.idx[C_lvl_qos] = i_31
                C_lvl_qos += 1
            end
        end
        i = phase_stop_20 + 1
    end
    i_start_2 = i
    phase_stop_21 = (min)((+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, B_lvl.I), i_stop)
    if phase_stop_21 >= i_start_2
        i_32 = i
        B_lvl_q = B_lvl.pos[1]
        B_lvl_q_stop = B_lvl.pos[1 + 1]
        B_lvl_i = if B_lvl_q < B_lvl_q_stop
                B_lvl.idx[B_lvl_q]
            else
                1
            end
        B_lvl_i1 = if B_lvl_q < B_lvl_q_stop
                B_lvl.idx[B_lvl_q_stop - 1]
            else
                0
            end
        i = i_start_2
        i_start_12 = i
        phase_start_9 = (max)(i_start_12, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), i_start_12))
        phase_stop_22 = (min)((+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, B_lvl_i1), phase_stop_21)
        if phase_stop_22 >= phase_start_9
            i_33 = i
            i = phase_start_9
            while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < (+)(phase_start_9, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta))
                B_lvl_q += 1
            end
            while i <= phase_stop_22
                i_start_13 = i
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_start_10 = (max)(i_start_13, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), i_start_13))
                phase_stop_23 = (min)((+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, B_lvl_i), phase_stop_22)
                if phase_stop_23 >= phase_start_10
                    i_34 = i
                    if B_lvl_i == (+)(phase_stop_23, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta))
                        B_lvl_2_val_5 = B_lvl_2.val[B_lvl_q]
                        i_35 = phase_stop_23
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2_dirty = false
                        C_lvl_2_val_11 = C_lvl_2.val[C_lvl_qos]
                        C_lvl_2_dirty = true
                        C_lvl_2_val_11 = B_lvl_2_val_5
                        C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_11
                        if C_lvl_2_dirty
                            C_lvl_dirty = true
                            C_lvl.idx[C_lvl_qos] = i_35
                            C_lvl_qos += 1
                        end
                        B_lvl_q += 1
                    else
                    end
                    i = phase_stop_23 + 1
                end
            end
            i = phase_stop_22 + 1
        end
        i_start_12 = i
        phase_start_11 = (max)(i_start_12, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), i_start_12))
        phase_stop_24 = (min)(phase_stop_21, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, (-)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta), phase_stop_21))
        if phase_stop_24 >= phase_start_11
            i_36 = i
            i = phase_stop_24 + 1
        end
        i = phase_stop_21 + 1
    end
    i_start_2 = i
    if i_stop >= i_start_2
        i_37 = i
        for i_38 = i_start_2:i_stop
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2_dirty = false
            C_lvl_2_val_12 = C_lvl_2.val[C_lvl_qos]
            C_lvl_2_dirty = true
            C_lvl_2_val_12 = missing
            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_12
            if C_lvl_2_dirty
                C_lvl_dirty = true
                C_lvl.idx[C_lvl_qos] = i_38
                C_lvl_qos += 1
            end
        end
        i = i_stop + 1
    end
    C_lvl.pos[1 + 1] = (C_lvl_qos - C_lvl_qos_fill) - 1
    C_lvl_qos_fill = C_lvl_qos - 1
    for p = 2:1 + 1
        C_lvl.pos[p] += C_lvl.pos[p - 1]
    end
    qos_stop = C_lvl.pos[1 + 1] - 1
    resize!(C_lvl.pos, 1 + 1)
    qos = C_lvl.pos[end] - 1
    resize!(C_lvl.idx, qos)
    resize!(C_lvl_2.val, qos)
    (C = Fiber((Finch.SparseListLevel){Int64}((max)(A_lvl.I, (+)(((ex.body.rhs.args[2]).idxs[1]).tns.tns.delta, B_lvl.I)), C_lvl.pos, C_lvl.idx, C_lvl_2), (Environment)(; )),)
end
