
struct DiagMask end

const diagmask = DiagMask()

Base.show(io::IO, ex::DiagMask) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::DiagMask)
    print(io, "diagmask")
end

virtualize(ex, ::Type{DiagMask}, ctx) = diagmask
FinchNotation.finch_leaf(x::DiagMask) = virtual(x)
Finch.virtual_size(::DiagMask, ctx) = (mkdim, mkdim)

function instantiate_reader(arr::DiagMask, ctx, protos::typeof(defaultread)...)
    Unfurled(
        arr = arr,
        body = Furlable(
            body = (ctx, ext) -> Lookup(
                body = (ctx, i) -> Furlable(
                    body = (ctx, ext) -> Pipeline([
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
Finch.virtual_size(::UpTriMask, ctx) = (mkdim, mkdim)

function instantiate_reader(arr::UpTriMask, ctx, protos::typeof(defaultread)...)
    Unfurled(
        arr = arr,
        body = Furlable(
            body = (ctx, ext) -> Lookup(
                body = (ctx, i) -> Furlable(
                    body = (ctx, ext) -> Pipeline([
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
Finch.virtual_size(::LoTriMask, ctx) = (mkdim, mkdim)

function instantiate_reader(arr::LoTriMask, ctx, protos::typeof(defaultread)...)
    Unfurled(
        arr = arr,
        body = Furlable(
            body = (ctx, ext) -> Lookup(
                body = (ctx, i) -> Furlable(
                    body = (ctx, ext) -> Pipeline([
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
Finch.virtual_size(::BandMask, ctx) = (mkdim, mkdim, mkdim)

function instantiate_reader(arr::BandMask, ctx, mode, protos::typeof(defaultread)...)
    Unfurled(
        arr = arr,
        tns = Furlable(
            body = (ctx, ext) -> Lookup(
                body = (ctx, k) -> Furlable(
                    body = (ctx, ext) -> Lookup(
                        body = (ctx, j) -> Furlable(
                            body = (ctx, ext) -> Pipeline([
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