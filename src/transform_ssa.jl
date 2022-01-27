struct SSAContext{Ctx} <: AbstractTransformContext
    renames
    binds
    ctx::Ctx
end

SSAContext(ctx) = SSAContext(Dict(), [], ctx)

function resolvename!(root, ctx::SSAContext, freshen)
    name = getname(root)
    if haskey(ctx.renames, name)
        if isempty(ctx.renames[name]) #redefining global name
            name′ = freshen(name, ctx.ctx)
            push!(ctx.renames[name], name′)
            return rename(root, name′)
        else
            return rename(root, ctx.renames[name][end])
        end
    else
        ctx.renames[name] = Any[name]
        return rename(root, name)
    end
end

function definename!(root, ctx::SSAContext, freshen)
    name = getname(root)
    push!(ctx.binds, name)
    if haskey(ctx.renames, name)
        name′ = freshen(name, ctx.ctx)
        push!(ctx.renames[name], name′)
        return rename(root, name′)
    else
        ctx.renames[name] = Any[name]
        return rename(root, name)
    end
end

function scope(f::F, ctx::SSAContext) where {F}
    binds′ = []
    res = f(SSAContext(ctx.renames, binds′))
    for name in binds′
        pop!(ctx.renames[name])
    end
    return res
end

#globals are getglobals(prgm) and getresult(prgm)
function getarguments(prgm)
    spc = SSAContext()
    transform_ssa!(prgm, spc)
    return filter(name -> !isempty(spc.renames[name]), keys(spc.renames))
end

function visit!(root::Name, ctx::SSAContext)
    resolvename!(root, ctx)
end

function visit!(root::Loop, ctx::SSAContext)
    scope(ctx) do ctx′
        idxs = map(idx->definename!(idx, ctx′), root.idxs)
        body = ctx(root.body)
        return loop(idxs, body)
    end
end

function visit!(root::With, ctx::SSAContext)
    scope(ctx) do ctx′
        prod = ctx(root.prod, ctx′)
        cons = ctx(root.cons, ctx)
        return with(cons, prod)
    end
end

function visit!(root::Access, ctx::SSAContext)
    if root.mode != Read()
        tns = definename!(root.tns, ctx)
    else
        tns = resolvename!(root.tns, ctx)
    end
    return Access(tns, root.mode, map(ctx, root.idxs))
end

is_homomorphic(a, b) = is_homomorphic(a, b, Dict())
function _is_homomorphic(a, b, names)
    res = is_homomorphic(a, b, names)
    if !res
        println(a)
        println(b)
        println()
    end
    return res
end

function is_homomorphic(a, b, names)
    if istree(a) && istree(b)
        if operation(a) == operation(b)
            if length(arguments(a)) == length(arguments(b))
                return all(map((c, d) -> is_homomorphic(c, d, names), arguments(a), arguments(b)))
            end
        end
    else
        if isrenamable(a) && isrenamable(b)
            return a == rename(deepcopy(b), get!(names, getname(a), getname(a)))
        else
            return a == b
        end
    end
    return false
end