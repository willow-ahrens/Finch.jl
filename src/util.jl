#TODO should we just have another IR? Ugh idk
shallowcopy(x::T) where T = T([getfield(x, k) for k ∈ fieldnames(T)]...)

kwfields(x::T) where T = Dict((k=>getfield(x, k) for k ∈ fieldnames(T))...)

function fill_range!(arr, v, i, j)
    @simd for k = i:j
        arr[k] = v
    end
    arr
end

function resize_if_smaller!(arr, i)
    if length(arr) < i
        resize!(arr, i)
    end
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

isgensym(s::Symbol) = occursin("#", string(s))
isgensym(s) = false

function gensymname(x::Symbol)
    m = Base.match(r"##(.+)#\d+", String(x))
    m === nothing || return m.captures[1]
    m = Base.match(r"#\d+#(.+)", String(x))
    m === nothing || return m.captures[1]
    return "x"
end

function regensym(ex)
    counter = 0
    syms = Dict{Symbol, Symbol}()
    Rewrite(Postwalk((x) -> if isgensym(x) 
        get!(()->Symbol("_", gensymname(x), "_", counter+=1), syms, x)
    end))(ex)
end

isassign(x) = x in Set([:+=, :*=, :&=, :|=, :(=)])
ispure(x) = string(x)[end] != '!'

issymbol(x) = x isa Symbol
isexpr(x) = x isa Expr

mark_dead(ex, refs, res) = ex, refs
function mark_dead(ex::Symbol, refs, res)
    return ex, (res ? union(refs, [ex]) : refs)
end
function mark_dead(ex::Expr, refs, res)
    if @capture ex :dead(~arg)
        return mark_dead(arg, refs, res)
    elseif @capture ex :block(~args...)
        args_2 = []
        for arg in args[end:-1:1]
            (arg, refs) = mark_dead(arg, refs, res)
            res = false
            push!(args_2, arg)
        end
        return Expr(:block, reverse(args_2)...), refs
    elseif @capture(ex, (~f)(~args...)) && f in (:ref, :call, :., :curly, :string, :kw)
        if f == :call && !ispure(args[1])
            println(args[1])
            res = true
        end
        args_2 = []
        for arg in args[end:-1:1]
            (arg, refs) = mark_dead(arg, refs, res)
            push!(args_2, arg)
        end
        return Expr(f, reverse(args_2)...), refs
    elseif @capture(ex, :tuple(~args...))
        args_2 = []
        for arg in args[end:-1:1]
            if @capture(arg, :(=)(~lhs, ~rhs))
                (lhs, refs) = mark_dead(lhs, refs, res)
                (rhs, refs) = mark_dead(rhs, refs, res)
                arg = :($lhs = $rhs)
            else
                (arg, refs) = mark_dead(arg, refs, res)
            end
            push!(args_2, arg)
        end
        return Expr(f, reverse(args_2)...), refs
    elseif (@capture ex (~f)(~cond, ~body)) && f in [:&&, :||]
        (body, body_refs) = mark_dead(body, refs, res)
        refs = union(body_refs, refs)
        (cond, refs) = mark_dead(cond, refs, res)
        return Expr(f, cond, body), refs
    elseif (@capture ex (~f)(~cond, ~body)) && f in [:if, :elseif]
        body, body_refs = mark_dead(body, refs, res)
        cond, refs = mark_dead(cond, union(refs, body_refs), true)
        return Expr(f, cond, body), refs
    elseif (@capture ex (~f)(~cond, ~body, ~tail)) && f in [:if, :elseif]
        body, body_refs = mark_dead(body, refs, res)
        tail, tail_refs = mark_dead(tail, refs, res)
        cond, refs = mark_dead(cond, union(tail_refs, body_refs), true)
        return Expr(f, cond, body, tail), refs
    elseif @capture(ex, :(=)(~lhs, ~rhs))
        lhs, refs, lhs_res = mark_dead_assign(lhs, refs)
        res |= lhs_res
        rhs, refs = mark_dead(rhs, refs, res)
        return Expr(f, lhs, rhs), refs
    elseif @capture(ex, (~f::isassign)(~lhs, ~rhs))
        lhs, refs, lhs_res = mark_dead_assign(lhs, refs)
        res |= lhs_res
        lhs, refs = mark_dead(lhs, refs, res)
        rhs, refs = mark_dead(rhs, refs, res)
        return Expr(f, lhs, rhs), refs
    elseif @capture ex :for(:(=)(~i, ~ext), ~body)
        while true
            body, new_refs = mark_dead(body, refs, true)
            if new_refs == refs
                refs
                break
            else
                refs = new_refs
            end
        end
        ext, refs = mark_dead(ext, refs, true)
        return Expr(:for, Expr(:(=), i, ext), body), refs
    elseif @capture ex :while(~cond, ~body)
        while true
            body, new_refs = mark_dead(body, refs, true)
            cond, new_refs = mark_dead(cond, new_refs, true)
            if new_refs == refs
                refs
                break
            else
                refs = new_refs
            end
        end
        return Expr(:while, cond, body), refs
    else
        error("dead code elimination reached unrecognized expression $ex")
    end
