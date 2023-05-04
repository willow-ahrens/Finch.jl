module HDF5Ext

    using Finch
    using Finch.JSON

    isdefined(Base, :get_extension) ? (using SparseArrays) : (using ..SparseArrays)

    include("binsparse.jl")
    include("fiberio.jl")
end