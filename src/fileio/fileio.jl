"""
    fwrite(filename::AbstractString, tns::Finch.Fiber)

Write the Finch fiber to a file using a file format determined by the file extension.
The following file extensions are supported:

- `.tns`: FROSTT `.tns` text file format
- `.ttx`: TensorMarket `.ttx` text file format
- `.bsp.h5`: [Binsparse](https://github.com/GraphBLAS/binsparse-specification) HDF5 file format
- `.bsp.npyd`: [Binsparse](https://github.com/GraphBLAS/binsparse-specification) NumPy and JSON subdirectory format
"""
function fwrite(filename::AbstractString, tns)
    if endswith(filename, ".tns")
        ftnswrite(filename, tns)
    elseif endswith(filename, ".ttx")
        fttwrite(filename, tns)
    elseif endswith(filename, ".bsp.h5")
        bspwrite(filename, tns)
    elseif endswith(filename, ".bsp.npyd")
        bspwrite(filename, tns)
    else
        error("Unknown file extension for file $filename")
    end
end

"""
    fread(filename::AbstractString)

Read the Finch fiber from a file using a file format determined by the file extension.
The following file extensions are supported:

- `.tns`: FROSTT `.tns` text file format
- `.ttx`: TensorMarket `.ttx` text file format
- `.bsp.h5`: [Binsparse](https://github.com/GraphBLAS/binsparse-specification) HDF5 file format
- `.bsp.npyd`: [Binsparse](https://github.com/GraphBLAS/binsparse-specification) NumPy and JSON subdirectory format
"""
function fread(filename::AbstractString)
    if endswith(filename, ".tns")
        ftnsread(filename)
    elseif endswith(filename, ".ttx")
        fttread(filename)
    elseif endswith(filename, ".bsp.h5")
        bspread(filename)
    elseif endswith(filename, ".bsp.npyd")
        bspread(filename)
    else
        error("Unknown file extension for file $filename")
    end
end

include("binsparse.jl")
include("tensormarket.jl")