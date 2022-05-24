"""
    getresults(stmt)

Return an iterator over the result tensors of an index expression. For example,
`where` statements return the results of the consumer, not the producer, and
assignments return their left hand sides.
"""
function getresults end

"""
    getunbound(stmt)

Return an iterator over the names in an index expression that have yet to be
bound.
```julia
julia> getunbound(@index_program @loop i :a[i, j] += 2)
[j]
julia> getunbound(@index_program i + j * 2 * i)
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
"""
function getname end

"""
    setname(ex, name)

Return a new expression, identical to `ex`, with the name `name`.
"""
function setname end

"""
    isliteral(ex)

Return a boolean indicating whether the expression is a literal. If an
expression is a literal, `getvalue(ex)` should return the literal value it
corresponds to. `getvalue` defaults to the identity.

See also: [`getvalue`](@ref)
"""
isliteral(ex) = true

"""
    getvalue(ex)

If `isliteral(ex)` is `true`, return the value of `ex`. Defaults to
the identity.

See also: [`isliteral`](@ref)
"""
getvalue(ex) = ex