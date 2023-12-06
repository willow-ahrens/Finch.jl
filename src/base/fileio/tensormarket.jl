"""
    fttxwrite(filename, tns)

Write a sparse Finch fiber to a TensorMarket file.
    
[TensorMarket](https://github.com/willow-ahrens/TensorMarket.jl) must be loaded for this function to be available.

See also: [ttwrite](http://willowahrens.io/TensorMarket.jl/stable/#TensorMarket.ttwrite)
"""
fttwrite(args...) = throw(FinchExtensionError("TensorMarket.jl must be loaded to use fttxwrite (hint: `using TensorMarket`)"))

"""
    fttxread(filename, infoonly=false, retcoord=false)

Read the TensorMarket file into a Finch fiber. The fiber will be dense or
COO depending on the format of the file.

[TensorMarket](https://github.com/willow-ahrens/TensorMarket.jl) must be loaded for this function to be available.

See also: [ttread](http://willowahrens.io/TensorMarket.jl/stable/#TensorMarket.ttread)
"""
fttread(args...) = throw(FinchExtensionError("TensorMarket.jl must be loaded to use fttxread (hint: `using TensorMarket`)"))

"""
    ftnswrite(filename, tns)

Write a sparse Finch fiber to a FROSTT `.tns` file.

[TensorMarket](https://github.com/willow-ahrens/TensorMarket.jl) must be loaded for this function to be available.
 
!!! danger
    This file format does not record the size or eltype of the tensor, and is provided for
    archival purposes only.

See also: [tnswrite](http://willowahrens.io/TensorMarket.jl/stable/#TensorMarket.tnswrite)
"""
ftnswrite(args...) = throw(FinchExtensionError("TensorMarket.jl must be loaded to use ftnswrite (hint: `using TensorMarket`)"))

"""
    ftnsread(filename)

Read the contents of the FROSTT `.tns` file 'filename' into a Finch COO Fiber.

[TensorMarket](https://github.com/willow-ahrens/TensorMarket.jl) must be loaded for this function to be available.

!!! danger
    This file format does not record the size or eltype of the tensor, and is provided for
    archival purposes only.

See also: [tnsread](http://willowahrens.io/TensorMarket.jl/stable/#TensorMarket.tnsread)
"""
ftnsread() = throw(FinchExtensionError("TensorMarket.jl must be loaded to use ftnsread (hint: `using TensorMarket`)"))
