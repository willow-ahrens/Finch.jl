using Finch
using SparseArrays
display(fiber(sprand(100, 0.5)))
display(fiber(sprand(100, 100, 0.5)))
display(fiber(rand(100, 100)))
display(fiber(rand(100, 100)))
display(fiber(rand(10, 10, 10)))