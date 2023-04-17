# 
# An example generating sparse code with Finch, make some changes and give it a try!
# 
# A note to visitors using Binder: it may take a minute or
# two to compile the first kernel, perhaps enjoy a nice little coffee break ^.^
#

using Finch

## Construct a CSR sparse input matrix (20% random nonzeros)
A = @fiber(d(sl(e(0.0))), fsprand((10, 10), 0.2))

## Construct a dense vector input and output (all random values)
x = rand(10)
y = rand(10)

## Emit code for matrix-vector multiply y = A * x
@finch_code begin
    for i = _, j = _
        y[i] += A[i, j] * x[j]
    end
end
