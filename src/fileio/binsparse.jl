"""
    bswrite(filename, tns)

Write the Finch fiber to a file using 
[Binsparse](https://github.com/GraphBLAS/binsparse-specification) HDF5 file
format.

[HDF5](https://github.com/JuliaIO/HDF5.jl) must be loaded for this function to be available

!!! warning
    The Binsparse spec is under development. Additionally, this function may not
    be fully conformant. Please file bug reports if you see anything amiss.
"""
function bswrite end

"""
    bsread(filename)

Read the [Binsparse](https://github.com/GraphBLAS/binsparse-specification) HDF5 file into a Finch tensor.

[HDF5](https://github.com/JuliaIO/HDF5.jl) must be loaded for this function to be available

!!! warning
    The Binsparse spec is under development. Additionally, this function may not
    be fully conformant. Please file bug reports if you see anything amiss.
"""
function bsread end