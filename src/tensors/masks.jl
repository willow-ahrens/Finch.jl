
struct DiagMask end

const diagmask = DiagMask()

Base.show(io::IO, ex::DiagMask) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::DiagMask)
    print(io, "diagmask")
end

virtualize(ex, ::Type{DiagMask}, ctx) = diagmask
FinchNotation.finch_leaf(x::DiagMask) = virtual(x)
Finch.virtual_size(::DiagMask, ctx) = (dimless, dimless)

function instantiate_reader(arr::DiagMask, ctx, subprotos, ::typeof(defaultread), ::typeof(defaultread))
    Unfurled(
        arr = arr,
        body = Furlable(
            body = (ctx, ext) -> Lookup(
                body = (ctx, i) -> Furlable(
                    body = (ctx, ext) -> Sequence([
                        Phase(
                            stop = (ctx, ext) -> value(:($(ctx(i)) - 1)),
                            body = (ctx, ext) -> Run(body=Fill(false))
                        ),
                        Phase(
                            stop = (ctx, ext) -> i,
                            body = (ctx, ext) -> Run(body=Fill(true)),
                        ),
                        Phase(body = (ctx, ext) -> Run(body=Fill(false)))
                    ])
                )
            )
        )
    )
end

struct UpTriMask end

const uptrimask = UpTriMask()

Base.show(io::IO, ex::UpTriMask) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::UpTriMask)
    print(io, "uptrimask")
end

virtualize(ex, ::Type{UpTriMask}, ctx) = uptrimask
FinchNotation.finch_leaf(x::UpTriMask) = virtual(x)
Finch.virtual_size(::UpTriMask, ctx) = (dimless, dimless)

function instantiate_reader(arr::UpTriMask, ctx, subprotos, ::typeof(defaultread), ::typeof(defaultread))
    Unfurled(
        arr = arr,
        body = Furlable(
            body = (ctx, ext) -> Lookup(
                body = (ctx, i) -> Furlable(
                    body = (ctx, ext) -> Sequence([
                        Phase(
                            stop = (ctx, ext) -> value(:($(ctx(i)))),
                            body = (ctx, ext) -> Run(body=Fill(true))
                        ),
                        Phase(
                            body = (ctx, ext) -> Run(body=Fill(false)),
                        )
                    ])
                )
            )
        )
    )
end

struct LoTriMask end

const lotrimask = LoTriMask()

Base.show(io::IO, ex::LoTriMask) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::LoTriMask)
    print(io, "lotrimask")
end

virtualize(ex, ::Type{LoTriMask}, ctx) = lotrimask
FinchNotation.finch_leaf(x::LoTriMask) = virtual(x)
Finch.virtual_size(::LoTriMask, ctx) = (dimless, dimless)

function instantiate_reader(arr::LoTriMask, ctx, subprotos, ::typeof(defaultread), ::typeof(defaultread))
    Unfurled(
        arr = arr,
        body = Furlable(
            body = (ctx, ext) -> Lookup(
                body = (ctx, i) -> Furlable(
                    body = (ctx, ext) -> Sequence([
                        Phase(
                            stop = (ctx, ext) -> value(:($(ctx(i)) - 1)),
                            body = (ctx, ext) -> Run(body=Fill(false))
                        ),
                        Phase(
                            body = (ctx, ext) -> Run(body=Fill(true)),
                        )
                    ])
                )
            )
        )
    )
end

struct BandMask end

const bandmask = BandMask()

Base.show(io::IO, ex::BandMask) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::BandMask)
    print(io, "bandmask")
end

virtualize(ex, ::Type{BandMask}, ctx) = bandmask
FinchNotation.finch_leaf(x::BandMask) = virtual(x)
Finch.virtual_size(::BandMask, ctx) = (dimless, dimless, dimless)

function instantiate_reader(arr::BandMask, ctx, mode, subprotos, ::typeof(defaultread), ::typeof(defaultread), ::typeof(defaultread))
    Unfurled(
        arr = arr,
        tns = Furlable(
            body = (ctx, ext) -> Lookup(
                body = (ctx, k) -> Furlable(
                    body = (ctx, ext) -> Lookup(
                        body = (ctx, j) -> Furlable(
                            body = (ctx, ext) -> Sequence([
                                Phase(
                                    stop = (ctx, ext) -> value(:($(ctx(j)) - 1)),
                                    body = (ctx, ext) -> Run(body=Fill(false))
                                ),
                                Phase(
                                    stop = (ctx, ext) -> k,
                                    body = (ctx, ext) -> Run(body=Fill(true))
                                ),
                                Phase(
                                    body = (ctx, ext) -> Run(body=Fill(false)),
                                )
                            ])
                        )
                    )
                )
            )
        )
    )
