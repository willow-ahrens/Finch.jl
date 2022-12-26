@inbounds begin
        B_lvl = ex.body.lhs.tns.tns.lvl
        B_lvl_2 = B_lvl.lvl
        B_lvl_2_val_alloc = length(B_lvl.lvl.val)
        B_lvl_2_val = 0
        A = ex.body.rhs.tns.tns
        I_lvl = (ex.body.rhs.idxs[2]).tns.tns.lvl
        I_lvl_pos_alloc = length(I_lvl.pos)
        I_lvl_idx_alloc = length(I_lvl.idx)
        I_lvl_val_alloc = length(I_lvl.val)
        (A_mode1_stop, A_mode2_stop) = size(A)
        i_stop = A_mode1_stop
        B_lvl_2_val_alloc = (Finch).refill!(B_lvl_2.val, 0, 0, 4)
        B_lvl_2_val_alloc < (*)(1, A_mode1_stop) && (B_lvl_2_val_alloc = (Finch).refill!(B_lvl_2.val, 0, B_lvl_2_val_alloc, (*)(1, A_mode1_stop)))
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
                    B_lvl_q = (1 - 1) * A_mode1_stop + i_2
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    B_lvl_2_val = A[i_2, I_lvl.val[I_lvl_q]]
                    B_lvl_2.val[B_lvl_q] = B_lvl_2_val
                end
                I_lvl_q += 1
            else
                for i_3 = phase_start:phase_stop
                    B_lvl_q = (1 - 1) * A_mode1_stop + i_3
                    B_lvl_2_val = B_lvl_2.val[B_lvl_q]
                    B_lvl_2_val = A[i_3, I_lvl.val[I_lvl_q]]
                    B_lvl_2.val[B_lvl_q] = B_lvl_2_val
                end
            end
            i = phase_stop + 1
        end
        qos = 1A_mode1_stop
        resize!(B_lvl_2.val, qos)
        (B = Fiber((Finch.DenseLevel){Int64}(A_mode1_stop, B_lvl_2), (Finch.Environment)(; )),)
    end
