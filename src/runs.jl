

Base.@kwdef mutable struct Run
    body
    ext
end

Pigeon.lower_axes(arr::Run, ctx::LowerJuliaContext) = (arr.ext,) #TODO probably wouldn't need this if tests were more realistic
Pigeon.getsites(arr::Run) = (1,) #TODO this is wrong I think?? and probably wouldn't need this if tests were more realistic
Pigeon.getname(arr::Run) = getname(arr.body)

struct RunAccessStyle end

Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Run) = RunAccessStyle()
Pigeon.combine_style(a::DefaultStyle, b::RunAccessStyle) = RunAccessStyle()
Pigeon.combine_style(a::RunAccessStyle, b::RunAccessStyle) = RunAccessStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::RunAccessStyle)
    @assert !isempty(root.idxs)
    root = visit!(root, AccessRunContext(root))
    #TODO add a simplify step here perhaps
    visit!(root, ctx)
end

struct AccessRunContext <: Pigeon.AbstractTransformContext
    root
end

function Pigeon.visit!(node::Access{Run, Read}, ctx::AccessRunContext, ::DefaultStyle)
    if length(node.idxs) == 1 && node.idxs[1] == ctx.root.idxs[1]
        return Access(node.tns.body, Read(), [])
    end
    return node
end

#assume ssa

struct RunAssignStyle end

Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Access{Run, <:Union{Write, Update}}) = RunAssignStyle()
Pigeon.combine_style(a::DefaultStyle, b::RunAssignStyle) = RunAssignStyle()
Pigeon.combine_style(a::RunAssignStyle, b::RunAssignStyle) = RunAssignStyle()
Pigeon.combine_style(a::RunAccessStyle, b::RunAssignStyle) = RunAccessStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::RunAssignStyle)
    root = visit!(root, AssignRunContext(root))
    @assert !visit!(root, DirtyRunContext(root.idxs[1]))
    return visit!(Loop(root.idxs[2:end], root.body), ctx)
end

Base.@kwdef mutable struct DirtyRunContext <: Pigeon.AbstractCollectContext
    idx
end

Pigeon.collector(ctx::DirtyRunContext) = any

Pigeon.postvisit!(node, ctx::DirtyRunContext) = false 

function Pigeon.visit!(node::Access, ctx::DirtyRunContext, ::DefaultStyle)
    return ctx.idx in node.idxs
end

Base.@kwdef mutable struct AssignRunContext <: Pigeon.AbstractTransformContext
    root
end

function Pigeon.visit!(node::Access{Run, <:Union{Write, Update}}, ctx::AssignRunContext, ::DefaultStyle)
    @assert node.idxs == ctx.root.idxs[1:1]
    Access(node.tns.body, node.mode, [])
end