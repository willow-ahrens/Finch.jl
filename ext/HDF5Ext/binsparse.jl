using Finch: level_ndims, SwizzleArray
using CIndices

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

function bsread_data(f, desc, key)
    t = desc["data_types"]["$(key)_type"]
    if (m = match(r"^iso\[([^\[]*)\]$", t)) != nothing
        throw(ArgumentError("iso values not currently supported"))
    elseif (m = match(r"^complex\[([^\[]*)\]$", t)) != nothing
        desc["data_types"]["$(key)_type"] = m.captures[1]
        data = bsread_data(f, desc, key)
        return reinterpret(reshape, Complex{eltype(data)}, reshape(data, 2, :))
    elseif (m = match(r"^[^\]]*$", t)) != nothing
        haskey(bsread_type_lookup, t) || throw(ArgumentError("unknown binsparse type $t"))
        convert(Vector{bsread_type_lookup[t]}, read(f[key]))
    else
        throw(ArgumentError("unknown binsparse type wrapper $t"))
    end
end

bswrite_type_lookup = Dict(v => k for (k, v) in bsread_type_lookup)

function bswrite_data(f, desc, key, data)
    type_desc = bswrite_data_helper(f, desc, key, data)
end

function bswrite_data_helper(f, desc, key, data::AbstractVector{T}) where {T}
    haskey(bswrite_type_lookup, T) || throw(ArgumentError("Cannot write $T to binsparse"))
    f[key] = data
    desc["data_types"]["$(key)_type"] = bswrite_type_lookup[T]
end

function bswrite_data_helper(f, desc, key, data::AbstractVector{Complex{T}}) where {T}
    data = reshape(reinterpret(reshape, T, data), :)
    bswrite_data_helper(f, desc, key, data)
    desc["data_types"]["$(key)_type"] = "complex[$(desc["data_types"]["$(key)_type"])]"
end

bsread_format_lookup = Dict(
    "CSR" => Dict(
        "swizzle" => [1, 2],
        "format" => Dict(
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
        "format" => Dict(
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
        "format" => Dict(
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
        "format" => Dict(
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
        "format" => Dict(
            "level" => "sparse",
            "rank" => 2,
            "subformat" => Dict(
                "level" => "element",
            )
        )
    ),

    "DMAT" => Dict(
        "swizzle" => [1, 2],
        "format" => Dict(
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
        "format" => Dict(
            "level" => "dense",
            "rank" => 1,
            "subformat" => Dict(
                "level" => "element",
            )
        )
    ),

    "VEC" => Dict(
        "swizzle" => [1],
        "format" => Dict(
            "level" => "sparse",
            "rank" => 1,
            "subformat" => Dict(
                "level" => "element",
            )
        )
    )
)

bswrite_format_lookup = Dict(v => k for (k, v) in bsread_format_lookup)

indices_zero_to_one(vec::Vector{Ti}) where {Ti} = unsafe_wrap(Array, reinterpret(Ptr{CIndex{Ti}}, pointer(vec)), length(vec); own = false)
indices_one_to_zero(vec::Vector{<:Integer}) = vec .- one(eltype(vec))
indices_one_to_zero(vec::Vector{<:CIndex{Ti}}) where {Ti} = unsafe_wrap(Array, reinterpret(Ptr{Ti}, pointer(vec)), length(vec); own = false)

Finch.bswrite(fname, fbr::Fiber, attrs = Dict()) = 
    bswrite(fname, swizzle(fbr, 1:ndims(fbr)...), attrs)
function Finch.bswrite(fname, arr::SwizzleArray{dims, <:Fiber}, attrs = Dict()) where {dims}
    h5open(fname, "w") do f
        desc = Dict(
            "format" => Dict(),
            "swizzle" => reverse(collect(dims)),
            "fill" => true,
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
        fmt = get(bsread_format_lookup, desc["format"], desc["format"])
        if !issorted(reverse(desc["swizzle"]))
            sigma = reverse(sortperm(desc["swizzle"]))
            desc["shape"] = desc["shape"][sigma]
        end
        fbr = Fiber(bsread_level(f, desc, fmt))
        if !issorted(reverse(desc["swizzle"]))
            fbr = swizzle(fbr, reverse(desc["swizzle"])...)
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
function bsread_level(f, desc, fmt, ::Val{:element})
    val = convert(Vector, bsread_data(f, desc, "values"))
    D = bsread_data(f, desc, "fill_value")[1]
    ElementLevel(D, val)
end

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
        shape = CIndex{Int}(desc["shape"][n + 1])
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
    shape = ntuple(r->eltype(tbl[r])(desc["shape"][n - R + r]), R)
    if R == 1
        SparseListLevel(lvl, shape[1], ptr, tbl[1])
    else
        SparseCOOLevel{Int(R), typeof(shape), eltype(ptr)}(lvl, shape, tbl, ptr)
    end
end