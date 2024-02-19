"""
    getunbound(stmt)

Return an iterator over the indices in a Finch program that have yet to be bound.
```julia
julia> getunbound(@finch_program for i=_; :a[i, j] += 2 end)
[j]
julia> getunbound(@finch_program i + j * 2 * i)
[i, j]
```
"""
getunbound(ex) = istree(ex) ? mapreduce(getunbound, union, arguments(ex), init=[]) : []

function getunbound(ex::FinchNode)
    if ex.kind === index
        return [ex]
    elseif @capture ex call(d, ~idx...)
        return []
    elseif ex.kind === loop
        return setdiff(union(getunbound(ex.body), getunbound(ex.ext)), getunbound(ex.idx))
    elseif istree(ex)
        return mapreduce(Finch.getunbound, union, arguments(ex), init=[])
    else
        return []
    end
end
