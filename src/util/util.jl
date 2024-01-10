is_function_def(node) =
    (@capture node :function(~args...)) ||
    (@capture node :->(~args...)) ||
    (@capture node (:(=))(:call(~f, ~args...), ~body)) ||
    (@capture node (:(=))(:where(:call(~f, ~args...), ~types), ~body))

has_function_def(root) = any(is_function_def, PostOrderDFS(root))
struct All{F}
    f::F
end

@inline (f::All{F})(args) where {F} = all(f.f, args)

struct Or{Fs}
    fs::Fs
end

Or(fs...) = Or{typeof(fs)}(fs)

@inline (f::Or{Fs})(arg) where {Fs} = any(g->g(arg), f.fs)

struct And{Fs}
    fs::Fs
end

And(fs...) = And{typeof(fs)}(fs)

@inline (f::And{Fs})(arg) where {Fs} = all(g->g(arg), f.fs)

staged_defs = []

"""
    Finch.@staged

This function is used internally in Finch in lieu of @generated functions. It
ensures the first Finch invocation runs in the latest world, and leaves hooks so
that subsequent calls to [`Finch.refresh`](@ref) can update the world and
invalidate old versions. If the body contains closures, this macro uses an
eval and invokelatest strategy. Otherwise, it uses a generated function.
"""
macro staged(def)
    (@capture def :function(:call(~name, ~args...), ~body)) || throw(ArgumentError("unrecognized function definition in @staged"))

    name_generator = gensym(Symbol(name, :_generator))
    name_invokelatest = gensym(Symbol(name, :_invokelatest))
    name_eval_invokelatest = gensym(Symbol(name, :_eval_invokelatest))

    def = quote
        function $name_generator($(args...))
            $body
        end

        function $name_invokelatest($(args...))
            $invokelatest($name_eval_invokelatest, $(args...))
        end

        function $name_eval_invokelatest($(args...))
            code = $name_generator($(map((arg)->:(typeof($arg)), args)...),)
            def = quote
                function $($(QuoteNode(name_invokelatest)))($($(map(arg -> :(:($($(QuoteNode(arg)))::$(typeof($arg)))), args)...)))
                    $($(QuoteNode(name_eval_invokelatest)))($($(map(QuoteNode, args)...)))
                end
                function $($(QuoteNode(name_eval_invokelatest)))($($(map(arg -> :(:($($(QuoteNode(arg)))::$(typeof($arg)))), args)...)))
                    $code
                end
            end
            ($@__MODULE__).eval(def)
            Base.invokelatest(($@__MODULE__).$name_eval_invokelatest, $(args...))
        end

        @generated function $name($(args...))
            # Taken from https://github.com/NHDaly/StagedFunctions.jl/blob/6fafbc560421f70b05e3df330b872877db0bf3ff/src/StagedFunctions.jl#L116
            body_2 = () -> begin
                code = $name_generator($(args...))
                if true #has_function_def(macroexpand($@__MODULE__, code))
                    :($($(name_invokelatest))($($(map(QuoteNode, args)...))))
                else 
                    quote
                        $code
                    end
                end
            end
            Core._apply_pure(body_2, ())
        end

    end

    return esc(quote
        push!(staged_defs, $(QuoteNode(def)))
        $(def)
    end)
end

"""
    Finch.refresh()

Finch caches the code for kernels as soon as they are run. If you modify the
Finch compiler after running a kernel, you'll need to invalidate the Finch
caches to reflect these changes by calling `Finch.refresh()`. This function
should only be called at global scope, and never during precompilation.
"""
function refresh()
    for def in staged_defs
        @eval $def
    end
end

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

"""
    pretty(ex) 

Make ex prettier. Shorthand for `ex |> unblock |> striplines |> regensym`.
"""
pretty(ex) = ex |> unblock |> striplines |> regensym

"""
    unquote_literals(ex)

unquote QuoteNodes when this doesn't change the semantic meaning. `ex` is the target Julia expression.
"""
unquote_literals(ex) = ex
unquote_literals(ex::Expr) = Expr(ex.head, map(unquote_literals, ex.args)...)
unquote_literals(ex::QuoteNode) = unquote_quoted(ex.value)
unquote_quoted(::Missing) = missing
unquote_quoted(ex) = QuoteNode(ex)

