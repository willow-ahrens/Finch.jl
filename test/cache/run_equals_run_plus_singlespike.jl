@inbounds begin
        C = ex.body.lhs.tns.tns
        A = (ex.body.rhs.args[1]).tns.tns
        B = (ex.body.rhs.args[2]).tns.tns
        C_stop = ((size)(C))[1]
        A_stop = ((size)(A))[1]
        B_stop = ((size)(B))[1]
        i_stop = C_stop
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
        while i <= i_stop - 1
            i_start = i
            phase_stop = (min)(A_i1, i_stop - 1)
            i = i
            if A_i1 == phase_stop
                push!(C.val, zero(Float64))
                C_p += 1
                C.val[C_p] = (+)(C.val[C_p], A.val[A_p])
                push!(C.idx, phase_stop)
                if A_p < length(A.idx)
                    A_p += 1
                    A_i1 = A.idx[A_p]
                end
            else
                push!(C.val, zero(Float64))
                C_p += 1
                C.val[C_p] = (+)(C.val[C_p], A.val[A_p])
                push!(C.idx, phase_stop)
            end
            i = phase_stop + 1
        end
        i = i_stop
        A_p = searchsortedfirst(A.idx, i_stop, A_p, length(A.idx), Base.Forward)
        A_i1 = A.idx[A_p]
        i_start_2 = i
        phase_stop_2 = (min)(A_i1, i_stop)
        i_2 = i
        if A_i1 == phase_stop_2
            push!(C.val, zero(Float64))
            C_p += 1
            C.val[C_p] = (+)(C.val[C_p], (+)(A.val[A_p], B.tail))
            push!(C.idx, phase_stop_2)
            if A_p < length(A.idx)
                A_p += 1
                A_i1 = A.idx[A_p]
            end
        else
            push!(C.val, zero(Float64))
            C_p += 1
            C.val[C_p] = (+)(C.val[C_p], (+)(A.val[A_p], B.tail))
            push!(C.idx, phase_stop_2)
        end
        i = phase_stop_2 + 1
        (C = C,)
    end
