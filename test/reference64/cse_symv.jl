begin
    y_lvl = (ex.body.body.bodies[1]).lhs.tns.bind.lvl
    y_lvl_2 = y_lvl.lvl
    y_lvl_val = y_lvl.lvl.val
    A_lvl = ((ex.body.body.bodies[1]).rhs.args[1]).tns.bind.lvl
    A_lvl_2 = A_lvl.lvl
    A_lvl_2_val = A_lvl_2.lvl.val
    x_lvl = ((ex.body.body.bodies[1]).rhs.args[2]).tns.bind.lvl
    x_lvl_val = x_lvl.lvl.val
    y_lvl.shape == A_lvl_2.shape || throw(DimensionMismatch("mismatched dimension limits ($(y_lvl.shape) != $(A_lvl_2.shape))"))
    x_lvl.shape == A_lvl.shape || throw(DimensionMismatch("mismatched dimension limits ($(x_lvl.shape) != $(A_lvl.shape))"))
    y_lvl.shape == x_lvl.shape || throw(DimensionMismatch("mismatched dimension limits ($(y_lvl.shape) != $(x_lvl.shape))"))
    y_lvl.shape == x_lvl.shape || throw(DimensionMismatch("mismatched dimension limits ($(y_lvl.shape) != $(x_lvl.shape))"))
    @warn "Performance Warning: non-concordant traversal of A[i, j] (hint: most arrays prefer column major or first index fast, run in fast mode to ignore this warning)"
    for i_6 = 1:y_lvl.shape
        y_lvl_q = (1 - 1) * y_lvl.shape + i_6
        x_lvl_q_2 = (1 - 1) * x_lvl.shape + i_6
        x_lvl_2_val = x_lvl_val[x_lvl_q_2]
        for j_6 = 1:y_lvl.shape
            A_lvl_q = (1 - 1) * A_lvl.shape + j_6
            x_lvl_q = (1 - 1) * x_lvl.shape + j_6
            y_lvl_q_2 = (1 - 1) * y_lvl.shape + j_6
            x_lvl_2_val_2 = x_lvl_val[x_lvl_q]
            A_lvl_2_q = (A_lvl_q - 1) * A_lvl_2.shape + i_6
            A_lvl_3_val = A_lvl_2_val[A_lvl_2_q]
            y_lvl_val[y_lvl_q] = y_lvl_val[y_lvl_q] + A_lvl_3_val * x_lvl_2_val_2
            y_lvl_val[y_lvl_q_2] = A_lvl_3_val * x_lvl_2_val + y_lvl_val[y_lvl_q_2]
        end
    end
    resize!(y_lvl_val, y_lvl.shape)
    (y = Tensor((DenseLevel){Int64}(y_lvl_2, y_lvl.shape)),)
end
