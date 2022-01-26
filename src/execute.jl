function register()
    Base.eval(Finch, quote
        @generated function execute(ex)
            scope(LowerJuliaContext()) do ctx
                execute_code_lowered(:ex, ex)
            end
        end
    end)
end

function execute_code_lowered(ex, T)
    code = scope(LowerJuliaContext()) do ctx
        prgm = virtualize(ex, T, ctx)
        dimensionalize!(prgm, ctx)
        quote
            $(initialize_program!(prgm, ctx))
            $(scope(ctx) do ctx2
                visit!(prgm, ctx2)
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