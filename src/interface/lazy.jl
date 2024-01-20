using Base: Broadcast
using Base.Broadcast: Broadcasted, BroadcastStyle, AbstractArrayStyle
using Base: broadcasted
const AbstractArrayOrBroadcasted = Union{AbstractArray,Broadcasted}

mutable struct LogicTensor{T, N}
    data
    extrude::NTuple{N, Bool}
end
LogicTensor{T}(data, extrude::NTuple{N, Bool}) where {T, N} = LogicTensor{T, N}(data, extrude)

Base.ndims(::Type{LogicTensor{T, N}}) where {T, N} = N
Base.eltype(::Type{<:LogicTensor{T}}) where {T} = T

function identify(data)
    lhs = alias(gensym(:A))
    subquery(query(lhs, data), lhs)
end

LogicTensor(data::Number) = LogicTensor{typeof(data), 0}(immediate(data), ())
LogicTensor{T}(data::Number) where {T} = LogicTensor{T, 0}(immediate(data), ())
LogicTensor(arr::Base.AbstractArrayOrBroadcasted) = LogicTensor{eltype(arr)}(arr)
function LogicTensor{T}(arr::Base.AbstractArrayOrBroadcasted) where {T}
    name = alias(gensym(:A))
    idxs = [field(gensym(:i)) for _ in 1:ndims(arr)]
    extrude = ntuple(n -> size(arr, n) == 1, ndims(arr))
    tns = subquery(query(name, table(immediate(arr), idxs...)), name)
    LogicTensor{eltype(arr), ndims(arr)}(tns, extrude)
end
LogicTensor(data::LogicTensor) = data

Base.sum(arr::LogicTensor; kwargs...) = reduce(+, arr; kwargs...)
Base.prod(arr::LogicTensor; kwargs...) = reduce(*, arr; kwargs...)
Base.any(arr::LogicTensor; kwargs...) = reduce(or, arr; init = false, kwargs...)
Base.all(arr::LogicTensor; kwargs...) = reduce(and, arr; init = true, kwargs...)
Base.minimum(arr::LogicTensor; kwargs...) = reduce(min, arr; init = Inf, kwargs...)
Base.maximum(arr::LogicTensor; kwargs...) = reduce(max, arr; init = -Inf, kwargs...)

function Base.mapreduce(f, op, src::LogicTensor, args...; kw...)
    reduce(op, map(f, src, args...); kw...)
end

function Base.map(f, src::LogicTensor, args...)
    args = (src, args...)
    idxs = [field(gensym(:i)) for _ in src.extrude]
    ldatas = map(args) do arg
        larg = LogicTensor(arg)
        @assert larg.extrude == src.extrude "Logic only supports matching size and number of dimensions"
        return relabel(larg.data, idxs...)
    end
    T = combine_eltypes(f, args)
    data = mapjoin(immediate(f), ldatas...)
    return LogicTensor{T}(identify(data), src.extrude)
end

function Base.map!(dst, f, src::LogicTensor, args...)
    res = map(f, src, args...)
    return LogicTensor(identify(reformat(dst, res.data)), res.extrude)
end

function initial_value(op, T)
    try
        reduce(op, Vector{T}())
    catch
        throw(ArgumentError("Please supply initial value for reduction of $T with $op."))
    end
end

function fixpoint_type(op, z, tns)
    S = Union{}
    T = typeof(z)
    while T != S
        S = T
        T = Union{T, combine_eltypes(op, (T, eltype(tns)))}
    end
    T
end

function Base.reduce(op, arg::LogicTensor{T, N}; dims=:, init = initial_value(op, Float64)) where {T, N}
    dims = dims == Colon() ? (1:N) : collect(dims)
    extrude = ((arg.extrude[n] for n in 1:N if !(n in dims))...,)
    fields = [field(gensym(:i)) for _ in 1:N]
    S = fixpoint_type(op, init, arg)
    data = aggregate(immediate(op), immediate(init), relabel(arg.data, fields), fields[dims]...)
    LogicTensor{S}(identify(data), extrude)
end

struct LogicStyle{N} <: BroadcastStyle end
Base.Broadcast.BroadcastStyle(F::Type{<:LogicTensor{T, N}}) where {T, N} = LogicStyle{N}()
Base.Broadcast.broadcastable(tns::LogicTensor) = tns
Base.Broadcast.BroadcastStyle(a::LogicStyle{M}, b::LogicStyle{N}) where {M, N} = LogicStyle{max(M, N)}()
Base.Broadcast.BroadcastStyle(a::LogicStyle{M}, b::FinchStyle{N}) where {M, N} = LogicStyle{max(M, N)}()
Base.Broadcast.BroadcastStyle(a::LogicStyle{M}, b::Broadcast.AbstractArrayStyle{N}) where {M, N} = LogicStyle{max(M, N)}()

function broadcast_to_logic(bc::Broadcast.Broadcasted)
    broadcasted(bc.f, map(broadcast_to_logic, bc.args)...)
end

function broadcast_to_logic(tns::LogicTensor)
    tns
end

