@inbounds begin
        C = ex.body.lhs.tns.tns
        A = (ex.body.rhs.args[1]).tns.tns
        B = (ex.body.rhs.args[2]).tns.tns
        C_stop = (size(C))[1]
        A_stop = (size(A))[1]
        B_stop = (size(B))[1]
        C_stop_2 = (size(C))[1]
        A_stop_2 = (size(A))[1]
        B_stop_2 = (size(B))[1]
        C_stop_3 = (size(C))[1]
        A_stop_3 = (size(A))[1]
        B_stop_3 = (size(B))[1]
        C_stop_4 = (size(C))[1]
        A_stop_4 = (size(A))[1]
        A_stop_2 == A_stop_4 || throw(DimensionMismatch("mismatched dimension limits"))
        B_stop_4 = (size(B))[1]
        A_stop_2 == B_stop_4 || throw(DimensionMismatch("mismatched dimension limits"))
        C.idx = [C.idx[end]]
        C.val = [0.0]
        C_p = 0
        C.idx = (Int64)[]
        C.val = (Float64)[]
        A_p = 1
        A_i1 = A.idx[A_p]
        B_p = 1
        B_i0 = 1
        B_i1 = B.idx[B_p]
        i_start = 1
        while i_start <= A_stop
            i_step = min(A_i1, B_i1, A_stop)
            if i_step < B_i1
                push!(C.val, zero(Float64))
                C_p += 1
                C.val[C_p] = C.val[C_p] + A.val[A_p]
                push!(C.idx, i_step)
            else
                push!(C.val, zero(Float64))
                C_p += 1
                C.val[C_p] = C.val[C_p] + A.val[A_p]
                push!(C.idx, i_step - 1)
                push!(C.val, zero(Float64))
                C_p += 1
                C.val[C_p] = C.val[C_p] + (A.val[A_p] + B.val[B_p])
                push!(C.idx, i_step)
                B_p += 1
                B_i0 = B_i1 + 1
                B_i1 = B.idx[B_p]
            end
            if A_i1 == i_step && A_p < length(A.idx)
                A_p += 1
                A_i1 = A.idx[A_p]
            end
            i_start = i_step + 1
        end
        (C = C,)
    end
