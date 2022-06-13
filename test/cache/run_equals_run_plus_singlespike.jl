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
        i = 1
        A_p = searchsortedfirst(A.idx, 1, A_p, length(A.idx), Base.Forward)
        A_i1 = A.idx[A_p]
        while i <= A_stop - 1
            i_start = i
            stop = min(A_stop - 1, A_i1)
            i = i
            if A_i1 == stop
                push!(C.val, zero(Float64))
                C_p += 1
                C.val[C_p] = C.val[C_p] + A.val[A_p]
                push!(C.idx, stop)
                if A_p < length(A.idx)
                    A_p += 1
                    A_i1 = A.idx[A_p]
                end
            else
                push!(C.val, zero(Float64))
                C_p += 1
                C.val[C_p] = C.val[C_p] + A.val[A_p]
                push!(C.idx, stop)
            end
            i = stop + 1
        end
        i = A_stop
        A_p = searchsortedfirst(A.idx, A_stop, A_p, length(A.idx), Base.Forward)
        A_i1 = A.idx[A_p]
        i_start_2 = i
        stop_3 = min(A_stop, A_i1)
        i_2 = i
        if A_i1 == stop_3
            push!(C.val, zero(Float64))
            C_p += 1
            C.val[C_p] = C.val[C_p] + (A.val[A_p] + B.tail)
            push!(C.idx, stop_3)
            if A_p < length(A.idx)
                A_p += 1
                A_i1 = A.idx[A_p]
            end
        else
            push!(C.val, zero(Float64))
            C_p += 1
            C.val[C_p] = C.val[C_p] + (A.val[A_p] + B.tail)
            push!(C.idx, stop_3)
        end
        i = stop_3 + 1
        (C = C,)
    end
