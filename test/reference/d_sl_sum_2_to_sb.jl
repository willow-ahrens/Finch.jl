begin
    B_lvl = ex.body.body.lhs.tns.tns.lvl
    B_lvl_qos_stop = (B_lvl_qos_fill = length(B_lvl.srt))
    B_lvl_2 = B_lvl.lvl
    A_lvl = ex.body.body.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_3 = A_lvl_2.lvl
    for B_lvl_r = 1:B_lvl_qos_fill
        B_lvl_p = first(B_lvl.srt[B_lvl_r])
        B_lvl.pos[B_lvl_p] = 0
        B_lvl.pos[B_lvl_p + 1] = 0
        B_lvl_i = last(B_lvl.srt[B_lvl_r])
        B_lvl_q = (B_lvl_p - 1) * A_lvl_2.I + B_lvl_i
        B_lvl.tbl[B_lvl_q] = false
        if true
            resize_if_smaller!(B_lvl_2.val, B_lvl_q)
            fill_range!(B_lvl_2.val, 0.0, B_lvl_q, B_lvl_q)
        end
    end
    B_lvl_qos_fill = 0
    if false
        B_lvl_qos_stop = 0
    end
    B_lvl.pos[1] = 1
    B_lvlq_start = (1 - 1) * A_lvl_2.I + 1
    B_lvlq_stop = 1 * A_lvl_2.I
    (Finch.resize_if_smaller!)(B_lvl.pos, 1 + 1)
    (Finch.fill_range!)(B_lvl.pos, 0, 1 + 1, 1 + 1)
    (Finch.resize_if_smaller!)(B_lvl.tbl, B_lvlq_stop)
    (Finch.fill_range!)(B_lvl.tbl, false, B_lvlq_start, B_lvlq_stop)
    resize_if_smaller!(B_lvl_2.val, B_lvlq_stop)
    fill_range!(B_lvl_2.val, 0.0, B_lvlq_start, B_lvlq_stop)
    for i = 1:A_lvl.I
        A_lvl_q = (1 - 1) * A_lvl.I + i
        A_lvl_2_q = A_lvl_2.pos[A_lvl_q]
        A_lvl_2_q_stop = A_lvl_2.pos[A_lvl_q + 1]
        A_lvl_2_i = if A_lvl_2_q < A_lvl_2_q_stop
                A_lvl_2.idx[A_lvl_2_q]
            else
                1
            end
        A_lvl_2_i1 = if A_lvl_2_q < A_lvl_2_q_stop
                A_lvl_2.idx[A_lvl_2_q_stop - 1]
            else
                0
            end
        j = 1
        j_start = j
        phase_stop = (min)(A_lvl_2_i1, A_lvl_2.I)
        if phase_stop >= j_start
            j = j
            j = j_start
            while A_lvl_2_q + 1 < A_lvl_2_q_stop && A_lvl_2.idx[A_lvl_2_q] < j_start
                A_lvl_2_q += 1
            end
            while j <= phase_stop
                j_start_2 = j
                A_lvl_2_i = A_lvl_2.idx[A_lvl_2_q]
                phase_stop_2 = (min)(A_lvl_2_i, phase_stop)
                j_2 = j
                if A_lvl_2_i == phase_stop_2
                    A_lvl_3_val_2 = A_lvl_3.val[A_lvl_2_q]
                    j_3 = phase_stop_2
                    B_lvl_2_dirty = false
                    B_lvl_q_2 = (1 - 1) * A_lvl_2.I + j_3
                    B_lvl_2_val_2 = B_lvl_2.val[B_lvl_q_2]
                    B_lvl_2_dirty = true
                    B_lvl_2_dirty = true
                    B_lvl_2_val_2 = (+)(A_lvl_3_val_2, B_lvl_2_val_2)
                    B_lvl_2.val[B_lvl_q_2] = B_lvl_2_val_2
                    if B_lvl_2_dirty
                        B_lvl_dirty = true
                        if !(B_lvl.tbl[B_lvl_q_2])
                            B_lvl.tbl[B_lvl_q_2] = true
                            B_lvl_qos_fill += 1
                            if B_lvl_qos_fill > B_lvl_qos_stop
                                B_lvl_qos_stop = max(B_lvl_qos_stop << 1, 1)
                                (Finch.resize_if_smaller!)(B_lvl.srt, B_lvl_qos_stop)
                            end
                            B_lvl.srt[B_lvl_qos_fill] = (1, j_3)
                        end
                    end
                    A_lvl_2_q += 1
                else
                end
                j = phase_stop_2 + 1
            end
            j = phase_stop + 1
        end
        j_start = j
        if A_lvl_2.I >= j_start
            j_4 = j
            j = A_lvl_2.I + 1
        end
    end
    sort!(@view(B_lvl.srt[1:B_lvl_qos_fill]))
    B_lvl_p_prev = 0
    for B_lvl_r_2 = 1:B_lvl_qos_fill
        B_lvl_p_2 = first(B_lvl.srt[B_lvl_r_2])
        if B_lvl_p_2 != B_lvl_p_prev
            B_lvl.pos[B_lvl_p_prev + 1] = B_lvl_r_2
            B_lvl.pos[B_lvl_p_2] = B_lvl_r_2
        end
        B_lvl_p_prev = B_lvl_p_2
    end
    B_lvl.pos[B_lvl_p_prev + 1] = B_lvl_qos_fill + 1
    resize!(B_lvl.pos, 1 + 1)
    resize!(B_lvl.tbl, 1 * A_lvl_2.I)
    resize!(B_lvl.srt, B_lvl_qos_fill)
    resize!(B_lvl_2.val, (*)(1, A_lvl_2.I))
    (B = Fiber((Finch.SparseBytemapLevel){Int64, Int64}(A_lvl_2.I, B_lvl.pos, B_lvl.tbl, B_lvl.srt, B_lvl_2), (Environment)(; )),)
end
