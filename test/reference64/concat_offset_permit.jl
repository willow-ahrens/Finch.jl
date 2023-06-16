begin
    C_lvl = (ex.bodies[1]).tns.tns.lvl
    C_lvl_2 = C_lvl.lvl
    A_lvl = ((ex.bodies[2]).body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    B_lvl = ((ex.bodies[2]).body.rhs.args[2]).tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    C_lvl_qos_stop = 0
    resize_if_smaller!(C_lvl.ptr, 1 + 1)
    fill_range!(C_lvl.ptr, 0, 1 + 1, 1 + 1)
    C_lvl_qos = 0 + 1
    phase_stop = min(C_lvl.shape, 0)
    if phase_stop >= 1
        for i_6 = 1:phase_stop
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvldirty = false
            B_lvl_q = B_lvl.ptr[1]
            B_lvl_q_stop = B_lvl.ptr[1 + 1]
            if B_lvl_q < B_lvl_q_stop
                B_lvl_i1 = B_lvl.idx[B_lvl_q_stop - 1]
            else
                B_lvl_i1 = 0
            end
            phase_start_2 = 10 + i_6
            phase_stop_2 = min(10 + i_6, B_lvl_i1)
            if phase_stop_2 >= phase_start_2
                s = phase_start_2
                if B_lvl.idx[B_lvl_q] < phase_start_2
                    B_lvl_q = scansearch(B_lvl.idx, phase_start_2, B_lvl_q, B_lvl_q_stop - 1)
                end
                while s <= phase_stop_2
                    B_lvl_i = B_lvl.idx[B_lvl_q]
                    phase_stop_3 = min(phase_stop_2, B_lvl_i)
                    if B_lvl_i == phase_stop_3
                        B_lvl_2_val_2 = B_lvl_2.val[B_lvl_q]
                        C_lvldirty = true
                        C_lvl_2.val[C_lvl_qos] = B_lvl_2_val_2
                        B_lvl_q += 1
                    end
                    s = phase_stop_3 + 1
                end
            end
            if C_lvldirty
                C_lvl.idx[C_lvl_qos] = i_6
                C_lvl_qos += 1
            end
        end
    end
    phase_stop_5 = min(C_lvl.shape, A_lvl.shape)
    if phase_stop_5 >= 1
        A_lvl_q = A_lvl.ptr[1]
        A_lvl_q_stop = A_lvl.ptr[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i1 = 0
        end
        phase_stop_6 = min(A_lvl_i1, phase_stop_5)
        if phase_stop_6 >= 1
            i = 1
            if A_lvl.idx[A_lvl_q] < 1
                A_lvl_q = scansearch(A_lvl.idx, 1, A_lvl_q, A_lvl_q_stop - 1)
            end
            while i <= phase_stop_6
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_7 = min(phase_stop_6, A_lvl_i)
                if A_lvl_i == phase_stop_7
                    A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                        resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvldirty = false
                    B_lvl_q_2 = B_lvl.ptr[1]
                    B_lvl_q_stop_2 = B_lvl.ptr[1 + 1]
                    if B_lvl_q_2 < B_lvl_q_stop_2
                        B_lvl_i1_2 = B_lvl.idx[B_lvl_q_stop_2 - 1]
                    else
                        B_lvl_i1_2 = 0
                    end
                    phase_start_8 = 10 + phase_stop_7
                    phase_stop_8 = min(10 + phase_stop_7, B_lvl_i1_2)
                    if phase_stop_8 >= phase_start_8
                        s = phase_start_8
                        if B_lvl.idx[B_lvl_q_2] < phase_start_8
                            B_lvl_q_2 = scansearch(B_lvl.idx, phase_start_8, B_lvl_q_2, B_lvl_q_stop_2 - 1)
                        end
                        while s <= phase_stop_8
                            B_lvl_i_2 = B_lvl.idx[B_lvl_q_2]
                            phase_stop_9 = min(phase_stop_8, B_lvl_i_2)
                            if B_lvl_i_2 == phase_stop_9
                                for s_8 = s:phase_stop_9 - 1
                                    C_lvl_2.val[C_lvl_qos] = coalesce(((Scalar){0.0, Float64}(A_lvl_2_val_2))[], 0.0)
                                end
                                B_lvl_2_val_3 = B_lvl_2.val[B_lvl_q_2]
                                C_lvldirty = true
                                C_lvl_2.val[C_lvl_qos] = coalesce(((Scalar){0.0, Float64}(A_lvl_2_val_2))[], B_lvl_2_val_3)
                                B_lvl_q_2 += 1
                            else
                                for s_10 = s:phase_stop_9
                                    C_lvl_2.val[C_lvl_qos] = coalesce(((Scalar){0.0, Float64}(A_lvl_2_val_2))[], 0.0)
                                end
                            end
                            s = phase_stop_9 + 1
                        end
                    end
                    phase_start_10 = max(10 + phase_stop_7, 1 + B_lvl_i1_2)
                    phase_stop_10 = 10 + phase_stop_7
                    if phase_stop_10 >= phase_start_10
                        for s_12 = phase_start_10:phase_stop_10
                            C_lvl_2.val[C_lvl_qos] = coalesce(((Scalar){0.0, Float64}(A_lvl_2_val_2))[], 0.0)
                        end
                    end
                    if C_lvldirty
                        C_lvl.idx[C_lvl_qos] = phase_stop_7
                        C_lvl_qos += 1
                    end
                    A_lvl_q += 1
                end
                i = phase_stop_7 + 1
            end
        end
    end
    phase_start_12 = max(1, 1 + A_lvl.shape)
    phase_stop_12 = C_lvl.shape
    if phase_stop_12 >= phase_start_12
        for i_16 = phase_start_12:phase_stop_12
            if C_lvl_qos > C_lvl_qos_stop
                C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
            end
            C_lvldirty = false
            B_lvl_q_3 = B_lvl.ptr[1]
            B_lvl_q_stop_3 = B_lvl.ptr[1 + 1]
            if B_lvl_q_3 < B_lvl_q_stop_3
                B_lvl_i1_3 = B_lvl.idx[B_lvl_q_stop_3 - 1]
            else
                B_lvl_i1_3 = 0
            end
            phase_start_13 = 10 + i_16
            phase_stop_13 = min(10 + i_16, B_lvl_i1_3)
            if phase_stop_13 >= phase_start_13
                s = phase_start_13
                if B_lvl.idx[B_lvl_q_3] < phase_start_13
                    B_lvl_q_3 = scansearch(B_lvl.idx, phase_start_13, B_lvl_q_3, B_lvl_q_stop_3 - 1)
                end
                while s <= phase_stop_13
                    B_lvl_i_3 = B_lvl.idx[B_lvl_q_3]
                    phase_stop_14 = min(phase_stop_13, B_lvl_i_3)
                    if B_lvl_i_3 == phase_stop_14
                        B_lvl_2_val_4 = B_lvl_2.val[B_lvl_q_3]
                        C_lvldirty = true
                        C_lvl_2.val[C_lvl_qos] = B_lvl_2_val_4
                        B_lvl_q_3 += 1
                    end
                    s = phase_stop_14 + 1
                end
            end
            if C_lvldirty
                C_lvl.idx[C_lvl_qos] = i_16
                C_lvl_qos += 1
            end
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
