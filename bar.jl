using Finch

A = @fiber(d(sl(e(0.0))))
x = @fiber(d(e(0.0)))
y = @fiber(d(e(0.0)))

prgm = Finch.@finch_program_instance begin
    y .= 0
    @loop j i y[i] += A[gallop(i), j] * x[j]
end

println(Finch.virtualize(:prgm, typeof(prgm), Finch.LowerJulia()))