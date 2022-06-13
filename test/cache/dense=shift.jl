@inbounds begin
        B = ex.body.lhs.tns.tns
        A = ex.body.rhs.tns.tns
        (B_mode1_stop,) = size(B)
        A_stop = (size(A))[1]
        (B_mode1_stop_2,) = size(B)
        A_stop_2 = (size(A))[1]
        (B_mode1_stop_3,) = size(B)
        A_stop_3 = (size(A))[1]
        (B_mode1_stop_4,) = size(B)
        (B_mode1_stop_5,) = size(B)
        A_stop_2 == B_mode1_stop_5 || throw(DimensionMismatch("mismatched dimension limits"))
        A_stop_4 = (size(A))[1]
        A_stop_2 == A_stop_4 || throw(DimensionMismatch("mismatched dimension limits"))
        fill!(B, 0)
        for i = 1:A_stop
            B[i] = A.val[i + A.shift]
        end
        (B = B,)
    end
