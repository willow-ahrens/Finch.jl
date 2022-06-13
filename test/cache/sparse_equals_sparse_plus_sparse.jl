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
        C.val = (Int64)[]
        C_p = 0
        C_I = A_stop + 1
        C.idx = (Int64)[C_I]
        C.val = (Float64)[]
        A_p = 1
        A_i0 = 1
        A_i1 = A.idx[A_p]
        B_p = 1
        B_i0 = 1
        B_i1 = B.idx[B_p]
        i_start = 1
        while i_start <= A_stop
            i_step = min(A_i1, B_i1, A_stop)
            if i_step < A_i1 && i_step < B_i1
            elseif i_step < B_i1
                i = i_step
                push!(C.idx, C_I)
                push!(C.val, zero(Float64))
                C_p += 1
                C.val[C_p] = C.val[C_p] + A.val[A_p]
                C.idx[C_p] = i
                A_p += 1
                A_i0 = A_i1 + 1
                A_i1 = A.idx[A_p]
            elseif i_step < A_i1
                i_2 = i_step
                push!(C.idx, C_I)
                push!(C.val, zero(Float64))
                C_p += 1
                C.val[C_p] = C.val[C_p] + B.val[B_p]
                C.idx[C_p] = i_2
                B_p += 1
                B_i0 = B_i1 + 1
                B_i1 = B.idx[B_p]
            else
                i_3 = i_step
                push!(C.idx, C_I)
                push!(C.val, zero(Float64))
                C_p += 1
                C.val[C_p] = C.val[C_p] + (A.val[A_p] + B.val[B_p])
                C.idx[C_p] = i_3
                A_p += 1
                A_i0 = A_i1 + 1
                A_i1 = A.idx[A_p]
                B_p += 1
                B_i0 = B_i1 + 1
                B_i1 = B.idx[B_p]
            end
            i_start = i_step + 1
        end
        (C = C,)
    end
