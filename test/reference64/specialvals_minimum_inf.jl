begin
    x = ex.body.lhs.tns.tns
    x_val = x.val
    yf_lvl = ex.body.rhs.tns.tns.lvl
    yf_lvl_2 = yf_lvl.lvl
    yf_lvl_q = yf_lvl.ptr[1]
    yf_lvl_q_stop = yf_lvl.ptr[1 + 1]
    if yf_lvl_q < yf_lvl_q_stop
        yf_lvl_i1 = yf_lvl.idx[yf_lvl_q_stop - 1]
    else
        yf_lvl_i1 = 0
    end
    phase_stop = min(yf_lvl_i1, yf_lvl.shape)
    if phase_stop >= 1
        i = 1
        if yf_lvl.idx[yf_lvl_q] < 1
            yf_lvl_q = scansearch(yf_lvl.idx, 1, yf_lvl_q, yf_lvl_q_stop - 1)
        end
        while i <= phase_stop
            yf_lvl_i = yf_lvl.idx[yf_lvl_q]
            phase_stop_2 = min(phase_stop, yf_lvl_i)
            if phase_stop_2 >= i
                if yf_lvl_i == phase_stop_2
                    yf_lvl_2_val_2 = yf_lvl_2.val[yf_lvl_q]
                    x_val = min(yf_lvl_2_val_2, x_val)
                    yf_lvl_q += 1
                end
                i = phase_stop_2 + 1
            end
        end
    end
    (x = (Scalar){Inf, Float64}(x_val),)
end
