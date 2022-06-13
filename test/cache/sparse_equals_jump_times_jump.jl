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
        while i <= A_stop
            i_start = i
            A_p = searchsortedfirst(A.idx, i_start, A_p, length(A.idx), Base.Forward)
            A_i0 = i_start
            A_i1 = A.idx[A_p]
            B_p = searchsortedfirst(B.idx, i_start, B_p, length(B.idx), Base.Forward)
            B_i0 = i_start
            B_i1 = B.idx[B_p]
            start = min(i_start, i_start)
            stop = max(A_i1, B_i1)
            start_3 = max(i_start, start)
            stop_3 = min(A_stop, stop)
            if stop_3 >= start_3
                i = i
                if stop_3 == A_i1 && stop_3 == B_i1
                    i_2 = stop_3
                    push!(C.idx, C_I)
                    push!(C.val, zero(Float64))
                    C_p += 1
                    C.val[C_p] = C.val[C_p] + A.val[A_p] * B.val[B_p]
                    C.idx[C_p] = i_2
                    A_p += 1
                    A_i0 = A_i1 + 1
                    A_i1 = A.idx[A_p]
                    B_p += 1
                    B_i0 = B_i1 + 1
                    B_i1 = B.idx[B_p]
                elseif stop_3 == B_i1
                    i = stop_3
                    A_p = searchsortedfirst(A.idx, stop_3, A_p, length(A.idx), Base.Forward)
                    A_i0 = stop_3
                    A_i1 = A.idx[A_p]
                    i_start_2 = i
                    stop_5 = min(stop_3, A_i1)
                    i_3 = i
                    if A_i1 == stop_5
                        i_4 = stop_5
                        push!(C.idx, C_I)
                        push!(C.val, zero(Float64))
                        C_p += 1
                        C.val[C_p] = C.val[C_p] + A.val[A_p] * B.val[B_p]
                        C.idx[C_p] = i_4
                        A_p += 1
                        A_i0 = A_i1 + 1
                        A_i1 = A.idx[A_p]
                    else
                    end
                    i = stop_5 + 1
                    B_p += 1
                    B_i0 = B_i1 + 1
                    B_i1 = B.idx[B_p]
                elseif stop_3 == A_i1
                    i = stop_3
                    B_p = searchsortedfirst(B.idx, stop_3, B_p, length(B.idx), Base.Forward)
                    B_i0 = stop_3
                    B_i1 = B.idx[B_p]
                    i_start_3 = i
                    stop_7 = min(stop_3, B_i1)
                    i_5 = i
                    if B_i1 == stop_7
                        i_6 = stop_7
                        push!(C.idx, C_I)
                        push!(C.val, zero(Float64))
                        C_p += 1
                        C.val[C_p] = C.val[C_p] + A.val[A_p] * B.val[B_p]
                        C.idx[C_p] = i_6
                        B_p += 1
                        B_i0 = B_i1 + 1
                        B_i1 = B.idx[B_p]
                    else
                    end
                    i = stop_7 + 1
                    A_p += 1
                    A_i0 = A_i1 + 1
                    A_i1 = A.idx[A_p]
                else
                    i = start_3
                    A_p = searchsortedfirst(A.idx, start_3, A_p, length(A.idx), Base.Forward)
                    A_i0 = start_3
                    A_i1 = A.idx[A_p]
                    B_p = searchsortedfirst(B.idx, start_3, B_p, length(B.idx), Base.Forward)
                    B_i0 = start_3
                    B_i1 = B.idx[B_p]
                    while i <= stop_3
                        i_start_4 = i
                        start_9 = max(i_start_4, i_start_4)
                        stop_9 = min(A_i1, B_i1)
                        start_11 = max(i_start_4, start_9)
                        stop_11 = min(stop_3, stop_9)
                        if stop_11 >= start_11
                            i_7 = i
                            if A_i1 == stop_11 && B_i1 == stop_11
                                i_8 = stop_11
                                push!(C.idx, C_I)
                                push!(C.val, zero(Float64))
                                C_p += 1
                                C.val[C_p] = C.val[C_p] + A.val[A_p] * B.val[B_p]
                                C.idx[C_p] = i_8
                                A_p += 1
                                A_i0 = A_i1 + 1
                                A_i1 = A.idx[A_p]
                                B_p += 1
                                B_i0 = B_i1 + 1
                                B_i1 = B.idx[B_p]
                            elseif B_i1 == stop_11
                                B_p += 1
                                B_i0 = B_i1 + 1
                                B_i1 = B.idx[B_p]
                            elseif A_i1 == stop_11
                                A_p += 1
                                A_i0 = A_i1 + 1
                                A_i1 = A.idx[A_p]
                            else
                            end
                            i = stop_11 + 1
                        end
                    end
                end
                i = stop_3 + 1
            end
        end
        (C = C,)
    end
