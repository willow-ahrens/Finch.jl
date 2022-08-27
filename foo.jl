using Finch
A = fsprand((20,), 0.4)
B = @fiber sv(e(0.0))
@finch @loop i B[i] = A[i]
C = @fiber sl(e(0.0))
D = copyto!(@fiber(sl(e(0.0))), fsprand((20,), 0.4))
@finch @loop i C[i] = B[i::gallop] + D[i]
display(A)
display(D)
display(C)