function register()
    Base.eval(Finch, quote
        @generated function execute(ex)
            scope(LowerJuliaContext()) do ctx
                lower_julia(virtualize(:ex, ex, ctx))
            end
        end
    end)
end

register()