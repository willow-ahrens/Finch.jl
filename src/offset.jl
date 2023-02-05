struct Offset end

Base.show(io::IO, ex::Offset) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Offset)
	print(io, "Offset()")
end

IndexNotation.value_instance(arg::Offset) = arg

const offset = Offset()

#Base.size(vec::Offset) = (nodim, nodim)

Base.getindex(arr::Offset, d, i) = d - i

struct VirtualOffset end

Base.show(io::IO, ex::VirtualOffset) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::VirtualOffset)
	print(io, "VirtualOffset()")
end

IndexNotation.isliteral(::VirtualOffset) =  false

virtualize(ex, ::Type{Offset}, ctx) = VirtualOffset()

(ctx::LowerJulia)(tns::VirtualOffset) = :(Offset())

virtual_size(arr::VirtualOffset, ctx::LowerJulia, dim) = (nodim, nodim)
virtual_resize!(arr::VirtualOffset, ctx::LowerJulia, delta_dim, idx_dim) = (arr, virtual_eldim(arr, ctx, delta_dim, idx_dim))
virtual_eldim(arr::VirtualOffset, ctx::LowerJulia, delta_dim, idx_dim) = combinedim(ctx, widendim(shiftdim(idx_dim, call(-, getstop(delta_dim)))), widendim(idx_dim))

function get_reader(::VirtualOffset, ctx, proto_delta, proto_idx)
    tns = Furlable(
        size = (nodim, nodim),
        body = (ctx, idx, ext) -> Lookup(
            body = (delta) -> Furlable(
                size = (nodim,),
                body = nothing,
                fuse = (tns, ctx, idx, ext) -> Pipeline([
                    Phase(
                        stride = (ctx, idx, ext_2) -> call(+, getstart(ext), delta, -1),
                        body = (start, step) -> Run(Simplify(Fill(literal(missing)))),
                    ),
                    Phase(
                        stride = (ctx, idx, ext_2) -> call(+, getstop(ext), delta),
                        body = (start, step) -> truncate(Shift(tns, delta), ctx, ext, Extent(start, step))
                    ),
                    Phase(
                        body = (start, step) -> Run(Simplify(Fill(literal(missing)))),
                    )
                ])
            )
        )
    )
end