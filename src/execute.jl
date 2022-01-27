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
    code = scope(LowerJulia()) do ctx
        prgm = virtualize(ex, T, ctx)
        prgm = TransformSSA(ctx.freshen)(prgm)
        GatherDimensions(ctx, ctx.dims)(prgm)
        quote
            $(initialize_program!(prgm, ctx))
            $(scope(ctx) do ctx2
                (ctx2)(prgm)
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

register()