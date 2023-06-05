using Finch

A = @fiber(d(sl(e(0.0))))
x = @fiber(d(e(0.0)))
y = @fiber(d(e(0.0)))

display(@finch_code begin
    y .= 0
    @loop j i y[i] += A[i, j] * x[j]
end)