begin
    @inbounds begin
            B_lvl = (ex.bodies[1]).tns.tns.lvl
            B_lvl_2 = B_lvl.lvl
            A_lvl = (ex.bodies[2]).body.rhs.tns.tns.lvl
            A_lvl_2 = A_lvl.lvl
            A_lvl_3 = A_lvl_2.lvl
            I_lvl = ((ex.bodies[2]).body.rhs.idxs[1]).tns.tns.lvl
            I_lvl.shape == A_lvl.shape || throw(DimensionMismatch("mismatched dimension limits ($(I_lvl.shape) != $(A_lvl.shape))"))
            resize_if_smaller!(B_lvl_2.val, I_lvl.shape)
            fill_range!(B_lvl_2.val, 0, 1, I_lvl.shape)
            I_lvl_q = I_lvl.ptr[1]
            I_lvl_q_stop = I_lvl.ptr[1 + 1]
            i = 1
            if I_lvl.idx[I_lvl_q] < 1
                I_lvl_q = scansearch(I_lvl.idx, 1, I_lvl_q, I_lvl_q_stop - 1)
            end
            while i <= I_lvl.shape
                i_start = i
                I_lvl_i = I_lvl.idx[I_lvl_q]
                phase_stop = (min)(I_lvl.shape, I_lvl_i)
                if I_lvl_i == phase_stop
                    for i_6 = i_start:phase_stop
                        B_lvl_q = (1 - 1) * I_lvl.shape + i_6
                        A_lvl_q = (1 - 1) * A_lvl.shape + i_6
                        s_2 = I_lvl.val[I_lvl_q]
                        A_lvl_2_q = (A_lvl_q - 1) * A_lvl_2.shape + s_2
                        A_lvl_3_val_2 = A_lvl_3.val[A_lvl_2_q]
                        B_lvl_2.val[B_lvl_q] = A_lvl_3_val_2
                    end
                    I_lvl_q += 1
                else
                    for i_7 = i_start:phase_stop
                        B_lvl_q = (1 - 1) * I_lvl.shape + i_7
                        A_lvl_q = (1 - 1) * A_lvl.shape + i_7
                        s_4 = I_lvl.val[I_lvl_q]
                        A_lvl_2_q_2 = (A_lvl_q - 1) * A_lvl_2.shape + s_4
                        A_lvl_3_val_3 = A_lvl_3.val[A_lvl_2_q_2]
                        B_lvl_2.val[B_lvl_q] = A_lvl_3_val_3
                    end
                end
                i = phase_stop + 1
            end
            qos = 1 * I_lvl.shape
            resize!(B_lvl_2.val, qos)
            (B = Fiber((Finch.DenseLevel){Int64}(B_lvl_2, I_lvl.shape)),)
        end
end
