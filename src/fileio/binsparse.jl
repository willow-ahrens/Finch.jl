"""
    bspwrite(::AbstractString, tns)
    bspwrite(::HDF5.File, tns)
    bspwrite(::NPYPath, tns)

Write the Finch tensor to a file using
[Binsparse](https://github.com/GraphBLAS/binsparse-specification) file format.

Supported file extensions are:

- `.bsp.h5`: HDF5 file format ([HDF5](https://github.com/JuliaIO/HDF5.jl) must be loaded)
- `.bspnpy`: NumPy and JSON directory format ([NPZ](https://github.com/fhs/NPZ.jl) must be loaded)

!!! warning
    The Binsparse spec is under development. Additionally, this function may not
    be fully conformant. Please file bug reports if you see anything amiss.
"""
function bspwrite end

"""
bspread(::AbstractString)
bspread(::HDF5.File)
bspread(::NPYPath)

Read the [Binsparse](https://github.com/GraphBLAS/binsparse-specification) file into a Finch tensor.

Supported file extensions are:

- `.bsp.h5`: HDF5 file format ([HDF5](https://github.com/JuliaIO/HDF5.jl) must be loaded)
- `.bspnpy`: NumPy and JSON directory format ([NPZ](https://github.com/fhs/NPZ.jl) must be loaded)

!!! warning
The Binsparse spec is under development. Additionally, this function may not
be fully conformant. Please file bug reports if you see anything amiss.
"""
function bspread end

using Finch: level_ndims, SwizzleArray
using CIndices

