function register()
    Base.eval(Finch, quote
        @generated function execute(ex)
            println(virtualize(:ex, ex))
            println(ex)
            thunk = lower_julia(virtualize(:ex, ex))
            println(thunk)
            thunk
        end
    end)
end

register()