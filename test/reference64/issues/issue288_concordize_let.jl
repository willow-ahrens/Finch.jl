begin
    X = (ex.bodies[1]).body.body.body.rhs.tns.bind
    A = (ex.bodies[1]).body.body.body.body.body.rhs.tns.bind
    C = (ex.bodies[1]).body.body.body.body.body.body.body.lhs.tns.bind
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
    result = nothing
    for k_4 = 1:C_mode3_stop
        sugar_4 = size(A)
        A_mode1_stop = sugar_4[1]
        A_mode2_stop = sugar_4[2]
        sugar_5 = size(C)
        C_mode2_stop = sugar_5[2]
        C_mode3_stop = sugar_5[3]
        for j_4 = 1:C_mode2_stop
            sugar_7 = size(C)
            C_mode2_stop = sugar_7[2]
            C_mode3_stop = sugar_7[3]
            for i_6 = 1:A_mode1_stop
                sugar_9 = size(C)
                C_mode2_stop = sugar_9[2]
                C_mode3_stop = sugar_9[3]
                val = X[i_6, j_4]
                for l_4 = 1:A_mode2_stop
                    sugar_11 = size(A)
                    A_mode1_stop = sugar_11[1]
                    A_mode2_stop = sugar_11[2]
                    val_2 = A[i_6, l_4, k_4]
                    phase_stop = min(i_6, l_4 + -1)
                    if phase_stop >= i_6
                        for s_5 = i_6:phase_stop
                            C[i_6, j_4, k_4] = val_2 * val + C[i_6, j_4, k_4]
                        end
                    end
                end
            end
        end
    end
    result = ()
    result
end