isgensym(s::Symbol) = occursin("#", string(s))
isgensym(s) = false

"""
    regensym(ex)

Give gensyms prettier names by renumbering them. `ex` is the target Julia expression.
"""
function regensym(ex)
    counter = 0
    syms = Dict{Symbol, Symbol}()
    Rewrite(Postwalk((x) -> if isgensym(x) 
        get!(()->Symbol("_", gensymname(x), "_", counter+=1), syms, x)
    end))(ex)
end
function gensymname(x::Symbol)
    m = Base.match(r"##(.+)#\d+", String(x))
    m === nothing || return m.captures[1]
    m = Base.match(r"#\d+#(.+)", String(x))
    m === nothing || return m.captures[1]
    return "x"
end

"""
    unblock(ex)

Flatten any redundant blocks into a single block, over the whole expression. `ex` is the target Julia expression.
"""
function unblock(ex::Expr)
    ex = Rewrite(Postwalk(Fixpoint(Chain([
        (@rule :block(~a..., :block(~b...), ~c...) => Expr(:block, a..., b..., c...)),
        (@rule :block(~a..., :(=)(~b, ~c), ~b) => Expr(:block, a..., Expr(:(=), ~b, ~c))),
        (@rule :block(~a) => a),
    ]))))(ex)
    if ex isa Expr && !@capture ex :block(~args...)
        ex = Expr(:block, ex)
    end
    ex
end
unblock(ex) = ex

"""
    unresolve(ex)

Unresolve function literals into function symbols. `ex` is the target Julia expression.
"""
function unresolve(ex)
    ex = Rewrite(Postwalk(unresolve1))(ex)
end
unresolve1(x) = x
unresolve1(f::Function) = methods(f).mt.name

"""
    striplines(ex)

Remove line numbers. `ex` is the target Julia expression
"""
function striplines(ex::Expr)
    islinenum(x) = x isa LineNumberNode
    Rewrite(Postwalk(Fixpoint(Chain([
        (@rule :block(~a..., ~b::islinenum, ~c...) => Expr(:block, a..., c...)),
        (@rule :macrocall(~a, ~b, ~c...) => Expr(:macrocall, a, nothing, c...)),
    ]))))(ex)
end
striplines(ex) = ex

"""
    dataflow(ex)

Run dead code elimination and constant propagation. `ex` is the target Julia expression.
"""
dataflow(ex) = ex |> striplines |> desugar |> propagate_copies |> mark_dead |> prune_dead |> resugar

isassign(x) = x in Set([:+=, :*=, :&=, :|=, :(=)])
incs = Dict(:+= => :+, :-= => :-, :*= => :*, :&= => :&, :|= => :|)
deincs = Dict(:+ => :+=, :* => :*=, :& => :&=, :| => :|=)
function ispure(x)
    if x isa Symbol
        return string(x) == "!" || (string(x)[end] != '!' && string(x) != "throw" && string(x) != "error")
    elseif @capture x :.(~mod, ~fn)
        return ispure(fn)
    elseif x isa Function
        return ispure(unresolve1(x))
    elseif x isa QuoteNode
        return ispure(x.value)
    else
        return false
    end
end

issymbol(x) = x isa Symbol
isexpr(x) = x isa Expr

function desugar(ex)
    sugar = 0
    Rewrite(Prewalk(Fixpoint(Chain([
        (@rule :(=)(:tuple(~lhss...), ~rhs) => begin
            var = Symbol(:sugar_, sugar += 1)
            Expr(:block, Expr(:(=), var, rhs), map(enumerate(lhss)) do (n, lhs)
                Expr(:(=), lhs, Expr(:ref, var, n))
            end..., var)
        end),
        (@rule :elseif(~args...) => Expr(:if, args...)),
        (@rule :if(~cond, ~a) => Expr(:if, cond, a, Expr(:block, nothing))),
        (@rule :(=)(:.(~x, ~p), ~rhs) => Expr(:call, :setproperty!, x, p, rhs)),
        (@rule :(=)(:ref(~a, ~i...), ~rhs) => Expr(:call, :setindex!, a, rhs, i...)),
        (@rule (~f)(~lhs, ~rhs) => if haskey(incs, f)
            Expr(:(=), lhs, Expr(:call, incs[f], lhs, rhs))
        end),
        (@rule :tuple(~a..., :(=)(~b, ~c)) =>
            Expr(:tuple, ~a..., Expr(:parameters, Expr(:kw, ~b, ~c)))),
        Fixpoint(@rule :tuple(~a..., :(=)(~b, ~c), :parameters(~d...)) =>
            Expr(:tuple, ~a..., Expr(:parameters, Expr(:kw, ~b, ~c), ~d...))),
    ]))))(ex)
