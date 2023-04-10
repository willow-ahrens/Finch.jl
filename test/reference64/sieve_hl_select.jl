begin
    @inbounds begin
            B = ex.body.body.lhs.tns.tns
            B_val = B.val
            A_lvl = ex.body.body.rhs.tns.tns.lvl
            A_lvl_2 = A_lvl.lvl
            A_lvl_q = A_lvl.ptr[1]
            A_lvl_q_stop = A_lvl.ptr[1 + 1]
            if A_lvl_q < A_lvl_q_stop
                A_lvl_i1 = A_lvl.idx[A_lvl_q_stop - 1]
            else
                A_lvl_i1 = 0
            end
            phase_stop = (min)(A_lvl_i1, A_lvl.shape)
            if phase_stop >= 1
                j = 1
                if A_lvl.idx[A_lvl_q] < 1
                    A_lvl_q = scansearch(A_lvl.idx, 1, A_lvl_q, A_lvl_q_stop - 1)
                end
                while j <= phase_stop
                    A_lvl_i = A_lvl.idx[A_lvl_q]
                    phase_stop_2 = (min)(phase_stop, A_lvl_i)
                    if A_lvl_i == phase_stop_2
                        A_lvl_2_val_2 = A_lvl_2.val[A_lvl_q]
                        j_7 = phase_stop_2
                        s_5 = 3
                        phase_stop_5 = (min)(3, j_7 - 1)
                        if phase_stop_5 >= 3
                            s_5 = phase_stop_5 + 1
                        end
                        s_5_start = s_5
                        phase_stop_6 = (min)(3, j_7)
                        if phase_stop_6 >= s_5_start
                            B_val = (+)(B_val, (*)(A_lvl_2_val_2, (+)(1, (-)(s_5_start), phase_stop_6)))
                        end
                        A_lvl_q += 1
                    end
                    j = phase_stop_2 + 1
                end
            end
            (B = (Scalar){0.0, Float64}(B_val),)
        end
end
