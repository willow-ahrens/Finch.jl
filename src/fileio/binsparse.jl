"""
    bspwrite(::AbstractString, tns)
    bspwrite(::HDF5.File, tns)
    bspwrite(::NPXPath, tns)

Write the Finch tensor to a file using
[Binsparse](https://github.com/GraphBLAS/binsparse-specification) file format.

Supported file extensions are:

- `.bsp.h5`: HDF5 file format ([HDF5](https://github.com/JuliaIO/HDF5.jl) must be loaded)
- `.bsp.npx`: NumPy and JSON directory format ([NPZ](https://github.com/fhs/NPZ.jl) must be loaded)

!!! warning
    The Binsparse spec is under development. Additionally, this function may not
    be fully conformant. Please file bug reports if you see anything amiss.
"""
function bspwrite end

"""
bspread(::AbstractString)
bspread(::HDF5.File)
bspread(::NPXPath)

Read the [Binsparse](https://github.com/GraphBLAS/binsparse-specification) file into a Finch tensor.

Supported file extensions are:

- `.bsp.h5`: HDF5 file format ([HDF5](https://github.com/JuliaIO/HDF5.jl) must be loaded)
- `.bsp.npx`: NumPy and JSON directory format ([NPZ](https://github.com/fhs/NPZ.jl) must be loaded)

!!! warning
The Binsparse spec is under development. Additionally, this function may not
be fully conformant. Please file bug reports if you see anything amiss.
"""
function bspread end

using Finch: level_ndims, SwizzleArray
using CIndices

bspread_type_lookup = Dict(
    "uint8" => UInt8,
    "uint16" => UInt16,
    "uint32" => UInt32,
    "uint64" => UInt64,
    "int8" => Int8,
    "int16" => Int16,
    "int32" => Int32,
    "int64" => Int64,
    "float32" => Float32,
    "float64" => Float64,
    "bint8" => Bool,
)

function bspread_data(f, desc, key)
    t = desc["data_types"]["$(key)_type"]
    if (m = match(r"^iso\[([^\[]*)\]$", t)) != nothing
        throw(ArgumentError("iso values not currently supported"))
    elseif (m = match(r"^complex\[([^\[]*)\]$", t)) != nothing
        desc["data_types"]["$(key)_type"] = m.captures[1]
        data = bspread_data(f, desc, key)
        return reinterpret(reshape, Complex{eltype(data)}, reshape(data, 2, :))
    elseif (m = match(r"^[^\]]*$", t)) != nothing
        haskey(bspread_type_lookup, t) || throw(ArgumentError("unknown binsparse type $t"))
        convert(Vector{bspread_type_lookup[t]}, read(f[key]))
    else
        throw(ArgumentError("unknown binsparse type wrapper $t"))
    end
end

bspwrite_type_lookup = Dict(v => k for (k, v) in bspread_type_lookup)

function bspwrite_data(f, desc, key, data)
    type_desc = bspwrite_data_helper(f, desc, key, data)
end

function bspwrite_data_helper(f, desc, key, data::AbstractVector{T}) where {T}
    haskey(bspwrite_type_lookup, T) || throw(ArgumentError("Cannot write $T to binsparse"))
    f[key] = data
    desc["data_types"]["$(key)_type"] = bspwrite_type_lookup[T]
end

function bspwrite_data_helper(f, desc, key, data::AbstractVector{Complex{T}}) where {T}
    data = reshape(reinterpret(reshape, T, data), :)
    bspwrite_data_helper(f, desc, key, data)
    desc["data_types"]["$(key)_type"] = "complex[$(desc["data_types"]["$(key)_type"])]"
end

