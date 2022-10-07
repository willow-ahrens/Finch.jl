function register()
    Base.eval(Finch, quote
        @generated function execute(ex)
            contain(LowerJulia()) do ctx
                execute_code(:ex, ex)
            end
        end
    end)
end

struct Lifetime <: IndexNode
    body
end

lifetime(arg) = Lifetime(arg)

SyntaxInterface.istree(::Lifetime) = true
SyntaxInterface.arguments(ex::Lifetime) = [ex.body]
SyntaxInterface.operation(::Lifetime) = lifetime
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(lifetime), args) = Lifetime(args...)

IndexNotation.isliteral(::Lifetime) =  false

struct LifetimeStyle end

Base.show(io, ex::Lifetime) = Base.show(io, MIME"text/plain", ex)
function Base.show(io::IO, mime::MIME"text/plain", ex::Lifetime)
    print(io, "Lifetime(")
    print(io, ex.body)
    print(io, ")")
end

(ctx::Stylize{LowerJulia})(node::Lifetime) = result_style(LifetimeStyle(), ctx(node.body))
combine_style(a::DefaultStyle, b::LifetimeStyle) = LifetimeStyle()
combine_style(a::ThunkStyle, b::LifetimeStyle) = ThunkStyle()
combine_style(a::LifetimeStyle, b::LifetimeStyle) = LifetimeStyle()

function (ctx::LowerJulia)(prgm::Lifetime, ::LifetimeStyle)
    prgm = prgm.body
    quote
        $(contain(ctx) do ctx_2
            prgm = Initialize(ctx = ctx_2)(prgm)
            ctx_2(prgm)
        end)
        $(contain(ctx) do ctx_2
            prgm = Finalize(ctx = ctx_2)(prgm)
            :(($(map(getresults(prgm)) do tns
                :($(getname(tns)) = $(ctx_2(tns)))
            end...), ))
        end)
    end
end

function execute_code(ex, T)
    prgm = nothing
    code = contain(LowerJulia()) do ctx
        quote
            $(begin
                prgm = virtualize(ex, T, ctx)
                #The following call separates tensor and index names from environment symbols.
                #TODO we might want to keep the namespace around, and/or further stratify index
                #names from tensor names
                contain(ctx) do ctx_2
                    prgm = TransformSSA(Freshen())(prgm)
                    prgm = ThunkVisitor(ctx_2)(prgm) #TODO this is a bit of a hack.
                    (prgm, dims) = dimensionalize!(prgm, ctx_2)
                    prgm = Initialize(ctx = ctx_2)(prgm)
                    prgm = ThunkVisitor(ctx_2)(prgm) #TODO this is a bit of a hack.
                    prgm = simplify(prgm)
                    ctx_2(prgm)
                end
            end)
            $(contain(ctx) do ctx_2
                prgm = Finalize(ctx = ctx_2)(prgm)
                :(($(map(getresults(prgm)) do tns
                    :($(getname(tns)) = $(ctx_2(tns)))
                end...), ))
            end)
        end
    end
    code = quote
        @inbounds begin
            $code
        end
    end
    code |>
        lower_caches |>
        lower_cleanup |>
        MacroTools.striplines |>
        MacroTools.flatten |>
        MacroTools.unresolve |>
        MacroTools.resyntax |>
        unquote_literals
end

macro finch(ex)
    results = Set()
    prgm = IndexNotation.capture_finch_instance(ex, results=results)
    thunk = quote
        res = $execute($prgm)
    end
    for tns in results
        push!(thunk.args, quote
            $(esc(tns)) = res.$tns
        end)
    end
    push!(thunk.args, quote
        res
    end)
    thunk
end

macro finch_code(ex)
    prgm = IndexNotation.capture_finch_instance(ex)
    return quote
        $execute_code(:ex, typeof($prgm))
    end
end

"""
    Initialize(ctx)

A transformation to initialize tensors that have just entered into scope.

See also: [`initialize!`](@ref)
"""
@kwdef struct Initialize{Ctx}
    ctx::Ctx
    target=nothing
    escape=[]
end
initialize!(tns, ctx, mode, idxs...) = access(tns, mode, idxs...)
function (ctx::Initialize)(node)
    if istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end

function (ctx::Initialize)(node::CINNode)
    if node.head === access && node.tns isa CINNode && node.tns.head === virtual
        if (ctx.target === nothing || (getname(node.tns) in ctx.target)) && !(getname(node.tns) in ctx.escape)
            initialize!(node.tns.val, ctx.ctx, node.mode, map(ctx, node.idxs)...)
        else
            return access(node.tns, node.mode, map(ctx, node.idxs)...)
        end
    elseif node.head === with
        ctx_2 = Initialize(ctx.ctx, ctx.target, union(ctx.escape, map(getname, getresults(node.prod))))
        with(ctx_2(node.cons), ctx_2(node.prod))
    elseif istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end

"""
    Finalize(ctx)

A transformation to finalize output tensors before they leave scope and are
returned to the caller.

See also: [`finalize!`](@ref)
"""
@kwdef struct Finalize{Ctx}
    ctx::Ctx
    target=nothing
    escape=[]
end
finalize!(tns, ctx, mode, idxs...) = tns
function (ctx::Finalize)(node)
    if istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end

function (ctx::Finalize)(node::CINNode)
    if node.head === access && node.tns isa CINNode && node.tns.head === virtual
        if (ctx.target === nothing || (getname(node.tns) in ctx.target)) && !(getname(node.tns) in ctx.escape)
            access(finalize!(node.tns.val, ctx.ctx, node.mode, node.idxs...), node.mode, node.idxs...)
        else
            access(node.tns, node.mode, map(ctx, node.idxs)...)
        end
    elseif node.head === with
        ctx_2 = Finalize(ctx.ctx, ctx.target, union(ctx.escape, map(getname, getresults(node.prod))))
        with(ctx_2(node.cons), ctx_2(node.prod))
    elseif istree(node)
        return similarterm(node, operation(node), map(ctx, arguments(node)))
    else
        return node
    end
end

register()