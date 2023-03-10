begin
    C_lvl = (ex.bodies[1]).tns.tns.lvl
    C_lvl_2 = C_lvl.lvl
    C_lvl_3 = (ex.bodies[2]).body.body.lhs.tns.tns.lvl
    C_lvl_4 = C_lvl_3.lvl
    A_lvl = (((ex.bodies[2]).body.body.rhs.args[1]).args[1]).tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_3 = (((ex.bodies[2]).body.body.rhs.args[2]).args[1]).tns.tns.lvl
    A_lvl_4 = A_lvl_3.lvl
    F_lvl = (((ex.bodies[2]).body.body.rhs.args[3]).args[1]).tns.tns.lvl
    F_lvl_2 = F_lvl.lvl
    C_lvl_qos_fill = 0
    C_lvl_qos_stop = 0
    (Finch.resize_if_smaller!)(C_lvl.ptr, 1 + 1)
    (Finch.fill_range!)(C_lvl.ptr, 0, 1 + 1, 1 + 1)
    C_lvl_qos = C_lvl_qos_fill + 1
    A_lvl_q = A_lvl.ptr[1]
    A_lvl_q_stop = A_lvl.ptr[1 + 1]
    if A_lvl_q < A_lvl_q_stop
        A_lvl_i = A_lvl.idx[A_lvl_q]
        A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
    else
        A_lvl_i = 1
        A_lvl_i1 = 0
    end
    i = 1
    i_start = i
    phase_stop = (min)(A_lvl_i1, A_lvl.I)
    if phase_stop >= i_start
        i_5 = i
        i = i_start
        if A_lvl.idx[A_lvl_q] < i_start
            A_lvl_q = scansearch(A_lvl.idx, i_start, A_lvl_q, A_lvl_q_stop - 1)
        end
        while i <= phase_stop
            i_start_2 = i
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_stop_2 = (min)(A_lvl_i, phase_stop)
            i_6 = i
            if A_lvl_i == phase_stop_2
                A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                i_7 = phase_stop_2
                if C_lvl_qos > C_lvl_qos_stop
                    C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                    (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                    resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                    fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                end
                C_lvldirty = false
                C_lvl_2_val_2 = C_lvl_2.val[C_lvl_qos]
                s_2 = (+)(-3, i_7)
                s_3 = s_2
                j = 1
                j_start = j
                phase_stop_3 = (min)(0, s_3, F_lvl.I)
                if phase_stop_3 >= j_start
                    j_4 = j
                    j = phase_stop_3 + 1
                end
                j_start = j
                phase_stop_4 = (min)(0, F_lvl.I, (+)(A_lvl.I, s_3))
                if phase_stop_4 >= j_start
                    j_5 = j
                    A_lvl_q_2 = A_lvl.ptr[1]
                    A_lvl_q_stop_2 = A_lvl.ptr[1 + 1]
                    if A_lvl_q_2 < A_lvl_q_stop_2
                        A_lvl_i_2 = A_lvl.idx[A_lvl_q_2]
                        A_lvl_i1_2 = A_lvl.idx[A_lvl_q_stop_2 - 1]
                    else
                        A_lvl_i_2 = 1
                        A_lvl_i1_2 = 0
                    end
                    j = j_start
                    j_start_2 = j
                    phase_stop_5 = (min)(phase_stop_4, (+)(s_3, A_lvl_i1_2))
                    if phase_stop_5 >= j_start_2
                        j_6 = j
                        j = phase_stop_5 + 1
                    end
                    j_start_2 = j
                    if phase_stop_4 >= j_start_2
                        j_7 = j
                        j = phase_stop_4 + 1
                    end
                    j = phase_stop_4 + 1
                end
                j_start = j
                phase_stop_6 = (min)(0, F_lvl.I)
                if phase_stop_6 >= j_start
                    j_8 = j
                    j = phase_stop_6 + 1
                end
                j_start = j
                phase_stop_7 = (min)(s_3, F_lvl.I)
                if phase_stop_7 >= j_start
                    j_9 = j
                    j = phase_stop_7 + 1
                end
                j_start = j
                phase_stop_8 = (min)(F_lvl.I, (+)(A_lvl.I, s_3))
                if phase_stop_8 >= j_start
                    j_10 = j
                    A_lvl_q_2 = A_lvl.ptr[1]
                    A_lvl_q_stop_2 = A_lvl.ptr[1 + 1]
                    if A_lvl_q_2 < A_lvl_q_stop_2
                        A_lvl_i_2 = A_lvl.idx[A_lvl_q_2]
                        A_lvl_i1_2 = A_lvl.idx[A_lvl_q_stop_2 - 1]
                    else
                        A_lvl_i_2 = 1
                        A_lvl_i1_2 = 0
                    end
                    j = j_start
                    j_start_3 = j
                    phase_stop_9 = (min)((+)(s_3, A_lvl_i1_2), phase_stop_8)
                    if phase_stop_9 >= j_start_3
                        j_11 = j
                        j = j_start_3
                        if A_lvl.idx[A_lvl_q_2] < (+)(j_start_3, (-)(s_3))
                            A_lvl_q_2 = scansearch(A_lvl.idx, (+)(j_start_3, (-)(s_3)), A_lvl_q_2, A_lvl_q_stop_2 - 1)
                        end
                        while j <= phase_stop_9
                            j_start_4 = j
                            A_lvl_i_2 = A_lvl.idx[A_lvl_q_2]
                            phase_stop_10 = (min)(phase_stop_9, (+)(s_3, A_lvl_i_2))
                            if phase_stop_10 >= j_start_4
                                j_12 = j
                                if A_lvl_i_2 == (+)(phase_stop_10, (-)(s_3))
                                    A_lvl_2_val_4 = A_lvl_2.val[A_lvl_q_2]
                                    j_13 = phase_stop_10
                                    F_lvl_q = (1 - 1) * F_lvl.I + j_13
                                    F_lvl_2_val_2 = F_lvl_2.val[F_lvl_q]
                                    C_lvldirty = true
                                    C_lvldirty = true
                                    C_lvl_2_val_2 = (+)((*)((!=)(A_lvl_2_val_2, 0), (coalesce)(F_lvl_2_val_2, 0), (coalesce)(A_lvl_2_val_4, 0)), C_lvl_2_val_2)
                                    A_lvl_q_2 += 1
                                else
                                end
                                j = phase_stop_10 + 1
                            end
                        end
                        j = phase_stop_9 + 1
                    end
                    j_start_3 = j
                    if phase_stop_8 >= j_start_3
                        j_14 = j
                        j = phase_stop_8 + 1
                    end
                    j = phase_stop_8 + 1
                end
                j_start = j
                if F_lvl.I >= j_start
                    j_15 = j
                    j = F_lvl.I + 1
                end
                j_start = j
                phase_stop_11 = (min)(s_3, F_lvl.I)
                if phase_stop_11 >= j_start
                    j_16 = j
                    j = phase_stop_11 + 1
                end
                j_start = j
                phase_stop_12 = (min)(F_lvl.I, (+)(A_lvl.I, s_3))
                if phase_stop_12 >= j_start
                    j_17 = j
                    A_lvl_q_2 = A_lvl.ptr[1]
                    A_lvl_q_stop_2 = A_lvl.ptr[1 + 1]
                    if A_lvl_q_2 < A_lvl_q_stop_2
                        A_lvl_i_2 = A_lvl.idx[A_lvl_q_2]
                        A_lvl_i1_2 = A_lvl.idx[A_lvl_q_stop_2 - 1]
                    else
                        A_lvl_i_2 = 1
                        A_lvl_i1_2 = 0
                    end
                    j = j_start
                    j_start_5 = j
                    phase_stop_13 = (min)((+)(s_3, A_lvl_i1_2), phase_stop_12)
                    if phase_stop_13 >= j_start_5
                        j_18 = j
                        j = phase_stop_13 + 1
                    end
                    j_start_5 = j
                    if phase_stop_12 >= j_start_5
                        j_19 = j
                        j = phase_stop_12 + 1
                    end
                    j = phase_stop_12 + 1
                end
                j_start = j
                if F_lvl.I >= j_start
                    j_20 = j
                    j = F_lvl.I + 1
                end
                C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_2
                if C_lvldirty
                    null = true
                    C_lvl.idx[C_lvl_qos] = i_7
                    C_lvl_qos += 1
                end
                A_lvl_q += 1
            else
            end
            i = phase_stop_2 + 1
        end
        i = phase_stop + 1
    end
    i_start = i
    if A_lvl.I >= i_start
        i_8 = i
        i = A_lvl.I + 1
    end
    C_lvl.ptr[1 + 1] = (C_lvl_qos - C_lvl_qos_fill) - 1
    C_lvl_qos_fill = C_lvl_qos - 1
    for p = 2:1 + 1
        C_lvl.ptr[p] += C_lvl.ptr[p - 1]
    end
    qos_stop = C_lvl.ptr[1 + 1] - 1
    resize!(C_lvl.ptr, 1 + 1)
    qos = C_lvl.ptr[end] - 1
    resize!(C_lvl.idx, qos)
    resize!(C_lvl_2.val, qos)
    (C = Fiber((Finch.SparseListLevel){Int64, Int64}(C_lvl_2, A_lvl.I, C_lvl.ptr, C_lvl.idx)),)
end
