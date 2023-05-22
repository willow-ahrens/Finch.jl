begin
    C_lvl = (ex.bodies[1]).tns.tns.lvl
    C_lvl_2 = C_lvl.lvl
    A_lvl = ((ex.bodies[2]).body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    B_lvl = ((ex.bodies[2]).body.rhs.args[2]).tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    i_start = min(1 + (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta, 1)
    i_stop = max(A_lvl.shape, (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta + B_lvl.shape)
    C_lvl_qos_stop = 0
    resize_if_smaller!(C_lvl.ptr, 1 + 1)
    fill_range!(C_lvl.ptr, 0, 1 + 1, 1 + 1)
    C_lvl_qos = 0 + 1
    phase_stop = min((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta, i_stop, 0)
    if phase_stop >= i_start
        for i_6 = i_start:phase_stop
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2.val[C_lvl_qos] = missing
            C_lvl.idx[C_lvl_qos] = i_6
            C_lvl_qos += 1
        end
    end
    phase_start_2 = max(1 + (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta, i_start)
    phase_stop_2 = min((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta + B_lvl.shape, i_stop, 0)
    if phase_stop_2 >= phase_start_2
        B_lvl_q = B_lvl.ptr[1]
        B_lvl_q_stop = B_lvl.ptr[1 + 1]
        if B_lvl_q < B_lvl_q_stop
            B_lvl_i1 = B_lvl.idx[B_lvl_q_stop - 1]
        else
            B_lvl_i1 = 0
        end
        phase_stop_3 = min(B_lvl_i1, phase_stop_2, (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta + B_lvl_i1)
        if phase_stop_3 >= phase_start_2
            i = phase_start_2
            if B_lvl.idx[B_lvl_q] < phase_start_2 + -((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta)
                B_lvl_q = scansearch(B_lvl.idx, phase_start_2 + -((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta), B_lvl_q, B_lvl_q_stop - 1)
            end
            while i <= phase_stop_3
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_stop_4 = min(phase_stop_3, (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta + B_lvl_i)
                if phase_stop_4 >= i
                    if B_lvl_i == phase_stop_4 + -((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta)
                        B_lvl_2_val_2 = B_lvl_2.val[B_lvl_q]
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2.val[C_lvl_qos] = B_lvl_2_val_2
                        C_lvl.idx[C_lvl_qos] = phase_stop_4
                        C_lvl_qos += 1
                        B_lvl_q += 1
                    end
                    i = phase_stop_4 + 1
                end
            end
        end
    end
    phase_start_6 = max(i_start, 1 + (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta + B_lvl.shape)
    phase_stop_6 = min(i_stop, 0)
    if phase_stop_6 >= phase_start_6
        for i_13 = phase_start_6:phase_stop_6
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2.val[C_lvl_qos] = missing
            C_lvl.idx[C_lvl_qos] = i_13
            C_lvl_qos += 1
        end
    end
    phase_start_7 = max(1, i_start)
    phase_stop_7 = min((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta, A_lvl.shape, i_stop)
    if phase_stop_7 >= phase_start_7
        A_lvl_q = A_lvl.ptr[1]
        A_lvl_q_stop = A_lvl.ptr[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i1 = 0
        end
        phase_stop_8 = min(A_lvl_i1, phase_stop_7)
        if phase_stop_8 >= phase_start_7
            i = phase_start_7
            if A_lvl.idx[A_lvl_q] < phase_start_7
                A_lvl_q = scansearch(A_lvl.idx, phase_start_7, A_lvl_q, A_lvl_q_stop - 1)
            end
            while i <= phase_stop_8
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_9 = min(phase_stop_8, A_lvl_i)
                if phase_stop_9 >= i
                    if A_lvl_i == phase_stop_9
                        A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2.val[C_lvl_qos] = A_lvl_2_val_2
                        C_lvl.idx[C_lvl_qos] = phase_stop_9
                        C_lvl_qos += 1
                        A_lvl_q += 1
                    end
                    i = phase_stop_9 + 1
                end
            end
        end
    end
    phase_start_11 = max(1 + (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta, 1, i_start)
    phase_stop_11 = min(A_lvl.shape, (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta + B_lvl.shape, i_stop)
    if phase_stop_11 >= phase_start_11
        A_lvl_q = A_lvl.ptr[1]
        A_lvl_q_stop = A_lvl.ptr[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i1 = 0
        end
        B_lvl_q = B_lvl.ptr[1]
        B_lvl_q_stop = B_lvl.ptr[1 + 1]
        if B_lvl_q < B_lvl_q_stop
            B_lvl_i1 = B_lvl.idx[B_lvl_q_stop - 1]
        else
            B_lvl_i1 = 0
        end
        phase_stop_12 = min(B_lvl_i1, (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta + B_lvl_i1, A_lvl_i1, phase_stop_11)
        if phase_stop_12 >= phase_start_11
            i = phase_start_11
            if A_lvl.idx[A_lvl_q] < phase_start_11
                A_lvl_q = scansearch(A_lvl.idx, phase_start_11, A_lvl_q, A_lvl_q_stop - 1)
            end
            if B_lvl.idx[B_lvl_q] < phase_start_11 + -((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta)
                B_lvl_q = scansearch(B_lvl.idx, phase_start_11 + -((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta), B_lvl_q, B_lvl_q_stop - 1)
            end
            while i <= phase_stop_12
                A_lvl_i = A_lvl.idx[A_lvl_q]
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_stop_13 = min((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta + B_lvl_i, A_lvl_i, phase_stop_12)
                if phase_stop_13 >= i
                    if A_lvl_i == phase_stop_13 && B_lvl_i == phase_stop_13 + -((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta)
                        A_lvl_2_val_3 = A_lvl_2.val[A_lvl_q]
                        B_lvl_2_val_3 = B_lvl_2.val[B_lvl_q]
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2.val[C_lvl_qos] = coalesce(A_lvl_2_val_3, B_lvl_2_val_3)
                        C_lvl.idx[C_lvl_qos] = phase_stop_13
                        C_lvl_qos += 1
                        A_lvl_q += 1
                        B_lvl_q += 1
                    elseif B_lvl_i == phase_stop_13 + -((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta)
                        B_lvl_q += 1
                    elseif A_lvl_i == phase_stop_13
                        A_lvl_2_val_3 = A_lvl_2.val[A_lvl_q]
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2.val[C_lvl_qos] = coalesce(A_lvl_2_val_3, 0.0)
                        C_lvl.idx[C_lvl_qos] = phase_stop_13
                        C_lvl_qos += 1
                        A_lvl_q += 1
                    end
                    i = phase_stop_13 + 1
                end
            end
        end
        phase_start_14 = max(1 + B_lvl_i1, phase_start_11)
        phase_stop_14 = min(A_lvl_i1, phase_stop_11)
        if phase_stop_14 >= phase_start_14
            i = phase_start_14
            if A_lvl.idx[A_lvl_q] < phase_start_14
                A_lvl_q = scansearch(A_lvl.idx, phase_start_14, A_lvl_q, A_lvl_q_stop - 1)
            end
            while i <= phase_stop_14
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_15 = min(A_lvl_i, phase_stop_14)
                if phase_stop_15 >= i
                    if A_lvl_i == phase_stop_15
                        A_lvl_2_val_4 = A_lvl_2.val[A_lvl_q]
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2.val[C_lvl_qos] = coalesce(A_lvl_2_val_4, 0.0)
                        C_lvl.idx[C_lvl_qos] = phase_stop_15
                        C_lvl_qos += 1
                        A_lvl_q += 1
                    end
                    i = phase_stop_15 + 1
                end
            end
        end
    end
    phase_start_18 = max(1, i_start, 1 + (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta + B_lvl.shape)
    phase_stop_18 = min(A_lvl.shape, i_stop)
    if phase_stop_18 >= phase_start_18
        A_lvl_q = A_lvl.ptr[1]
        A_lvl_q_stop = A_lvl.ptr[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i1 = 0
        end
        phase_stop_19 = min(A_lvl_i1, phase_stop_18)
        if phase_stop_19 >= phase_start_18
            i = phase_start_18
            if A_lvl.idx[A_lvl_q] < phase_start_18
                A_lvl_q = scansearch(A_lvl.idx, phase_start_18, A_lvl_q, A_lvl_q_stop - 1)
            end
            while i <= phase_stop_19
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_20 = min(A_lvl_i, phase_stop_19)
                if phase_stop_20 >= i
                    if A_lvl_i == phase_stop_20
                        A_lvl_2_val_5 = A_lvl_2.val[A_lvl_q]
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2.val[C_lvl_qos] = A_lvl_2_val_5
                        C_lvl.idx[C_lvl_qos] = phase_stop_20
                        C_lvl_qos += 1
                        A_lvl_q += 1
                    end
                    i = phase_stop_20 + 1
                end
            end
        end
    end
    phase_start_22 = max(i_start, 1 + A_lvl.shape)
    phase_stop_22 = min((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta, i_stop)
    if phase_stop_22 >= phase_start_22
        for i_35 = phase_start_22:phase_stop_22
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2.val[C_lvl_qos] = missing
            C_lvl.idx[C_lvl_qos] = i_35
            C_lvl_qos += 1
        end
    end
    phase_start_23 = max(1 + (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta, i_start, 1 + A_lvl.shape)
    phase_stop_23 = min((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta + B_lvl.shape, i_stop)
    if phase_stop_23 >= phase_start_23
        B_lvl_q = B_lvl.ptr[1]
        B_lvl_q_stop = B_lvl.ptr[1 + 1]
        if B_lvl_q < B_lvl_q_stop
            B_lvl_i1 = B_lvl.idx[B_lvl_q_stop - 1]
        else
            B_lvl_i1 = 0
        end
        phase_stop_24 = min(B_lvl_i1, (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta + B_lvl_i1, phase_stop_23)
        if phase_stop_24 >= phase_start_23
            i = phase_start_23
            if B_lvl.idx[B_lvl_q] < phase_start_23 + -((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta)
                B_lvl_q = scansearch(B_lvl.idx, phase_start_23 + -((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta), B_lvl_q, B_lvl_q_stop - 1)
            end
            while i <= phase_stop_24
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_stop_25 = min((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta + B_lvl_i, phase_stop_24)
                if phase_stop_25 >= i
                    if B_lvl_i == phase_stop_25 + -((((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta)
                        B_lvl_2_val_4 = B_lvl_2.val[B_lvl_q]
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2.val[C_lvl_qos] = B_lvl_2_val_4
                        C_lvl.idx[C_lvl_qos] = phase_stop_25
                        C_lvl_qos += 1
                        B_lvl_q += 1
                    end
                    i = phase_stop_25 + 1
                end
            end
        end
    end
    phase_start_27 = max(i_start, 1 + (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta + B_lvl.shape, 1 + A_lvl.shape)
    if i_stop >= phase_start_27
        for i_42 = phase_start_27:i_stop
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2.val[C_lvl_qos] = missing
            C_lvl.idx[C_lvl_qos] = i_42
            C_lvl_qos += 1
        end
    end
    C_lvl.ptr[1 + 1] = (C_lvl_qos - 0) - 1
    for p = 2:1 + 1
        C_lvl.ptr[p] += C_lvl.ptr[p - 1]
    end
    resize!(C_lvl.ptr, 1 + 1)
    qos = C_lvl.ptr[end] - 1
    resize!(C_lvl.idx, qos)
    resize!(C_lvl_2.val, qos)
    (C = Fiber((SparseListLevel){Int64, Int64}(C_lvl_2, max(A_lvl.shape, B_lvl.shape + (((ex.bodies[2]).body.rhs.args[2]).idxs[1]).tns.tns.delta), C_lvl.ptr, C_lvl.idx)),)
end
