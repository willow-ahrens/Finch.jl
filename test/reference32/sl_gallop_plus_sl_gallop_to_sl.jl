begin
    C_lvl = ex.body.lhs.tns.tns.lvl
    C_lvl_2 = C_lvl.lvl
    A_lvl = (ex.body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    B_lvl = (ex.body.rhs.args[2]).tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    C_lvl_qos_fill = 0
    C_lvl_qos_stop = 0
    (Finch.resize_if_smaller!)(C_lvl.pos, 1 + 1)
    (Finch.fill_range!)(C_lvl.pos, 0, 1 + 1, 1 + 1)
    C_lvl_qos = C_lvl_qos_fill + 1
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
    i = 1
    i_start = i
    phase_stop = (min)(A_lvl.I, A_lvl_i1, B_lvl_i1)
    if phase_stop >= i_start
        i = i
        i = i_start
        while i <= phase_stop
            i_start_2 = i
            while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < i_start_2
                B_lvl_q += 1
            end
            B_lvl_i = B_lvl.idx[B_lvl_q]
            while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < i_start_2
                A_lvl_q += 1
            end
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_stop_2 = (min)((max)(A_lvl_i, B_lvl_i), phase_stop)
            if phase_stop_2 >= i_start_2
                i_2 = i
                if phase_stop_2 == B_lvl_i && phase_stop_2 == A_lvl_i
                    B_lvl_2_val_2 = B_lvl_2.val[B_lvl_q]
                    A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                    i_3 = phase_stop_2
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                        resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2_dirty = false
                    C_lvl_2_val_2 = C_lvl_2.val[C_lvl_qos]
                    C_lvl_2_dirty = true
                    C_lvl_2_dirty = true
                    C_lvl_2_val_2 = (+)(B_lvl_2_val_2, C_lvl_2_val_2, A_lvl_2_val_2)
                    C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_2
                    if C_lvl_2_dirty
                        C_lvl_dirty = true
                        C_lvl.idx[C_lvl_qos] = i_3
                        C_lvl_qos += 1
                    end
                    B_lvl_q += 1
                    A_lvl_q += 1
                elseif phase_stop_2 == A_lvl_i
                    i = i_start_2
                    while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < i_start_2
                        B_lvl_q += 1
                    end
                    while i <= phase_stop_2 - 1
                        i_start_3 = i
                        B_lvl_i = B_lvl.idx[B_lvl_q]
                        phase_stop_3 = (min)(B_lvl_i, phase_stop_2 - 1)
                        i_4 = i
                        if B_lvl_i == phase_stop_3
                            B_lvl_2_val_3 = B_lvl_2.val[B_lvl_q]
                            i_5 = phase_stop_3
                            if C_lvl_qos > C_lvl_qos_stop
                                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                            end
                            C_lvl_2_dirty = false
                            C_lvl_2_val_3 = C_lvl_2.val[C_lvl_qos]
                            C_lvl_2_dirty = true
                            C_lvl_2_dirty = true
                            C_lvl_2_val_3 = (+)(B_lvl_2_val_3, C_lvl_2_val_3)
                            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_3
                            if C_lvl_2_dirty
                                C_lvl_dirty = true
                                C_lvl.idx[C_lvl_qos] = i_5
                                C_lvl_qos += 1
                            end
                            B_lvl_q += 1
                        else
                        end
                        i = phase_stop_3 + 1
                    end
                    A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                    i = phase_stop_2
                    while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < phase_stop_2
                        B_lvl_q += 1
                    end
                    i_start_4 = i
                    B_lvl_i = B_lvl.idx[B_lvl_q]
                    phase_stop_4 = (min)(B_lvl_i, phase_stop_2)
                    i_6 = i
                    if B_lvl_i == phase_stop_4
                        for i_7 = i_start_4:phase_stop_4 - 1
                            if C_lvl_qos > C_lvl_qos_stop
                                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                            end
                            C_lvl_2_dirty = false
                            C_lvl_2_val_4 = C_lvl_2.val[C_lvl_qos]
                            C_lvl_2_dirty = true
                            C_lvl_2_dirty = true
                            C_lvl_2_val_4 = (+)(A_lvl_2_val_2, C_lvl_2_val_4)
                            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_4
                            if C_lvl_2_dirty
                                C_lvl_dirty = true
                                C_lvl.idx[C_lvl_qos] = i_7
                                C_lvl_qos += 1
                            end
                        end
                        B_lvl_2_val_3 = B_lvl_2.val[B_lvl_q]
                        i_8 = phase_stop_4
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2_dirty = false
                        C_lvl_2_val_5 = C_lvl_2.val[C_lvl_qos]
                        C_lvl_2_dirty = true
                        C_lvl_2_dirty = true
                        C_lvl_2_val_5 = (+)(A_lvl_2_val_2, B_lvl_2_val_3, C_lvl_2_val_5)
                        C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_5
                        if C_lvl_2_dirty
                            C_lvl_dirty = true
                            C_lvl.idx[C_lvl_qos] = i_8
                            C_lvl_qos += 1
                        end
                        B_lvl_q += 1
                    else
                        for i_9 = i_start_4:phase_stop_4
                            if C_lvl_qos > C_lvl_qos_stop
                                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                            end
                            C_lvl_2_dirty = false
                            C_lvl_2_val_6 = C_lvl_2.val[C_lvl_qos]
                            C_lvl_2_dirty = true
                            C_lvl_2_dirty = true
                            C_lvl_2_val_6 = (+)(A_lvl_2_val_2, C_lvl_2_val_6)
                            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_6
                            if C_lvl_2_dirty
                                C_lvl_dirty = true
                                C_lvl.idx[C_lvl_qos] = i_9
                                C_lvl_qos += 1
                            end
                        end
                    end
                    i = phase_stop_4 + 1
                    A_lvl_q += 1
                elseif phase_stop_2 == B_lvl_i
                    i = i_start_2
                    while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < i_start_2
                        A_lvl_q += 1
                    end
                    while i <= phase_stop_2 - 1
                        i_start_5 = i
                        A_lvl_i = A_lvl.idx[A_lvl_q]
                        phase_stop_5 = (min)(A_lvl_i, phase_stop_2 - 1)
                        i_10 = i
                        if A_lvl_i == phase_stop_5
                            A_lvl_2_val_3 = A_lvl_2.val[A_lvl_q]
                            i_11 = phase_stop_5
                            if C_lvl_qos > C_lvl_qos_stop
                                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                            end
                            C_lvl_2_dirty = false
                            C_lvl_2_val_7 = C_lvl_2.val[C_lvl_qos]
                            C_lvl_2_dirty = true
                            C_lvl_2_dirty = true
                            C_lvl_2_val_7 = (+)(A_lvl_2_val_3, C_lvl_2_val_7)
                            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_7
                            if C_lvl_2_dirty
                                C_lvl_dirty = true
                                C_lvl.idx[C_lvl_qos] = i_11
                                C_lvl_qos += 1
                            end
                            A_lvl_q += 1
                        else
                        end
                        i = phase_stop_5 + 1
                    end
                    B_lvl_2_val_2 = B_lvl_2.val[B_lvl_q]
                    i = phase_stop_2
                    while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < phase_stop_2
                        A_lvl_q += 1
                    end
                    i_start_6 = i
                    A_lvl_i = A_lvl.idx[A_lvl_q]
                    phase_stop_6 = (min)(A_lvl_i, phase_stop_2)
                    i_12 = i
                    if A_lvl_i == phase_stop_6
                        for i_13 = i_start_6:phase_stop_6 - 1
                            if C_lvl_qos > C_lvl_qos_stop
                                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                            end
                            C_lvl_2_dirty = false
                            C_lvl_2_val_8 = C_lvl_2.val[C_lvl_qos]
                            C_lvl_2_dirty = true
                            C_lvl_2_dirty = true
                            C_lvl_2_val_8 = (+)(B_lvl_2_val_2, C_lvl_2_val_8)
                            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_8
                            if C_lvl_2_dirty
                                C_lvl_dirty = true
                                C_lvl.idx[C_lvl_qos] = i_13
                                C_lvl_qos += 1
                            end
                        end
                        A_lvl_2_val_3 = A_lvl_2.val[A_lvl_q]
                        i_14 = phase_stop_6
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2_dirty = false
                        C_lvl_2_val_9 = C_lvl_2.val[C_lvl_qos]
                        C_lvl_2_dirty = true
                        C_lvl_2_dirty = true
                        C_lvl_2_val_9 = (+)(B_lvl_2_val_2, A_lvl_2_val_3, C_lvl_2_val_9)
                        C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_9
                        if C_lvl_2_dirty
                            C_lvl_dirty = true
                            C_lvl.idx[C_lvl_qos] = i_14
                            C_lvl_qos += 1
                        end
                        A_lvl_q += 1
                    else
                        for i_15 = i_start_6:phase_stop_6
                            if C_lvl_qos > C_lvl_qos_stop
                                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                            end
                            C_lvl_2_dirty = false
                            C_lvl_2_val_10 = C_lvl_2.val[C_lvl_qos]
                            C_lvl_2_dirty = true
                            C_lvl_2_dirty = true
                            C_lvl_2_val_10 = (+)(B_lvl_2_val_2, C_lvl_2_val_10)
                            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_10
                            if C_lvl_2_dirty
                                C_lvl_dirty = true
                                C_lvl.idx[C_lvl_qos] = i_15
                                C_lvl_qos += 1
                            end
                        end
                    end
                    i = phase_stop_6 + 1
                    B_lvl_q += 1
                else
                    i = i_start_2
                    while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < i_start_2
                        B_lvl_q += 1
                    end
                    while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < i_start_2
                        A_lvl_q += 1
                    end
                    while i <= phase_stop_2
                        i_start_7 = i
                        B_lvl_i = B_lvl.idx[B_lvl_q]
                        A_lvl_i = A_lvl.idx[A_lvl_q]
                        phase_stop_7 = (min)(A_lvl_i, B_lvl_i, phase_stop_2)
                        i_16 = i
                        if B_lvl_i == phase_stop_7 && A_lvl_i == phase_stop_7
                            B_lvl_2_val_3 = B_lvl_2.val[B_lvl_q]
                            A_lvl_2_val_3 = A_lvl_2.val[A_lvl_q]
                            i_17 = phase_stop_7
                            if C_lvl_qos > C_lvl_qos_stop
                                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                            end
                            C_lvl_2_dirty = false
                            C_lvl_2_val_11 = C_lvl_2.val[C_lvl_qos]
                            C_lvl_2_dirty = true
                            C_lvl_2_dirty = true
                            C_lvl_2_val_11 = (+)(B_lvl_2_val_3, A_lvl_2_val_3, C_lvl_2_val_11)
                            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_11
                            if C_lvl_2_dirty
                                C_lvl_dirty = true
                                C_lvl.idx[C_lvl_qos] = i_17
                                C_lvl_qos += 1
                            end
                            B_lvl_q += 1
                            A_lvl_q += 1
                        elseif A_lvl_i == phase_stop_7
                            A_lvl_2_val_3 = A_lvl_2.val[A_lvl_q]
                            i_18 = phase_stop_7
                            if C_lvl_qos > C_lvl_qos_stop
                                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                            end
                            C_lvl_2_dirty = false
                            C_lvl_2_val_12 = C_lvl_2.val[C_lvl_qos]
                            C_lvl_2_dirty = true
                            C_lvl_2_dirty = true
                            C_lvl_2_val_12 = (+)(A_lvl_2_val_3, C_lvl_2_val_12)
                            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_12
                            if C_lvl_2_dirty
                                C_lvl_dirty = true
                                C_lvl.idx[C_lvl_qos] = i_18
                                C_lvl_qos += 1
                            end
                            A_lvl_q += 1
                        elseif B_lvl_i == phase_stop_7
                            B_lvl_2_val_3 = B_lvl_2.val[B_lvl_q]
                            i_19 = phase_stop_7
                            if C_lvl_qos > C_lvl_qos_stop
                                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                            end
                            C_lvl_2_dirty = false
                            C_lvl_2_val_13 = C_lvl_2.val[C_lvl_qos]
                            C_lvl_2_dirty = true
                            C_lvl_2_dirty = true
                            C_lvl_2_val_13 = (+)(B_lvl_2_val_3, C_lvl_2_val_13)
                            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_13
                            if C_lvl_2_dirty
                                C_lvl_dirty = true
                                C_lvl.idx[C_lvl_qos] = i_19
                                C_lvl_qos += 1
                            end
                            B_lvl_q += 1
                        else
                        end
                        i = phase_stop_7 + 1
                    end
                end
                i = phase_stop_2 + 1
            end
        end
        i = phase_stop + 1
    end
    i_start = i
    phase_stop_8 = (min)(A_lvl.I, B_lvl_i1)
    if phase_stop_8 >= i_start
        i_20 = i
        i = i_start
        while i <= phase_stop_8
            i_start_8 = i
            while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < i_start_8
                B_lvl_q += 1
            end
            B_lvl_i = B_lvl.idx[B_lvl_q]
            phase_stop_9 = (min)(B_lvl_i, phase_stop_8)
            if phase_stop_9 >= i_start_8
                i_21 = i
                if phase_stop_9 == B_lvl_i
                    B_lvl_2_val_4 = B_lvl_2.val[B_lvl_q]
                    i_22 = phase_stop_9
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                        resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2_dirty = false
                    C_lvl_2_val_14 = C_lvl_2.val[C_lvl_qos]
                    C_lvl_2_dirty = true
                    C_lvl_2_dirty = true
                    C_lvl_2_val_14 = (+)(B_lvl_2_val_4, C_lvl_2_val_14)
                    C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_14
                    if C_lvl_2_dirty
                        C_lvl_dirty = true
                        C_lvl.idx[C_lvl_qos] = i_22
                        C_lvl_qos += 1
                    end
                    B_lvl_q += 1
                else
                    i = i_start_8
                    while B_lvl_q + 1 < B_lvl_q_stop && B_lvl.idx[B_lvl_q] < i_start_8
                        B_lvl_q += 1
                    end
                    while i <= phase_stop_9
                        i_start_9 = i
                        B_lvl_i = B_lvl.idx[B_lvl_q]
                        phase_stop_10 = (min)(B_lvl_i, phase_stop_9)
                        i_23 = i
                        if B_lvl_i == phase_stop_10
                            B_lvl_2_val_5 = B_lvl_2.val[B_lvl_q]
                            i_24 = phase_stop_10
                            if C_lvl_qos > C_lvl_qos_stop
                                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                            end
                            C_lvl_2_dirty = false
                            C_lvl_2_val_15 = C_lvl_2.val[C_lvl_qos]
                            C_lvl_2_dirty = true
                            C_lvl_2_dirty = true
                            C_lvl_2_val_15 = (+)(B_lvl_2_val_5, C_lvl_2_val_15)
                            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_15
                            if C_lvl_2_dirty
                                C_lvl_dirty = true
                                C_lvl.idx[C_lvl_qos] = i_24
                                C_lvl_qos += 1
                            end
                            B_lvl_q += 1
                        else
                        end
                        i = phase_stop_10 + 1
                    end
                end
                i = phase_stop_9 + 1
            end
        end
        i = phase_stop_8 + 1
    end
    i_start = i
    phase_stop_11 = (min)(A_lvl.I, A_lvl_i1)
    if phase_stop_11 >= i_start
        i_25 = i
        i = i_start
        while i <= phase_stop_11
            i_start_10 = i
            while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < i_start_10
                A_lvl_q += 1
            end
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_stop_12 = (min)(A_lvl_i, phase_stop_11)
            if phase_stop_12 >= i_start_10
                i_26 = i
                if phase_stop_12 == A_lvl_i
                    A_lvl_2_val_4 = A_lvl_2.val[A_lvl_q]
                    i_27 = phase_stop_12
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                        resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2_dirty = false
                    C_lvl_2_val_16 = C_lvl_2.val[C_lvl_qos]
                    C_lvl_2_dirty = true
                    C_lvl_2_dirty = true
                    C_lvl_2_val_16 = (+)(A_lvl_2_val_4, C_lvl_2_val_16)
                    C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_16
                    if C_lvl_2_dirty
                        C_lvl_dirty = true
                        C_lvl.idx[C_lvl_qos] = i_27
                        C_lvl_qos += 1
                    end
                    A_lvl_q += 1
                else
                    i = i_start_10
                    while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < i_start_10
                        A_lvl_q += 1
                    end
                    while i <= phase_stop_12
                        i_start_11 = i
                        A_lvl_i = A_lvl.idx[A_lvl_q]
                        phase_stop_13 = (min)(A_lvl_i, phase_stop_12)
                        i_28 = i
                        if A_lvl_i == phase_stop_13
                            A_lvl_2_val_5 = A_lvl_2.val[A_lvl_q]
                            i_29 = phase_stop_13
                            if C_lvl_qos > C_lvl_qos_stop
                                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                                (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                            end
                            C_lvl_2_dirty = false
                            C_lvl_2_val_17 = C_lvl_2.val[C_lvl_qos]
                            C_lvl_2_dirty = true
                            C_lvl_2_dirty = true
                            C_lvl_2_val_17 = (+)(A_lvl_2_val_5, C_lvl_2_val_17)
                            C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_17
                            if C_lvl_2_dirty
                                C_lvl_dirty = true
                                C_lvl.idx[C_lvl_qos] = i_29
                                C_lvl_qos += 1
                            end
                            A_lvl_q += 1
                        else
                        end
                        i = phase_stop_13 + 1
                    end
                end
                i = phase_stop_12 + 1
            end
        end
        i = phase_stop_11 + 1
    end
    i_start = i
    if A_lvl.I >= i_start
        i_30 = i
        i = A_lvl.I + 1
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
    (C = Fiber((Finch.SparseListLevel){Int64}(A_lvl.I, C_lvl.pos, C_lvl.idx, C_lvl_2)),)
end
