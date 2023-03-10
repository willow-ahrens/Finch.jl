begin
    C_lvl = (ex.bodies[1]).tns.tns.lvl
    C_lvl_2 = C_lvl.lvl
    C_lvl_3 = (ex.bodies[2]).body.lhs.tns.tns.lvl
    C_lvl_4 = C_lvl_3.lvl
    A_lvl = (ex.bodies[2]).body.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    win = ((ex.bodies[2]).body.rhs.idxs[1]).tns.tns
    i_start = (+)(first(win), (-)(1, first(win)))
    i_stop = (+)(last(win), (-)(1, first(win)))
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
    i = i_start
    i_start_2 = i
    phase_start = (max)(i_start_2, (+)(i_start_2, (-)(first(win)), first(win)))
    phase_stop = (min)(i_stop, (+)(1, (-)(first(win)), A_lvl_i1))
    if phase_stop >= phase_start
        i_4 = i
        i = phase_start
        if A_lvl.idx[A_lvl_q] < (+)(phase_start, (-)((-)(1, first(win))))
            A_lvl_q = scansearch(A_lvl.idx, (+)(phase_start, (-)((-)(1, first(win)))), A_lvl_q, A_lvl_q_stop - 1)
        end
        while i <= phase_stop
            i_start_3 = i
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_start_2 = (max)(i_start_3, (+)((-)(first(win)), first(win), i_start_3))
            phase_stop_2 = (min)(phase_stop, (+)(1, (-)(first(win)), A_lvl_i))
            if phase_stop_2 >= phase_start_2
                i_5 = i
                if A_lvl_i == (+)(phase_stop_2, (-)((-)(1, first(win))))
                    A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                    i_6 = phase_stop_2
                    if C_lvl_qos > C_lvl_qos_stop
                        C_lvl_qos_stop = max(C_lvl_qos_stop << 1, 1)
                        (Finch.resize_if_smaller!)(C_lvl.idx, C_lvl_qos_stop)
                        resize_if_smaller!(C_lvl_2.val, C_lvl_qos_stop)
                        fill_range!(C_lvl_2.val, 0.0, C_lvl_qos, C_lvl_qos_stop)
                    end
                    C_lvldirty = false
                    C_lvl_2_val_2 = C_lvl_2.val[C_lvl_qos]
                    C_lvldirty = true
                    C_lvl_2_val_2 = A_lvl_2_val_2
                    C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_2
                    if C_lvldirty
                        null = true
                        C_lvl.idx[C_lvl_qos] = i_6
                        C_lvl_qos += 1
                    end
                    A_lvl_q += 1
                else
                end
                i = phase_stop_2 + 1
            end
        end
        i = phase_stop + 1
    end
    i_start_2 = i
    phase_start_3 = (max)(i_start_2, (+)(i_start_2, (-)(first(win)), first(win)))
    phase_stop_3 = (min)(i_stop, (+)((-)(first(win)), first(win), i_stop))
    if phase_stop_3 >= phase_start_3
        i_7 = i
        i = phase_stop_3 + 1
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
    (C = Fiber((Finch.SparseListLevel){Int64, Int32}(C_lvl_2, (+)(last(win), (-)(1, first(win))), C_lvl.ptr, C_lvl.idx)),)
end
