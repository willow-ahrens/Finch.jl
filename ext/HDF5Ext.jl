module HDF5Ext

using Finch
using Finch.JSON

isdefined(Base, :get_extension) ? (using HDF5) : (using ..HDF5)

function Finch.bspread_h5(fname)
    h5open(fname, "r") do io
        Finch.bspread_tensor(io)
    end
end

function Finch.bspwrite_h5(fname, arr, attrs = Dict())
    h5open(fname, "w") do io
        Finch.bspwrite_tensor(io, arr, attrs)
    end
    fname
end

end