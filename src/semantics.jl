

"""
    getunbound(stmt)

Return an iterator over the names in an index expression that have yet to be
bound.
```julia
julia> getunbound(@finch_program @loop i :a[i, j] += 2)
[j]
julia> getunbound(@finch_program i + j * 2 * i)
[i, j]
```
"""
getunbound(ex) = istree(ex) ? mapreduce(getunbound, union, arguments(ex), init=[]) : []

"""
    getname(ex)

Return the name of the index expression `ex`. The name serves as a unique
identifier and often corresponds to the variable name which holds a tensor.
Tensors can have the same name only if they are `===` to each other. The names
of indices are used to distinguish the loops they reference.

#TODO this function shouldn't exist
"""
function getname end

"""
    setname(ex, name)

Return a new expression, identical to `ex`, with the name `name`.
"""
function setname end

"""
    default(fbr)

The default for a fiber is the value that each element of the fiber will have
after initialization. This value is most often zero, and defaults to nothing.

See also: [`declare!`](@ref)
"""
function default end