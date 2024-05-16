flatten_plans = Rewrite(Postwalk(Fixpoint(Chain([
    (@rule plan(~a1..., plan(~b...), ~a2...) => plan(a1..., b..., a2...)),
]))))

isolate_aggregates = Rewrite(Postwalk(
    @rule aggregate(~op, ~init, ~arg, ~idxs...) => begin
        name = alias(gensym(:A))
        subquery(name, aggregate(~op, ~init, ~arg, ~idxs...))
    end
))

isolate_reformats = Rewrite(Postwalk(
    @rule reformat(~tns, ~arg) => begin
        name = alias(gensym(:A))
        subquery(name, reformat(tns, arg))
    end
))

isolate_tables = Rewrite(Postwalk(
    @rule table(~tns, ~idxs...) => begin
        name = alias(gensym(:A))
        subquery(name, table(tns, idxs...))
    end
))


function lift_subqueries_expr(node::LogicNode, bindings)
    if node.kind === subquery
        if !haskey(bindings, node.lhs)
            arg_2 = lift_subqueries_expr(node.arg, bindings)
            bindings[node.lhs] = arg_2
        end
        node.lhs
    elseif istree(node)
        similarterm(node, operation(node), map(n -> lift_subqueries_expr(n, bindings), arguments(node)))
    else
        node
    end
end

"""
    lift_subqueries

Creates a plan that lifts all subqueries to the top level of the program, with
unique queries for each distinct subquery alias. This function processes the rhs
of each subquery once, to carefully extract SSA form from any nested pointer
structure. After calling lift_subqueries, it is safe to map over the program
(recursive pointers to subquery structures will not incur exponential overhead).
"""
function lift_subqueries(node::LogicNode)
    if node.kind === plan
        plan(map(lift_subqueries, node.bodies))
    elseif node.kind === query
        bindings = OrderedDict()
        rhs_2 = lift_subqueries_expr(node.rhs, bindings)
        plan(map(((lhs, rhs),) -> query(lhs, rhs), collect(bindings)), query(node.lhs, rhs_2))
    elseif node.kind === produces
        node
    else
        error()
    end
end

function pretty_labels(root)
    fields = Dict()
    aliases = Dict()
    Rewrite(Postwalk(Chain([
        (@rule ~i::isfield => get!(fields, i, field(Symbol(:i, length(fields))))),
        (@rule ~a::isalias => get!(aliases, a, alias(Symbol(:A, length(aliases))))),
    ])))(root)
end

"""
push_fields(node)

This program modifies all `EXPR` statements in the program, as
defined in the following grammar:
```
    LEAF := relabel(ALIAS, FIELD...) |
            table(IMMEDIATE, FIELD...) |
            IMMEDIATE
    EXPR := LEAF |
            reorder(EXPR, FIELD...) |
            relabel(EXPR, FIELD...) |
            mapjoin(IMMEDIATE, EXPR...)
```

Pushes all reorder and relabel statements down to LEAF nodes of each EXPR.
Output LEAF nodes will match the form `reorder(relabel(LEAF, FIELD...),
FIELD...)`, omitting reorder or relabel if not present as an ancestor of the
LEAF in the original EXPR. Tables and immediates will absorb relabels.
"""
function push_fields(root)
    root = Rewrite(Prewalk(Fixpoint(Chain([
        (@rule relabel(mapjoin(~op, ~args...), ~idxs...) => begin
            idxs_2 = getfields(mapjoin(op, args...))
            mapjoin(op, map(arg -> relabel(reorder(arg, idxs_2...), idxs...), args)...)
        end),
        (@rule relabel(relabel(~arg, ~idxs...), ~idxs_2...) =>
            relabel(~arg, ~idxs_2...)),
        (@rule relabel(reorder(~arg, ~idxs_1...), ~idxs_2...) => begin
            idxs_3 = getfields(arg)
            reidx = Dict(map(Pair, idxs_1, idxs_2)...)
            idxs_4 = map(idx -> get(reidx, idx, idx), idxs_3)
            reorder(relabel(arg, idxs_4...), idxs_2...)
        end),
        (@rule relabel(table(~arg, ~idxs_1...), ~idxs_2...) => begin
            table(arg, idxs_2...)
        end),
        (@rule relabel(~arg::isimmediate) => arg),
    ]))))(root)
    root = Rewrite(Prewalk(Fixpoint(Chain([
        (@rule reorder(mapjoin(~op, ~args...), ~idxs...) =>
            mapjoin(op, map(arg -> reorder(arg, ~idxs...), args)...)),
        (@rule reorder(reorder(~arg, ~idxs...), ~idxs_2...) =>
            reorder(~arg, ~idxs_2...)),
    ]))))(root)
    root
