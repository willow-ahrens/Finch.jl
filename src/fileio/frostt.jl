"""
    ftnswrite(filename, tns)

Write a sparse Finch fiber to a FROSTT `.tns` file.

!!! danger
    This file format does not record the size or eltype of the tensor, and is provided for
    archival purposes only.

See also: [tnswrite](@ref)
"""
function ftnswrite(filename, A)
    tnswrite(filename, ffindnz(A)...)
end

"""
    ftnsread(filename)

Read the contents of the FROSTT `.tns` file 'filename' into a Finch COO Fiber.

!!! danger
    This file format does not record the size or eltype of the tensor, and is provided for
    archival purposes only.

See also: [tnsread](@ref)
"""
function ftnsread(filename)
    fsparse(tnsread(filename)...)
end

"""
    tnsread(filename)

Read the contents of the FROSTT `.tns` file 'filename' into a sparse
coordinate list.

Coordinate lists are returned as a tuple of arrays (analogous to `findnz()`)
```
    ((row_coordinates, column_coordinates, ...), values)
````

This format assumes the size of the tensor equals its maximum coordinate in each
dimension.

See also: [`tnswrite`](@ref)
"""
function tnsread(fname)
    I = nothing
    V = Any[]
    for line in readlines(fname)
        if length(line) > 1
            line = split(line, "#")[1]
            entries = split(line)
            if length(entries) >= 1
                if isnothing(I)
                    I = ((Int[] for _ in 1:length(entries) - 1)...,)
                end
                for (n, e) in enumerate(entries[1:end-1])
                    push!(I[n], parse(Int, e))
                end
                push!(V, something(
                    tryparse(Bool, entries[end]),
                    tryparse(Int, entries[end]),
                    tryparse(Float64, entries[end]),
                    tryparse(Complex{Int}, entries[end]),
                    tryparse(Complex{Float64}, entries[end])
                ))
            end
        end
    end
    if isnothing(I)
        I = ()
    end
    return (I, map(identity, V))
end

"""
    tnswrite(filename, (I_1, I_2, ...), V)

Write sparse tensor coordinates to file 'filename' in FROSTT `.tns` format.

Coordinate lists are specified as a tuple of arrays (analogous to `findnz()`)
```
    (I, V) = (row_coordinates, column_coordinates, ...), values)
````

This format assumes the size of the tensor equals its maximum coordinate in each
dimension.

See also: [`tnsread`](@ref)
"""
function tnswrite(fname, I, V)
    open(fname, "w") do io
        for (crd, val) in zip(zip(I...), V)
            write(io, join(crd, " "))
            write(io, " ")
            if val isa Bool
                val = Int(val)
            end
            write(io, repr(val))
            write(io, "\n")
        end
    end
end