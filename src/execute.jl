function register()
    Base.eval(Finch, quote
        @generated function execute(ex)
            thunk = lower_julia(virtualize(:ex, ex))
            thunk
        end
    end)
end

register()