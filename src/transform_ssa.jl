"""
    TransformSSA(freshen)

A transformation of a program to SSA form. Fresh names will be generated with
`freshen(name)`.
"""
@kwdef mutable struct TransformSSA <: AbstractTransformVisitor
    renames
    binds
    freshen
end

TransformSSA(freshen) = TransformSSA(Dict(), [], freshen)

function resolvename!(root, ctx::TransformSSA)
    name = getname(root)
    if haskey(ctx.renames, name)
        if isempty(ctx.renames[name]) #redefining global name
            name′ = ctx.freshen(name)
            push!(ctx.renames[name], name′)
            return setname(root, name′)
        else
            return setname(root, ctx.renames[name][end])
        end
    else
        ctx.renames[name] = Any[name]
        return setname(root, name)
    end
end

function definename!(root, ctx::TransformSSA)
    name = getname(root)
    push!(ctx.binds, name)
    name2 = ctx.freshen(name)
    push!(get!(ctx.renames, name, []), name2)
    return setname(root, name2)
end

function scope(f::F, ctx::TransformSSA) where {F}
    ctx_2 = TransformSSA(
        renames = ctx.renames, 
        freshen = ctx.freshen,
        binds = [])
    ctx_2.binds = []
    res = f(ctx_2)
    for name in ctx_2.binds
        pop!(ctx.renames[name])
    end
    return res
end

#globals are getglobals(prgm) and getresults(prgm)
#TODO make a version of this that returns tensors that are sources called getsources?
#=
function getglobals(prgm)
    spc = TransformSSA()
    transform_ssa!(prgm, spc)
    return filter(name -> !isempty(spc.renames[name]), keys(spc.renames))
end
=#

function (ctx::TransformSSA)(root::Name)
    resolvename!(root, ctx)
end

function (ctx::TransformSSA)(root::Loop)
    scope(ctx) do ctx2
        idxs = map(idx->definename!(idx, ctx2), root.idxs)
        body = ctx(root.body)
        return loop(idxs, body)
    end
end

function (ctx::TransformSSA)(root::With)
    scope(ctx) do ctx2
        prod = ctx2(root.prod)
        cons = ctx(root.cons)
        return with(cons, prod)
    end
end

function (ctx::TransformSSA)(root::Access)
    if root.mode != Read()
        tns = definename!(root.tns, ctx)
    else
        tns = resolvename!(root.tns, ctx)
    end
    return Access(tns, root.mode, map(ctx, root.idxs))
end