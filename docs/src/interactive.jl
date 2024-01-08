# 
# An example generating sparse code with Finch, make some changes and give it a try!
# 
# A note to visitors using Binder: it may take a minute or
# two to compile the first kernel, perhaps enjoy a nice little coffee break ^.^
#

using Finch

## Construct a CSR sparse input matrix (20% random nonzeros)
A = Fiber(Dense(SparseList(Element(0.0))), fsprand(5, 7, 0.2))

## Construct a dense vector input and output (all random values)
x = rand(7)
y = rand(5)

## Emit code for matrix-vector multiply y = A * x
@finch_code begin
    for j = _, i = _
        y[i] += A[i, j] * x[j]
    end
end