end

"""
propagate_transpose_queries(root)

Removes non-materializing permutation queries by propagating them to the
expressions they contain. Pushes fields and also removes copies. Removes queries of the form:
```
    query(ALIAS, reorder(relabel(ALIAS, FIELD...), FIELD...))
```

Does not remove queries which define production aliases.

Accepts programs of the form:
```
       TABLE  := table(IMMEDIATE, FIELD...)
       ACCESS := reorder(relabel(ALIAS, FIELD...), FIELD...)
    POINTWISE := ACCESS | mapjoin(IMMEDIATE, POINTWISE...) | reorder(IMMEDIATE, FIELD...) | IMMEDIATE
    MAPREDUCE := POINTWISE | aggregate(IMMEDIATE, IMMEDIATE, POINTWISE, FIELD...)
  INPUT_QUERY := query(ALIAS, TABLE)
COMPUTE_QUERY := query(ALIAS, reformat(IMMEDIATE, MAPREDUCE)) | query(ALIAS, MAPREDUCE))
         PLAN := plan(STEP...)
         STEP := COMPUTE_QUERY | INPUT_QUERY | PLAN | produces(ALIAS...)
         ROOT := STEP
```
"""
function propagate_transpose_queries(root::LogicNode)
    return propagate_transpose_queries_impl(root, getproductions(root), Dict{LogicNode, LogicNode}())
end

function propagate_transpose_queries_impl(node, productions, bindings)
    if @capture node plan(~stmts...)
        stmts = map(stmts) do stmt
            propagate_transpose_queries_impl(stmt, productions, bindings)
        end
        plan(stmts...)
    elseif @capture node query(~lhs, ~rhs)
        rhs = push_fields(Rewrite(Postwalk((node) -> get(bindings, node, node)))(rhs))
        if lhs in productions
            query(lhs, rhs)
        else
            if @capture rhs reorder(relabel(~tns::isalias, ~idxs_1...), ~idxs_2...)
                bindings[lhs] = rhs
                plan()
            elseif @capture rhs relabel(~tns::isalias, ~idxs_1...)
                bindings[lhs] = rhs
                plan()
            elseif isalias(rhs)
                bindings[lhs] = rhs
                plan()
            else
                query(lhs, rhs)
            end
        end
    elseif @capture node produces(~args...)
        node
    else
        throw(ArgumentError("Unrecognized program in propagate_transpose_queries"))
    end
end

function propagate_copy_queries(root)
    copies = Dict()
    for node in PostOrderDFS(root)
        if @capture node query(~a, ~b::isalias)
            copies[a] = get(copies, b, b)
        end
    end
    Rewrite(Postwalk(Chain([
        (a -> get(copies, a, nothing)),
        (@rule query(~a, ~a) => plan()),
    ])))(root)
end

"""
This one is a placeholder that places reorder statements inside aggregate and mapjoin query nodes.
only works on the output of propagate_fields(push_fields(prgm))
"""
function lift_fields(prgm)
    Rewrite(Postwalk(Chain([
        (@rule aggregate(~op, ~init, ~arg, ~idxs_1...) => begin
            idxs_2 = getfields(arg)
            aggregate(op, init, reorder(arg, idxs_2...), idxs_1...)
        end),
        (@rule query(~lhs, ~rhs) => if rhs.kind === mapjoin
            idxs = getfields(rhs)
            query(lhs, reorder(rhs, idxs...))
        end),
        (@rule query(~lhs, reformat(~arg)) => if arg.kind === mapjoin
            idxs = getfields(arg)
            query(lhs, reformat(reorder(arg, idxs...)))
        end),
    ])))(prgm)
end

pad_labels = Rewrite(Postwalk(
    @rule relabel(~arg, ~idxs...) => reorder(relabel(~arg, ~idxs...), idxs...)
))

function propagate_into_reformats(root)
    Rewrite(Postwalk(Chain([
        (@rule plan(~a1..., query(~b, ~c), ~a2..., query(~d, reformat(~tns, ~b)), ~a3...) => begin
            if !(b in PostOrderDFS(plan(a2..., a3...))) && (c.kind === mapjoin || c.kind === aggregate || c.kind === reorder)
                plan(a1..., query(d, reformat(tns, c)), a2..., a3...)
            end
        end),
    ])))(root)
end

function issubsequence(a, b)
    a = collect(a)
    b = collect(b)
    return issubset(a, b) && intersect(b, a) == a
end

