using Finch

A = @fiber(d(sl(e(0.0))))
x = @fiber(d(e(0.0)))
y = @fiber(d(e(0.0)))

#prgm = Finch.@finch_program_instance begin
Finch.@finch begin
    y .= 0
    for j = parallel(_)
        for i = _
            y[i] += A[walk(i), j] * x[j]
        end
    end
end

#debug the program

#debug = Finch.begin_debug(prgm)
