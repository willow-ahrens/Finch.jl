module HDF5Ext

using Finch
using Finch.JSON
using Finch.DataStructures

isdefined(Base, :get_extension) ? (using HDF5) : (using ..HDF5)

function Finch.bspread_h5(fname)
    h5open(fname, "r") do io
        Finch.bspread(io)
    end
end

function Finch.bspwrite_h5(fname, arr, attrs = OrderedDict())
    h5open(fname, "w") do io
        Finch.bspwrite(io, arr, attrs)
    end
    fname
end

Finch.bspread_header(f::HDF5.File, key) = JSON.parse(read(f[key]))
Finch.bspwrite_header(f::HDF5.File, str::String, key) = (f[key] = str)
Finch.bspread_vector(g::HDF5.File, key) = read(g[key])
Finch.bspwrite_vector(g::HDF5.File, vec, key) = (g[key] = vec)

end