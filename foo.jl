using Finch

y = @fiber d(e(0.0))
A = @fiber d(sl(e(0.0)))
x = @fiber sl(e(0.0))
println(@finch_code begin
    @loop j i y[i] += A[i, j] * x[j]
end)