bspread_type_lookup = OrderedDict(
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

function bspread_vector end
function bspwrite_vector end

function bspread_data(f, desc, key)
    t = desc["data_types"][key]
    if (m = match(r"^iso\[([^\[]*)\]$", t)) !== nothing
        throw(ArgumentError("iso values not currently supported"))
    elseif (m = match(r"^complex\[([^\[]*)\]$", t)) !== nothing
        desc["data_types"][key] = m.captures[1]
        data = bspread_data(f, desc, key)
        return reinterpret(Complex{eltype(data)}, data)
    elseif (m = match(r"^[^\]]*$", t)) !== nothing
        haskey(bspread_type_lookup, t) || throw(ArgumentError("unknown binsparse type $t"))
        convert(Vector{bspread_type_lookup[t]}, bspread_vector(f, key))
    else
        throw(ArgumentError("unknown binsparse type wrapper $t"))
    end
end

bspwrite_type_lookup = OrderedDict(v => k for (k, v) in bspread_type_lookup)

function bspwrite_data(f, desc, key, data)
    type_desc = bspwrite_data_helper(f, desc, key, data)
end

function bspwrite_data_helper(f, desc, key, data::AbstractVector{T}) where {T}
    haskey(bspwrite_type_lookup, T) || throw(ArgumentError("Cannot write $T to binsparse"))
    bspwrite_vector(f, data, key)
    desc["data_types"][key] = bspwrite_type_lookup[T]
end

function bspwrite_data_helper(f, desc, key, data::AbstractVector{Complex{T}}) where {T}
    data = reinterpret(T, data)
    bspwrite_data_helper(f, desc, key, data)
    desc["data_types"][key] = "complex[$(desc["data_types"][key])]"
end

bspread_format_lookup = OrderedDict(
    "DVEC" => OrderedDict(
        "subformat" => OrderedDict(
            "level" => "dense",
            "rank" => 1,
            "subformat" => OrderedDict(
                "level" => "element",
            )
        )
    ),

    "DMAT" => OrderedDict(
        "subformat" => OrderedDict(
            "level" => "dense",
            "rank" => 1,
            "subformat" => OrderedDict(
                "level" => "dense",
                "rank" => 1,
                "subformat" => OrderedDict(
                    "level" => "element",
                )
            )
        )
    ),

    "DMATR" => OrderedDict(
        "subformat" => OrderedDict(
            "level" => "dense",
            "rank" => 1,
            "subformat" => OrderedDict(
                "level" => "dense",
                "rank" => 1,
                "subformat" => OrderedDict(
                    "level" => "element",
                )
            )
        )
    ),

    "DMATC" => OrderedDict(
        "swizzle" => [1, 0],
        "subformat" => OrderedDict(
            "level" => "dense",
            "rank" => 1,
            "subformat" => OrderedDict(
                "level" => "dense",
                "rank" => 1,
                "subformat" => OrderedDict(
                    "level" => "element",
                )
            )
        )
    ),

    "CVEC" => OrderedDict(
        "subformat" => OrderedDict(
            "level" => "sparse",
            "rank" => 1,
            "subformat" => OrderedDict(
                "level" => "element",
            )
        )
    ),

    "CSR" => OrderedDict(
        "subformat" => OrderedDict(
            "level" => "dense",
            "rank" => 1,
            "subformat" => OrderedDict(
                "level" => "sparse",
                "rank" => 1,
                "subformat" => OrderedDict(
                    "level" => "element",
                )
            )
        )
    ),

    "CSC" => OrderedDict(
        "swizzle" => [1, 0],
        "subformat" => OrderedDict(
            "level" => "dense",
            "rank" => 1,
            "subformat" => OrderedDict(
                "level" => "sparse",
                "rank" => 1,
                "subformat" => OrderedDict(
                    "level" => "element",
                )
            )
        )
    ),

    "DCSR" => OrderedDict(
        "subformat" => OrderedDict(
            "level" => "sparse",
            "rank" => 1,
            "subformat" => OrderedDict(
                "level" => "sparse",
                "rank" => 1,
                "subformat" => OrderedDict(
                    "level" => "element",
                )
            )
        )
    ),

    "DCSC" => OrderedDict(
        "swizzle" => [1, 0],
        "subformat" => OrderedDict(
            "level" => "sparse",
            "rank" => 1,
            "subformat" => OrderedDict(
                "level" => "sparse",
                "rank" => 1,
                "subformat" => OrderedDict(
                    "level" => "element",
                )
            )
        )
    ),

    "COO" => OrderedDict(
        "subformat" => OrderedDict(
            "level" => "sparse",
            "rank" => 2,
            "subformat" => OrderedDict(
                "level" => "element",
            )
        )
    ),

    "COOR" => OrderedDict(
        "subformat" => OrderedDict(
            "level" => "sparse",
            "rank" => 2,
            "subformat" => OrderedDict(
                "level" => "element",
            )
        )
    ),

    "COOC" => OrderedDict(
        "swizzle" => [1, 0],
        "subformat" => OrderedDict(
            "level" => "sparse",
            "rank" => 2,
            "subformat" => OrderedDict(
                "level" => "element",
            )
        )
    ),
)

bspwrite_format_lookup = OrderedDict(v => k for (k, v) in bspread_format_lookup)

#indices_zero_to_one(vec::Vector{Ti}) where {Ti} = unsafe_wrap(Array, reinterpret(Ptr{CIndex{Ti}}, pointer(vec)), length(vec); own = true)
indices_zero_to_one(vec::Vector) = vec .+ one(eltype(vec))
indices_one_to_zero(vec::Vector) = vec .- one(eltype(vec))
#indices_one_to_zero(vec::Vector{<:CIndex{Ti}}) where {Ti} = unsafe_wrap(Array, reinterpret(Ptr{Ti}, pointer(vec)), length(vec); own = true)

struct NPYPath
    dirname::String
end

function bspwrite_h5 end
function bspwrite_bspnpy end

function bspwrite(fname::AbstractString, arr, attrs = OrderedDict())
    if endswith(fname, ".h5") || endswith(fname, ".hdf5")
        bspwrite_h5(fname, arr, attrs)
    elseif endswith(fname, ".bspnpy")
        bspwrite_bspnpy(fname, arr, attrs)
    else
        error("Unknown file extension for file $fname")
    end
end
bspwrite(fname, arr, attrs = OrderedDict()) = bspwrite_tensor(fname, arr, attrs)

bspwrite_tensor(io, fbr::Fiber, attrs = OrderedDict()) = 
    bspwrite_tensor(io, swizzle(fbr, 1:ndims(fbr)...), attrs)

function bspwrite_tensor(io, arr::SwizzleArray{dims, <:Fiber}, attrs = OrderedDict()) where {dims}
    desc = OrderedDict(
        "format" => OrderedDict{Any, Any}(
            "subformat" => OrderedDict(),
        ),
        "fill" => true,
        "shape" => map(Int, size(arr)),
        "data_types" => OrderedDict(),
        "version" => "0.1",
        "attrs" => attrs,
    )
    if !issorted(reverse(collect(dims)))
        desc["format"]["swizzle"] = reverse(collect(dims)) .- 1
    end
    bspwrite_level(io, desc, desc["format"]["subformat"], arr.body.lvl)
    desc["format"] = get(bspwrite_format_lookup, desc["format"], desc["format"])
    bspwrite_header(io, json(Dict("binsparse" => desc), 4))
end

function bspwrite_header end

function bspread_h5 end
function bspread_bspnpy end

function bspread(fname::AbstractString)
    if endswith(fname, ".h5") || endswith(fname, ".hdf5")
        bspread_h5(fname)
    elseif endswith(fname, ".bspnpy")
        bspread_bspnpy(fname)
    else
        error("Unknown file extension for file $fname")
    end
end

function bspread_header end

function bspread(f)
    desc = bspread_header(f)["binsparse"]
    @assert desc["version"] == "0.1"
    fmt = OrderedDict{Any, Any}(get(bspread_format_lookup, desc["format"], desc["format"]))
    if !haskey(fmt, "swizzle")
        fmt["swizzle"] = collect(0:length(desc["shape"]) - 1)
    end
    if !issorted(reverse(fmt["swizzle"]))
        sigma = sortperm(reverse(fmt["swizzle"] .+ 1))
        desc["shape"] = desc["shape"][sigma]
    end
    fbr = Fiber(bspread_level(f, desc, fmt["subformat"]))
    if !issorted(reverse(fmt["swizzle"]))
        fbr = swizzle(fbr, reverse(fmt["swizzle"] .+ 1)...)
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
    if haskey(f, "fill_value")
        D = bspread_data(f, desc, "fill_value")[1]
    else
        D = zero(eltype(val))
    end
    ElementLevel(D, val)
end

function bspwrite_level(f, desc, fmt, lvl::DenseLevel{D}) where {D}
    fmt["level"] = "dense"
    fmt["rank"] = 1
    fmt["subformat"] = OrderedDict()
    bspwrite_level(f, desc, fmt["subformat"], lvl.lvl)
end
function bspread_level(f, desc, fmt, ::Val{:dense})
    lvl = bspread_level(f, desc, fmt["subformat"])
    R = fmt["rank"]
    for r = 1:R
        n = level_ndims(typeof(lvl))
        shape = Int(desc["shape"][n + 1])
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
    fmt["subformat"] = OrderedDict()
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
    fmt["subformat"] = OrderedDict()
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
        SparseCOOLevel{Int(R), typeof(shape)}(lvl, shape, ptr, tbl)
    end
end
