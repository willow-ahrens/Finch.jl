@inbounds begin
        C = ex.body.lhs.tns.tns
        A = (ex.body.rhs.args[1]).tns.tns
        B = (ex.body.rhs.args[2]).tns.tns
        C_stop = (size(C))[1]
        A_stop = (size(A))[1]
        B_stop = (size(B))[1]
        i_stop = C_stop
        C.idx = [C.idx[end]]
        C.val = (Int64)[]
        C_p = 0
        C_I = i_stop + 1
        C.idx = (Int64)[C_I]
        C.val = (Float64)[]
        A_p = 1
        A_i0 = 1
        A_i1 = A.idx[A_p]
        B_p = 1
        B_i0 = 1
        B_i1 = B.idx[B_p]
        i = 1
        while i <= i_stop
            i_start = i
            A_p = searchsortedfirst(A.idx, i_start, A_p, length(A.idx), Base.Forward)
            A_i0 = i_start
            A_i1 = A.idx[A_p]
            B_p = searchsortedfirst(B.idx, i_start, B_p, length(B.idx), Base.Forward)
            B_i0 = i_start
            B_i1 = B.idx[B_p]
            phase_start = max(i_start, min(i_start))
            phase_stop = min(max(A_i1, B_i1), i_stop)
            if phase_stop >= phase_start
                i = i
                if phase_stop == A_i1 && phase_stop == B_i1
                    i_2 = phase_stop
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
                elseif phase_stop == B_i1
                    i = phase_start
                    A_p = searchsortedfirst(A.idx, phase_start, A_p, length(A.idx), Base.Forward)
                    A_i0 = phase_start
                    A_i1 = A.idx[A_p]
                    while i <= phase_stop - 1
                        i_start_2 = i
                        phase_stop_2 = min(A_i1, phase_stop - 1)
                        i_3 = i
                        if A_i1 == phase_stop_2
                            i_4 = phase_stop_2
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
                        i = phase_stop_2 + 1
                    end
                    i = phase_stop
                    A_p = searchsortedfirst(A.idx, phase_stop, A_p, length(A.idx), Base.Forward)
                    A_i0 = phase_stop
                    A_i1 = A.idx[A_p]
                    i_start_3 = i
                    phase_start_3 = max(i_start_3)
                    phase_stop_3 = min(A_i1, phase_stop)
                    i_5 = i
                    if A_i1 == phase_stop_3
                        for i_6 = phase_start_3:phase_stop_3 - 1
                            push!(C.idx, C_I)
                            push!(C.val, zero(Float64))
                            C_p += 1
                            C.val[C_p] = C.val[C_p] + B.val[B_p]
                            C.idx[C_p] = i_6
                        end
                        i_7 = phase_stop_3
                        push!(C.idx, C_I)
                        push!(C.val, zero(Float64))
                        C_p += 1
                        C.val[C_p] = C.val[C_p] + (A.val[A_p] + B.val[B_p])
                        C.idx[C_p] = i_7
                        A_p += 1
                        A_i0 = A_i1 + 1
                        A_i1 = A.idx[A_p]
                    else
                        for i_8 = phase_start_3:phase_stop_3
                            push!(C.idx, C_I)
                            push!(C.val, zero(Float64))
                            C_p += 1
                            C.val[C_p] = C.val[C_p] + B.val[B_p]
                            C.idx[C_p] = i_8
                        end
                    end
                    i = phase_stop_3 + 1
                    B_p += 1
                    B_i0 = B_i1 + 1
                    B_i1 = B.idx[B_p]
                elseif phase_stop == A_i1
                    i = phase_start
                    B_p = searchsortedfirst(B.idx, phase_start, B_p, length(B.idx), Base.Forward)
                    B_i0 = phase_start
                    B_i1 = B.idx[B_p]
                    while i <= phase_stop - 1
                        i_start_4 = i
                        phase_stop_4 = min(phase_stop - 1, B_i1)
                        i_9 = i
                        if B_i1 == phase_stop_4
                            i_10 = phase_stop_4
                            push!(C.idx, C_I)
                            push!(C.val, zero(Float64))
                            C_p += 1
                            C.val[C_p] = C.val[C_p] + B.val[B_p]
                            C.idx[C_p] = i_10
                            B_p += 1
                            B_i0 = B_i1 + 1
                            B_i1 = B.idx[B_p]
                        else
                        end
                        i = phase_stop_4 + 1
                    end
                    i = phase_stop
                    B_p = searchsortedfirst(B.idx, phase_stop, B_p, length(B.idx), Base.Forward)
                    B_i0 = phase_stop
                    B_i1 = B.idx[B_p]
                    i_start_5 = i
                    phase_start_5 = max(i_start_5)
                    phase_stop_5 = min(B_i1, phase_stop)
                    i_11 = i
                    if B_i1 == phase_stop_5
                        for i_12 = phase_start_5:phase_stop_5 - 1
                            push!(C.idx, C_I)
                            push!(C.val, zero(Float64))
                            C_p += 1
                            C.val[C_p] = C.val[C_p] + A.val[A_p]
                            C.idx[C_p] = i_12
                        end
                        i_13 = phase_stop_5
                        push!(C.idx, C_I)
                        push!(C.val, zero(Float64))
                        C_p += 1
                        C.val[C_p] = C.val[C_p] + (A.val[A_p] + B.val[B_p])
                        C.idx[C_p] = i_13
                        B_p += 1
                        B_i0 = B_i1 + 1
                        B_i1 = B.idx[B_p]
                    else
                        for i_14 = phase_start_5:phase_stop_5
                            push!(C.idx, C_I)
                            push!(C.val, zero(Float64))
                            C_p += 1
                            C.val[C_p] = C.val[C_p] + A.val[A_p]
                            C.idx[C_p] = i_14
                        end
                    end
                    i = phase_stop_5 + 1
                    A_p += 1
                    A_i0 = A_i1 + 1
                    A_i1 = A.idx[A_p]
                else
                    i = phase_start
                    A_p = searchsortedfirst(A.idx, phase_start, A_p, length(A.idx), Base.Forward)
                    A_i0 = phase_start
                    A_i1 = A.idx[A_p]
                    B_p = searchsortedfirst(B.idx, phase_start, B_p, length(B.idx), Base.Forward)
                    B_i0 = phase_start
                    B_i1 = B.idx[B_p]
                    while i <= phase_stop
                        i_start_6 = i
                        phase_start_6 = max(i_start_6)
                        phase_stop_6 = min(A_i1, B_i1, phase_stop)
                        if phase_stop_6 >= phase_start_6
                            i_15 = i
                            if A_i1 == phase_stop_6 && B_i1 == phase_stop_6
                                i_16 = phase_stop_6
                                push!(C.idx, C_I)
                                push!(C.val, zero(Float64))
                                C_p += 1
                                C.val[C_p] = C.val[C_p] + (A.val[A_p] + B.val[B_p])
                                C.idx[C_p] = i_16
                                A_p += 1
                                A_i0 = A_i1 + 1
                                A_i1 = A.idx[A_p]
                                B_p += 1
                                B_i0 = B_i1 + 1
                                B_i1 = B.idx[B_p]
                            elseif B_i1 == phase_stop_6
                                i_17 = phase_stop_6
                                push!(C.idx, C_I)
                                push!(C.val, zero(Float64))
                                C_p += 1
                                C.val[C_p] = C.val[C_p] + B.val[B_p]
                                C.idx[C_p] = i_17
                                B_p += 1
                                B_i0 = B_i1 + 1
                                B_i1 = B.idx[B_p]
                            elseif A_i1 == phase_stop_6
                                i_18 = phase_stop_6
                                push!(C.idx, C_I)
                                push!(C.val, zero(Float64))
                                C_p += 1
                                C.val[C_p] = C.val[C_p] + A.val[A_p]
                                C.idx[C_p] = i_18
                                A_p += 1
                                A_i0 = A_i1 + 1
                                A_i1 = A.idx[A_p]
                            else
                            end
                            i = phase_stop_6 + 1
                        end
                    end
                end
                i = phase_stop + 1
            end
        end
        (C = C,)
    end
