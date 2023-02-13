
struct DiagMask end

const diagmask = DiagMask()

Base.show(io::IO, ex::DiagMask) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::DiagMask)
    print(io, "diagmask")
end

virtualize(ex, ::Type{DiagMask}, ctx) = diagmask
FinchNotation.isliteral(::DiagMask) = false
Finch.virtual_size(::DiagMask, ctx) = (nodim, nodim)

function get_reader(::DiagMask, ctx, protos...)
    tns = Furlable(
        size = (nodim, nodim),
        body = (ctx, idx, ext) -> Lookup(
            body = (i) -> Furlable(
                size = (nodim,),
                body = (ctx, idx, ext) -> Pipeline([
                    Phase(
                        stride = (ctx, idx, ext) -> value(:($(ctx(i)) - 1)),
                        body = (start, step) -> Run(body=Simplify(Fill(false)))
                    ),
                    Phase(
                        stride = (ctx, idx, ext) -> i,
                        body = (start, step) -> Run(body=Simplify(Fill(true))),
                    ),
                    Phase(body = (start, step) -> Run(body=Simplify(Fill(false))))
                ])
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
FinchNotation.isliteral(::UpTriMask) = false
Finch.virtual_size(::UpTriMask, ctx) = (nodim, nodim)

function get_reader(::UpTriMask, ctx, protos...)
    tns = Furlable(
        size = (nodim, nodim),
        body = (ctx, idx, ext) -> Lookup(
            body = (i) -> Furlable(
                size = (nodim,),
                body = (ctx, idx, ext) -> Pipeline([
                    Phase(
                        stride = (ctx, idx, ext) -> value(:($(ctx(i)))),
                        body = (start, step) -> Run(body=Simplify(Fill(true)))
                    ),
                    Phase(
                        body = (start, step) -> Run(body=Simplify(Fill(false))),
                    )
                ])
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
FinchNotation.isliteral(::LoTriMask) = false
Finch.virtual_size(::LoTriMask, ctx) = (nodim, nodim)

function get_reader(::LoTriMask, ctx, protos...)
    tns = Furlable(
        size = (nodim, nodim),
        body = (ctx, idx, ext) -> Lookup(
            body = (i) -> Furlable(
                size = (nodim,),
                body = (ctx, idx, ext) -> Pipeline([
                    Phase(
                        stride = (ctx, idx, ext) -> value(:($(ctx(i)) - 1)),
                        body = (start, step) -> Run(body=Simplify(Fill(false)))
                    ),
                    Phase(
                        body = (start, step) -> Run(body=Simplify(Fill(true))),
                    )
                ])
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
FinchNotation.isliteral(::BandMask) = false
Finch.virtual_size(::BandMask, ctx) = (nodim, nodim, nodim)

function get_reader(::BandMask, ctx, mode, protos...)
    tns = Furlable(
        size = (nodim, nodim, nodim),
        body = (ctx, idx, ext) -> Lookup(
            body = (k) -> Furlable(
                size = (nodim, nodim),
                body = (ctx, idx, ext) -> Lookup(
                    body = (j) -> Furlable(
                        size = (nodim,),
                        body = (ctx, idx, ext) -> Pipeline([
                            Phase(
                                stride = (ctx, idx, ext) -> value(:($(ctx(j)) - 1)),
                                body = (start, step) -> Run(body=Simplify(Fill(false)))
                            ),
                            Phase(
                                stride = (ctx, idx, ext) -> k,
                                body = (start, step) -> Run(body=Simplify(Fill(true)))
                            ),
                            Phase(
                                body = (start, step) -> Run(body=Simplify(Fill(false))),
                            )
                        ])
                    )
                )
            )
        )
    )
end