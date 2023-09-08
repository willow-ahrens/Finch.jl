using NPZ
using JSON

struct NPXGroup <: AbstractDict
    dirname::String
end

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
Base.setindex!(g::NPXGroup, val::JSONText, key::AbstractString) = npzwrite(mkpath(joinpath(g.dirname, "$(key).json")), val)
function Base.setindex!(g::NPXGroup, val::AbstractDict, key::AbstractString)
    for (key_2, val) in val
        setindex!(NPXGroup[key], val, key_2)
    end
end

function Finch.bspread_npx(fname)
    bspread(NPXGroup(fname))
end

function Finch.bspwrite_npx(fname, arr, attrs = Dict()) where {dims}
    bspwrite(NPXGroup(fname), arr, attrs)
    fname
end