begin
    B_lvl = ex.body.lhs.tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    A_lvl = ex.body.rhs.tns.tns.lvl
    resize_if_smaller!(B_lvl_2.val, A_lvl.I)
    fill_range!(B_lvl_2.val, 0.0, 1, A_lvl.I)
    A_lvl_q = A_lvl.pos[1]
    A_lvl_q_stop = A_lvl.pos[1 + 1]
    if A_lvl_q < A_lvl_q_stop
        A_lvl_i = A_lvl.idx[A_lvl_q]
        A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
    else
        A_lvl_i = 1
        A_lvl_i1 = 0
    end
    i = 1
    while A_lvl_q + 1 < A_lvl_q_stop && A_lvl.idx[A_lvl_q] < 1
        A_lvl_q += 1
    end
    while i <= A_lvl.I
        i_start = i
        A_lvl_i = A_lvl.idx[A_lvl_q]
        phase_stop = (min)(A_lvl.I, A_lvl_i)
        i = i
        if A_lvl_i == phase_stop
            for i_2 = i_start:phase_stop
                B_lvl_q = (1 - 1) * A_lvl.I + i_2
                B_lvl_2_val_2 = B_lvl_2.val[B_lvl_q]
                B_lvl_2_dirty = true
                B_lvl_2_val_2 = A_lvl.val[A_lvl_q]
                B_lvl_2.val[B_lvl_q] = B_lvl_2_val_2
            end
            A_lvl_q += 1
        else
            for i_3 = i_start:phase_stop
                B_lvl_q = (1 - 1) * A_lvl.I + i_3
                B_lvl_2_val_3 = B_lvl_2.val[B_lvl_q]
                B_lvl_2_dirty = true
                B_lvl_2_val_3 = A_lvl.val[A_lvl_q]
                B_lvl_2.val[B_lvl_q] = B_lvl_2_val_3
            end
        end
        i = phase_stop + 1
    end
    qos = 1 * A_lvl.I
    resize!(B_lvl_2.val, qos)
    (B = Fiber((Finch.DenseLevel){Int64}(A_lvl.I, B_lvl_2)),)
end
