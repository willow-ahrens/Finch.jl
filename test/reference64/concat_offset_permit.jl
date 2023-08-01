begin
    C_lvl = (ex.bodies[1]).tns.tns.lvl
    C_lvl_2 = C_lvl.lvl
    A_lvl = ((ex.bodies[2]).body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    B_lvl = ((ex.bodies[2]).body.rhs.args[2]).tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    C_lvl_qos_stop = 0
    Finch.resize_if_smaller!(C_lvl.ptr, 1 + 1)
    Finch.fill_range!(C_lvl.ptr, 0, 1 + 1, 1 + 1)
    C_lvl_qos = 0 + 1
    phase_stop = min(C_lvl.shape, 0)
    if phase_stop >= 1
        for i_6 = 1:phase_stop
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                Finch.resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                Finch.resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                Finch.fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2.val[C_lvl_qos] = missing
            C_lvl.idx[C_lvl_qos] = i_6
            C_lvl_qos += 1
        end
    end
    phase_stop_2 = min(C_lvl.shape, 10, A_lvl.shape)
    if phase_stop_2 >= 1
        A_lvl_q = A_lvl.ptr[1]
        A_lvl_q_stop = A_lvl.ptr[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i1 = 0
        end
        phase_stop_3 = min(A_lvl_i1, phase_stop_2)
        if phase_stop_3 >= 1
            i = 1
            if A_lvl.idx[A_lvl_q] < 1
                A_lvl_q = Finch.scansearch(A_lvl.idx, 1, A_lvl_q, A_lvl_q_stop - 1)
            end
            while i <= phase_stop_3
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_4 = min(phase_stop_3, A_lvl_i)
                if A_lvl_i == phase_stop_4
                    A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        Finch.resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                        Finch.resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        Finch.fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2.val[C_lvl_qos] = A_lvl_2_val_2
                    C_lvl.idx[C_lvl_qos] = phase_stop_4
                    C_lvl_qos += 1
                    A_lvl_q += 1
                end
                i = phase_stop_4 + 1
            end
        end
    end
    phase_start_6 = max(1, 1 + A_lvl.shape)
    phase_stop_6 = min(C_lvl.shape, 10)
    if phase_stop_6 >= phase_start_6
        for i_13 = phase_start_6:phase_stop_6
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                Finch.resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                Finch.resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                Finch.fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2.val[C_lvl_qos] = missing
            C_lvl.idx[C_lvl_qos] = i_13
            C_lvl_qos += 1
        end
    end
    phase_stop_7 = min(C_lvl.shape, 0, 10 + B_lvl.shape)
    if phase_stop_7 >= 11
        B_lvl_q = B_lvl.ptr[1]
        B_lvl_q_stop = B_lvl.ptr[1 + 1]
        if B_lvl_q < B_lvl_q_stop
            B_lvl_i1 = B_lvl.idx[B_lvl_q_stop - 1]
        else
            B_lvl_i1 = 0
        end
        phase_stop_8 = min(phase_stop_7, 10 + B_lvl_i1)
        if phase_stop_8 >= 11
            i = 11
            if B_lvl.idx[B_lvl_q] < 11 + +(-10)
                B_lvl_q = Finch.scansearch(B_lvl.idx, 11 + +(-10), B_lvl_q, B_lvl_q_stop - 1)
            end
            while i <= phase_stop_8
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_stop_9 = min(phase_stop_8, 10 + B_lvl_i)
                if B_lvl_i == phase_stop_9 + +(-10)
                    B_lvl_2_val_2 = B_lvl_2.val[B_lvl_q]
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        Finch.resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                        Finch.resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        Finch.fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2.val[C_lvl_qos] = B_lvl_2_val_2
                    C_lvl.idx[C_lvl_qos] = phase_stop_9
                    C_lvl_qos += 1
                    B_lvl_q += 1
                end
                i = phase_stop_9 + 1
            end
        end
    end
    phase_stop_11 = min(C_lvl.shape, A_lvl.shape, 10 + B_lvl.shape)
    if phase_stop_11 >= 11
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
        phase_stop_12 = min(A_lvl_i1, 10 + B_lvl_i1, phase_stop_11)
        if phase_stop_12 >= 11
            i = 11
            if A_lvl.idx[A_lvl_q] < 11
                A_lvl_q = Finch.scansearch(A_lvl.idx, 11, A_lvl_q, A_lvl_q_stop - 1)
            end
            if B_lvl.idx[B_lvl_q] < 11 + +(-10)
                B_lvl_q = Finch.scansearch(B_lvl.idx, 11 + +(-10), B_lvl_q, B_lvl_q_stop - 1)
            end
            while i <= phase_stop_12
                A_lvl_i = A_lvl.idx[A_lvl_q]
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_stop_13 = min(A_lvl_i, 10 + B_lvl_i, phase_stop_12)
                if A_lvl_i == phase_stop_13 && B_lvl_i == phase_stop_13 + +(-10)
                    A_lvl_2_val_3 = A_lvl_2.val[A_lvl_q]
                    B_lvl_2_val_3 = B_lvl_2.val[B_lvl_q]
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        Finch.resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                        Finch.resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        Finch.fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2.val[C_lvl_qos] = coalesce(A_lvl_2_val_3, B_lvl_2_val_3)
                    C_lvl.idx[C_lvl_qos] = phase_stop_13
                    C_lvl_qos += 1
                    A_lvl_q += 1
                    B_lvl_q += 1
                elseif B_lvl_i == phase_stop_13 + +(-10)
                    B_lvl_q += 1
                elseif A_lvl_i == phase_stop_13
                    A_lvl_2_val_3 = A_lvl_2.val[A_lvl_q]
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        Finch.resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                        Finch.resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        Finch.fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2.val[C_lvl_qos] = coalesce(A_lvl_2_val_3, 0.0)
                    C_lvl.idx[C_lvl_qos] = phase_stop_13
                    C_lvl_qos += 1
                    A_lvl_q += 1
                end
                i = phase_stop_13 + 1
            end
        end
        phase_start_15 = max(11 + B_lvl_i1, 11)
        phase_stop_15 = min(A_lvl_i1, phase_stop_11)
        if phase_stop_15 >= phase_start_15
            i = phase_start_15
            if A_lvl.idx[A_lvl_q] < phase_start_15
                A_lvl_q = Finch.scansearch(A_lvl.idx, phase_start_15, A_lvl_q, A_lvl_q_stop - 1)
            end
            while i <= phase_stop_15
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_16 = min(A_lvl_i, phase_stop_15)
                if A_lvl_i == phase_stop_16
                    A_lvl_2_val_4 = A_lvl_2.val[A_lvl_q]
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        Finch.resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                        Finch.resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        Finch.fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2.val[C_lvl_qos] = coalesce(A_lvl_2_val_4, 0.0)
                    C_lvl.idx[C_lvl_qos] = phase_stop_16
                    C_lvl_qos += 1
                    A_lvl_q += 1
                end
                i = phase_stop_16 + 1
            end
        end
    end
    phase_start_18 = max(11, 1 + A_lvl.shape)
    phase_stop_18 = min(C_lvl.shape, 10 + B_lvl.shape)
    if phase_stop_18 >= phase_start_18
        B_lvl_q = B_lvl.ptr[1]
        B_lvl_q_stop = B_lvl.ptr[1 + 1]
        if B_lvl_q < B_lvl_q_stop
            B_lvl_i1 = B_lvl.idx[B_lvl_q_stop - 1]
        else
            B_lvl_i1 = 0
        end
        phase_stop_19 = min(10 + B_lvl_i1, phase_stop_18)
        if phase_stop_19 >= phase_start_18
            i = phase_start_18
            if B_lvl.idx[B_lvl_q] < phase_start_18 + +(-10)
                B_lvl_q = Finch.scansearch(B_lvl.idx, phase_start_18 + +(-10), B_lvl_q, B_lvl_q_stop - 1)
            end
            while i <= phase_stop_19
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_stop_20 = min(10 + B_lvl_i, phase_stop_19)
                if B_lvl_i == phase_stop_20 + +(-10)
                    B_lvl_2_val_4 = B_lvl_2.val[B_lvl_q]
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        Finch.resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                        Finch.resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        Finch.fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2.val[C_lvl_qos] = B_lvl_2_val_4
                    C_lvl.idx[C_lvl_qos] = phase_stop_20
                    C_lvl_qos += 1
                    B_lvl_q += 1
                end
                i = phase_stop_20 + 1
            end
        end
    end
    phase_start_22 = max(1, 11 + B_lvl.shape)
    phase_stop_22 = min(C_lvl.shape, 0)
    if phase_stop_22 >= phase_start_22
        for i_35 = phase_start_22:phase_stop_22
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                Finch.resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                Finch.resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                Finch.fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvl_2.val[C_lvl_qos] = missing
            C_lvl.idx[C_lvl_qos] = i_35
            C_lvl_qos += 1
        end
    end
    phase_start_23 = max(1, 11 + B_lvl.shape)
    phase_stop_23 = min(C_lvl.shape, A_lvl.shape)
    if phase_stop_23 >= phase_start_23
        A_lvl_q = A_lvl.ptr[1]
        A_lvl_q_stop = A_lvl.ptr[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i1 = 0
        end
        phase_stop_24 = min(A_lvl_i1, phase_stop_23)
        if phase_stop_24 >= phase_start_23
            i = phase_start_23
            if A_lvl.idx[A_lvl_q] < phase_start_23
                A_lvl_q = Finch.scansearch(A_lvl.idx, phase_start_23, A_lvl_q, A_lvl_q_stop - 1)
            end
            while i <= phase_stop_24
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_25 = min(A_lvl_i, phase_stop_24)
                if A_lvl_i == phase_stop_25
                    A_lvl_2_val_5 = A_lvl_2.val[A_lvl_q]
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        Finch.resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                        Finch.resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        Finch.fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2.val[C_lvl_qos] = A_lvl_2_val_5
                    C_lvl.idx[C_lvl_qos] = phase_stop_25
                    C_lvl_qos += 1
                    A_lvl_q += 1
                end
                i = phase_stop_25 + 1
            end
        end
    end
    phase_start_27 = max(1, 1 + A_lvl.shape, 11 + B_lvl.shape)
    phase_stop_27 = C_lvl.shape
    if phase_stop_27 >= phase_start_27
        for i_42 = phase_start_27:phase_stop_27
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                Finch.resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                Finch.resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                Finch.fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
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
    (C = Fiber((SparseListLevel){Int64, Int64}(C_lvl_2, C_lvl.shape, C_lvl.ptr, C_lvl.idx)),)
end
