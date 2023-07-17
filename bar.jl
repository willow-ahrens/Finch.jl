using Finch

A = @fiber(d(sl(e(0.0))))
x = @fiber(d(e(0.0)))
y = @fiber(d(e(0.0)))

println(@finch_code begin
    y .= 0
    for tid = _
        for j = _
            if multicoremask(4)[tid, j]
                for i = _
                    y[i] += A[walk(i), j] * x[j]
                end
            end
        end
    end
end)