function broadcast_to_logic(tns)
    LogicTensor(tns)
end

function broadcast_to_query(bc::Broadcast.Broadcasted, idxs)
    mapjoin(immediate(bc.f), map(arg -> broadcast_to_query(arg, idxs), bc.args)...)
end

function broadcast_to_query(tns::LogicTensor{T, N}, idxs) where {T, N}
    data_2 = relabel(tns.data, idxs[1:N]...)
    reorder(data_2, idxs[findall(!, tns.extrude)]...)
end

function broadcast_to_extrude(bc::Broadcast.Broadcasted, n)
    any(map(arg -> broadcast_to_extrude(arg, n), bc.args))
end

function broadcast_to_extrude(tns::LogicTensor, n)
    get(tns.extrude, n, false)
end

function Base.materialize!(dest, bc::Broadcasted{<:LogicStyle})
    return copyto!(dest, bc)
end

function Base.materialize(bc::Broadcasted{<:LogicStyle})
    return copy(bc)
end

Base.copyto!(out, bc::Broadcasted{LogicStyle{N}}) where {N} = copyto!(out, copy(bc))

function Base.copy(bc::Broadcasted{LogicStyle{N}}) where {N}
    bc_lgc = broadcast_to_logic(bc)
    data = broadcast_to_query(bc_lgc, [field(gensym(:i)) for _ in 1:N])
    extrude = ntuple(n -> broadcast_to_extrude(bc_lgc, n), N)
    return LogicTensor{eltype(bc)}(identify(data), extrude)
end

function Base.copyto!(::LogicTensor, ::Any)
    throw(ArgumentError("cannot materialize into a LogicTensor"))
end

function Base.copyto!(dst::AbstractArray, src::LogicTensor{T, N}) where {T, N}
    return LogicTensor{T, N}(reformat(immediate(dst), src.data), src.extrude)
end

Base.permutedims(arg::LogicTensor{T, 2}) where {T} = permutedims(arg, [2, 1])
function Base.permutedims(arg::LogicTensor{T, N}, perm) where {T, N}
    length(perm) == N || throw(ArgumentError("permutedims given wrong number of dimensions"))
    isperm(perm) || throw(ArgumentError("permutedims given invalid permutation"))
    perm = collect(perm)
    idxs = [field(gensym(:i)) for _ in 1:N]
    return LogicTensor{T, N}(reorder(relabel(arg.data, idxs...), idxs[perm]...), arg.extrude[perm])
end

isolate_aggregates = Rewrite(Postwalk(
    @rule aggregate(~op, ~init, ~arg, ~idxs...) => begin
        name = alias(gensym(:A))
        subquery(query(name, aggregate(~op, ~init, ~arg, ~idxs...)), name)
    end
))

isolate_reformats = Rewrite(Postwalk(
    @rule reformat(~tns, ~arg) => begin
        name = alias(gensym(:A))
        subquery(query(name, reformat(tns, arg)), name)
    end
))

isolate_tables = Rewrite(Postwalk(
    @rule table(~tns, ~idxs...) => begin
        name = alias(gensym(:A))
        subquery(query(name, table(tns, idxs...)), name)
    end
))

lift_subqueries = Rewrite(Fixpoint(Postwalk(Chain([
    (@rule (~op)(~a1..., subquery(~p, ~b), ~a2...) => if op !== subquery && op !== query
        subquery(p, op(a1, b, a2))
    end),
    Fixpoint(@rule query(~a, subquery(~p, ~b)) => plan(p, query(a, b), produces(a))),
    Fixpoint(@rule plan(~a1..., plan(~b..., produces(~c...)), ~a2...) => plan(a1, b, a2)),
    (@rule plan(~args...) => plan(unique(args))),
]))))

function simplify_queries(bindings)
    Rewrite(Fixpoint(Postwalk(Chain([
        (@rule aggregate(~op, ~init, ~arg) => mapjoin(op, init, arg)),
        (@rule mapjoin(overwrite, ~lhs, ~rhs) =>
            reorder(rhs, getfields(mapjoin(overwrite, ~lhs, ~rhs), bindings)...)),
    ]))))
end

propagate_copy_queries = Rewrite(Fixpoint(Postwalk(Chain([
    (@rule plan(~a1..., query(~b, ~c), ~a2..., produces(~d...)) => if c.kind === alias && !(b in d)
        rw = Rewrite(Postwalk(@rule b => c))
        plan(a1..., map(rw, a2)..., produces(d...))
    end),
]))))

function pretty_labels(root)
    fields = Dict()
    aliases = Dict()
    Rewrite(Postwalk(Chain([
        (@rule ~i::isfield => get!(fields, i, field(Symbol(:i, length(fields))))),
        (@rule ~a::isalias => get!(aliases, a, alias(Symbol(:A, length(aliases))))),
    ])))(root)
end

