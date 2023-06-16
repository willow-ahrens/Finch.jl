@kwdef struct RootArray
    tag
end

Base.:(==)(tns::RootArray, tns_2::RootArray) = tns.tag == tns_2.tag
Base.hash(tns::RootArray, seed::UInt) = hash(tns.tag, seed)

Base.show(io::IO, ex::RootArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::RootArray)
    print(io, "RootArray(")
    print(io, ex.tag)
    print(io, ")")
end

Base.summary(io::IO, tns::RootArray) = print(io, tns.tag.name)

FinchNotation.finch_leaf(x::RootArray) = virtual(x)

virtual_size(tns::RootArray, ctx) = virtual_size(resolve(tns.tag, ctx), ctx)
virtual_resize!(tns::RootArray, ctx, dims...) = virtual_resize!(resolve(tns.tag, ctx), ctx, dims...)
virtual_default(tns::RootArray, ctx) = virtual_default(resolve(tns.tag, ctx), ctx)

(ctx::Stylize{<:AbstractCompiler})(tns::RootArray) = ctx(resolve(tns.tag, ctx.ctx))
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::RootArray)
    stylize_access(node, ctx, resolve(tns.tag, ctx.ctx))
end

instantiate_reader(tns::RootArray, ctx::LowerJulia, protos...) = instantiate_reader(resolve(tns.tag, ctx), ctx, protos...)
instantiate_updater(tns::RootArray, ctx::LowerJulia, protos...) = instantiate_updater(resolve(tns.tag, ctx), ctx, protos...)

#TODO I don't think we should ever need these
declare!(tns::RootArray, ctx::LowerJulia, init) = declare!(resolve(tns.tag, ctx), ctx, init)
thaw!(tns::RootArray, ctx::LowerJulia) = thaw!(resolve(tns.tag, ctx), ctx)
freeze!(tns::RootArray, ctx::LowerJulia) = freeze!(resolve(tns.tag, ctx), ctx)

function unfurl_access(tns::RootArray, ctx, ext, protos...)
    unfurl_access(resolve(tns.tag, ctx), ctx, ext, protos...)
end

function lower(node::RootArray, ctx::AbstractCompiler, ::DefaultStyle)
    ctx(node.body)
end

lowerjulia_access(ctx::AbstractCompiler, node, tns::RootArray) = 
    lowerjulia_access(ctx, node, resolve(tns.tag, ctx))

getroot(tns::RootArray) = tns.tag

function getroot(node::FinchNode)
    if node.kind === virtual
        return getroot(node.val)
    else
        return node
    end
end