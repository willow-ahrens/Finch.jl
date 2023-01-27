begin
    C_lvl = ex.body.lhs.tns.tns.lvl
    C_lvl_2 = C_lvl.lvl
    C_lvl_2_val = 0.0
    A_lvl = (ex.body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_2_val = 0.0
    B_lvl = (ex.body.rhs.args[2]).tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    B_lvl_2_val = 0.0
    i_stop = (max)(A_lvl.I, (+)(10, B_lvl.I))
    C_lvl_qos_fill = 0
    C_lvl_qos_stop = 0
    (Finch.resize_if_smaller!)(C_lvl.pos, 1 + 1)
    (Finch.fill_range!)(C_lvl.pos, 0, 1 + 1, 1 + 1)
    C_lvl_qos = C_lvl_qos_fill + 1
    i = 1
    i_start = i
    phase_stop = (min)(0, i_stop)
    if phase_stop >= i_start
        i = i
        for i_2 = i_start:phase_stop
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2_dirty = false
            C_lvl_2_val = C_lvl_2.val[C_lvl_qos]
            C_lvl_2_dirty = true
            C_lvl_2_val = missing
            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val
            if C_lvl_2_dirty
                C_lvl_dirty = true
                C_lvl.idx[C_lvl_qos] = i_2
                C_lvl_qos += 1
            end
        end
        i = phase_stop + 1
    end
    i_start = i
    phase_stop_2 = (min)((+)(10, B_lvl.I), 0, i_stop)
    if phase_stop_2 >= i_start
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
        i = i_start
        i_start_2 = i
        phase_stop_3 = (min)(phase_stop_2, (+)(10, B_lvl_i1))
        if phase_stop_3 >= i_start_2
            i_4 = i
            i = i_start_2
            while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < (+)(i_start_2, (-)(10))
                B_lvl_q += 1
            end
            while i <= phase_stop_3
                i_start_3 = i
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_stop_4 = (min)(phase_stop_3, (+)(10, B_lvl_i))
                if phase_stop_4 >= i_start_3
                    i_5 = i
                    if B_lvl_i == (+)(phase_stop_4, (-)(10))
                        B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                        i_6 = phase_stop_4
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2_dirty = false
                        C_lvl_2_val = C_lvl_2.val[C_lvl_qos]
                        C_lvl_2_dirty = true
                        C_lvl_2_val = B_lvl_2_val
                        C_lvl_2.val[C_lvl_qos] = C_lvl_2_val
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
        i_start_2 = i
        if phase_stop_2 >= i_start_2
            i_7 = i
            i = phase_stop_2 + 1
        end
        i = phase_stop_2 + 1
    end
    i_start = i
    phase_stop_5 = (min)(0, i_stop)
    if phase_stop_5 >= i_start
        i_8 = i
        for i_9 = i_start:phase_stop_5
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2_dirty = false
            C_lvl_2_val = C_lvl_2.val[C_lvl_qos]
            C_lvl_2_dirty = true
            C_lvl_2_val = missing
            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val
            if C_lvl_2_dirty
                C_lvl_dirty = true
                C_lvl.idx[C_lvl_qos] = i_9
                C_lvl_qos += 1
            end
        end
        i = phase_stop_5 + 1
    end
    i_start = i
    phase_stop_6 = (min)(A_lvl.I, 10, i_stop)
    if phase_stop_6 >= i_start
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
        i = i_start
        i_start_4 = i
        phase_stop_7 = (min)(A_lvl_i1, phase_stop_6)
        if phase_stop_7 >= i_start_4
            i_11 = i
            i = i_start_4
            while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < i_start_4
                A_lvl_q += 1
            end
            while i <= phase_stop_7
                i_start_5 = i
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_8 = (min)(A_lvl_i, phase_stop_7)
                i_12 = i
                if A_lvl_i == phase_stop_8
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    i_13 = phase_stop_8
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                        resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2_dirty = false
                    C_lvl_2_val = C_lvl_2.val[C_lvl_qos]
                    C_lvl_2_dirty = true
                    C_lvl_2_val = A_lvl_2_val
                    C_lvl_2.val[C_lvl_qos] = C_lvl_2_val
                    if C_lvl_2_dirty
                        C_lvl_dirty = true
                        C_lvl.idx[C_lvl_qos] = i_13
                        C_lvl_qos += 1
                    end
                    A_lvl_q += 1
                else
                end
                i = phase_stop_8 + 1
            end
            i = phase_stop_7 + 1
        end
        i_start_4 = i
        if phase_stop_6 >= i_start_4
            i_14 = i
            i = phase_stop_6 + 1
        end
        i = phase_stop_6 + 1
    end
    i_start = i
    phase_stop_9 = (min)(A_lvl.I, (+)(10, B_lvl.I), i_stop)
    if phase_stop_9 >= i_start
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
        i = i_start
        i_start_6 = i
        phase_stop_10 = (min)((+)(10, B_lvl_i1), A_lvl_i1, phase_stop_9)
        if phase_stop_10 >= i_start_6
            i_16 = i
            i = i_start_6
            while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < i_start_6
                A_lvl_q += 1
            end
            while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < (+)(i_start_6, (-)(10))
                B_lvl_q += 1
            end
            while i <= phase_stop_10
                i_start_7 = i
                A_lvl_i = A_lvl.idx[A_lvl_q]
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_stop_11 = (min)((+)(10, B_lvl_i), A_lvl_i, phase_stop_10)
                if phase_stop_11 >= i_start_7
                    i_17 = i
                    if A_lvl_i == phase_stop_11 && B_lvl_i == (+)(phase_stop_11, (-)(10))
                        A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                        B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                        i_18 = phase_stop_11
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2_dirty = false
                        C_lvl_2_val = C_lvl_2.val[C_lvl_qos]
                        C_lvl_2_dirty = true
                        C_lvl_2_val = (coalesce)(A_lvl_2_val, B_lvl_2_val)
                        C_lvl_2.val[C_lvl_qos] = C_lvl_2_val
                        if C_lvl_2_dirty
                            C_lvl_dirty = true
                            C_lvl.idx[C_lvl_qos] = i_18
                            C_lvl_qos += 1
                        end
                        A_lvl_q += 1
                        B_lvl_q += 1
                    elseif B_lvl_i == (+)(phase_stop_11, (-)(10))
                        B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                        B_lvl_q += 1
                    elseif A_lvl_i == phase_stop_11
                        A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                        i_19 = phase_stop_11
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2_dirty = false
                        C_lvl_2_val = C_lvl_2.val[C_lvl_qos]
                        C_lvl_2_dirty = true
                        C_lvl_2_val = (coalesce)(A_lvl_2_val, 0.0)
                        C_lvl_2.val[C_lvl_qos] = C_lvl_2_val
                        if C_lvl_2_dirty
                            C_lvl_dirty = true
                            C_lvl.idx[C_lvl_qos] = i_19
                            C_lvl_qos += 1
                        end
                        A_lvl_q += 1
                    else
                    end
                    i = phase_stop_11 + 1
                end
            end
            i = phase_stop_10 + 1
        end
        i_start_6 = i
        phase_stop_12 = (min)(A_lvl_i1, phase_stop_9)
        if phase_stop_12 >= i_start_6
            i_20 = i
            i = i_start_6
            while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < i_start_6
                A_lvl_q += 1
            end
            while i <= phase_stop_12
                i_start_8 = i
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_13 = (min)(A_lvl_i, phase_stop_12)
                i_21 = i
                if A_lvl_i == phase_stop_13
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    i_22 = phase_stop_13
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                        resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2_dirty = false
                    C_lvl_2_val = C_lvl_2.val[C_lvl_qos]
                    C_lvl_2_dirty = true
                    C_lvl_2_val = (coalesce)(A_lvl_2_val, 0.0)
                    C_lvl_2.val[C_lvl_qos] = C_lvl_2_val
                    if C_lvl_2_dirty
                        C_lvl_dirty = true
                        C_lvl.idx[C_lvl_qos] = i_22
                        C_lvl_qos += 1
                    end
                    A_lvl_q += 1
                else
                end
                i = phase_stop_13 + 1
            end
            i = phase_stop_12 + 1
        end
        i_start_6 = i
        phase_stop_14 = (min)((+)(10, B_lvl_i1), phase_stop_9)
        if phase_stop_14 >= i_start_6
            i_23 = i
            i = phase_stop_14 + 1
        end
        i_start_6 = i
        if phase_stop_9 >= i_start_6
            i_24 = i
            i = phase_stop_9 + 1
        end
        i = phase_stop_9 + 1
    end
    i_start = i
    phase_stop_15 = (min)(A_lvl.I, i_stop)
    if phase_stop_15 >= i_start
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
        i = i_start
        i_start_9 = i
        phase_stop_16 = (min)(A_lvl_i1, phase_stop_15)
        if phase_stop_16 >= i_start_9
            i_26 = i
            i = i_start_9
            while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < i_start_9
                A_lvl_q += 1
            end
            while i <= phase_stop_16
                i_start_10 = i
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_17 = (min)(A_lvl_i, phase_stop_16)
                i_27 = i
                if A_lvl_i == phase_stop_17
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    i_28 = phase_stop_17
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                        resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2_dirty = false
                    C_lvl_2_val = C_lvl_2.val[C_lvl_qos]
                    C_lvl_2_dirty = true
                    C_lvl_2_val = A_lvl_2_val
                    C_lvl_2.val[C_lvl_qos] = C_lvl_2_val
                    if C_lvl_2_dirty
                        C_lvl_dirty = true
                        C_lvl.idx[C_lvl_qos] = i_28
                        C_lvl_qos += 1
                    end
                    A_lvl_q += 1
                else
                end
                i = phase_stop_17 + 1
            end
            i = phase_stop_16 + 1
        end
        i_start_9 = i
        if phase_stop_15 >= i_start_9
            i_29 = i
            i = phase_stop_15 + 1
        end
        i = phase_stop_15 + 1
    end
    i_start = i
    phase_stop_18 = (min)(10, i_stop)
    if phase_stop_18 >= i_start
        i_30 = i
        for i_31 = i_start:phase_stop_18
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2_dirty = false
            C_lvl_2_val = C_lvl_2.val[C_lvl_qos]
            C_lvl_2_dirty = true
            C_lvl_2_val = missing
            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val
            if C_lvl_2_dirty
                C_lvl_dirty = true
                C_lvl.idx[C_lvl_qos] = i_31
                C_lvl_qos += 1
            end
        end
        i = phase_stop_18 + 1
    end
    i_start = i
    phase_stop_19 = (min)((+)(10, B_lvl.I), i_stop)
    if phase_stop_19 >= i_start
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
        i = i_start
        i_start_11 = i
        phase_stop_20 = (min)((+)(10, B_lvl_i1), phase_stop_19)
        if phase_stop_20 >= i_start_11
            i_33 = i
            i = i_start_11
            while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < (+)(i_start_11, (-)(10))
                B_lvl_q += 1
            end
            while i <= phase_stop_20
                i_start_12 = i
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_stop_21 = (min)((+)(10, B_lvl_i), phase_stop_20)
                if phase_stop_21 >= i_start_12
                    i_34 = i
                    if B_lvl_i == (+)(phase_stop_21, (-)(10))
                        B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                        i_35 = phase_stop_21
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2_dirty = false
                        C_lvl_2_val = C_lvl_2.val[C_lvl_qos]
                        C_lvl_2_dirty = true
                        C_lvl_2_val = B_lvl_2_val
                        C_lvl_2.val[C_lvl_qos] = C_lvl_2_val
                        if C_lvl_2_dirty
                            C_lvl_dirty = true
                            C_lvl.idx[C_lvl_qos] = i_35
                            C_lvl_qos += 1
                        end
                        B_lvl_q += 1
                    else
                    end
                    i = phase_stop_21 + 1
                end
            end
            i = phase_stop_20 + 1
        end
        i_start_11 = i
        if phase_stop_19 >= i_start_11
            i_36 = i
            i = phase_stop_19 + 1
        end
        i = phase_stop_19 + 1
    end
    i_start = i
    if i_stop >= i_start
        i_37 = i
        for i_38 = i_start:i_stop
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2_dirty = false
            C_lvl_2_val = C_lvl_2.val[C_lvl_qos]
            C_lvl_2_dirty = true
            C_lvl_2_val = missing
            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val
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
    (C = Fiber((Finch.SparseListLevel){Int64}((max)(A_lvl.I, (+)(10, B_lvl.I)), C_lvl.pos, C_lvl.idx, C_lvl_2), (Environment)(; )),)
end