function push_labels(root, bindings)
    Rewrite(Postwalk(Chain([
        (@rule reorder(mapjoin(~op, ~args...), ~idxs...) => 
            mapjoin(op, map(arg -> reorder(arg, ~idxs...), args)...)),
        (@rule relabel(mapjoin(~op, ~args...), ~idxs...) => begin
            idxs_2 = getfields(mapjoin(op, args...), bindings)
            mapjoin(op, map(arg -> relabel(reorder(arg, idxs_2...), idxs...), args)...)
        end),
        (@rule reorder(reorder(~arg, ~idxs...), ~idxs_2...) =>
            reorder(~arg, ~idxs_2...)),
        (@rule relabel(relabel(~arg, ~idxs...), ~idxs_2...) =>
            relabel(~arg, ~idxs_2...)),
        (@rule relabel(reorder(~arg, ~idxs...), ~idxs_2...) => begin
            reidx = Dict(map(Pair, idxs, idxs_2)...)
            idxs_3 = getfields(arg, bindings)
            idxs_4 = map(idx -> get(reidx, idx, idx), idxs_3)
            reorder(relabel(arg, idxs_4...), idxs_2...)
        end),
        (@rule reformat(~tns, relabel(~arg, ~idxs...)) => relabel(reformat(tns, arg), idxs...)),
        (@rule plan(~a1..., query(~b, relabel(~c, ~i...)), ~a2...) => begin
            d = alias(gensym(:A))
            bindings[d] = c
            rw = Rewrite(Postwalk(@rule b => relabel(d, i...)))
            plan(a1..., query(d, c), map(rw, a2)...)
        end),
    ])))(root)
end

function fuse_reformats(root)
    Rewrite(Postwalk(Chain([
        (@rule plan(~a1..., query(~b, ~c), ~a2..., query(~d, reformat(~tns, ~b)), ~a3...) => begin
            if !(b in PostOrderDFS(plan(a2..., a3...))) && c.kind !== reformat
                plan(a1..., query(d, reformat(tns, c)), a2..., a3...)
            end
        end),
    ])))(root)
end

pad_with_aggregate = Rewrite(Postwalk(Chain([
    (@rule query(~a, reformat(~tns, ~b)) => begin
        if b.kind !== aggregate && b.kind !== table
            query(a, reformat(tns, aggregate(overwrite, immediate(nothing), b)))
        end
    end),
    (@rule query(~a, ~b) => begin
        if b.kind !== aggregate && b.kind !== reformat && b.kind !== table
            query(a, aggregate(overwrite, immediate(nothing), b))
        end
    end),
])))

function concordize(root, bindings)
    needed_swizzles = Dict()
    root = Rewrite(Postwalk(Chain([
        (@rule reorder(~a::isalias, ~idxs...) => begin
            idxs_2 = intersect(idxs, getfields(a, bindings))
            if !issorted(idxs_2, by = idx -> findfirst(isequal(idx), idxs))
                b = get!(get!(needed_swizzles, a, Dict()), idxs_2, alias(gensym(:A)))
                reorder(b, idxs...)
            end
        end),
        (@rule reorder(relabel(~a::isalias, ~idxs_2...), ~idxs...) => begin
            idxs_3 = getfields(a, bindings)
            reidx = Dict(map(Pair, idxs_2, idxs_3)...)
            idxs_4 = map(idx -> reidx[idx], intersect(idxs, idxs_2))
            if !issorted(idxs_4, by = idx -> findfirst(isequal(idx), idxs_3))
                b = get!(get!(needed_swizzles, a, Dict()), idxs_4, alias(gensym(:A)))
                reorder(relabel(b, idxs_2...), idxs...)
            end
        end),
    ])))(root)
    root = Rewrite(Postwalk(Chain([
        (@rule query(~a, ~b) => begin
            idxs = getfields(a, bindings)
            if haskey(needed_swizzles, a)
                swizzle_queries = map(pairs(needed_swizzles[a])) do (idxs_2, c)
                    idxs_3 = copy(idxs)
                    view(idxs_3, findall(idx -> idx in idxs_2, idxs)) .= idxs_2
                    bindings[c] = reorder(a, idxs_3...)
                    query(c, reorder(a, idxs_3...))
                end
                plan(query, swizzle_queries...)
            end
        end),
    ])))(root)
end

compute(arg) = compute((arg,))
#compute(arg) = compute((arg,))[1]
function compute(args::NTuple)
    args = collect(args)
    vars = map(arg -> alias(gensym(:A)), args)
    bodies = map((arg, var) -> query(var, arg.data), args, vars)
    prgm = plan(bodies, produces(vars))
    display(prgm)
    prgm = isolate_tables(prgm)
    prgm = isolate_reformats(prgm)
    prgm = isolate_aggregates(prgm)
    prgm = lift_subqueries(prgm)
    bindings = getbindings(prgm)
    prgm = simplify_queries(bindings)(prgm)
    prgm = propagate_copy_queries(prgm)
    prgm = pretty_labels(prgm)
    bindings = getbindings(prgm)
    display(prgm)
    prgm = push_labels(prgm, bindings)
    display(prgm)
    prgm = concordize(prgm, bindings)
    prgm = fuse_reformats(prgm)
    prgm = pad_with_aggregate(prgm)
    display(prgm)
end