end

function resugar(ex)
    Rewrite(Fixpoint(Postwalk(Chain([
        (@rule :call(:setproperty!, ~x, ~p, ~v) => Expr(:(=), Expr(:., x, p), v)),
        (@rule :call(:setindex!, ~x, ~v, ~i...) => Expr(:(=), Expr(:ref, x, i...), v)),
        (@rule :(=)(~lhs, :call(~f, ~lhs, ~rhs)) => if haskey(deincs, f)
            Expr(deincs[f], lhs, rhs)
        end),
        Fixpoint(@rule :tuple(~a..., :parameters(:kw(~b, ~c), ~d...)) =>
            Expr(:tuple, ~a..., Expr(:(=), ~b, ~c), Expr(:parameters, ~d...))),
        (@rule :tuple(~a..., :parameters()) => Expr(:tuple, ~a...)),
        (@rule :if(~cond, ~a, :block(nothing)) => Expr(:if, cond, a)),
        (@rule :if(~cond, ~a, :block()) => Expr(:if, cond, a)),
        (@rule :if(~cond, ~a, :if(~b...)) => Expr(:if, cond, a, Expr(:elseif, b...))),
        (@rule :block(~a) => a),
    ]))))(ex)
end

@kwdef struct PropagateCopies
    refs = Dict()
    ids = Dict()
    vals = Dict()
end

Base.:(==)(a::PropagateCopies, b::PropagateCopies) = (a.ids == b.ids) && (a.refs == b.refs)
Base.copy(ctx::PropagateCopies) = PropagateCopies(copy(ctx.refs), copy(ctx.ids), copy(ctx.vals))
function Base.merge!(ctx::PropagateCopies, ctx_2::PropagateCopies) 
    merge!(intersect, ctx.refs, ctx_2.refs)
    merge!(union, ctx.ids, ctx_2.ids)
    merge!(union, ctx.vals, ctx_2.vals)
end

function propagate_copies(ex)
    id = 0
    ex = Postwalk(@rule(:(=)(~lhs::issymbol, ~rhs) => 
        Expr(:def, Expr(:(=), lhs, rhs), id += 1)))(ex)

    ex = unblock(ex)

    ex = PropagateCopies()(ex)

    ex = Postwalk(@rule(:def(:(=)(~lhs::issymbol, ~rhs), ~id) => 
        Expr(:(=), lhs, rhs)))(ex)
end

