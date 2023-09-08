module NPZExt 

using Finch
using Finch : NPXGroup
using Finch.JSON
using Finch.DataStructures

isdefined(Base, :get_extension) ? (using NPZ) : (using ..NPZ)

using NPZ

function Base.getindex(g::NPXGroup, key::AbstractString)
    path =joinpath(g.dirname, key)
    if endswith(key, ".npy")
        npyread(path)
    elseif endswith(key, ".json")
        JSON.parsefile(path)
    else
        NPXGroup(path)
    end
end
Base.getindex(g::NPXGroup, key::AbstractString) = NPXGroup(joinpath(g.dirname, key))

Base.setindex!(g::NPXGroup, val::AbstractArray, key::AbstractString) = npzwrite(mkpath(joinpath(g.dirname, "$(key).npy")), val)
Finch.bspwrite_header(f::NPXGroup, str::String, key) = npzwrite(mkpath(joinpath(g.dirname, "$(key).json")), str)
function Base.setindex!(g::NPXGroup, val::AbstractDict, key::AbstractString)
    for (key_2, val) in val
        setindex!(g[key], val, key_2)
    end
end

function Finch.bspread_npx(fname)
    bspread(NPXGroup(fname))
end

function Finch.bspwrite_npx(fname, arr, attrs = OrderedDict())
    bspwrite(NPXGroup(fname), arr, attrs)
    fname
end

end