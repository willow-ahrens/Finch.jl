ARGS

if !@isdefined utils
    utils = true

    function diff(name, res)
        global ARGS
        "nodiff" in ARGS && return true
        ref_dir = joinpath(@__DIR__, "reference$(Sys.WORD_SIZE)")
        ref_file = joinpath(ref_dir, name)
        if "overwrite" in ARGS
            mkpath(ref_dir)
            open(ref_file, "w") do f
                println(f, res)
            end
            true
        else
            ref = read(ref_file, String)
            res = sprint(println, res)
            if ref == res
                return true
            else
                if "verbose" in ARGS
                    println("=== reference ===")
                    println(ref)
                    println("=== test ===")
                    println(res)
                end
                return false
            end
        end
    end

    reference_getindex(arr, inds...) = getindex(arr, inds...)
    reference_getindex(arr::Fiber, inds...) = arr(inds...)

    function reference_isequal(a,b)
        size(a) == size(b) || return false
        axes(a) == axes(b) || return false
        for i in Base.product(axes(a)...)
            reference_getindex(a, i...) == reference_getindex(b, i...) || return false
        end
        return true
    end

    isstructequal(a, b) = a === b

    isstructequal(a::T, b::T) where {T <: Fiber} = 
        isstructequal(a.lvl, b.lvl)

    isstructequal(a::T, b::T) where {T <: Finch.SubFiber} = 
        isstructequal(a.lvl, b.lvl) &&
        isstructequal(a.pos, b.pos)

    isstructequal(a::T, b::T)  where {T <: Pattern} = true

    isstructequal(a::T, b::T) where {T <: Element} =
        a.val == b.val

    isstructequal(a::T, b::T) where {T <: RepeatRLE} =
        a.I == b.I &&
        a.pos == b.pos &&
        a.idx == b.idx &&
        a.val == b.val

    isstructequal(a::T, b::T) where {T <: Dense} =
        a.I == b.I &&
        isstructequal(a.lvl, b.lvl)

    isstructequal(a::T, b::T) where {T <: SparseList} =
        a.I == b.I &&
        a.pos == b.pos &&
        a.idx == b.idx &&
        isstructequal(a.lvl, b.lvl)

    isstructequal(a::T, b::T) where {T <: SparseCoo} =
        a.I == b.I &&
        a.pos == b.pos &&
        a.tbl == b.tbl &&
        isstructequal(a.lvl, b.lvl)

    isstructequal(a::T, b::T) where {T <: SparseHash} =
        a.I == b.I &&
        a.pos == b.pos &&
        a.tbl == b.tbl &&
        a.srt == b.srt &&
        isstructequal(a.lvl, b.lvl)

    isstructequal(a::T, b::T) where {T <: SparseVBL} =
        a.I == b.I &&
        a.pos == b.pos &&
        a.idx == b.idx &&
        a.ofs == b.ofs &&
        isstructequal(a.lvl, b.lvl)

    isstructequal(a::T, b::T) where {T <: SparseBytemap} =
        a.I == b.I &&
        a.pos == b.pos &&
        a.tbl == b.tbl &&
        a.srt == b.srt &&
        isstructequal(a.lvl, b.lvl)
end