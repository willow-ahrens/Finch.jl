@generated function execute(ex)
    thunk = lower_julia(virtualize(:ex, ex))
    thunk
end
