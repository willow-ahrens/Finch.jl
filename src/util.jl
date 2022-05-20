#TODO should we just have another IR? Ugh idk
shallowcopy(x::T) where T = T([getfield(x, k) for k ∈ fieldnames(T)]...)

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

(Base.:^)(T::Type, i::Int) = ∘(repeated(T, i)..., identity)
(Base.:^)(f::Function, i::Int) = ∘(repeated(f, i)..., identity)

module DisjointDicts
    export DisjointDict

    struct Link{K}
        k::K
    end

    struct Root{V}
        v::V
    end

    Base.convert(::Type{<:Union{Link{K}, Root{V}}}, x::Link{K2}) where {K, V, K2 <: K} = Link{K}(x.k)
    Base.convert(::Type{<:Union{Link{K}, Root{V}}}, x::Root{V2}) where {K, V, V2 <: V} = Root{V}(x.v)

    struct DisjointDict{K, V}
        data::Dict{K, Union{Link{K}, Root{V}}}
    end
    DisjointDict(args...) = DisjointDict{Any, Any}(args...)
    DisjointDict{K, V}() where {K, V} = DisjointDict{K, V}(Dict{K, Union{Link{K}, Root{V}}}())
    function DisjointDict{K, V}(args::Pair...) where {K, V}
        x = DisjointDict{K, V}()
        for (k, v) in args
            x[k...] = v
        end
        x
    end

    function root!(x::DisjointDict, k)
        if x.data[k] isa Root
            return k
        else
            r = root!(x, x.data[k].k)
            @assert k != r
            x.data[k] = Link(r)
            return r
        end
    end

    Base.haskey(x::DisjointDict, k) = haskey(x.data, k)

    function Base.getindex(x::DisjointDict, k)
        haskey(x.data, k) || KeyError(k)
        return x.data[root!(x, k)].v
    end

    function Base.get(x::DisjointDict, k, v)
        haskey(x.data, k) ? x[k] : v
    end

    function Base.setindex!(x::DisjointDict, v, k, ls...)
        if haskey(x.data, k)
            r = root!(x, k)
        else
            r = k
        end
        x.data[r] = Root(v)
        for l in ls
            if haskey(x.data, l)
                s = root!(x, l)
                if s != r
                    x.data[s] = Link(r)
                end
            else
                x.data[l] = Link(r)
            end
        end
        return v
    end

    Base.keys(x::DisjointDict) = keys(x.data)
    Base.values(x::DisjointDict) = [v.v for v in values(x.data) if v isa Root]
    Base.length(x::DisjointDict) = length(x.data)

    function Base.mergewith!(op::Op, x::DisjointDict, ys...) where {Op}
        for y in ys
            for k in keys(y)
                if k == root!(y, k)
                    if haskey(x, k)
                        x[k] = op(x[k], y[k])
                    else
                        x[k] = y[k]
                    end
                end
            end
            for k in keys(y)
                if haskey(x, k) && root!(x, k) != root!(x, root!(y, k))
                    x[k, root!(y, k)] = op(x[k], x[root!(y, k)])
                else
                    x[k, root!(y, k)] = x[root!(y, k)]
                end
            end
        end
    end
end

using Finch.DisjointDicts