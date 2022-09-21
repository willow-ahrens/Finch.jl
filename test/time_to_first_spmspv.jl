using Finch
y = @fiber d(e(0.0))
A = @fiber d(sl(e(0.0)))
x = @fiber sl(e(0.0))

first_run = @elapsed Finch.execute_code(:ex, typeof(Finch.@finch_program_instance @loop i j y[i] += A[i, j] * x[i]))
second_run = @elapsed Finch.execute_code(:ex, typeof(Finch.@finch_program_instance @loop i j y[i] += A[i, j] * x[i]))

using MethodAnalysis
using RewriteTools

finch_methods = length(methodinstances(Finch))
rewrite_methods = length(methodinstances(RewriteTools))

@info "results" first_run second_run finch_methods rewrite_methods
# With no precompilation or anything, this takes 71.272644599s on my garbage macbookpro
# With precompilation, this takes 48.013980111s on my garbage macbookpro
# With precompilation and removing excess style computations, this takes 45.323332916s on my garbage macbookpro
# After making arrays more reliably Any, this takes 44.811293213
# After deparameterizing Access and removing unresolve:
#┌ Info: results
#│   first_run = 39.680086167
#│   second_run = 0.138437737
#│   finch_methods = 994
#└   rewrite_methods = 1612
