#=
ttread and ttwrite are modification of:
https://github.com/JuliaSparse/MatrixMarket.jl/blob/5a44fe0a2a29c763f8a20ac1ec8247bf45e6b78d/src/MatrixMarket.jl
Copyright (c) 2013: Viral B. Shah.
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
=#

"""
    fttwrite(filename, tns)

Write a sparse Finch fiber to a TensorMarket file.
    
See also: [ttwrite](@ref)
"""
function fttwrite(filename, A)
    ttwrite(filename, ffindnz(A)..., size(A))
end

"""
    fttread(filename, infoonly=false, retcoord=false)

Read the TensorMarket file into a Finch fiber. The fiber will be dense or
COO depending on the format of the file.

See also: [ttread](@ref)
"""
function fttread(filename, infoonly = false, retcoord=false)
    infoonly && return ttread(filename, true)
    out = ttread(filename, false, retcoord)
    if out isa Tuple
        (I, V, shape, coords...) = out
        A = fsparse(I, V, shape)
        if retcoord
            (A, coords...)
        else
            A
        end
    else
        out
    end
end

struct ParseError
    error :: String
end

_parseint(x) = parse(Int, x)

"""
    ttread(filename, infoonly::Bool=false, retcoord::Bool=false)

Read the contents of the Tensor Market file 'filename' into a sparse
coordinate list or dense array, depending on the Tensor Market format
indicated by 'coordinate' (coordinate sparse storage), or 'array' (dense
array storage).

Coordinate lists are returned as a tuple of arrays (analogous to `findnz()`)
```
    ((row_coordinates, column_coordinates, ...), values, size)
````

If infoonly is true (default: false), only information on the size and
structure is returned from reading the header. The actual data for the
matrix elements are not parsed.

If retcoord is true (default: false), the coordinate and value vectors
are returned, if it is a sparse matrix, along with the header information.

See also: [`ttwrite`](@ref)
"""
function ttread(filename, infoonly::Bool=false, retcoord::Bool=false)
    open(filename,"r") do mmfile
        # Read first line
        firstline = chomp(readline(mmfile))
        tokens = split(firstline)
        if length(tokens) != 5
            throw(ParseError(string("Not enough words on first line: ", firstline)))
        end
        if tokens[1] != "%%MatrixMarket"
            throw(ParseError(string("Expected start of header `%%MatrixMarket`, got `$(tokens[1])`")))
        end
        (head1, rep, field, symm) = map(lowercase, tokens[2:5])
        if (head1 != "matrix" && head1 != "tensor")
            throw(ParseError("Unknown TensorMarket data type: $head1 (only \"matrix\" or \"tensor\" are supported)"))
        end
        if (rep != "coordinate" && rep != "array")
            throw(ParseError("Unknown TensorMarket representation: $rep (only \"coordinate\" or \"array\" are supported)"))
        end

        eltype = field == "real" ? Float64 :
                 field == "complex" ? ComplexF64 :
                 field == "integer" ? Int64 :
                 field == "pattern" ? Bool :
                 throw(ParseError("Unsupported field $field (only real and complex are supported)"))

        if symm != "general"
            throw(ParseError("Unknown TensorMarket symmetry: $symm (only \"general\" is supported)"))
        end

        # Skip all comments and empty lines
        ll   = readline(mmfile)
        while length(chomp(ll))==0 || (length(ll) > 0 && ll[1] == '%')
            ll = readline(mmfile)
        end
        # Read tensor dimensions (and number of entries) from first non-comment line
        dd = map(_parseint, split(ll))
        if length(dd) < 0
            throw(ParseError(string("Could not read in matrix dimensions from line: ", ll)))
        end
        shape = rep == "array" ? (dd...,) : (dd[1:end-1]...,)
        entries = rep == "array" ? prod(shape) : dd[end]
        infoonly && return (shape, entries, rep, field, symm)

        N = length(shape)

        cc = ((Vector{Int}(undef, entries) for _ in shape)...,)
        xx = Vector{eltype}(undef, entries)

        if rep == "array"
            i = 0
            while i < entries
                line = split(readline(mmfile))
                j = 1
                @assert length(line) >= 1
                while j <= length(line)
                    i += 1
                    if eltype == ComplexF64
                        real = parse(Float64, line[j + 0])
                        imag = parse(Float64, line[j + 1])
                        xx[i] = ComplexF64(real, imag)
                        j += 2
                    else
                        xx[i] = parse(eltype, line[j])
                        j += 1
                    end
                    for n in 1:N
                        cc[n][i] = reverse(Tuple(CartesianIndices(reverse(shape))[i]))[n]
                    end
                end
            end
        else
            for i in 1:entries
                line = split(readline(mmfile))
                @assert length(line) >= N
                for n in 1:N
                    cc[n][i] = _parseint(line[n])
                end
                if eltype == ComplexF64
                    @assert length(line) == N + 2
                    real = parse(Float64, line[N + 1])
                    imag = parse(Float64, line[N + 2])
                    xx[i] = ComplexF64(real, imag)
                elseif eltype == Bool
                    @assert length(line) == N
                    xx[i] = true
                else
                    @assert length(line) == N + 1
                    xx[i] = parse(eltype, line[N + 1])
                end
            end
        end

        (retcoord
         ? (cc, xx, shape, entries, rep, field, symm)
         : (cc, xx, shape))
    end
end

"""
    ttwrite(filename, (I_1, I_2, ...), V, size)

Write sparse tensor coordinates to file 'filename' in TensorMarket format.

Coordinate lists are specified as a tuple of arrays (analogous to `findnz()`)
```
    (I, V) = (row_coordinates, column_coordinates, ...), values)
````

See also: [`ttread`](@ref)
"""
function ttwrite(filename, I, V, shape)
    open(filename, "w") do file
    elem = eltype(V) <: Bool ? "pattern" :
           eltype(V) <: Integer ?  "integer" :
           eltype(V) <: AbstractFloat ? "real" :
           eltype(V) <: Complex ? "complex" :
           error("Invalid matrix type")
    sym = "general"

    # write mm header
    write(file, "%%MatrixMarket tensor coordinate $elem $sym\n")

    # write matrix size and number of nonzeros
    write(file, "$(join(shape, " ")) $(length(V))\n")

    for (coord, val) in zip(zip(I...), V)
        write(file, join(coord, " "))
        write(file, " ")
        if elem == "pattern" # omit values on pattern matrices
        elseif elem == "complex"
            write(file, " $(real(val)) $(imag(val))")
        else
            write(file, " $(val)")
        end
        write(file, "\n")
    end
  end
end