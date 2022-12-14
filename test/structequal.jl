isstructequal(a, b) = a === b
isstructequal(a::T, b::T) where {T <: Fiber} = 
    isstructequal(a.lvl, b.lvl) &&
    isstructequal(a.env, b.env)
isstructequal(a::T, b::T)  where {T <: Pattern} =
    a.val == b.val
isstructequal(a::T, b::T) where {T <: Element} =
    a.val == b.val
isstructequal(a::T, b::T) where {T <: RepeatList} =
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
isstructequal(a::T, b::T) where {T <: SparseHash} =
    a.I == b.I &&
    a.pos == b.pos &&
    a.tbl == b.tbl &&
    a.srt == b.srt &&
    isstructequal(a.lvl, b.lvl)
isstructequal(a::T, b::T) where {T <: SparseCoo} =
    a.I == b.I &&
    a.pos == b.pos &&
    a.tbl == b.tbl &&
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
    a.srt_stop == b.srt_stop &&
    isstructequal(a.lvl, b.lvl)