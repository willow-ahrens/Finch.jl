"""
Parallelism analysis plan: We will allow automatic paralleization when the following conditions are meet:
All non-locally defined tensors that are written, are only written to with the plain index i in a injective and consistent way and with an associative operator.

all reader or updater accesses on i need to be concurrent (safe to iterate multiple instances of at the same time)

two array axis properties: is_concurrent and is_injective
third properties: is_atomic

You aren't allowed to update a tensor without accessing it with i or marking atomic.

new array: make_atomic
"""


#=
# willow says hello!
for node in PostOrderDFS(prgm)
    if @capture node access(~tns, ~mode, ~idxs..., i)
    if @capture node access(~tns, ~mode, ~idxs...)
=#
