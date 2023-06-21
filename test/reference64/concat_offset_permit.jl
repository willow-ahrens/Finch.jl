begin
    C_lvl = (ex.bodies[1]).tns.tns.lvl
    C_lvl_2 = C_lvl.lvl
    A_lvl = ((ex.bodies[2]).body.rhs.args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    B_lvl = ((ex.bodies[2]).body.rhs.args[2]).tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    i_stop = 10 + B_lvl.shape
    C_lvl_qos_stop = 0
    resize_if_smaller!(C_lvl.ptr, 1 + 1)
    fill_range!(C_lvl.ptr, 0, 1 + 1, 1 + 1)
    C_lvl_qos = 0 + 1
    B_lvl_q = B_lvl.ptr[1]
    B_lvl_q_stop = B_lvl.ptr[1 + 1]
    if B_lvl_q < B_lvl_q_stop
        B_lvl_i1 = B_lvl.idx[B_lvl_q_stop - 1]
    else
        B_lvl_i1 = 0
    end
    phase_stop = min(i_stop, 10 + B_lvl_i1, 0)
    if phase_stop >= 11
        i = 11
        if B_lvl.idx[B_lvl_q] < 11 + -(+10)
            B_lvl_q = scansearch(B_lvl.idx, 11 + -(+10), B_lvl_q, B_lvl_q_stop - 1)
        end
        while i <= phase_stop
            B_lvl_i = B_lvl.idx[B_lvl_q]
            phase_stop_2 = min(phase_stop, 10 + B_lvl_i)
            if B_lvl_i == phase_stop_2 + -(+10)
                B_lvl_2_val_2 = B_lvl_2.val[B_lvl_q]
                if C_lvl_qos > C_lvl_qos_stop
                    C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                    resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                    resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                    fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                end
                C_lvl_2.val[C_lvl_qos] = B_lvl_2_val_2
                C_lvl.idx[C_lvl_qos] = phase_stop_2
                C_lvl_qos += 1
                B_lvl_q += 1
            end
            i = phase_stop_2 + 1
        end
    end
    phase_start_3 = max(1, 11)
    phase_stop_3 = min(i_stop, 10 + B_lvl_i1, A_lvl.shape)
    if phase_stop_3 >= phase_start_3
        A_lvl_q = A_lvl.ptr[1]
        A_lvl_q_stop = A_lvl.ptr[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i1 = 0
        end
        phase_stop_4 = min(A_lvl_i1, phase_stop_3)
        if phase_stop_4 >= phase_start_3
            i = phase_start_3
            if A_lvl.idx[A_lvl_q] < phase_start_3
                A_lvl_q = scansearch(A_lvl.idx, phase_start_3, A_lvl_q, A_lvl_q_stop - 1)
            end
            if B_lvl.idx[B_lvl_q] < phase_start_3 + -(+10)
                B_lvl_q = scansearch(B_lvl.idx, phase_start_3 + -(+10), B_lvl_q, B_lvl_q_stop - 1)
            end
            while i <= phase_stop_4
                A_lvl_i = A_lvl.idx[A_lvl_q]
                B_lvl_i = B_lvl.idx[B_lvl_q]
                phase_stop_5 = min(10 + B_lvl_i, phase_stop_4, A_lvl_i)
                if phase_stop_5 >= i
                    if A_lvl_i == phase_stop_5 && B_lvl_i == phase_stop_5 + -(+10)
                        A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                        B_lvl_2_val_3 = B_lvl_2.val[B_lvl_q]
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2.val[C_lvl_qos] = coalesce(((Scalar){0.0, Float64}(A_lvl_2_val_2))[], B_lvl_2_val_3)
                        C_lvl.idx[C_lvl_qos] = phase_stop_5
                        C_lvl_qos += 1
                        A_lvl_q += 1
                        B_lvl_q += 1
                    elseif B_lvl_i == phase_stop_5 + -(+10)
                        B_lvl_q += 1
                    elseif A_lvl_i == phase_stop_5
                        A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                        if C_lvl_qos > C_lvl_qos_stop
                            C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                            resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                            resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                            fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                        end
                        C_lvl_2.val[C_lvl_qos] = coalesce(((Scalar){0.0, Float64}(A_lvl_2_val_2))[], 0.0)
                        C_lvl.idx[C_lvl_qos] = phase_stop_5
                        C_lvl_qos += 1
                        A_lvl_q += 1
                    end
                    i = phase_stop_5 + 1
                end
            end
        end
    end
    phase_start_7 = max(11, 1 + A_lvl.shape)
    phase_stop_7 = min(i_stop, 10 + B_lvl_i1)
    if phase_stop_7 >= phase_start_7
        i = phase_start_7
        if B_lvl.idx[B_lvl_q] < phase_start_7 + -(+10)
            B_lvl_q = scansearch(B_lvl.idx, phase_start_7 + -(+10), B_lvl_q, B_lvl_q_stop - 1)
        end
        while i <= phase_stop_7
            B_lvl_i = B_lvl.idx[B_lvl_q]
            phase_stop_8 = min(10 + B_lvl_i, phase_stop_7)
            if B_lvl_i == phase_stop_8 + -(+10)
                B_lvl_2_val_4 = B_lvl_2.val[B_lvl_q]
                if C_lvl_qos > C_lvl_qos_stop
                    C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                    resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                    resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                    fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                end
                C_lvl_2.val[C_lvl_qos] = B_lvl_2_val_4
                C_lvl.idx[C_lvl_qos] = phase_stop_8
                C_lvl_qos += 1
                B_lvl_q += 1
            end
            i = phase_stop_8 + 1
        end
    end
    phase_start_10 = max(1, 11, 11 + B_lvl_i1)
    phase_stop_10 = min(i_stop, A_lvl.shape)
    if phase_stop_10 >= phase_start_10
        A_lvl_q = A_lvl.ptr[1]
        A_lvl_q_stop = A_lvl.ptr[1 + 1]
        if A_lvl_q < A_lvl_q_stop
            A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
        else
            A_lvl_i1 = 0
        end
        phase_stop_11 = min(A_lvl_i1, phase_stop_10)
        if phase_stop_11 >= phase_start_10
            i = phase_start_10
            if A_lvl.idx[A_lvl_q] < phase_start_10
                A_lvl_q = scansearch(A_lvl.idx, phase_start_10, A_lvl_q, A_lvl_q_stop - 1)
            end
            while i <= phase_stop_11
                A_lvl_i = A_lvl.idx[A_lvl_q]
                phase_stop_12 = min(A_lvl_i, phase_stop_11)
                if A_lvl_i == phase_stop_12
                    A_lvl_2_val_3 = A_lvl_2.val[A_lvl_q]
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        resize_if_smaller!(C_lvl.idx, C_lvl_qos_stop)
                        resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvl_2.val[C_lvl_qos] = coalesce(((Scalar){0.0, Float64}(A_lvl_2_val_3))[], 0.0)
                    C_lvl.idx[C_lvl_qos] = phase_stop_12
                    C_lvl_qos += 1
                    A_lvl_q += 1
                end
                i = phase_stop_12 + 1
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
    (C = Fiber((SparseListLevel){Int64, Int64}(C_lvl_2, B_lvl.shape + +10, C_lvl.ptr, C_lvl.idx)),)
end
