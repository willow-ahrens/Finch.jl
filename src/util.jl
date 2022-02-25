#TODO should we just have another IR? Ugh idk
shallowcopy(x::T) where T = T([getfield(x, k) for k ∈ fieldnames(T)]...)

function refill!(arr, val, p, q)
    p_2 = regrow!(arr, p, q)
    @simd for p_3 = p + 1:p_2
        arr[p_3] = val
    end
    p_2
end

function regrow!(arr, p, q)
    p_2 = p
    while p_2 < q
        p_2 *= 4
    end
    if p_2 > length(arr)
        resize!(arr, p_2)
    end
    p_2
end

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