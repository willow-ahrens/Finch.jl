using Pigeon: Read, Write, Update

Base.@kwdef struct Run
    body
    ext
end

Pigeon.lower_axes(arr::Run, ctx::LowerJuliaContext) = (arr.ext,) #TODO probably wouldn't need this if tests were more realistic
Pigeon.getsites(arr::Run) = (1,) #TODO this is wrong I think?? and probably wouldn't need this if tests were more realistic
Pigeon.getname(arr::Run) = getname(arr.body)

struct RunStyle end

Pigeon.make_style(root::Loop, ctx::LowerJuliaContext, node::Run) = RunStyle()
Pigeon.combine_style(a::DefaultStyle, b::RunStyle) = RunStyle()
Pigeon.combine_style(a::RunStyle, b::RunStyle) = RunStyle()

function Pigeon.visit!(root::Loop, ctx::LowerJuliaContext, ::RunStyle)
    #TODO all runs in rhs become scalars
    #TODO add a simplify step perhaps
    #TODO if we had a run-length lhs whose rhs was independent of i, we should do something clever here
    #TODO if we had a run on the lhs, we could substitute something here
    #TODO essentially, this is an unwrap and simplify thing
    @assert !isempty(root.idxs)
    root = visit!(root, AccessRunContext(root))
    dirty = DirtyRunContext(idx = root.idxs[1])
    visit!(root, dirty)
    root = visit!(root, AssignRunContext(root, dirty.deps))
    dirty = DirtyRunContext(idx = root.idxs[1])
    visit!(root, dirty)
    #TODO This step is a bit of a hack. At this point, we probably have for i scalar[] += scalar[].
    if !any(values(dirty.deps))
        return visit!(Loop(root.idxs[2:end], root.body), ctx)
    else
        return visit!(root, ctx)
    end
end

struct AccessRunContext <: Pigeon.AbstractTransformContext
    root
end

function Pigeon.visit!(node::Access{Run, Read}, ctx::AccessRunContext, ::DefaultStyle)
    if length(node.idxs) == 1 && node.idxs[1] == ctx.root.idxs[1]
        return node.tns.body
    end
    return node
end

#assume ssa

Base.@kwdef mutable struct DirtyRunContext <: Pigeon.AbstractWalkContext
    idx
    lhs = nothing
    deps = DefaultDict(false)
end

function Pigeon.visit!(node::With, ctx::DirtyRunContext, ::DefaultStyle)
    prod = Pigeon.visit!(node.prod, ctx)
    cons = Pigeon.visit!(node.cons, ctx)
end

function Pigeon.visit!(node::Access{<:Any, Read}, ctx::DirtyRunContext, ::DefaultStyle)
    ctx.deps[ctx.lhs] |= ((ctx.idx in node.idxs) | ctx.deps[getname(node.tns)])
end

function Pigeon.visit!(node::Assign, ctx::DirtyRunContext, ::DefaultStyle)
    ctx.lhs = getname(node.lhs.tns)
    visit!(node.rhs, ctx)
end

Base.@kwdef mutable struct AssignRunContext <: Pigeon.AbstractTransformContext
    root
    deps
end

function Pigeon.visit!(node::Access{Run, <:Union{Write, Update}}, ctx::AssignRunContext, ::DefaultStyle)
    @assert !ctx.deps[getname(node.tns)]
    @assert node.idxs == ctx.root.idxs[1:1]
    node.tns.body
end