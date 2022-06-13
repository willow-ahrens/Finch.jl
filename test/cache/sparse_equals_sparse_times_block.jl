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
        B_p = 1
        B_i0 = 1
        B_i1 = B.idx[B_p]
        i = 1
        i_start = i
        start = max(i_start, i_start)
        stop = min(A_stop, A.start - 1)
        if stop >= start
            i = i
            i = stop + 1
        end
        i_start = i
        start_3 = max(i_start, i_start)
        stop_3 = min(A_stop, A.stop)
        if stop_3 >= start_3
            i_2 = i
            i = start_3
            B_p = searchsortedfirst(B.idx, start_3, B_p, length(B.idx), Base.Forward)
            B_i0 = start_3
            B_i1 = B.idx[B_p]
            while i <= stop_3
                i_start_2 = i
                stop_5 = min(stop_3, B_i1)
                i_3 = i
                if B_i1 == stop_5
                    i_4 = stop_5
                    push!(C.idx, C_I)
                    push!(C.val, zero(Float64))
                    C_p += 1
                    C.val[C_p] = C.val[C_p] + A.val[(i_4 - A.start) + 1] * B.val[B_p]
                    C.idx[C_p] = i_4
                    B_p += 1
                    B_i0 = B_i1 + 1
                    B_i1 = B.idx[B_p]
                else
                end
                i = stop_5 + 1
            end
            i = stop_3 + 1
        end
        i_start = i
        i_5 = i
        i = A_stop + 1
        (C = C,)
    end
