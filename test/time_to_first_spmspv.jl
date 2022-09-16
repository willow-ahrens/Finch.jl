using Finch
y = @fiber d(e(0.0))
A = @fiber d(sl(e(0.0)))
x = @fiber sl(e(0.0))
println(@elapsed Finch.execute_code(:ex, typeof(Finch.@finch_program_instance @loop i j y[i] += A[i, j] * x[i])))
# With no precompilation or anything, this takes 71.272644599 on my garbage macbook pro.