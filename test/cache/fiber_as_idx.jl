@inbounds begin
        B_lvl = ex.body.lhs.tns.tns.lvl
        B_lvl_2 = B_lvl.lvl
        B_lvl_2_val_alloc = length(B_lvl.lvl.val)
        B_lvl_2_val = 0
        A_lvl = ex.body.rhs.tns.tns.lvl
        A_lvl_2 = A_lvl.lvl
        A_lvl_3 = A_lvl_2.lvl
        A_lvl_3_val_alloc = length(A_lvl_2.lvl.val)
        A_lvl_3_val = 0
        I_lvl = (ex.body.rhs.idxs[2]).tns.tns.lvl
        I_lvl_pos_alloc = length(I_lvl.pos)
        I_lvl_idx_alloc = length(I_lvl.idx)
        I_lvl_val_alloc = length(I_lvl.val)
        i_stop = A_lvl.I
        B_lvl_2_val_alloc = (Finch).refill!(B_lvl_2.val, 0, 0, 4)
        B_lvl_2_val_alloc < (*)(1, A_lvl.I) && (B_lvl_2_val_alloc = (Finch).refill!(B_lvl_2.val, 0, B_lvl_2_val_alloc, (*)(1, A_lvl.I)))
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
        while i <= i_stop
            i_start = i
            I_lvl_i = I_lvl.idx[I_lvl_q]
            phase_start = i_start
            phase_stop = (min)(I_lvl_i, i_stop)
            i = i
            if I_lvl_i == phase_stop
                for i_2 = phase_start:phase_stop
                    B_lvl_q = (1 - 1) * A_lvl.I + i_2
                    A_lvl_q = (1 - 1) * A_lvl.I + i_2
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    s_2 = I_lvl.val[I_lvl_q]
                    for s_3 = s_2:s_2
                        A_lvl_2_q = (A_lvl_q - 1) * A_lvl_2.I + s_3
                        A_lvl_3_val = A_lvl_3.val[A_lvl_2_q]
                        B_lvl_2_val = A_lvl_3_val
                    end
                    B_lvl_2.val[B_lvl_q] = B_lvl_2_val
                end
                I_lvl_q += 1
            else
                for i_3 = phase_start:phase_stop
                    B_lvl_q = (1 - 1) * A_lvl.I + i_3
                    A_lvl_q = (1 - 1) * A_lvl.I + i_3
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    s_5 = I_lvl.val[I_lvl_q]
                    for s_6 = s_5:s_5
                        A_lvl_2_q_2 = (A_lvl_q - 1) * A_lvl_2.I + s_6
                        A_lvl_3_val = A_lvl_3.val[A_lvl_2_q_2]
                        B_lvl_2_val = A_lvl_3_val
                    end
                    B_lvl_2.val[B_lvl_q] = B_lvl_2_val
                end
            end
            i = phase_stop + 1
        end
        qos = 1 * A_lvl.I
        resize!(B_lvl_2.val, qos)
        (B = Fiber((Finch.DenseLevel){Int64}(A_lvl.I, B_lvl_2), (Finch.Environment)(; )),)
    end