function withsubsequence(a, b)
    a = collect(a)
    b = collect(b)
    view(b, findall(idx -> idx in a, b)) .= a
    b
end

"""
    concordize(root)

Accepts a program of the following form:

```
        TABLE := table(IMMEDIATE, FIELD...)
       ACCESS := reorder(relabel(ALIAS, FIELD...), FIELD...)
      COMPUTE := ACCESS |
                 mapjoin(IMMEDIATE, COMPUTE...) |
                 aggregate(IMMEDIATE, IMMEDIATE, COMPUTE, FIELD...) |
                 reformat(IMMEDIATE, COMPUTE) |
                 IMMEDIATE
COMPUTE_QUERY := query(ALIAS, COMPUTE)
  INPUT_QUERY := query(ALIAS, TABLE)
         STEP := COMPUTE_QUERY | INPUT_QUERY | produces(ALIAS...)
         ROOT := PLAN(STEP...)
```   

Inserts permutation statements of the form `query(ALIAS, reorder(ALIAS,
FIELD...))` and updates `relabel`s so that
they match their containing `reorder`s. Modified `ACCESS` statements match the form:

```
ACCESS := reorder(relabel(ALIAS, idxs_1::FIELD...), idxs_2::FIELD...) where issubsequence(idxs_1, idxs_2)
```
"""
function concordize(root)
    needed_swizzles = Dict()
    spc = Namespace()
    map(node->freshen(spc, node.name), unique(filter(Or(isfield, isalias), collect(PostOrderDFS(root)))))
    #Collect the needed swizzles
    root = Rewrite(Postwalk(
        @rule reorder(relabel(~a::isalias, ~idxs_1...), ~idxs_2...) => begin
            idxs_3 = intersect(idxs_1, idxs_2)
            if !issubsequence(idxs_3, idxs_2)
                idxs_4 = withsubsequence(intersect(idxs_2, idxs_1), idxs_1)
                perm = map(idx -> findfirst(isequal(idx), idxs_1), idxs_4)
                reorder(relabel(get!(get!(needed_swizzles, a, OrderedDict()), perm, alias(freshen(spc, a.name))), idxs_4), idxs_2...)
            end
        end
    ))(root)
    #Insert the swizzles
    root = Rewrite(Postwalk(Chain([
        (@rule query(~a, ~b) => begin
            if haskey(needed_swizzles, a)
                idxs = getfields(b)
                swizzle_queries = map(collect(needed_swizzles[a])) do (perm, c)
                    query(c, reorder(relabel(a, idxs...), idxs[perm]...))
                end
                plan(query(a, b), swizzle_queries...)
            end
        end),
    ])))(root)
    root = flatten_plans(root)
end

drop_noisy_reorders = Rewrite(Postwalk(
    @rule reorder(relabel(~arg, ~idxs...), ~idxs...) => relabel(arg, idxs...)
))

function format_queries(node::LogicNode, defer = false, bindings=Dict())
    if @capture node plan(~stmts...)
        stmts = map(stmts) do stmt
            format_queries(stmt, defer, bindings)
        end
        plan(stmts...)
    elseif (@capture node query(~lhs, ~rhs)) && rhs.kind !== reformat && rhs.kind !== table
        rep = SuitableRep(bindings)(rhs)
        bindings[lhs] = rep
        if defer
            tns = deferred(fiber_ctr(rep), typeof(rep_construct(rep)))
        else
            tns = immediate(rep_construct(rep))
        end
        query(lhs, reformat(tns, rhs))
    elseif @capture node query(~lhs, ~rhs)
        bindings[lhs] = SuitableRep(bindings)(rhs)
        node
    else
        node
    end
end
struct SuitableRep
    bindings::Dict
