# 
# It's easy to generate sparse code with Finch, give it a try!
# 
# A note to visitors using Binder: it may take a minute or
# two to compile the first kernel, perhaps enjoy a nice little coffee break ^.^
#

using Finch

A = fsprand((10, 10), 0.5)

x = rand(10)
y = rand(10)

@finch_code begin
    for i = _, j = _
        y[i] += A[i, j] * x[j]
    end
end