function (ctx::PropagateCopies)(ex)
    if issymbol(ex)
        if haskey(ctx.ids, ex) && length(ctx.vals[ex]) == 1
            val = first(ctx.vals[ex])
            if isexpr(val)
                return ex
            elseif issymbol(val)
                if issubset(ctx.ids[ex], get(ctx.refs, val, Set([])))
                    return val
                end
            else
                return val
            end
        end
        return ex
    elseif @capture ex :macrocall(~f, ~ln, ~args...)
        return Expr(:macrocall, f, ln, map(ctx, args)...)
    elseif @capture ex :block(~args...)
        return Expr(:block, map(ctx, args)...)
    elseif @capture(ex, (~f)(~args...)) && f in (:ref, :call, :., :curly, :string, :kw, :parameters, :tuple)
        return Expr(f, map(ctx, args)...)
    elseif (@capture ex (~f)(~cond, ~body)) && f in [:&&, :||]
        cond = ctx(cond)
        ctx_2 = copy(ctx)
        body = ctx_2(body)
        merge!(ctx, ctx_2)
        return Expr(f, cond, body)
    elseif (@capture ex :if(~cond, ~body, ~tail))
        cond = ctx(cond)
        ctx_2 = copy(ctx)
        body = ctx_2(body)
        tail = ctx(tail)
        merge!(ctx, ctx_2)
        return Expr(:if, cond, body, tail)
    elseif @capture(ex, :def(:(=)(~lhs::issymbol, ~rhs), ~id))
        rhs = ctx(rhs)
        rhs == lhs && return rhs
        ctx.refs[lhs] = Set([])
        if issymbol(rhs)
            ctx.refs[rhs] = union(get(ctx.refs, rhs, Set([])), [id])
            ctx.ids[lhs] = Set([id])
            ctx.vals[lhs] = Set([rhs])
        else
            ctx.ids[lhs] = Set([id])
            ctx.vals[lhs] = Set([rhs])
        end
        return Expr(:def, Expr(:(=), lhs, rhs), id)
    elseif @capture ex :for(:def(:(=)(~i, ~ext), ~id), ~body)
        ext = ctx(ext)
        body_2 = body
        while true
            ctx_2 = copy(ctx)
            body_2 = ctx(body)
            ctx_2 == ctx && break
        end
        return Expr(:for, Expr(:def, Expr(:(=), i, ext), id), body_2)
    elseif @capture ex :while(~cond, ~body)
        cond_2 = cond
        body_2 = body
        while true
            ctx_2 = copy(ctx)
            cond_2 = ctx(cond)
            ctx_3 = copy(ctx)
            body_2 = ctx_3(body)
            merge!(ctx, ctx_3)
            ctx_2 == ctx && break
        end
        return Expr(:while, cond_2, body_2)
    elseif !isexpr(ex) || ex.head == :break
        ex
    else
        error("propagate_copies reached unrecognized expression $ex")
    end
end

iseffectful(ex) = false
function iseffectful(ex::Expr)
    @capture(ex, :call(~f::(!ispure), ~args...)) && return true
    @capture(ex, :(=)(~lhs::issymbol, ~rhs)) && lhs != :_ && return true
    @capture(ex, :for(~lhs, ~rhs)) && return iseffectful(rhs) #TODO this could be handled better if we desugared :for
    return any(iseffectful, ex.args)
end

@kwdef struct MarkDead
    refs = Set()
end

Base.:(==)(a::MarkDead, b::MarkDead) = a.refs == b.refs

branch(ctx::MarkDead) = MarkDead(copy(ctx.refs))
Base.copy(ctx::MarkDead) = MarkDead(copy(ctx.refs))
function meet!(ctx::MarkDead, ctx_2::MarkDead) 
    union!(ctx.refs, ctx_2.refs)
end

function (ctx::MarkDead)(ex, res)
    if issymbol(ex)
        if res
            push!(ctx.refs, ex)
        end
        ex
    elseif !isexpr(ex) || ex.head == :break
        ex
    elseif @capture ex :macrocall(~f, ~ln, ~args...)
        return Expr(:macrocall, f, ln, reverse(map((arg)->ctx(arg, res), reverse(args)))...)
    elseif @capture ex :block(~args...)
        args_2 = []
        for arg in args[end:-1:1]
            push!(args_2, ctx(arg, res))
            res = false
        end
        return Expr(:block, reverse(args_2)...)
    elseif @capture(ex, (~head)(~args...)) && head in (:ref, :call, :., :curly, :string, :kw, :parameters, :tuple)
        res |= head == :call && !ispure(args[1])
        return Expr(head, reverse(map((arg)->ctx(arg, res), reverse(args)))...)
    elseif (@capture ex (~f)(~cond, ~body)) && f in [:&&, :||]
        ctx_2 = branch(ctx)
        body = ctx_2(body, res)
        meet!(ctx, ctx_2)
        cond = ctx(cond, res || iseffectful(body))
        return Expr(f, cond, body)
    elseif (@capture ex :if(~cond, ~body, ~tail))
        ctx_2 = branch(ctx)
        tail = ctx_2(tail, res)
        body = ctx(body, res)
        meet!(ctx, ctx_2)
        cond = ctx(cond, res || iseffectful(tail) || iseffectful(body))
        return Expr(:if, cond, body, tail)
    elseif @capture(ex, :(=)(~lhs::issymbol, ~rhs))
        if lhs in ctx.refs
            res = true
        else
            lhs = :_
        end
        delete!(ctx.refs, lhs)
        rhs = ctx(rhs, res)
        return Expr(f, lhs, rhs)
    elseif @capture ex :for(:(=)(~i, ~ext), ~body)
        body_2 = body
        while true
            ctx_2 = copy(ctx)
            ctx_3 = branch(ctx)
            body_2 = ctx_3(body, false)
            meet!(ctx, ctx_3)
            ext = ctx(ext, iseffectful(body_2))
            ctx == ctx_2 && break
        end
        return Expr(:for, Expr(:(=), i, ext), body_2)
    elseif @capture ex :while(~cond, ~body)
        body_2 = body
        cond_2 = cond
        while true
            ctx_2 = copy(ctx)
            ctx_3 = branch(ctx)
            body_2 = ctx_3(body, false)
            meet!(ctx, ctx_3)
            cond_2 = ctx(cond, iseffectful(body_2))
            ctx == ctx_2 && break
        end
        return Expr(:while, cond_2, body_2)
    else
        error("dead code elimination reached unrecognized expression $ex")
    end
