begin
    C_lvl = ex.cons.body.lhs.tns.tns.lvl
    C_lvl_2 = C_lvl.lvl
    B_lvl = ex.cons.body.rhs.tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    B_lvl_3 = ex.prod.body.lhs.tns.tns.lvl
    B_lvl_4 = B_lvl_3.lvl
    A_lvl = ex.prod.body.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    C_lvl_qos_fill = 0
    C_lvl_qos_stop = 0
    (Finch.resize_if_smaller!)(C_lvl.pos, 1 + 1)
    (Finch.fill_range!)(C_lvl.pos, 0, 1 + 1, 1 + 1)
    B_lvl_qos_fill = 0
    B_lvl_qos_stop = 0
    (Finch.resize_if_smaller!)(B_lvl.pos, 1 + 1)
    (Finch.fill_range!)(B_lvl.pos, 0, 1 + 1, 1 + 1)
    B_lvl_q = B_lvl_qos_fill + 1
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
    phase_stop = (min)(A_lvl.I, A_lvl_i1)
    if phase_stop >= i_start
        i = i
        i = i_start
        while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < i_start
            A_lvl_q += 1
        end
        while i <= phase_stop
            i_start_2 = i
            A_lvl_i = A_lvl.idx[A_lvl_q]
            phase_stop_2 = (min)(A_lvl_i, phase_stop)
            i_2 = i
            if A_lvl_i == phase_stop_2
                A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                i_3 = phase_stop_2
                if B_lvl_q > B_lvl_qos_stop
                    B_lvl_qos_stop = max(B_lvl_qos_stop << 1, 1)
                    resize_if_smaller!(B_lvl.tbl[1], B_lvl_qos_stop)
                    resize_if_smaller!(B_lvl_2.val, B_lvl_qos_stop)
                    fill_range!(B_lvl_2.val, 0.0, B_lvl_q, B_lvl_qos_stop)
                end
                B_lvl_2_dirty = false
                B_lvl_2_val_2 = B_lvl_2.val[B_lvl_q]
                B_lvl_2_dirty = true
                B_lvl_2_dirty = true
                B_lvl_2_val_2 = (+)(A_lvl_2_val_2, B_lvl_2_val_2)
                B_lvl_2.val[B_lvl_q] = B_lvl_2_val_2
                if B_lvl_2_dirty
                    B_lvl_dirty = true
                    (B_lvl.tbl[1])[B_lvl_q] = i_3
                    B_lvl_q += 1
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
        i_4 = i
        i = A_lvl.I + 1
    end
    B_lvl.pos[1 + 1] = (B_lvl_q - B_lvl_qos_fill) - 1
    B_lvl_qos_fill = B_lvl_q - 1
    for p = 2:1 + 1
        B_lvl.pos[p] += B_lvl.pos[p - 1]
    end
    qos_stop = B_lvl.pos[1 + 1] - 1
    C_lvl_qos = C_lvl_qos_fill + 1
    B_lvl_q_2 = B_lvl.pos[1]
    B_lvl_q_stop = B_lvl.pos[1 + 1]
    if B_lvl_q_2 < B_lvl_q_stop
        B_lvl_i = (B_lvl.tbl[1])[B_lvl_q_2]
        B_lvl_i_stop = (B_lvl.tbl[1])[B_lvl_q_stop - 1]
    else
        B_lvl_i = 1
        B_lvl_i_stop = 0
    end
    i_2 = 1
    i_2_start = i_2
    phase_stop_3 = (min)(A_lvl.I, B_lvl_i_stop)
    if phase_stop_3 >= i_2_start
        i_5 = i_2
        i_2 = i_2_start
        while B_lvl_q_2 + 1 < B_lvl_q_stop && (B_lvl.tbl[1])[B_lvl_q_2] < i_2_start
            B_lvl_q_2 += 1
        end
        while i_2 <= phase_stop_3
            i_2_start_2 = i_2
            B_lvl_i = (B_lvl.tbl[1])[B_lvl_q_2]
            phase_stop_4 = (min)(B_lvl_i, phase_stop_3)
            i_6 = i_2
            if B_lvl_i == phase_stop_4
                B_lvl_2_val_3 = B_lvl_2.val[B_lvl_q_2]
                i_7 = phase_stop_4
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
                C_lvl_2_val_2 = (+)(B_lvl_2_val_3, C_lvl_2_val_2)
                C_lvl_2.val[C_lvl_qos] = C_lvl_2_val_2
                if C_lvl_2_dirty
                    C_lvl_dirty = true
                    C_lvl.idx[C_lvl_qos] = i_7
                    C_lvl_qos += 1
                end
                B_lvl_q_2 += 1
            else
            end
            i_2 = phase_stop_4 + 1
        end
        i_2 = phase_stop_3 + 1
    end
    i_2_start = i_2
    if A_lvl.I >= i_2_start
        i_8 = i_2
        i_2 = A_lvl.I + 1
    end
    C_lvl.pos[1 + 1] = (C_lvl_qos - C_lvl_qos_fill) - 1
    C_lvl_qos_fill = C_lvl_qos - 1
    for p_2 = 2:1 + 1
        C_lvl.pos[p_2] += C_lvl.pos[p_2 - 1]
    end
    qos_stop_2 = C_lvl.pos[1 + 1] - 1
    resize!(C_lvl.pos, 1 + 1)
    qos = C_lvl.pos[end] - 1
    resize!(C_lvl.idx, qos)
    resize!(C_lvl_2.val, qos)
    (C = Fiber((Finch.SparseListLevel){Int64}(A_lvl.I, C_lvl.pos, C_lvl.idx, C_lvl_2), (Environment)(; )),)
end
