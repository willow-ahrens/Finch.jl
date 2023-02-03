"""
    TransformSSA(freshen)

A transformation of a program to SSA form. Fresh names will be generated with
`freshen(name)`.
"""
@kwdef mutable struct TransformSSA
    renames
    binds
    freshen
end

function (ctx::TransformSSA)(node)
    if istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
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

function contain(f::F, ctx::TransformSSA) where {F}
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

function (ctx::TransformSSA)(node::IndexNode)
    if node.kind === index
        resolvename!(node, ctx)
    elseif node.kind === with
        contain(ctx) do ctx_2
            prod = ctx_2(node.prod)
            cons = ctx(node.cons)
            return with(cons, prod)
        end
    elseif node.kind === loop
        contain(ctx) do ctx_2
            idx = definename!(node.idx, ctx_2)
            body = ctx(node.body)
            return loop(idx, body)
        end
    elseif istree(node)
        similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        node
    end
end