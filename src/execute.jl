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
        Pigeon.visit!(prgm, ctx)
    end
    MacroTools.prettify(code, alias=false, lines=false)
end

register()