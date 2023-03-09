begin
    x = ex.body.lhs.tns.tns
    x_val = x.val
    yf_lvl = ex.body.rhs.tns.tns.lvl
    yf_lvl_2 = yf_lvl.lvl
    yf_lvl_q = yf_lvl.ptr[1]
    yf_lvl_q_stop = yf_lvl.ptr[1 + 1]
    if yf_lvl_q < yf_lvl_q_stop
        yf_lvl_i = yf_lvl.idx[yf_lvl_q]
        yf_lvl_i1 = yf_lvl.idx[yf_lvl_q_stop - 1]
    else
        yf_lvl_i = 1
        yf_lvl_i1 = 0
    end
    i = 1
    i_start = i
    phase_stop = (min)(yf_lvl_i1, yf_lvl.I)
    if phase_stop >= i_start
        i_3 = i
        i = i_start
        if yf_lvl.idx[yf_lvl_q] < i_start
            yf_lvl_q = scansearch(yf_lvl.idx, i_start, yf_lvl_q, yf_lvl_q_stop - 1)
        end
        while i <= phase_stop
            i_start_2 = i
            yf_lvl_i = yf_lvl.idx[yf_lvl_q]
            phase_stop_2 = (min)(yf_lvl_i, phase_stop)
            i_4 = i
            if yf_lvl_i == phase_stop_2
                x_val = (min)(NaN, x_val)
                yf_lvl_2_val_2 = yf_lvl_2.val[yf_lvl_q]
                i_5 = phase_stop_2
                x_val = (min)(x_val, yf_lvl_2_val_2)
                yf_lvl_q += 1
            else
                x_val = (min)(NaN, x_val)
            end
            i = phase_stop_2 + 1
        end
        i = phase_stop + 1
    end
    i_start = i
    if yf_lvl.I >= i_start
        i_6 = i
        x_val = (min)(NaN, x_val)
        i = yf_lvl.I + 1
    end
    (x = (Scalar){Inf, Float64}(x_val),)
end
