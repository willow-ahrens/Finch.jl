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
        i = 1
        A_p = searchsortedfirst(A.idx, 1, A_p, length(A.idx), Base.Forward)
        A_i0 = 1
        A_i1 = A.idx[A_p]
        B_p = searchsortedfirst(B.idx, 1, B_p, length(B.idx), Base.Forward)
        B_i0 = 1
        B_i1 = B.idx[B_p]
        while i <= A_stop
            i_start = i
            start = max(i_start, i_start)
            stop = min(A_i1, B_i1)
            start_3 = max(i_start, start)
            stop_3 = min(A_stop, stop)
            if stop_3 >= start_3
                i = i
                if A_i1 == stop_3 && B_i1 == stop_3
                    i_2 = stop_3
                    push!(C.idx, C_I)
                    push!(C.val, zero(Float64))
                    C_p += 1
                    C.val[C_p] = C.val[C_p] + (A.val[A_p] + B.val[B_p])
                    C.idx[C_p] = i_2
                    A_p += 1
                    A_i0 = A_i1 + 1
                    A_i1 = A.idx[A_p]
                    B_p += 1
                    B_i0 = B_i1 + 1
                    B_i1 = B.idx[B_p]
                elseif B_i1 == stop_3
                    i_3 = stop_3
                    push!(C.idx, C_I)
                    push!(C.val, zero(Float64))
                    C_p += 1
                    C.val[C_p] = C.val[C_p] + B.val[B_p]
                    C.idx[C_p] = i_3
                    B_p += 1
                    B_i0 = B_i1 + 1
                    B_i1 = B.idx[B_p]
                elseif A_i1 == stop_3
                    i_4 = stop_3
                    push!(C.idx, C_I)
                    push!(C.val, zero(Float64))
                    C_p += 1
                    C.val[C_p] = C.val[C_p] + A.val[A_p]
                    C.idx[C_p] = i_4
                    A_p += 1
                    A_i0 = A_i1 + 1
                    A_i1 = A.idx[A_p]
                else
                end
                i = stop_3 + 1
            end
        end
        (C = C,)
    end
