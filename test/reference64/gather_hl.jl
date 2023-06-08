begin
    B = ex.lhs.tns.tns
    B_val = B.val
    A_lvl = ex.rhs.tns.tns.lvl
    A_lvl_2 = A_lvl.lvl
    B_val = (Fiber((SparseListLevel){Int64, Int64}(A_lvl_2, A_lvl.shape, A_lvl.ptr, A_lvl.idx)))[5] + B_val
    (B = (Scalar){0.0, Float64}(B_val),)
end
