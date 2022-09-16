using Finch
using Profile
using ProfileView
y = @fiber d(e(0.0))
A = @fiber d(sl(e(0.0)))
x = @fiber sl(e(0.0))
println(@elapsed Finch.execute_code(:ex, typeof(Finch.@finch_program_instance @loop i j y[i] += A[i, j] * x[i])))
# With no precompilation or anything, this takes 71.272644599s on my garbage macbookpro
# With precompilation, this takes 48.013980111s on my garbage macbookpro
# With precompilation and removing excess style computations, this takes 45.323332916s on my garbage macbookpro
# After making arrays more reliably Any, this takes 44.811293213, 7m09.5s to run tests
# Without calling unresolve, this is 49.808295968, somehow?
# If we never call RewriteTools, this would take 24.325700075s