end

struct SplitMask
    P::Int
end

Base.show(io::IO, ex::SplitMask) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::SplitMask)
    print(io, "splitmask(", ex.P, ")")
end

struct VirtualSplitMask
    P
end

function virtualize(ex, ::Type{SplitMask}, ctx)
    return VirtualSplitMask(value(:($ex.P), Int))
end

FinchNotation.finch_leaf(x::VirtualSplitMask) = virtual(x)
Finch.virtual_size(arr::VirtualSplitMask, ctx) = (dimless, Extent(literal(1), arr.P))

function instantiate_reader(arr::VirtualSplitMask, ctx, subprotos, ::typeof(defaultread), ::typeof(defaultread))
    Unfurled(
        arr = arr,
        body = Furlable(
            body = (ctx, ext) -> Lookup(
                body = (ctx, i) -> Furlable(
                    body = (ctx, ext_2) -> begin
                        Sequence([
                            Phase(
                                stop = (ctx, ext) -> call(+, call(-, getstart(ext_2), 1), call(fld, call(*, measure(ext_2), call(-, i, 1)), arr.P)),
                                body = (ctx, ext) -> Run(body=Fill(false))
                            ),
                            Phase(
                                stop = (ctx, ext) -> call(+, call(-, getstart(ext_2), 1), call(fld, call(*, measure(ext_2), i), arr.P)),
                                body = (ctx, ext) -> Run(body=Fill(true)),
                            ),
                            Phase(body = (ctx, ext) -> Run(body=Fill(false)))
                        ])
                    end
                )
            )
        )
    )
end

struct ChunkMask{Dim}
    b::Int
    dim::Dim
end

Base.show(io::IO, ex::ChunkMask) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::ChunkMask)
    print(io, "chunkmask(", ex.b, ex.dim, ")")
end

struct VirtualChunkMask
    b
    dim
end

function virtualize(ex, ::Type{ChunkMask{Dim}}, ctx) where {Dim}
    return VirtualChunkMask(
        value(:($ex.b), Int),
        virtualize(:($ex.dim), Dim, ctx))
end

function chunkmask end

function Finch.virtual_call(::typeof(chunkmask), ctx, b, dim)
    if dim.kind === virtual
        return VirtualChunkMask(b, dim.val)
    end
end

virtual_uncall(arr::VirtualChunkMask) = call(chunkmask, arr.b, arr.dim)

FinchNotation.finch_leaf(x::VirtualChunkMask) = virtual(x)
Finch.virtual_size(arr::VirtualChunkMask, ctx) = (arr.dim, Extent(literal(1), call(cld, measure(arr.dim), arr.b)))

function instantiate_reader(arr::VirtualChunkMask, ctx, subprotos, ::typeof(defaultread), ::typeof(defaultread))
    Unfurled(
        arr = arr,
        body = Furlable(
            body = (ctx, ext) -> Sequence([
                Phase(
                    stop = (ctx, ext) -> call(cld, measure(arr.dim), arr.b),
                    body = (ctx, ext) -> Lookup(
                        body = (ctx, i) -> Furlable(
                            body = (ctx, ext) -> Sequence([
                                Phase(
                                    stop = (ctx, ext) -> call(*, arr.b, call(-, i, 1)),
                                    body = (ctx, ext) -> Run(body=Fill(false))
                                ),
                                Phase(
                                    stop = (ctx, ext) -> call(*, arr.b, i),
                                    body = (ctx, ext) -> Run(body=Fill(true)),
                                ),
                                Phase(body = (ctx, ext) -> Run(body=Fill(false)))
                            ])
                        )
                    )
                ),
                Phase(
                    body = (ctx, ext) -> Run(
                        body = Furlable(
                            body = (ctx, ext) -> Sequence([
                                Phase(
                                    stop = (ctx, ext) -> call(*, call(fld, measure(arr.dim), arr.b), arr.b),
                                    body = (ctx, ext) -> Run(body=Fill(false))
                                ),
                                Phase(
                                    body = (ctx, ext) -> Run(body=Fill(true)),
                                )
                            ])
                        )
                    )
                )
            ])
        )
    )
end