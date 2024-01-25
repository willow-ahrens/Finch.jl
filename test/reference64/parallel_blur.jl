begin
    output_lvl = (ex.bodies[1]).tns.bind.lvl
    output_lvl_2 = output_lvl.lvl
    output_lvl_3 = output_lvl_2.lvl
    output_lvl_2_val = output_lvl_2.lvl.val
    cpu = ((ex.bodies[2]).ext.args[2]).bind
    input_lvl = (((ex.bodies[2]).body.bodies[2]).body.rhs.args[1]).tns.bind.lvl
    input_lvl_2 = input_lvl.lvl
    input_lvl_2_val = input_lvl_2.lvl.val
    1 == 1 + --1 || throw(DimensionMismatch("mismatched dimension limits ($(1) != $(1 + --1))"))
    input_lvl_2.shape == input_lvl_2.shape + --1 || throw(DimensionMismatch("mismatched dimension limits ($(input_lvl_2.shape) != $(input_lvl_2.shape + --1))"))
    input_lvl.shape + -0 == input_lvl.shape || throw(DimensionMismatch("mismatched dimension limits ($(input_lvl.shape + -0) != $(input_lvl.shape))"))
    1 == 1 + -0 || throw(DimensionMismatch("mismatched dimension limits ($(1) != $(1 + -0))"))
    1 == 1 + -1 || throw(DimensionMismatch("mismatched dimension limits ($(1) != $(1 + -1))"))
    input_lvl_2.shape == input_lvl_2.shape + -1 || throw(DimensionMismatch("mismatched dimension limits ($(input_lvl_2.shape) != $(input_lvl_2.shape + -1))"))
    1 == 1 + -0 || throw(DimensionMismatch("mismatched dimension limits ($(1) != $(1 + -0))"))
    y_stop = input_lvl.shape
    pos_stop = input_lvl_2.shape * input_lvl.shape
    Finch.resize_if_smaller!(output_lvl_2_val, pos_stop)
    Finch.fill_range!(output_lvl_2_val, 0.0, 1, pos_stop)
    input_lvl_2_val = moveto(input_lvl_2_val, cpu)
    val_2 = output_lvl_2_val
    output_lvl_2_val = moveto(output_lvl_2_val, cpu)
    Threads.@threads for i = 1:cpu.n
            tmp_lvl_val = moveto(val_3, CPUThread(i, cpu, Serial()))
            phase_start_2 = max(1, 1 + fld(y_stop * (i + -1), cpu.n))
            phase_stop_2 = min(y_stop, fld(y_stop * i, cpu.n))
            if phase_stop_2 >= phase_start_2
                for y_8 = phase_start_2:phase_stop_2
                    input_lvl_q_2 = (1 - 1) * input_lvl.shape + (y_8 + 0)
                    input_lvl_q = (1 - 1) * input_lvl.shape + y_8
                    input_lvl_q_3 = (1 - 1) * input_lvl.shape + (y_8 + 0)
                    output_lvl_q = (1 - 1) * (input_lvl.shape + -0) + y_8
                    Finch.resize_if_smaller!(tmp_lvl_val, input_lvl_2.shape)
                    Finch.fill_range!(tmp_lvl_val, 0, 1, input_lvl_2.shape)
                    for x_9 = 1:input_lvl_2.shape
                        tmp_lvl_q = (1 - 1) * input_lvl_2.shape + x_9
                        input_lvl_2_q = (input_lvl_q_2 - 1) * input_lvl_2.shape + (x_9 + -1)
                        input_lvl_2_q_2 = (input_lvl_q - 1) * input_lvl_2.shape + x_9
                        input_lvl_2_q_3 = (input_lvl_q_3 - 1) * input_lvl_2.shape + (x_9 + 1)
                        input_lvl_3_val = input_lvl_2_val[input_lvl_2_q]
                        input_lvl_3_val_2 = input_lvl_2_val[input_lvl_2_q_2]
                        input_lvl_3_val_3 = input_lvl_2_val[input_lvl_2_q_3]
                        tmp_lvl_val[tmp_lvl_q] = input_lvl_3_val + tmp_lvl_val[tmp_lvl_q] + input_lvl_3_val_2 + input_lvl_3_val_3
                    end
                    for x_10 = 1:input_lvl_2.shape
                        output_lvl_2_q = (output_lvl_q - 1) * input_lvl_2.shape + x_10
                        tmp_lvl_q_2 = (1 - 1) * input_lvl_2.shape + x_10
                        tmp_lvl_2_val = tmp_lvl_val[tmp_lvl_q_2]
                        output_lvl_2_val[output_lvl_2_q] = tmp_lvl_2_val
                    end
                end
            end
        end
    qos = 1 * (input_lvl.shape + -0)
    qos_2 = qos * input_lvl_2.shape
    resize!(val_2, qos_2)
    (output = Tensor((DenseLevel){Int64}((DenseLevel){Int64}(output_lvl_3, input_lvl_2.shape), input_lvl.shape + -0)),)
end