bspread_format_lookup = Dict(
    "CSR" => Dict(
        "swizzle" => [1, 2],
        "subformat" => Dict(
            "level" => "dense",
            "rank" => 1,
            "subformat" => Dict(
                "level" => "sparse",
                "rank" => 1,
                "subformat" => Dict(
                    "level" => "element",
                )
            )
        )
    ),

    "CSC" => Dict(
        "swizzle" => [2, 1],
        "subformat" => Dict(
            "level" => "dense",
            "rank" => 1,
            "subformat" => Dict(
                "level" => "sparse",
                "rank" => 1,
                "subformat" => Dict(
                    "level" => "element",
                )
            )
        )
    ),

    "DCSR" => Dict(
        "swizzle" => [1, 2],
        "subformat" => Dict(
            "level" => "sparse",
            "rank" => 1,
            "subformat" => Dict(
                "level" => "sparse",
                "rank" => 1,
                "subformat" => Dict(
                    "level" => "element",
                )
            )
        )
    ),

    "DCSC" => Dict(
        "swizzle" => [2, 1],
        "subformat" => Dict(
            "level" => "sparse",
            "rank" => 1,
            "subformat" => Dict(
                "level" => "sparse",
                "rank" => 1,
                "subformat" => Dict(
                    "level" => "element",
                )
            )
        )
    ),

    "COO" => Dict(
        "swizzle" => [1, 2],
        "subformat" => Dict(
            "level" => "sparse",
            "rank" => 2,
            "subformat" => Dict(
                "level" => "element",
            )
        )
    ),

    "DMAT" => Dict(
        "swizzle" => [1, 2],
        "subformat" => Dict(
            "level" => "dense",
            "rank" => 1,
            "subformat" => Dict(
                "level" => "dense",
                "rank" => 1,
                "subformat" => Dict(
                    "level" => "element",
                )
            )
        )
    ),

    "DVEC" => Dict(
        "swizzle" => [1],
        "subformat" => Dict(
            "level" => "dense",
            "rank" => 1,
            "subformat" => Dict(
                "level" => "element",
            )
        )
    ),

    "VEC" => Dict(
        "swizzle" => [1],
        "subformat" => Dict(
            "level" => "sparse",
            "rank" => 1,
            "subformat" => Dict(
                "level" => "element",
            )
        )
    )
)

bspwrite_format_lookup = Dict(v => k for (k, v) in bspread_format_lookup)

indices_zero_to_one(vec::Vector{Ti}) where {Ti} = unsafe_wrap(Array, reinterpret(Ptr{CIndex{Ti}}, pointer(vec)), length(vec); own = false)
indices_one_to_zero(vec::Vector{<:Integer}) = vec .- one(eltype(vec))
indices_one_to_zero(vec::Vector{<:CIndex{Ti}}) where {Ti} = unsafe_wrap(Array, reinterpret(Ptr{Ti}, pointer(vec)), length(vec); own = false)

struct NPXGroup
    dirname::String
end

function bspwrite_h5 end
function bspwrite_npx end

function bspwrite(fname::AbstractString, arr, attrs = Dict())
    if endswith(fname, ".h5")
        bspwrite_h5(fname, arr, attrs)
    elseif endswith(fname, ".npx")
        bspwrite_npx(fname, arr, attrs)
    else
        error("Unknown file extension for file $fname")
    end
end

bspwrite_tensor(io, fbr::Fiber, attrs = Dict()) = 
    bspwrite_tensor(io, swizzle(fbr, 1:ndims(fbr)...), attrs)
function bspwrite_tensor(io, arr::SwizzleArray{dims, <:Fiber}, attrs = Dict()) where {dims}
    desc = Dict(
        "format" => Dict(
            "subformat" => Dict(),
            "swizzle" => reverse(collect(dims)),
        ),
        "fill" => true,
        "shape" => map(Int, size(arr)),
        "data_types" => Dict(),
        "attrs" => attrs,
    )
    bspwrite_level(io, desc, desc["format"]["subformat"], arr.body.lvl)
    desc["format"] = get(bspwrite_format_lookup, desc["format"], desc["format"])
    io["binsparse"] = json(desc, 4)
end

function bspread_h5 end
function bspread_npx end

function bspread(fname::AbstractString)
    if endswith(fname, ".h5")
        bspread_h5(fname)
    elseif endswith(fname, ".npx")
        bspread_npx(fname)
    else
        error("Unknown file extension for file $fname")
    end
end

