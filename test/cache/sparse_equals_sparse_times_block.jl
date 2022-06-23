@inbounds begin
        C = ex.body.lhs.tns.tns
        A = (ex.body.rhs.args[1]).tns.tns
        B = (ex.body.rhs.args[2]).tns.tns
        C_stop = ((size)(C))[1]
        A_stop = ((size)(A))[1]
        B_stop = ((size)(B))[1]
        i_stop = C_stop
        C.idx = [C.idx[end]]
        C.val = (Int64)[]
        C_p = 0
        C_I = i_stop + 1
        C.idx = (Int64)[C_I]
        C.val = (Float64)[]
        B_p = 1
        B_i0 = 1
        B_i1 = B.idx[B_p]
        i = 1
        i_start = i
        phase_start = (max)(i_start)
        phase_stop = (min)(A.start - 1, i_stop)
        if phase_stop >= phase_start
            i = i
            i = phase_stop + 1
        end
        i_start = i
        phase_start_2 = (max)(i_start)
        phase_stop_2 = (min)(i_stop, A.stop)
        if phase_stop_2 >= phase_start_2
            i_2 = i
            i = phase_start_2
            B_p = searchsortedfirst(B.idx, phase_start_2, B_p, length(B.idx), Base.Forward)
            B_i0 = phase_start_2
            B_i1 = B.idx[B_p]
            while i <= phase_stop_2
                i_start_2 = i
                phase_stop_3 = (min)(phase_stop_2, B_i1)
                i_3 = i
                if B_i1 == phase_stop_3
                    i_4 = phase_stop_3
                    push!(C.idx, C_I)
                    push!(C.val, zero(Float64))
                    C_p += 1
                    C.val[C_p] = (+)(C.val[C_p], (*)(A.val[(i_4 - A.start) + 1], B.val[B_p]))
                    C.idx[C_p] = i_4
                    B_p += 1
                    B_i0 = B_i1 + 1
                    B_i1 = B.idx[B_p]
                else
                end
                i = phase_stop_3 + 1
            end
            i = phase_stop_2 + 1
        end
        i_start = i
        phase_start_4 = (max)(i_start)
        phase_stop_4 = (min)(i_stop)
        if phase_stop_4 >= phase_start_4
            i_5 = i
            i = phase_stop_4 + 1
        end
        (C = C,)
    end
