module HDF5Ext

    using Finch
    using Finch.JSON

    isdefined(Base, :get_extension) ? (using HDF5) : (using ..HDF5)

    include("binsparse.jl")
    include("fiberio.jl")
end