end
function (ctx::SuitableRep)(ex)
    if ex.kind === alias
        return ctx.bindings[ex]
    elseif @capture ex table(~tns::isimmediate, ~idxs...)
        return data_rep(ex.tns.val)
    elseif @capture ex table(~tns::isdeferred, ~idxs...)
        return data_rep(ex.tns.type)
    elseif ex.kind === mapjoin
        #This step assumes concordant mapjoin arguments, and also that the
        #mapjoin arguments have the same number of dimensions. It's necessary to
        #assume this because it's not possible to recursively reconstruct a
        #total ordering of the indices as we go.
        return map_rep(ex.op.val, map(ctx, ex.args)...)
    elseif ex.kind === aggregate
        idxs = getfields(ex.arg)
        return aggregate_rep(ex.op.val, ex.init.val, ctx(ex.arg), map(idx->findfirst(isequal(idx), idxs), ex.idxs))
    elseif ex.kind === reorder
        rep = ctx(ex.arg)
        idxs = getfields(ex.arg)
        #first reduce dropped dimensions
        rep = aggregate_rep(initwrite(fill_value(rep)), fill_value(rep), rep, findall(idx -> idx in setdiff(idxs, ex.idxs), idxs))
        #then permute remaining dimensions to match
        perm = sortperm(intersect(idxs, ex.idxs), by=idx->findfirst(isequal(idx), ex.idxs))
        rep = permutedims_rep(rep, perm)
        #then add new dimensions
        return expanddims_rep(rep, findall(idx -> !(idx in idxs), ex.idxs))
    elseif ex.kind === relabel
        return ctx(ex.arg)
    elseif ex.kind === reformat
        return data_rep(ex.tns.val)
    elseif ex.kind === immediate
        return ElementData(ex.val, typeof(ex.val))
    else
        error("Unrecognized expression: $(ex.kind)")
    end
end

function propagate_map_queries(root)
    root = Rewrite(Postwalk(@rule aggregate(~op, ~init, ~arg) => mapjoin(op, init, arg)))(root)
    rets = getproductions(root)
    props = Dict()
    for node in PostOrderDFS(root)
        if @capture node query(~a, mapjoin(~op, ~args...))
            if !(a in rets)
                props[a] = mapjoin(op, args...)
            end
        end
    end
    Rewrite(Prewalk(Chain([
        (a -> if haskey(props, a) props[a] end),
        (@rule query(~a, ~b) => if haskey(props, a) plan() end),
        (@rule plan(~a1..., plan(), ~a2...) => plan(a1..., a2...)),
    ])))(root)
end

function normalize_names(ex)
    spc = Namespace()
    scope = Dict()
    normname(sym) = get!(scope, sym) do
        if isgensym(sym)
            sym = gensymname(sym)
        end
        freshen(spc, sym)
    end
    Rewrite(Postwalk(@rule ~a::isalias => alias(normname(a.name))))(ex)
end

function toposort(perms::Vector{Vector{T}}) where T
    graph = Dict{T, Set{T}}()
    for perm in perms
        i = nothing
        for j in perm
            if i != nothing
                push!(get!(graph, i, Set{T}()), j)
            end
            i = j
        end
    end
    #https://rosettacode.org/wiki/Topological_sort#Julia
    for (k, v) in graph
        delete!(v, k)
    end
    extraitems = setdiff(reduce(union, values(graph)), keys(graph))
    for item in extraitems
        graph[item] = Set{T}()
    end
    rst = Vector{T}()
    while true
        ordered = Set(item for (item, dep) in graph if isempty(dep))
        if isempty(ordered) break end
        append!(rst, ordered)
        graph = Dict{T,Set{T}}(item => setdiff(dep, ordered) for (item, dep) in graph if item ∉ ordered)
    end
    if isempty(graph)
        return rst
    else
        # a cyclic dependency exists amongst $(keys(graph))
        return nothing
    end
end

function heuristic_loop_order(node)
    perms = Vector{LogicNode}[]
    for node in PostOrderDFS(node)
        if @capture node relabel(~arg, ~idxs...)
            push!(perms, idxs)
        end
    end
    sort!(perms, by=length)
    res = something(toposort(perms), getfields(node))
    if mapreduce(max, length, perms, init = 0) < length(unique(reduce(vcat, perms)))
        counts = Dict()
        for perm in perms
            for idx in perm
                counts[idx] = get(counts, idx, 0) + 1
            end
        end
        sort!(res, by=idx -> counts[idx] == 1, alg=Base.MergeSort)
    end
    return res
end

