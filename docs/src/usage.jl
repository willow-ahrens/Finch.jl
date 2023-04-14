# 
# Hi there this is a test to use Literate.jl for a Finch example

using Finch

A = fsprand((10, 10), 0.5)

x = rand(10)
y = rand(10)

@finch_code begin
    y .= 0
    for i = _, j = _
        y[i] += A[i, j] * x[j]
    end
end


# Well, did this print anything?