function bspread_tensor(f)
    desc = JSON.parse(read(f["binsparse"]))
    fmt = get(bspread_format_lookup, desc["format"], desc["format"])
    if !issorted(reverse(fmt["swizzle"]))
        sigma = reverse(sortperm(fmt["swizzle"]))
        desc["shape"] = desc["shape"][sigma]
    end
    fbr = Fiber(bspread_level(f, desc, fmt["subformat"]))
    if !issorted(reverse(fmt["swizzle"]))
        fbr = swizzle(fbr, reverse(fmt["swizzle"])...)
    end
    if haskey(desc, "structure")
        throw(ArgumentError("binsparse structure field currently unsupported"))
    end
    fbr
end

bspread_level(f, desc, fmt) = bspread_level(f, desc, fmt, Val(Symbol(fmt["level"])))

function bspwrite_level(f, desc, fmt, lvl::ElementLevel{D}) where {D}
    fmt["level"] = "element"
    bspwrite_data(f, desc, "values", lvl.val)
    bspwrite_data(f, desc, "fill_value", [D])
end
function bspread_level(f, desc, fmt, ::Val{:element})
    val = convert(Vector, bspread_data(f, desc, "values"))
    D = bspread_data(f, desc, "fill_value")[1]
    ElementLevel(D, val)
end

function bspwrite_level(f, desc, fmt, lvl::DenseLevel{D}) where {D}
    fmt["level"] = "dense"
    fmt["rank"] = 1
    fmt["subformat"] = Dict()
    bspwrite_level(f, desc, fmt["subformat"], lvl.lvl)
end
function bspread_level(f, desc, fmt, ::Val{:dense})
    lvl = bspread_level(f, desc, fmt["subformat"])
    R = fmt["rank"]
    for r = 1:R
        n = level_ndims(typeof(lvl))
        shape = CIndex{Int}(desc["shape"][n + 1])
        lvl = DenseLevel(lvl, shape)
    end
    lvl
end

function bspwrite_level(f, desc, fmt, lvl::SparseListLevel)
    fmt["level"] = "sparse"
    fmt["rank"] = 1
    n = level_ndims(typeof(lvl))
    N = length(desc["shape"])
    if N - n > 0
        bspwrite_data(f, desc, "pointers_to_$(N - n)", indices_one_to_zero(lvl.ptr))
    end
    bspwrite_data(f, desc, "indices_$(N - n)", indices_one_to_zero(lvl.idx))
    fmt["subformat"] = Dict()
    bspwrite_level(f, desc, fmt["subformat"], lvl.lvl)
end
function bspwrite_level(f, desc, fmt, lvl::SparseCOOLevel{R}) where {R}
    fmt["level"] = "sparse"
    fmt["rank"] = R
    n = level_ndims(typeof(lvl))
    N = length(desc["shape"])
    if N - n > 0
        bspwrite_data(f, desc, "pointers_to_$(N - n)", indices_one_to_zero(lvl.ptr))
    end
    for r = 1:R
        bspwrite_data(f, desc, "indices_$(N - n + r - 1)", indices_one_to_zero(lvl.tbl[r]))
    end
    fmt["subformat"] = Dict()
    bspwrite_level(f, desc, fmt["subformat"], lvl.lvl)
end
function bspread_level(f, desc, fmt, ::Val{:sparse})
    R = fmt["rank"]
    lvl = bspread_level(f, desc, fmt["subformat"])
    n = level_ndims(typeof(lvl)) + R
    N = length(desc["shape"])
    tbl = (map(1:R) do r
        indices_zero_to_one(bspread_data(f, desc, "indices_$(N - n + r - 1)"))
    end...,)
    if N - n > 0
        ptr = bspread_data(f, desc, "pointers_to_$(N - n)")
    else
        ptr = [0, length(tbl[1])]
    end
    ptr = indices_zero_to_one(ptr)
    shape = ntuple(r->eltype(tbl[r])(desc["shape"][n - R + r]), R)
    if R == 1
        SparseListLevel(lvl, shape[1], ptr, tbl[1])
    else
        SparseCOOLevel{Int(R), typeof(shape), eltype(ptr)}(lvl, shape, tbl, ptr)
    end
end