begin
    C_lvl = ex.body.lhs.tns.tns.lvl
    C_lvl_2 = C_lvl.lvl
    A_lvl = ex.body.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    i_start = (+)((ex.body.rhs.idxs[1]).tns.tns.start, (-)(1, (ex.body.rhs.idxs[1]).tns.tns.start))
    i_stop = (+)((ex.body.rhs.idxs[1]).tns.tns.stop, (-)(1, (ex.body.rhs.idxs[1]).tns.tns.start))
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
    phase_start = (max)(i_start_2, (+)((-)((ex.body.rhs.idxs[1]).tns.tns.start), i_start_2, (ex.body.rhs.idxs[1]).tns.tns.start))
    phase_stop = (min)(i_stop, (+)((-)((ex.body.rhs.idxs[1]).tns.tns.start), 1, A_lvl_i1))
    if phase_stop >= phase_start
        i = i
        i = phase_start
        while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < (+)(phase_start, (-)((-)(1, (ex.body.rhs.idxs[1]).tns.tns.start)))
            A_lvl_q += 1
        end
        while i <= phase_stop
            i_start_3 = i
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_start_2 = (max)(i_start_3, (+)((-)((ex.body.rhs.idxs[1]).tns.tns.start), (ex.body.rhs.idxs[1]).tns.tns.start, i_start_3))
            phase_stop_2 = (min)(phase_stop, (+)((-)((ex.body.rhs.idxs[1]).tns.tns.start), 1, A_lvl_i))
            if phase_stop_2 >= phase_start_2
                i_2 = i
                if A_lvl_i == (+)(phase_stop_2, (-)((-)(1, (ex.body.rhs.idxs[1]).tns.tns.start)))
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
                    C_lvl_2_val_2 = A_lvl_2_val_2
                    C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_2
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
    phase_start_3 = (max)(i_start_2, (+)((-)((ex.body.rhs.idxs[1]).tns.tns.start), i_start_2, (ex.body.rhs.idxs[1]).tns.tns.start))
    phase_stop_3 = (min)(i_stop, (+)((-)((ex.body.rhs.idxs[1]).tns.tns.start), (ex.body.rhs.idxs[1]).tns.tns.start, i_stop))
    if phase_stop_3 >= phase_start_3
        i_4 = i
        i = phase_stop_3 + 1
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
    (C = Fiber((Finch.SparseListLevel){Int64}((+)((ex.body.rhs.idxs[1]).tns.tns.stop, (-)(1, (ex.body.rhs.idxs[1]).tns.tns.start)), C_lvl.pos, C_lvl.idx, C_lvl_2)),)
end
