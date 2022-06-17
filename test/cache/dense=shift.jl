@inbounds begin
        B = ex.body.lhs.tns.tns
        A = ex.body.rhs.tns.tns
        (B_mode1_stop,) = size(B)
        A_stop = (size(A))[1]
        i_stop = B_mode1_stop
        (B_mode1_stop,) = size(B)
        1 == 1 || throw(DimensionMismatch("mismatched dimension start"))
        B_mode1_stop == B_mode1_stop || throw(DimensionMismatch("mismatched dimension stop"))
        fill!(B, 0)
        for i = 1:i_stop
            B[i] = A.val[i + A.shift]
        end
        (B = B,)
    end