"""
set_loop_order(root)

Heuristically chooses a total order for all loops in the program by inserting
`reorder` statments inside reformat, query, and aggregate nodes.

Accepts programs of the form:
```
      REORDER := reorder(relabel(ALIAS, FIELD...), FIELD...)
       ACCESS := reorder(relabel(ALIAS, idxs_1::FIELD...), idxs_2::FIELD...) where issubsequence(idxs_1, idxs_2)
    POINTWISE := ACCESS | mapjoin(IMMEDIATE, POINTWISE...) | reorder(IMMEDIATE, FIELD...) | IMMEDIATE
    MAPREDUCE := POINTWISE | aggregate(IMMEDIATE, IMMEDIATE, POINTWISE, FIELD...)
       TABLE  := table(IMMEDIATE, FIELD...)
COMPUTE_QUERY := query(ALIAS, reformat(IMMEDIATE, arg::(REORDER | MAPREDUCE)))
  INPUT_QUERY := query(ALIAS, TABLE)
         STEP := COMPUTE_QUERY | INPUT_QUERY
         ROOT := PLAN(STEP..., produces(ALIAS...))
```
"""
function set_loop_order(node, perms = Dict(), reps = Dict())
    if @capture node plan(~stmts...)
        stmts = map(stmts) do stmt
            set_loop_order(stmt, fields)
        end
        plan(stmts...)
    elseif @capture node query(~lhs, reformat(~tns, ~rhs::isalias))
        rhs_2 = perms[rhs]
        perms[lhs] = lhs
        reps[lhs] = SuitableRep(reps)(rhs_2)
        query(lhs, reformat(tns, rhs_2))
    elseif @capture node query(~lhs, reformat(~tns, ~rhs))
        arg = alias(gensym(:A))
        set_loop_order(plan(
            query(A, rhs),
            query(lhs, reformat(tns, A))
        ), perms, reps)
    elseif @capture node query(~lhs, table(~tns, ~idxs...))
        reps[lhs] = SuitableRep(reps)(node.rhs)
        perms[lhs] = lhs
        node
    elseif @capture node query(~lhs, aggregate(~op, ~init, ~arg, ~idxs...))
        arg = push_fields(Rewrite(Postwalk(tns -> get(perms, tns, tns)))(arg))
        idxs_2 = heuristic_loop_order(arg)
        rhs_2 = aggregate(op, init, reorder(arg, idxs_2...), idxs...)
        reps[lhs] = SuitableRep(reps)(rhs_2)
        perms[lhs] = reorder(relabel(lhs, getfields(rhs_2)), getfields(node.rhs))
        query(lhs, rhs)
    elseif @capture node query(~lhs, reorder(relabel(~tns::isalias, ~idxs_1...), ~idxs_2...))
        tns = get(perms, tns, tns)
        reps[lhs] = SuitableRep(reps)(node.rhs)
        perm[lhs] = lhs
    elseif @capture node query(~lhs, ~rhs)
        #assuming rhs is a bunch of mapjoins
        arg = push_fields(Rewrite(Postwalk(tns -> get(perms, tns, tns)))(arg))
        idxs = heuristic_pointwise_loop_order(rhs)
        rhs_2 = reorder(rhs, idxs...)
        reps[lhs] = SuitableRep(reps)(rhs_2)
        perms[lhs] = reorder(relabel(lhs, idxs), getfields(rhs))
        query(lhs, rhs_2)
    else
        throw(ArgumentError("Unrecognized program in set_loop_order"))
    end
end

function optimize(prgm)
    #deduplicate and lift inline subqueries to regular queries
    prgm = lift_subqueries(prgm)

    #At this point in the program, all statements should be unique, so
    #it is okay to name different occurences of things.

    #these steps lift reformat, aggregate, and table nodes into separate
    #queries, using subqueries as temporaries.
    prgm = isolate_reformats(prgm)
    prgm = isolate_aggregates(prgm)
    prgm = isolate_tables(prgm)
    prgm = lift_subqueries(prgm)

    #I shouldn't use gensym but I do, so this cleans up the names
    prgm = pretty_labels(prgm)

    #These steps fuse copy, permutation, and mapjoin statements
    #into later expressions.
    #Only reformat statements preserve intermediate breaks in computation
    prgm = propagate_copy_queries(prgm)
    prgm = propagate_transpose_queries(prgm)
    prgm = propagate_map_queries(prgm)

    #These steps assign a global loop order to each statement.
    prgm = propagate_fields(prgm)

    prgm = push_fields(prgm)
    prgm = lift_fields(prgm)
    prgm = push_fields(prgm)

    #After we have a global loop order, we concordize the program
    prgm = concordize(prgm)

    #Add reformat statements where there aren't any
    prgm = propagate_into_reformats(prgm)
    prgm = propagate_copy_queries(prgm)

    #Normalize names for caching
    prgm = normalize_names(prgm)
end

"""
    DefaultLogicOptimizer(ctx)

The default optimizer for finch logic programs. Optimizes to a structure
suitable for the LogicCompiler or LogicInterpreter, then calls `ctx` on the
resulting program.
"""
struct DefaultLogicOptimizer
    ctx
end

function (ctx::DefaultLogicOptimizer)(prgm)
    prgm = optimize(prgm)
    ctx.ctx(prgm)
end

function set_options(ctx::DefaultLogicOptimizer; kwargs...)
    DefaultLogicOptimizer(set_options(ctx.ctx; kwargs...))
end