end

function mark_dead_assign(lhs, refs)
    return (lhs, refs, true)
end


function mark_dead_assign(lhs::Symbol, refs)
    if !(lhs in refs)
        refs = setdiff(refs, [lhs])
        return (Expr(:dead, lhs), refs, false)
    else
        return (lhs, refs, true)
    end
end

function mark_dead_assign(lhs::Expr, refs)
    if @capture lhs :dead(~arg)
        return mark_dead_assign(arg, refs)
    elseif @capture lhs :tuple(~args...)
        new_args = []
        res = false
        for arg in args
            (arg, refs, arg_res) = mark_dead_assign(arg, refs)
            push!(new_args, arg)
            res |= arg_res
        end
        lhs = Expr(:tuple, args...)
        lhs = res ? Expr(:dead, lhs) : lhs
        return (lhs, refs, res)
    elseif @capture(lhs, (~f)(~args...)) && f in [:ref, :.]
        lhs, refs = mark_dead(Expr(f, args...), refs, true)
        return (lhs, refs, true)
    else
        error("dead code elimination reached unrecognized assignment $ex")
    end
end

function dce(ex)
    ex, refs = mark_dead(ex, Set(), true)

    ex = Rewrite(Prewalk(Chain([
        Fixpoint(@rule :block(~a..., :block(~b...), ~c...) => Expr(:block, a..., b..., c...)),
        (@rule :block(~a1..., :if(~cond, ~b), ~a2..., ~c) =>
            Expr(:block, a1..., Expr(:if, cond, Expr(:block, b, nothing)), a2..., c)),
        (@rule :block(~a1..., :if(~cond, ~b, ~c), ~a2..., ~d) =>
            Expr(:block, a1..., Expr(:if, cond, Expr(:block, b, nothing), Expr(:block, c, nothing)), a2..., d)),
        (@rule :block(~a1..., :elseif(~cond, ~b), ~a2..., ~c) =>
            Expr(:block, a1..., Expr(:elseif, cond, Expr(:block, b, nothing)), a2..., c)),
        (@rule :block(~a1..., :elseif(~cond, ~b, ~c), ~a2..., ~d) =>
            Expr(:block, a1..., Expr(:elseif, cond, Expr(:block, b, nothing), Expr(:block, c, nothing)), a2..., d)),
        (@rule :for(~itr, ~body) => Expr(:for, itr, Expr(:block, body, nothing))),
        (@rule :while(~cond, ~body) => Expr(:while, cond, Expr(:block, body, nothing))),
    ])))(ex)

    ex = Rewrite(Fixpoint(Postwalk(Chain([
        (@rule :dead(~lhs) => :_),
        Fixpoint(@rule :block(~a..., :block(~b...), ~c...) => Expr(:block, a..., b..., c...)),
        (@rule (~f::isassign)(:_, ~rhs) => rhs),
        (@rule :block(~a..., :call(~f::ispure, ~b...), ~c..., ~d) => Expr(:block, a..., b..., c..., d)),
        (@rule :block(~a..., :.(~b...), ~c..., ~d) => Expr(:block, a..., b..., c..., d)),
        (@rule :block(~a..., :ref(~b...), ~c..., ~d) => Expr(:block, a..., b..., c..., d)),
        (@rule :block(~a..., ~b::(!isexpr), ~c..., ~d) => Expr(:block, a..., c..., d)),
        (@rule :if(~cond, :block(nothing)) => Expr(:block, cond, nothing)),
        (@rule :if(~cond, ~a, ~a) => Expr(:block, cond, a)),
        (@rule :elseif(~cond, :block(nothing)) => Expr(:block, cond, nothing)),
        (@rule :elseif(~cond, ~a, ~a) => Expr(:block, cond, a)),
        (@rule :for(:(=)(~i, ~itr), :block(nothing)) => Expr(:block, itr, nothing)),
        (@rule :while(~cond, :block(nothing)) => Expr(:block, cond, nothing)),
    ]))))(ex)

    ex = Rewrite(Postwalk(Fixpoint(Chain([
        (@rule :block(~a..., :block(~b...), ~c...) => Expr(:block, a..., b..., c...)),
        (@rule :block(~a1..., :if(~cond, ~b1..., :block(~c..., nothing), ~b2...), ~a2..., ~d) =>
            Expr(:block, a1..., Expr(:if, cond, b1..., Expr(:block, c...), b2...), a2..., d)),
        (@rule :block(~a1..., :elseif(~cond, ~b1..., :block(~c..., nothing), ~b2...), ~a2..., ~d) =>
            Expr(:block, a1..., Expr(:elseif, cond, b1..., Expr(:block, c...), b2...), a2..., d)),
        (@rule :for(~itr, :block(~body..., nothing)) => Expr(:for, itr, Expr(:block, body...))),
        (@rule :while(~cond, :block(~body..., nothing)) => Expr(:while, cond, Expr(:block, body...))),
    ]))))(ex)

    ex
