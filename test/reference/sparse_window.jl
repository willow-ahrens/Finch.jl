begin
    C_lvl = ex.body.lhs.tns.tns.lvl
    C_lvl_2 = C_lvl.lvl
    C_lvl_2_val = 0.0
    A_lvl = ex.body.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_2_val = 0.0
    i_start = (+)(2, (-)(1, 2))
    i_stop = (+)(4, (-)(1, 2))
    C_lvl_qos_fill = 0
    C_lvl_qos_stop = 0
    (Finch.resize_if_smaller!)(C_lvl.pos, 1 + 1)
    (Finch.fill_range!)(C_lvl.pos, 0, 1 + 1, 1 + 1)
    C_lvl_qos = C_lvl_qos_fill + 1
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
    i_start_2 = i
    phase_stop = (min)(i_stop, (+)(-1, A_lvl_i1))
    if phase_stop >= i_start_2
        i = i
        i = i_start_2
        while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < (+)(i_start_2, (-)((-)(1, 2)))
            A_lvl_q += 1
        end
        while i <= phase_stop
            i_start_3 = i
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_stop_2 = (min)(phase_stop, (+)(-1, A_lvl_i))
            if phase_stop_2 >= i_start_3
                i_2 = i
                if A_lvl_i == (+)(phase_stop_2, (-)((-)(1, 2)))
                    A_lvl_2_val = A_lvl_2.val[A_lvl_q]
                    i_3 = phase_stop_2
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
                        C_lvl.idx[C_lvl_qos] = i_3
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
    if i_stop >= i_start_2
        i_4 = i
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
    (C = Fiber((Finch.SparseListLevel){Int64}((+)(4, (-)(1, 2)), C_lvl.pos, C_lvl.idx, C_lvl_2), (Environment)(; )),)
end
