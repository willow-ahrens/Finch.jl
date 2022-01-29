function strip_res(ex, ignore = false)
    if ex isa Expr && ex.head == :block
        if ignore && ex.args[end] isa Symbol && 
                match(r"res(_(\d*)$)?", string(ex.args[end])) !== nothing
            Expr(:block, map(ex.args[1:end-1]) do arg
                if arg isa Expr && arg.head == :(=) && arg.args[1] == ex.args[end]
                    strip_res(arg.args[2], true)
                else
                    strip_res(arg, true)
                end
            end...)
        else
            Expr(:block, map(ex.args[1:end - 1]) do arg
                strip_res(arg, true)
            end..., strip_res(ex.args[end], ignore))
        end
    elseif ex isa Expr && ex.head in [:if, :elseif, :for, :while]
        Expr(ex.head, strip_res(ex.args[1]), map(arg->strip_res(arg, ignore), ex.args[2:end])...)
    elseif ex isa Expr
        Expr(ex.head, map(strip_res, ex.args)...)
    else
        ex
    end
end