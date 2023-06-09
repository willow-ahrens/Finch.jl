@kwdef struct RootArray
    tag
    body
end

Base.:(==)(tns::RootArray, tns_2::RootArray) = tns.tag == tns_2.tag
Base.hash(tns::RootArray, seed::UInt) = hash(tns.tag, seed)

Base.show(io::IO, ex::RootArray) = Base.show(io, MIME"text/plain"(), ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::RootArray)
    print(io, "RootArray(")
    print(io, ex.tag)
    print(io, ", ")
    print(io, ex.body)
    print(io, ")")
end

FinchNotation.finch_leaf(x::RootArray) = virtual(x)

virtual_size(tns::RootArray, ctx) = virtual_size(tns.body, ctx)
virtual_resize!(tns::RootArray, ctx, dims...) = virtual_resize!(tns.body, ctx, dims...)
virtual_default(tns::RootArray, ctx) = virtual_default(tns.body, ctx)

(ctx::Stylize{<:AbstractCompiler})(node::RootArray) = ctx(node.body)
function stylize_access(node, ctx::Stylize{<:AbstractCompiler}, tns::RootArray)
    stylize_access(node, ctx, tns.body)
end

unfurl_reader(tns::RootArray, ctx::LowerJulia, protos...) = unfurl_reader(tns.body, ctx, protos...)
unfurl_updater(tns::RootArray, ctx::LowerJulia, protos...) = unfurl_updater(tns.body, ctx, protos...)

declare!(tns::RootArray, ctx::LowerJulia, init) = declare!(tns.body, ctx, init)
thaw!(tns::RootArray, ctx::LowerJulia) = thaw!(tns.body, ctx)
freeze!(tns::RootArray, ctx::LowerJulia) = freeze!(tns.body, ctx)

function unfurl_access(tns::RootArray, ctx, protos...)
    unfurl_access(tns.body, ctx, protos...)
end

function select_access(node, ctx::Finch.SelectVisitor, tns::RootArray)
    select_access(node, ctx, tns.body)
end

function lower(node::RootArray, ctx::AbstractCompiler, ::DefaultStyle)
    ctx(node.body)
end

lowerjulia_access(ctx::AbstractCompiler, node, tns::RootArray) = 
    lowerjulia_access(ctx, node, tns.body)

getdata(tns::RootArray) = tns

function getdata(node::FinchNode)
    if node.kind === virtual
        return getdata(node.val)
    else
        error("getdata: not a virtual node")
    end
end

getroot(tns::RootArray) = tns.tag

function getroot(node::FinchNode)
    if node.kind === virtual
        return getroot(node.val)
    else
        error("getdata: not a virtual node")
    end
end