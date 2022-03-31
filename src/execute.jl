function register()
    Base.eval(Finch, quote
        @generated function execute(ex)
            contain(LowerJulia()) do ctx
                execute_code_lowered(:ex, ex)
            end
        end
    end)
end

function execute_code_lowered(ex, T)
    prgm = nothing
    code = contain(LowerJulia()) do ctx
        quote
            $(contain(ctx) do ctx_2
                prgm = virtualize(ex, T, ctx)
                #The following call separates tensor and index names from environment symbols.
                #TODO we might want to keep the namespace around, and/or further stratify index
                #names from tensor names
                prgm = TransformSSA(Freshen())(prgm)
                GatherDimensions(ctx, ctx.dims)(prgm)
                prgm = Initialize(ctx_2)(prgm)
                prgm = ThunkVisitor(ctx_2)(prgm) #TODO this is a bit of a hack.
                ctx_2(prgm)
            end)
            $(contain(ctx) do ctx_2
                prgm = Finalize(ctx_2)(prgm)
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
    code = MacroTools.prettify(strip_res(code), alias=false, lines=false)
end

macro index(ex)
    results = Set()
    prgm = IndexNotation.capture_index_instance(ex; namify=false, mode = Read(), results = results)
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

macro index_code_lowered(ex)
    prgm = IndexNotation.capture_index_instance(ex; namify=false, mode = Read(), results=Set())
    return quote
        $execute_code_lowered(:ex, typeof($prgm))
    end
end

"""
    Initialize(ctx)

A transformation to initialize output tensors that have just entered into scope.

See also: [`initialize!`](@ref)
"""
struct Initialize{Ctx} <: AbstractTransformVisitor
    ctx::Ctx
end
initialize!(tns, ctx, mode, idxs...) = access(tns, mode, idxs...)

(ctx::Initialize)(node::With, ::DefaultStyle) =
    With(ctx(node.cons), node.prod)

function postvisit!(acc::Access{<:Any, <:Union{Write, Update}}, ctx::Initialize, args)
    initialize!(acc.tns, ctx.ctx, acc.mode, acc.idxs...)
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
finalize!(tns, ctx, mode) = tns

(ctx::Finalize)(node::With, ::DefaultStyle) =
    With(ctx(node.cons), node.prod)

function postvisit!(acc::Access{<:Any, <:Union{Write, Update}}, ctx::Finalize, args)
    Access(finalize!(acc.tns, ctx.ctx, acc.mode), acc.mode, acc.idxs)
end


register()