end

mark_dead(ex) = MarkDead()(ex, true)

function prune_dead(ex)
    ex = desugar(ex)
    
    ex = Rewrite(Fixpoint(Chain([
        Prewalk(Chain([
            Fixpoint(@rule :block(:block(~a...), ~b...) => Expr(:block, a..., b...)),
            (@rule :block(~a, ~b, ~c...) => Expr(:block, a, Expr(:block, b, c...))),
            (@rule :block(:if(~cond, ~a, ~b), ~c) =>
                Expr(:block, Expr(:if, cond, Expr(:block, a, nothing), Expr(:block, b, nothing)), c)),
            (@rule :for(~itr, ~body) => Expr(:for, itr, Expr(:block, body, nothing))),
            (@rule :while(~cond, ~body) => Expr(:while, cond, Expr(:block, body, nothing))),
        ])),
        Fixpoint(Postwalk(Chain([
            Fixpoint(@rule :block(~a..., :block(~b...), ~c...) => Expr(:block, a..., b..., c...)),
            (@rule (~f::isassign)(:_, ~rhs) => rhs),
            (@rule :block(~a..., :call(~f::ispure, ~b...), ~c..., ~d) => Expr(:block, a..., b..., c..., d)),
            (@rule :block(~a..., (~f)(~b...), ~c..., ~d) => if f in (:ref, :., :curly, :string, :kw, :parameters, :tuple) 
                Expr(:block, a..., b..., c..., d)
            end),
            (@rule :block(~a..., ~b::(!isexpr), ~c..., ~d) => Expr(:block, a..., c..., d)),
            (@rule :if(~cond, ~a, ~a) => Expr(:block, cond, a)),
            (@rule :if(true, ~a, ~b) => a), #TODO should probably go with a propagation pass
            (@rule :if(false, ~a, ~b) => b), #TODO should probably go with a propagation pass
            (@rule :for(:(=)(~i, ~itr), ~body::(!iseffectful)) => Expr(:block, itr, nothing)),
            (@rule :while(~cond, ~body::(!iseffectful)) => Expr(:block, cond, nothing)),
            (@rule :for(:(=)(~i, ~itr), :block(nothing)) => Expr(:block, itr, nothing)),
            (@rule :while(~cond, :block(nothing)) => Expr(:block, cond, nothing)),
        ])))
    ])))(ex)

    ex = Rewrite(Postwalk(Fixpoint(Chain([
        (@rule :block(~a..., :block(~b...), ~c...) => Expr(:block, a..., b..., c...)),
        (@rule :block(~a1..., :if(~cond, ~b1..., :block(~c..., nothing), ~b2...), ~a2..., ~d) =>
            Expr(:block, a1..., Expr(:if, cond, b1..., Expr(:block, c...), b2...), a2..., d)),
        (@rule :for(~itr, :block(~body..., nothing)) => Expr(:for, itr, Expr(:block, body...))),
        (@rule :while(~cond, :block(~body..., nothing)) => Expr(:while, cond, Expr(:block, body...))),
    ]))))(ex)
end


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
