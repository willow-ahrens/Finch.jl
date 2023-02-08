begin
    B_lvl = ex.body.lhs.tns.tns.lvl
    B_lvl_2 = B_lvl.lvl
    A_lvl = ex.body.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_3 = A_lvl_2.lvl
    I_lvl = (ex.body.rhs.idxs[2]).tns.tns.lvl
    resize_if_smaller!(B_lvl_2.val, A_lvl.I)
    fill_range!(B_lvl_2.val, 0, 1, A_lvl.I)
    I_lvl_q = I_lvl.pos[1]
    I_lvl_q_stop = I_lvl.pos[1 + 1]
    if I_lvl_q < I_lvl_q_stop
        I_lvl_i = I_lvl.idx[I_lvl_q]
        I_lvl_i1 = I_lvl.idx[I_lvl_q_stop - 1]
    else
        I_lvl_i = 1
        I_lvl_i1 = 0
    end
    i = 1
    while I_lvl_q + 1 < I_lvl_q_stop && I_lvl.idx[I_lvl_q] < 1
        I_lvl_q += 1
    end
    while i <= A_lvl.I
        i_start = i
        I_lvl_i = I_lvl.idx[I_lvl_q]
        phase_stop = (min)(A_lvl.I, I_lvl_i)
        i = i
        if I_lvl_i == phase_stop
            for i_2 = i_start:phase_stop
                B_lvl_q = (1 - 1) * A_lvl.I + i_2
                A_lvl_q = (1 - 1) * A_lvl.I + i_2
                B_lvl_2_val_2 = B_lvl_2.val[B_lvl_q]
                for s_2 = I_lvl.val[I_lvl_q]:I_lvl.val[I_lvl_q]
                    A_lvl_2_q = (A_lvl_q - 1) * A_lvl_2.I + s_2
                    A_lvl_3_val_2 = A_lvl_3.val[A_lvl_2_q]
                    B_lvl_2_dirty = true
                    B_lvl_2_val_2 = A_lvl_3_val_2
                end
                B_lvl_2.val[B_lvl_q] = B_lvl_2_val_2
            end
            I_lvl_q += 1
        else
            for i_3 = i_start:phase_stop
                B_lvl_q = (1 - 1) * A_lvl.I + i_3
                A_lvl_q = (1 - 1) * A_lvl.I + i_3
                B_lvl_2_val_3 = B_lvl_2.val[B_lvl_q]
                for s_4 = I_lvl.val[I_lvl_q]:I_lvl.val[I_lvl_q]
                    A_lvl_2_q_2 = (A_lvl_q - 1) * A_lvl_2.I + s_4
                    A_lvl_3_val_3 = A_lvl_3.val[A_lvl_2_q_2]
                    B_lvl_2_dirty = true
                    B_lvl_2_val_3 = A_lvl_3_val_3
                end
                B_lvl_2.val[B_lvl_q] = B_lvl_2_val_3
            end
        end
        i = phase_stop + 1
    end
    qos = 1 * A_lvl.I
    resize!(B_lvl_2.val, qos)
    (B = Fiber((Finch.DenseLevel){Int64}(A_lvl.I, B_lvl_2)),)
end
