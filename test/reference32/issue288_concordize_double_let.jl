begin
    X = ex.body.body.body.rhs.tns.bind
    A = (ex.body.body.body.body.body.bodies[1]).rhs.tns.bind
    C = (ex.body.body.body.body.body.bodies[1]).body.body.lhs.tns.bind
    sugar_1 = size(X)
    X_mode1_stop = sugar_1[1]
    X_mode2_stop = sugar_1[2]
    sugar_2 = size(A)
    A_mode1_stop = sugar_2[1]
    A_mode3_stop = sugar_2[3]
    A_mode1_stop == X_mode1_stop || throw(DimensionMismatch("mismatched dimension limits ($(A_mode1_stop) != $(X_mode1_stop))"))
    sugar_3 = size(C)
    C_mode1_stop = sugar_3[1]
    C_mode2_stop = sugar_3[2]
    C_mode3_stop = sugar_3[3]
    A_mode1_stop == C_mode1_stop || throw(DimensionMismatch("mismatched dimension limits ($(A_mode1_stop) != $(C_mode1_stop))"))
    C_mode2_stop == X_mode2_stop || throw(DimensionMismatch("mismatched dimension limits ($(C_mode2_stop) != $(X_mode2_stop))"))
    C_mode3_stop == A_mode3_stop || throw(DimensionMismatch("mismatched dimension limits ($(C_mode3_stop) != $(A_mode3_stop))"))
    sugar_4 = size(A)
    A_mode1_stop = sugar_4[1]
    A_mode3_stop = sugar_4[3]
    C_mode3_stop == A_mode3_stop || throw(DimensionMismatch("mismatched dimension limits ($(C_mode3_stop) != $(A_mode3_stop))"))
    sugar_5 = size(C)
    C_mode1_stop = sugar_5[1]
    C_mode3_stop = sugar_5[3]
    A_mode1_stop == C_mode1_stop || throw(DimensionMismatch("mismatched dimension limits ($(A_mode1_stop) != $(C_mode1_stop))"))
    for k_6 = 1:C_mode3_stop
        sugar_8 = size(A)
        A_mode1_stop = sugar_8[1]
        A_mode2_stop = sugar_8[2]
        sugar_9 = size(C)
        C_mode2_stop = sugar_9[2]
        for j_5 = 1:C_mode2_stop
            for i_9 = 1:A_mode1_stop
                val = X[i_9, j_5]
                for l_6 = 1:A_mode2_stop
                    val_2 = A[i_9, l_6, k_6]
                    phase_stop = min(i_9, (l_6 + 0) + -1)
                    if phase_stop >= i_9
                        for s_7 = i_9:phase_stop
                            C[i_9, j_5, k_6] = val_2 * val + C[i_9, j_5, k_6]
                        end
                    end
                    val_3 = A[i_9, l_6, k_6]
                    phase_stop_3 = min((l_6 + 0) + -1, i_9)
                    if phase_stop_3 >= i_9
                        for s_12 = i_9:phase_stop_3
                            C[i_9, j_5, k_6] = val * val_3 + C[i_9, j_5, k_6]
                        end
                    end
                end
            end
        end
    end
    (C = C,)
end
