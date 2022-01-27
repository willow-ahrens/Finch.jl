function register()
    Base.eval(Finch, quote
        @generated function execute(ex)
            scope(LowerJulia()) do ctx
                execute_code_lowered(:ex, ex)
            end
        end
    end)
end

function execute_code_lowered(ex, T)
    prgm = nothing
    code = scope(LowerJulia()) do ctx
        quote
            $(scope(ctx) do ctx2
                prgm = virtualize(ex, T, ctx)
                #The following call separates tensor and index names from environment symbols.
                #TODO we might want to keep the namespace around, and/or further stratify index
                #names from tensor names
                prgm = TransformSSA(Freshen())(prgm)
                GatherDimensions(ctx, ctx.dims)(prgm)
                prgm = Initialize(ctx)(prgm)
                ctx2(prgm)
            end)
            $(scope(ctx) do ctx2
                prgm = Finalize(ctx2)(prgm)
                :(($(map(getresults(prgm)) do tns
                    :($(getname(tns)) = $(ctx2(tns)))
                end...), ))
            end)
        end
    end
    code = quote
        @inbounds begin
            $code
        end
    end
    code = MacroTools.prettify(code, alias=false, lines=false)
end

"""
    Initialize(ctx)

A transformation to initialize output tensors that have just entered into scope.

See also: [`initialize!`](@ref)
"""
struct Initialize{Ctx} <: AbstractTransformVisitor
    ctx::Ctx
end
initialize!(tns, ctx) = tns

(ctx::Initialize)(node::With, ::DefaultStyle) =
    With(ctx(node.cons), node.prod)

function postvisit!(acc::Access{<:Any, <:Union{Write, Update}}, ctx::Initialize, args)
    Access(initialize!(acc.tns, ctx.ctx), acc.mode, acc.idxs)
end

"""
    Finalize(ctx)

A transformation to finalize output tensors before they leave scope and are
returned to the caller.

See also: [`finalize!`](@ref)
"""
struct Finalize{Ctx} <: AbstractTransformVisitor
    ctx::Ctx
end
finalize!(tns, ctx) = tns

(ctx::Finalize)(node::With, ::DefaultStyle) =
    With(ctx(node.cons), node.prod)

function postvisit!(acc::Access{<:Any, <:Union{Write, Update}}, ctx::Finalize, args)
    Access(finalize!(acc.tns, ctx.ctx), acc.mode, acc.idxs)
end


register()