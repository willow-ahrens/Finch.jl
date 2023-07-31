function spgemm_inner(A, B)
    z = default(A) * default(B) + false
    C = Fiber!(Dense(SparseList(Element(z))))
    w = Fiber!(SparseHash{2}(Element(z)))
    AT = Fiber!(Dense(SparseList(Element(z))))
    @finch (w .= 0; @loop k i w[k, i] = A[i, k])
    @finch (AT .= 0; @loop i k AT[k, i] = w[k, i])
    @finch (C .= 0; @loop j i k C[i, j] += AT[k, i] * B[k, j])
    return C
end

function spgemm_outer(A, B)
    z = default(A) * default(B) + false
    C = Fiber!(Dense(SparseList(Element(z))))
    w = Fiber!(SparseHash{2}(Element(z)))
    BT = Fiber!(Dense(SparseList(Element(z))))
    @finch (w .= 0; @loop j k w[j, k] = B[k, j])
    @finch (BT .= 0; @loop k j BT[j, k] = w[j, k])
    @finch (w .= 0; @loop k i j w[i, j] += A[i, k] * BT[j, k])
    @finch (C .= 0; @loop j i C[i, j] = w[i, j])
    return C
end

function spgemm_gustavson(A, B)
    z = default(A) * default(B) + false
    C = Fiber!(Dense(SparseList(Element(z))))
    w = Fiber!(SparseByteMap(Element(z)))
    @finch begin
        C .= 0
        @loop j begin
            w .= 0
            @loop k i w[i] += A[i, k] * B[k, j]
            @loop i C[i, j] = w[i]
        end
    end
    return C
end