end

"""
    unblock(ex)
Flatten any redundant blocks into a single block, over the whole expression.
"""
function unblock(ex::Expr)
    Rewrite(Postwalk(Fixpoint(Chain([
        (@rule :block(~a..., :block(~b...), ~c...) => Expr(:block, a..., b..., c...)),
        (@rule :block(~a) => a),
    ]))))(ex)
end
unblock(ex) = ex

"""
    striplines(ex)
Remove line numbers
"""
function striplines(ex::Expr)
    islinenum(x) = x isa LineNumberNode
    Rewrite(Postwalk(Fixpoint(Chain([
        (@rule :block(~a..., ~b::islinenum, ~c...) => Expr(:block, a..., c...)),
        (@rule :macrocall(~a, ~b, ~c...) => Expr(:macrocall, a, nothing, c...)),
    ]))))(ex)
end
striplines(ex) = ex

(Base.:^)(T::Type, i::Int) = ∘(repeated(T, i)..., identity)
(Base.:^)(f::Function, i::Int) = ∘(repeated(f, i)..., identity)

"""
    scansearch(v, x, lo, hi)

return the first value of `v` greater than or equal to `x`, within the range
`lo:hi`. Return `hi+1` if all values are less than `x`.
"""
Base.@propagate_inbounds function scansearch(v, x, lo::T, hi::T)::T where T<:Integer
    u = T(1)
    stop = min(hi, lo + T(32))
    while lo + u < stop && v[lo] < x
        lo += u
    end
    lo = lo - u
    hi = hi + u
    while lo < hi - u
        m = lo + ((hi - lo) >>> 0x01)
        if v[m] < x
            lo = m
        else
            hi = m
        end
    end
    return hi
end

struct Cindex{T} <: Integer
    val::T
    Cindex{T}(i, b::Bool=true) where {T} = new{T}(T(i) - b)
    Cindex{T}(i::Cindex{T}) where {T} = i
end

cindex_types = [Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128, BigInt]
for S in cindex_types
    @eval begin
        @inline Base.promote_rule(::Type{Cindex{T}}, ::Type{$S}) where {T} = promote_type(T, $S)
        Base.convert(::Type{Cindex{T}}, i::$S) where {T} = Cindex(convert(T, i))
        Cindex(i::$S) = Cindex{$S}(i)
        (::Type{$S})(i::Cindex{T}) where {T} = convert($S, i.val + true)
        Base.convert(::Type{$S}, i::Cindex) = convert($S, i.val + true)
        @inline Base.:(<<)(a::Cindex{T}, b::$S) where {T} = T(a) << b
    end
end
for S in [Float32, Float64]
    @eval begin
        @inline Base.promote_rule(::Type{Cindex{T}}, ::Type{$S}) where {T} = Cindex{promote_type(T, $S)}
        (::Type{$S})(i::Cindex{T}) where {T} = convert($S, i.val + true)
    end
end
Base.promote_rule(::Type{Cindex{T}}, ::Type{Cindex{S}}) where {T, S} = promote_type(T, S)
Base.convert(::Type{Cindex{T}}, i::Cindex) where {T} = Cindex{T}(convert(T, i.val), false)
Base.hash(x::Cindex, h::UInt) = hash(typeof(x), hash(x.val, h))

for op in [:*, :+, :-, :min, :max]
    @eval @inline Base.$op(a::Cindex{T}, b::Cindex{T}) where {T} = Cindex($op(T(a), T(b)))
end

for op in [:*, :+, :-, :min, :max]
    @eval @inline Base.$op(a::Cindex{T}) where {T} = Cindex($op(T(a)))
end

for op in [:<, :<=, :isless]
    @eval @inline Base.$op(a::Cindex{T}, b::Cindex{T}) where {T} = $op(T(a), T(b))
end