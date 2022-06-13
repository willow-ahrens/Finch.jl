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
            i_step = min(max(A_i1, B_i1), A_stop)
            if i_step == A_i1 && i_step == B_i1
                i = i_step
                push!(C.idx, C_I)
                push!(C.val, zero(Float64))
                C_p += 1
                C.val[C_p] = C.val[C_p] + (A.val[A_p] + B.val[B_p])
                C.idx[C_p] = i
                A_p += 1
                A_i0 = A_i1 + 1
                A_i1 = A.idx[A_p]
                B_p += 1
                B_i0 = B_i1 + 1
                B_i1 = B.idx[B_p]
            elseif i_step == B_i1
                i_start_2 = i_start
                while i_start_2 <= i_step - 1
                    i_step_2 = min(A_i1, i_step - 1)
                    if i_step_2 < A_i1
                    else
                        i_2 = i_step_2
                        push!(C.idx, C_I)
                        push!(C.val, zero(Float64))
                        C_p += 1
                        C.val[C_p] = C.val[C_p] + A.val[A_p]
                        C.idx[C_p] = i_2
                        A_p += 1
                        A_i0 = A_i1 + 1
                        A_i1 = A.idx[A_p]
                    end
                    i_start_2 = i_step_2 + 1
                end
                i_start_3 = i_step
                if i_start_3 < A_i1
                    i_3 = i_step
                    push!(C.idx, C_I)
                    push!(C.val, zero(Float64))
                    C_p += 1
                    C.val[C_p] = C.val[C_p] + B.val[B_p]
                    C.idx[C_p] = i_3
                else
                    i_4 = i_step
                    push!(C.idx, C_I)
                    push!(C.val, zero(Float64))
                    C_p += 1
                    C.val[C_p] = C.val[C_p] + (A.val[A_p] + B.val[B_p])
                    C.idx[C_p] = i_4
                    A_p += 1
                    A_i0 = A_i1 + 1
                    A_i1 = A.idx[A_p]
                end
                B_p += 1
                B_i0 = B_i1 + 1
                B_i1 = B.idx[B_p]
            elseif i_step == A_i1
                i_start_4 = i_start
                while i_start_4 <= i_step - 1
                    i_step_3 = min(B_i1, i_step - 1)
                    if i_step_3 < B_i1
                    else
                        i_5 = i_step_3
                        push!(C.idx, C_I)
                        push!(C.val, zero(Float64))
                        C_p += 1
                        C.val[C_p] = C.val[C_p] + B.val[B_p]
                        C.idx[C_p] = i_5
                        B_p += 1
                        B_i0 = B_i1 + 1
                        B_i1 = B.idx[B_p]
                    end
                    i_start_4 = i_step_3 + 1
                end
                i_start_5 = i_step
                if i_start_5 < B_i1
                    i_6 = i_step
                    push!(C.idx, C_I)
                    push!(C.val, zero(Float64))
                    C_p += 1
                    C.val[C_p] = C.val[C_p] + A.val[A_p]
                    C.idx[C_p] = i_6
                else
                    i_7 = i_step
                    push!(C.idx, C_I)
                    push!(C.val, zero(Float64))
                    C_p += 1
                    C.val[C_p] = C.val[C_p] + (A.val[A_p] + B.val[B_p])
                    C.idx[C_p] = i_7
                    B_p += 1
                    B_i0 = B_i1 + 1
                    B_i1 = B.idx[B_p]
                end
                A_p += 1
                A_i0 = A_i1 + 1
                A_i1 = A.idx[A_p]
            else
                i_start_6 = i_start
                while i_start_6 <= i_step
                    i_step_4 = min(A_i1, B_i1, i_step)
                    if i_step_4 < A_i1 && i_step_4 < B_i1
                    elseif i_step_4 < B_i1
                        i_8 = i_step_4
                        push!(C.idx, C_I)
                        push!(C.val, zero(Float64))
                        C_p += 1
                        C.val[C_p] = C.val[C_p] + A.val[A_p]
                        C.idx[C_p] = i_8
                        A_p += 1
                        A_i0 = A_i1 + 1
                        A_i1 = A.idx[A_p]
                    elseif i_step_4 < A_i1
                        i_9 = i_step_4
                        push!(C.idx, C_I)
                        push!(C.val, zero(Float64))
                        C_p += 1
                        C.val[C_p] = C.val[C_p] + B.val[B_p]
                        C.idx[C_p] = i_9
                        B_p += 1
                        B_i0 = B_i1 + 1
                        B_i1 = B.idx[B_p]
                    else
                        i_10 = i_step_4
                        push!(C.idx, C_I)
                        push!(C.val, zero(Float64))
                        C_p += 1
                        C.val[C_p] = C.val[C_p] + (A.val[A_p] + B.val[B_p])
                        C.idx[C_p] = i_10
                        A_p += 1
                        A_i0 = A_i1 + 1
                        A_i1 = A.idx[A_p]
                        B_p += 1
                        B_i0 = B_i1 + 1
                        B_i1 = B.idx[B_p]
                    end
                    i_start_6 = i_step_4 + 1
                end
            end
            i_start = i_step + 1
        end
        (C = C,)
    end
