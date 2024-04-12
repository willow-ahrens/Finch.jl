truncate(ctx, node, ext, ext_2) = node

@kwdef struct Furlable
    body
end

FinchNotation.finch_leaf(x::Furlable) = virtual(x)

#Base.show(io::IO, ex::Furlable) = Base.show(io, MIME"text/plain"(), ex)
#function Base.show(io::IO, mime::MIME"text/plain", ex::Furlable)
#    print(io, "Furlable()")
#end


"""
    unfurl(ctx, tns, ext, protos...)
    
Return an array object (usually a looplet nest) for lowering the virtual tensor
`tns`. `ext` is the extent of the looplet. `protos` is the list of protocols
that should be used for each index, but one doesn't need to unfurl all the
indices at once.
"""
function unfurl(ctx, tns::Furlable, ext, mode, protos...)
    tns = tns.body(ctx, ext)
    return tns
end
unfurl(ctx, tns, ext, mode, protos...) = tns

instantiate(tns::Furlable, ctx, mode, protos) = tns