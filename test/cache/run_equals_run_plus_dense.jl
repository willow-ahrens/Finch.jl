@inbounds begin
        C = ex.body.lhs.tns.tns
        A = (ex.body.rhs.args[1]).tns.tns
        B = (ex.body.rhs.args[2]).tns.tns
        C_stop = (size(C))[1]
        A_stop = (size(A))[1]
        (B_mode1_stop,) = size(B)
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
        while i <= i_stop
            i_start = i
            phase_start = max(i_start)
            phase_stop = min(i_stop, A_i1)
            i = i
            if A_i1 == phase_stop
                for i_2 = phase_start:phase_stop
                    push!(C.val, zero(Float64))
                    C_p += 1
                    C.val[C_p] = C.val[C_p] + (A.val[A_p] + B[i_2])
                    push!(C.idx, i_2)
                end
                if A_p < length(A.idx)
                    A_p += 1
                    A_i1 = A.idx[A_p]
                end
            else
                for i_3 = phase_start:phase_stop
                    push!(C.val, zero(Float64))
                    C_p += 1
                    C.val[C_p] = C.val[C_p] + (A.val[A_p] + B[i_3])
                    push!(C.idx, i_3)
                end
            end
            i = phase_stop + 1
        end
        (C = C,)
    end
