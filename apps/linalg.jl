function spgemm_inner(A, B)
    z = default(A) * default(B) + false
    C = Fiber!(Dense(SparseList(Element(z))))
    w = Fiber!(SparseHash{2}(Element(z)))
    AT = Fiber!(Dense(SparseList(Element(z))))
    @finch mode=finchfast (w .= 0; for k=_, i=_; w[k, i] = A[i, k] end)
    @finch mode=finchfast (AT .= 0; for i=_, k=_; AT[k, i] = w[k, i] end)
    @finch (C .= 0; for j=_, i=_, k=_; C[i, j] += AT[k, i] * B[k, j] end)
    return C
end

function spgemm_outer(A, B)
    z = default(A) * default(B) + false
    C = Fiber!(Dense(SparseList(Element(z))))
    w = Fiber!(SparseHash{2}(Element(z)))
    BT = Fiber!(Dense(SparseList(Element(z))))
    @finch (w .= 0; for j=_, k=_; w[j, k] = B[k, j] end)
    @finch (BT .= 0; for k=_, j=_; BT[j, k] = w[j, k] end)
    @finch (w .= 0; for k=_, i=_, j=_; w[i, j] += A[i, k] * BT[j, k] end)
    @finch (C .= 0; for j=_, i=_; C[i, j] = w[i, j] end)
    return C
end

function spgemm_gustavson(A, B)
    z = default(A) * default(B) + false
    C = Fiber!(Dense(SparseList(Element(z))))
    w = Fiber!(SparseByteMap(Element(z)))
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