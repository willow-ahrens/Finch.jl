using Finch: level_ndims, SwizzleArray
using CIndices

bswrite_type_lookup = Dict(
    UInt8 => "uint8",
    UInt16 => "uint16",
    UInt32 => "uint32",
    UInt64 => "uint64",
    Int8 => "int8",
    Int16 => "int16",
    Int32 => "int32",
    Int64 => "int64",
    Float32 => "float32",
    Float64 => "float64",
    Bool => "bint8",
)

bsread_type_lookup = Dict(
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

bswrite_format_lookup = Dict(
    "CSR" => Dict(
        "swizzle" => [1, 2],
        "level" => Dict(
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
        "level" => Dict(
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
        "level" => Dict(
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
        "level" => Dict(
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
        "level" => Dict(
            "level" => "sparse",
            "rank" => 2,
            "subformat" => Dict(
                "level" => "element",
            )
        )
    ),

    "DMAT" => Dict(
        "swizzle" => [1, 2],
        "level" => Dict(
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
        "level" => Dict(
            "level" => "dense",
            "rank" => 1,
            "subformat" => Dict(
                "level" => "element",
            )
        )
    ),

    "VEC" => Dict(
        "swizzle" => [1],
        "level" => Dict(
            "level" => "sparse",
            "rank" => 1,
            "subformat" => Dict(
                "level" => "element",
            )
        )
    )
)

indices_one_to_zero(vec::Vector{<:Integer}) = vec .- one(eltype(vec))
indices_one_to_zero(vec::Vector{<:CIndex{Ti}}) where {Ti} = unsafe_wrap(Array, reinterpret(Ptr{Ti}, pointer(vec)), length(vec); own = false)
indices_zero_to_one(vec::Vector{Ti}) where {Ti} = unsafe_wrap(Array, reinterpret(Ptr{CIndex{Ti}}, pointer(vec)), length(vec); own = false)

function bswrite_data(f, desc, key, data)
    desc["data_types"]["$(key)_type"] = bswrite_type_lookup[eltype(data)]
    f[key] = reinterpret(bsread_type_lookup[bswrite_type_lookup[eltype(data)]], data)
end

bsread_data(f, desc, key) = bsread_data(f, desc, key, Val{desc["data_types"]["$(key)_type"]})

function bsread_data(f, desc, key, valtype)
    data = read(f[key])
    T = bsread_type_lookup[valtype]
    convert(Vector{T}, reinterpret(T, data))
end

Finch.bswrite(fname, fbr::Fiber, attrs = Dict()) = 
    bswrite(fname, swizzle(fbr, (1:ndims(fbr)...)), attrs)
function Finch.bswrite(fname, arr::SwizzleArray{dims, <:Fiber}, attrs = Dict()) where {dims}
    h5open(fname, "w") do f
        desc = Dict(
            "format" => Dict(),
            "fill" => true,
            "swizzle" => reverse(collect(dims)),
            "shape" => map(Int, size(arr)),
            "data_types" => Dict(),
            "attrs" => attrs,
        )
        bswrite_level(f, desc, desc["format"], arr.body.lvl)
        desc["format"] = get(bswrite_format_lookup, desc["format"], desc["format"])
        f["binsparse"] = json(desc, 4)
    end
    fname
end

function Finch.bsread(fname)
    h5open(fname, "r") do f
        desc = JSON.parse(read(f["binsparse"]))
        fbr = Fiber(bsread_level(f, desc, desc["format"]))
        if !issorted(reverse(desc["swizzle"]))
            fbr = swizzle(fbr, reverse(desc["swizzle"]))
        end
        fbr
    end
end
bsread_level(f, desc, fmt) = bsread_level(f, desc, fmt, Val(Symbol(fmt["level"])))

function bswrite_level(f, desc, fmt, lvl::ElementLevel{D}) where {D}
    fmt["level"] = "element"
    bswrite_data(f, desc, "values", lvl.val)
    bswrite_data(f, desc, "fill_value", [D])
end

bsread_level(f, desc, fmt, ::Val{:element}) =
    bsread_element_level(f, desc, fmt, desc["data_types"]["values_type"])

function bsread_element_level(f, desc, fmt, valtype)
    if (m = match(r"^iso\[([^\[]*)\]$", valtype)) != nothing
        throw(ArgumentError("iso values not currently supported"))
    elseif (m = match(r"^complex\[([^\[]*)\]$", valtype)) != nothing
        lvl = bsread_element_level(f, desc, fmt, m.captures[1])
        return bsread_element_level_complex(lvl)
    elseif (m = match(r"^[^\[]*$", valtype)) != nothing
        val = bsread_data(f, desc, "values", valtype)
        D = bsread_data(f, desc, "fill_value", valtype)[1]
        return ElementLevel(D, val)
    else
        throw(ArgumentError("unknown value type wrapper $valtype"))
    end
end

bsread_element_level_complex(lvl::ElementLevel{D}) where {D} = ElementLevel{Complex{D}}(reinterpret(Complex{D}, lvl.val))

function bswrite_level(f, desc, fmt, lvl::DenseLevel{D}) where {D}
    fmt["level"] = "dense"
    fmt["rank"] = 1
    fmt["subformat"] = Dict()
    bswrite_level(f, desc, fmt["subformat"], lvl.lvl)
end
function bsread_level(f, desc, fmt, ::Val{:dense})
    lvl = bsread_level(f, desc, fmt["subformat"])
    R = fmt["rank"]
    for r = 1:R
        n = level_ndims(typeof(lvl))
        shape = CIndex{Int}(desc["shape"][end - n])
        lvl = DenseLevel(lvl, shape)
    end
    lvl
end

function bswrite_level(f, desc, fmt, lvl::SparseListLevel)
    fmt["level"] = "sparse"
    fmt["rank"] = 1
    n = level_ndims(typeof(lvl))
    N = length(desc["shape"])
    if N - n > 0
        bswrite_data(f, desc, "pointers_to_$(N - n)", indices_one_to_zero(lvl.ptr))
    end
    bswrite_data(f, desc, "indices_$(N - n)", indices_one_to_zero(lvl.idx))
    fmt["subformat"] = Dict()
    bswrite_level(f, desc, fmt["subformat"], lvl.lvl)
end
function bswrite_level(f, desc, fmt, lvl::SparseCOOLevel{R}) where {R}
    fmt["level"] = "sparse"
    fmt["rank"] = R
    n = level_ndims(typeof(lvl))
    N = length(desc["shape"])
    if N - n > 0
        bswrite_data(f, desc, "pointers_to_$(N - n)", indices_one_to_zero(lvl.ptr))
    end
    for r = 1:R
        bswrite_data(f, desc, "indices_$(N - n + r - 1)", indices_one_to_zero(lvl.tbl[r]))
    end
    fmt["subformat"] = Dict()
    bswrite_level(f, desc, fmt["subformat"], lvl.lvl)
end
function bsread_level(f, desc, fmt, ::Val{:sparse})
    R = fmt["rank"]
    lvl = bsread_level(f, desc, fmt["subformat"])
    n = level_ndims(typeof(lvl)) + R
    N = length(desc["shape"])
    tbl = (map(1:R) do r
        indices_zero_to_one(bsread_data(f, desc, "indices_$(N - n + r - 1)"))
    end...,)
    if N - n > 0
        ptr = bsread_data(f, desc, "pointers_to_$(N - n)")
    else
        ptr = [0, length(tbl[1])]
    end
    ptr = indices_zero_to_one(ptr)
    shape = ntuple(r->eltype(tbl[r])(desc["shape"][N - n + r]), R)
    if R == 1
        SparseListLevel(lvl, shape[1], ptr, tbl[1])
    else
        SparseCOOLevel{Int(R), typeof(shape), eltype(ptr)}(lvl, shape, tbl, ptr)
    end
end