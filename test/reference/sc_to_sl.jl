begin
    A_lvl = ex.body.lhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    B_lvl = ex.body.rhs.tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    A_lvl_qos_fill = 0
    A_lvl_qos_stop = 0
    (Finch.resize_if_smaller!)(A_lvl.pos, 1 + 1)
    (Finch.fill_range!)(A_lvl.pos, 0, 1 + 1, 1 + 1)
    A_lvl_qos = A_lvl_qos_fill + 1
    B_lvl_q = B_lvl.pos[1]
    B_lvl_q_stop = B_lvl.pos[1 + 1]
    if B_lvl_q < B_lvl_q_stop
        B_lvl_i = (B_lvl.tbl[1])[B_lvl_q]
        B_lvl_i_stop = (B_lvl.tbl[1])[B_lvl_q_stop - 1]
    else
        B_lvl_i = 1
        B_lvl_i_stop = 0
    end
    i = 1
    i_start = i
    phase_stop = (min)(B_lvl.I[1], B_lvl_i_stop)
    if phase_stop >= i_start
        i = i
        i = i_start
        while B_lvl_q + 1 < B_lvl_q_stop && (B_lvl.tbl[1])[B_lvl_q] < i_start
            B_lvl_q += 1
        end
        while i <= phase_stop
            i_start_2 = i
            B_lvl_i = (B_lvl.tbl[1])[B_lvl_q]
            phase_stop_2 = (min)(B_lvl_i, phase_stop)
            i_2 = i
            if B_lvl_i == phase_stop_2
                B_lvl_2_val_2 = B_lvl_2.val[B_lvl_q]
                i_3 = phase_stop_2
                if A_lvl_qos > A_lvl_qos_stop
                    A_lvl_qos_stop = max(A_lvl_qos_stop << 1, 1)
                    (Finch.resize_if_smaller!)(A_lvl.idx, A_lvl_qos_stop)
                    resize_if_smaller!(A_lvl_2.val, A_lvl_qos_stop)
                    fill_range!(A_lvl_2.val, 0.0, A_lvl_qos, A_lvl_qos_stop)
                end
                A_lvl_2_dirty = false
                A_lvl_2_val_2 = A_lvl_2.val[A_lvl_qos]
                A_lvl_2_dirty = true
                A_lvl_2_dirty = true
                A_lvl_2_val_2 = (+)(B_lvl_2_val_2, A_lvl_2_val_2)
                A_lvl_2.val[A_lvl_qos] = A_lvl_2_val_2
                if A_lvl_2_dirty
                    A_lvl_dirty = true
                    A_lvl.idx[A_lvl_qos] = i_3
                    A_lvl_qos += 1
                end
                B_lvl_q += 1
            else
            end
            i = phase_stop_2 + 1
        end
        i = phase_stop + 1
    end
    i_start = i
    if B_lvl.I[1] >= i_start
        i_4 = i
        i = B_lvl.I[1] + 1
    end
    A_lvl.pos[1 + 1] = (A_lvl_qos - A_lvl_qos_fill) - 1
    A_lvl_qos_fill = A_lvl_qos - 1
    for p = 2:1 + 1
        A_lvl.pos[p] += A_lvl.pos[p - 1]
    end
    qos_stop = A_lvl.pos[1 + 1] - 1
    resize!(A_lvl.pos, 1 + 1)
    qos = A_lvl.pos[end] - 1
    resize!(A_lvl.idx, qos)
    resize!(A_lvl_2.val, qos)
    (A = Fiber((Finch.SparseListLevel){Int64}(B_lvl.I[1], A_lvl.pos, A_lvl.idx, A_lvl_2)),)
end
