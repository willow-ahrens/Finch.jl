"""
    ttxwrite(filename, tns)

Write a sparse Finch fiber to a TensorMarket file.
    
[TensorMarket](https://github.com/willow-ahrens/TensorMarket.jl) must be loaded for this function to be available.

See also: [ttwrite](http://willowahrens.io/TensorMarket.jl/stable/#TensorMarket.ttwrite)
"""
function ttxwrite end

"""
    ttxread(filename, infoonly=false, retcoord=false)

Read the TensorMarket file into a Finch fiber. The fiber will be dense or
COO depending on the format of the file.

[TensorMarket](https://github.com/willow-ahrens/TensorMarket.jl) must be loaded for this function to be available.

See also: [ttread](http://willowahrens.io/TensorMarket.jl/stable/#TensorMarket.ttread)
"""
function ttxread end

"""
    tnswrite(filename, tns)

Write a sparse Finch fiber to a FROSTT `.tns` file.

[TensorMarket](https://github.com/willow-ahrens/TensorMarket.jl) must be loaded for this function to be available.
 
!!! danger
    This file format does not record the size or eltype of the tensor, and is provided for
    archival purposes only.

See also: [tnswrite](http://willowahrens.io/TensorMarket.jl/stable/#TensorMarket.tnswrite)
"""
function tnswrite end

"""
    tnsread(filename)

Read the contents of the FROSTT `.tns` file 'filename' into a Finch COO Fiber.

[TensorMarket](https://github.com/willow-ahrens/TensorMarket.jl) must be loaded for this function to be available.

!!! danger
    This file format does not record the size or eltype of the tensor, and is provided for
    archival purposes only.

See also: [tnsread](http://willowahrens.io/TensorMarket.jl/stable/#TensorMarket.tnsread)
"""
function tnsread end

"""
    bspwrite(filename, tns)

Write the Finch fiber to a file using 
[Binsparse](https://github.com/GraphBLAS/binsparse-specification) HDF5 file
format.

[HDF5](https://github.com/JuliaIO/HDF5.jl) must be loaded for this function to be available

!!! warning
    The Binsparse spec is under development. Additionally, this function may not
    be fully conformant. Please file bug reports if you see anything amiss.
"""
function bspwrite end

"""
    bspread(filename)

Read the [Binsparse](https://github.com/GraphBLAS/binsparse-specification) HDF5 file into a Finch tensor.

[HDF5](https://github.com/JuliaIO/HDF5.jl) must be loaded for this function to be available

!!! warning
    The Binsparse spec is under development. Additionally, this function may not
    be fully conformant. Please file bug reports if you see anything amiss.
"""
function bspread end