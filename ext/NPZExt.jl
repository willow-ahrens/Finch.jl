module NPZExt 

using Finch
using Finch: NPYDGroup
using Finch.JSON
using Finch.DataStructures

isdefined(Base, :get_extension) ? (using NPZ) : (using ..NPZ)

using NPZ

function Base.getindex(g::NPYDGroup, key::AbstractString)
    path = joinpath(g.dirname, key)
    if isfile(key, "$path.npy")
        npyread("$path.npy")
    else
        NPYDGroup(path)
    end
end

Finch.bspwrite_header(g::NPYDGroup, str::String, key) = write(joinpath(mkpath(g.dirname), "$(key).json"), str)
Finch.bspread_header(g::NPYDGroup, str::String, key) = JSON.parsefile(Joinpath(g.dirname, "$key.json"))

Base.setindex!(g::NPYDGroup, val::AbstractArray, key::AbstractString) = npzwrite(joinpath(mkpath(g.dirname), "$(key).npy"), val)
function Base.setindex!(g::NPYDGroup, val::AbstractDict, key::AbstractString)
    for (key_2, val) in val
        setindex!(g[key], val, key_2)
    end
end

function Finch.bspread_npyd(fname)
    bspread(NPYDGroup(fname))
end

function Finch.bspwrite_npyd(fname, arr, attrs = OrderedDict())
    bspwrite(NPYDGroup(fname), arr, attrs)
    fname
end

end