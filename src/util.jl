#TODO should we just have another IR? Ugh idk
shallowcopy(x::T) where T = T([getfield(x, k) for k ∈ fieldnames(T)]...)

kwfields(x::T) where T = Dict((k=>getfield(x, k) for k ∈ fieldnames(T))...)

function refill!(arr, val, p, q)
    p_2 = regrow!(arr, p, q)
    @simd for p_3 = p + 1:p_2
        arr[p_3] = val
    end
    p_2
end

function regrow!(arr, p, q::T) where {T <: Integer}
    p_2 = 2 << (sizeof(T) * 8 - leading_zeros(q)) #round to next power of two, multiply by two
    if p_2 > length(arr)
        resize!(arr, p_2)
    end
    p_2
end

function lower_caches(ex)
    consumers = Dict()
    function collect_consumers(ex, parent)
        if ex isa Symbol
            push!(get!(consumers, parent, Set()), ex)
        elseif ex isa Expr
            if ex.head == :cache
                (var, body) = ex.args
                push!(get!(consumers, var, Set()), parent)
                collect_consumers(body, var)
            else
                args = map(ex.args) do arg
                    collect_consumers(arg, parent)
                end
            end
        end
    end
    collect_consumers(ex, nothing)
    used = Set()
    function mark_used(var)
        if !(var in used)
            push!(used, var)
            for var_2 in get(consumers, var, [])
                mark_used(var_2)
            end
        end
    end
    mark_used(nothing)
    function prune_caches(ex)
        if ex isa Expr
            if ex.head == :cache
                (var, body) = ex.args
                if var in used 
                    return prune_caches(body)
                else
                    quote end
                end
            else
                Expr(ex.head, map(prune_caches, ex.args)...)
            end
        else
            return ex
        end
    end
    return prune_caches(ex)
end

function lower_cleanup(ex, ignore=false)
    if ex isa Expr && ex.head == :cleanup
        (sym::Symbol, result, cleanup) = ex.args
        result = lower_cleanup(result, ignore)
        cleanup = lower_cleanup(cleanup, true)
        if ignore
            return quote
                $result
                $cleanup
            end
        else
            return quote
                $sym = $result
                $cleanup
                $sym
            end
        end
    elseif ex isa Expr && ex.head == :block
        Expr(:block, map(ex.args[1:end - 1]) do arg
            lower_cleanup(arg, true)
        end..., lower_cleanup(ex.args[end], ignore))
    elseif ex isa Expr && ex.head in [:if, :elseif, :for, :while]
        Expr(ex.head, lower_cleanup(ex.args[1]), map(arg->lower_cleanup(arg, ignore), ex.args[2:end])...)
    elseif ex isa Expr
        Expr(ex.head, map(lower_cleanup, ex.args)...)
    else
        ex
    end
end

unquote_literals(ex) = ex
unquote_literals(ex::Expr) = Expr(ex.head, map(unquote_literals, ex.args)...)
unquote_literals(ex::QuoteNode) = unquote_quoted(ex.value)

unquote_quoted(::Missing) = missing
unquote_quoted(ex) = QuoteNode(ex)

"""
    unblock(ex)
Flatten any redundant blocks into a single block, over the whole expression.
"""
function unblock(ex::Expr)
    Rewrite(Postwalk(Chain([
        (@rule :block(~a..., :block(~b...), ~c...) => Expr(:block, a..., b..., c...)),
        (@rule :block(~a) => a),
    ])))(ex)
end
unblock(ex) = ex

"""
    striplines(ex)
Remove line numbers
"""
function striplines(ex::Expr)
    islinenum(x) = x isa LineNumberNode
    Rewrite(Postwalk(@rule :block(~a..., ~b::islinenum, ~c...) => Expr(:block, a..., c...)))(ex)
end
striplines(ex) = ex

(Base.:^)(T::Type, i::Int) = ∘(repeated(T, i)..., identity)
(Base.:^)(f::Function, i::Int) = ∘(repeated(f, i)..., identity)