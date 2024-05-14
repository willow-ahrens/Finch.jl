function spgemm_inner(A, B)
    z = fill_value(A) * fill_value(B) + false
    C = Tensor(Dense(SparseList(Element(z))))
    w = Tensor(SparseDict(SparseDict(Element(z))))
    AT = Tensor(Dense(SparseList(Element(z))))
    @finch mode=:fast (w .= 0; for k=_, i=_; w[k, i] = A[i, k] end)
    @finch mode=:fast (AT .= 0; for i=_, k=_; AT[k, i] = w[k, i] end)
    @finch (C .= 0; for j=_, i=_, k=_; C[i, j] += AT[k, i] * B[k, j] end)
    return C
end

function spgemm_outer(A, B)
    z = fill_value(A) * fill_value(B) + false
    C = Tensor(Dense(SparseList(Element(z))))
    w = Tensor(SparseDict(SparseDict(Element(z))))
    BT = Tensor(Dense(SparseList(Element(z))))
    @finch mode=:fast (w .= 0; for j=_, k=_; w[j, k] = B[k, j] end)
    @finch (BT .= 0; for k=_, j=_; BT[j, k] = w[j, k] end)
    @finch (w .= 0; for k=_, j=_, i=_; w[i, j] += A[i, k] * BT[j, k] end)
    @finch (C .= 0; for j=_, i=_; C[i, j] = w[i, j] end)
    return C
end

function spgemm_gustavson(A, B)
    z = fill_value(A) * fill_value(B) + false
    C = Tensor(Dense(SparseList(Element(z))))
    w = Tensor(SparseByteMap(Element(z)))
    @finch begin
        C .= 0
        for j=_
            w .= 0
            for k=_, i=_; w[i] += A[i, k] * B[k, j] end
            for i=_; C[i, j] = w[i] end
        end
    end
    return C
end