flatten_plans = Rewrite(Postwalk(Fixpoint(Chain([
    (@rule plan(~a1..., plan(~b..., produces(~c...)), ~a2...) => plan(a1..., b..., a2...)),
    (@rule plan(~a1..., plan(~b...), ~a2...) => plan(a1..., b..., a2...)),
]))))

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

function simplify_queries(prgm)
    Rewrite(Fixpoint(Postwalk(Chain([
        (@rule aggregate(~op, ~init, ~arg) => mapjoin(op, arg)),
        (@rule mapjoin(overwrite, ~lhs, ~rhs) =>
            reorder(rhs, getfields(mapjoin(overwrite, ~lhs, ~rhs))...)),
    ]))))(prgm)
end

function propagate_copy_queries(root)
    copies = Dict()
    for node in PostOrderDFS(root)
        if @capture node query(~a, ~b::isalias)
            copies[a] = b
        end
    end
    Rewrite(Postwalk(Chain([
        Fixpoint(a -> if haskey(copies, a) copies[a] end),
        (@rule query(~a, ~a) => plan()),
        (@rule plan(~a1..., plan(), ~a2...) => plan(a1..., a2...)),
    ])))(root)
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

function push_labels(root)
    root = Rewrite(Postwalk(Chain([
        (@rule relabel(~arg, ~idxs...) => reorder(relabel(~arg, ~idxs...), idxs...)),
        #TODO: This statement sets the loop order, which should probably be done with more forethought as a separate step before concordization.
        (@rule mapjoin(~args...) => reorder(mapjoin(args...), getfields(mapjoin(args...))...))
    ])))(root)

    root = Rewrite(Fixpoint(Prewalk(Chain([
        (@rule reorder(mapjoin(~op, ~args...), ~idxs...) =>
            mapjoin(op, map(arg -> reorder(arg, ~idxs...), args)...)),
        (@rule relabel(mapjoin(~op, ~args...), ~idxs...) => begin
            idxs_2 = getfields(mapjoin(op, args...))
            mapjoin(op, map(arg -> relabel(reorder(arg, idxs_2...), idxs...), args)...)
        end),
        (@rule reorder(reorder(~arg, ~idxs...), ~idxs_2...) =>
            reorder(~arg, ~idxs_2...)),
        (@rule relabel(relabel(~arg, ~idxs...), ~idxs_2...) =>
            relabel(~arg, ~idxs_2...)),
        (@rule relabel(reorder(relabel(~arg, ~idxs...), ~idxs_2...), ~idxs_3...) => begin
            reidx = Dict(map(Pair, idxs_2, idxs_3)...)
            idxs_4 = map(idx -> get(reidx, idx, idx), idxs)
            reorder(relabel(arg, idxs_4...), idxs_3...)
        end),
    ]))))(root)
end

#=
    root = Rewrite(Fixpoint(Postwalk(Chain([
        (@rule plan(~a1..., query(~b, relabel(~c, ~i...)), ~a2...) => begin
            d = alias(gensym(:A))
            bindings[d] = c
            rw = Rewrite(Postwalk(@rule b => relabel(d, i...)))
            plan(a1..., query(d, c), map(rw, a2)...)
        end),
        (@rule plan(~a1..., query(~b, reorder(~c, ~i...)), ~a2...) => begin
            d = alias(gensym(:A))
            bindings[d] = c
            rw = Rewrite(Postwalk(@rule b => reorder(d, i...)))
            plan(a1..., query(d, c), map(rw, a2)...)
        end),
        #(@rule reformat(~tns, relabel(~arg, ~idxs...)) => relabel(reformat(tns, arg), idxs...)),
    ]))))(root)
=#
#=
function pull_reorders(root, bindings)
    root = Rewrite(Fixpoint(Prewalk(Chain([
        (@rule mapjoin(~args...) => reorder(mapjoin(args...), getfields(mapjoin(args...), bindings)...))
    ]))))(root)
    root = Rewrite(Fixpoint(Prewalk(Chain([
        (@rule mapjoin(~a1..., reorder(~b, ~i...), ~a2...) => mapjoin(a1..., b, a2...)),
    ]))))(root)
end

function push_reorders(root, bindings)
    Rewrite(Fixpoint(Postwalk(Chain([
        (@rule plan(~a1..., query(~b, reorder(~c, ~i...)), ~a2...) => begin
            d = alias(gensym(:A))
            bindings[d] = c
            rw = Rewrite(Postwalk(@rule b => reorder(d, i...)))
            plan(a1..., query(d, c), map(rw, a2)...)
        end),
    ]))))(root)
end
=#

"""
order_loops(root)

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
function order_loops(prgm)
    
end


pad_labels = Rewrite(Postwalk(
    @rule relabel(~arg, ~idxs...) => reorder(relabel(~arg, ~idxs...), idxs...)
))

function fuse_reformats(root)
    Rewrite(Postwalk(Chain([
        (@rule plan(~a1..., query(~b, ~c), ~a2..., query(~d, reformat(~tns, ~b)), ~a3...) => begin
            if !(b in PostOrderDFS(plan(a2..., a3...))) && c.kind !== reformat
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
         STEP := COMPUTE_QUERY | INPUT_QUERY
         ROOT := PLAN(STEP..., produces(ALIAS...))
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
                reorder(relabel(get!(get!(needed_swizzles, a, Dict()), perm, alias(freshen(spc, a.name))), idxs_4), idxs_2...)
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

function format_queries(bindings)
    Rewrite(Postwalk(
        @rule query(~a, ~b) => if b.kind !== reformat && b.kind !== table
            query(a, reformat(immediate(suitable_storage(b, bindings)), b))
        end
    ))
end

struct SuitableRep
    bindings::Dict
end
suitable_storage(ex, bindings) = rep_construct(SuitableRep(bindings)(ex))
function (ctx::SuitableRep)(ex)
    if ex.kind === alias
        return ctx(ctx.bindings[ex])
    elseif ex.kind === table
        return data_rep(ex.tns.val)
    elseif ex.kind === mapjoin
        #This step assumes concordant mapjoin arguments, and also that the
        #mapjoin arguments have the same number of dimensions. It's necessary to
        #assume this because it's not possible to recursively reconstruct a
        #total ordering of the indices as we go.
        return map_rep(ex.op.val, map(ctx, ex.args)...)
    elseif ex.kind === aggregate
        idxs = getfields(ex.arg, ctx.bindings)
        return aggregate_rep(ex.op.val, ex.init.val, ctx(ex.arg), map(idx->findfirst(isequal(idx), idxs), ex.idxs))
    elseif ex.kind === reorder
        #In this step, we need to consider that the reorder may add or permute
        #dims. I haven't considered whether this is robust to dropping dims (it
        #probably isn't)
        idxs = getfields(ex.arg, ctx.bindings)
        perm = sortperm(idxs, by=idx->findfirst(isequal(idx), ex.idxs))
        rep = permutedims_rep(ctx(ex.arg), perm)
        dims = findall(idx -> idx in idxs, ex.idxs)
        return extrude_rep(rep, dims)
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

"""
    FinchInterpreter

The finch interpreter is a simple interpreter for finch logic programs. The interpreter is
only capable of executing programs of the form:
      REORDER := reorder(relabel(ALIAS, FIELD...), FIELD...)
       ACCESS := reorder(relabel(ALIAS, idxs_1::FIELD...), idxs_2::FIELD...) where issubsequence(idxs_1, idxs_2)
    POINTWISE := ACCESS | mapjoin(IMMEDIATE, POINTWISE...) | reorder(IMMEDIATE, FIELD...) | IMMEDIATE
    MAPREDUCE := POINTWISE | aggregate(IMMEDIATE, IMMEDIATE, POINTWISE, FIELD...)
       TABLE  := table(IMMEDIATE, FIELD...)
COMPUTE_QUERY := query(ALIAS, reformat(IMMEDIATE, arg::(REORDER | MAPREDUCE)))
  INPUT_QUERY := query(ALIAS, TABLE)
         STEP := COMPUTE_QUERY | INPUT_QUERY
         ROOT := PLAN(STEP..., produces(ALIAS...))
"""
struct FinchInterpreter
    scope::Dict
end

FinchInterpreter() = FinchInterpreter(Dict())

using Finch.FinchNotation: block_instance, declare_instance, call_instance, loop_instance, index_instance, variable_instance, tag_instance, access_instance, assign_instance, literal_instance, yieldbind_instance

function finch_pointwise_logic_to_program(scope, ex)
    if @capture ex mapjoin(~op, ~args...)
        call_instance(literal_instance(op.val), map(arg -> finch_pointwise_logic_to_program(scope, arg), args)...)
    elseif (@capture ex reorder(relabel(~arg::isalias, ~idxs_1...), ~idxs_2...)) && issubsequence(idxs_1, idxs_2)
        idxs_3 = map(enumerate(idxs_1)) do (n, idx)
            idx in idxs_2 ? index_instance(idx.name) : first(axes(arg)[n])
        end
        access_instance(tag_instance(variable_instance(arg.name), scope[arg]), literal_instance(reader), idxs_3...)
    elseif (@capture ex reorder(~arg::isimmediate, ~idxs...))
        literal_instance(arg.val)
    elseif ex.kind === immediate
        literal_instance(ex.val)
    else
        error("Unrecognized logic: $(ex)")
    end
end

function (ctx::FinchInterpreter)(ex)
    if ex.kind === alias
        ex.scope[ex]
    elseif @capture ex query(~lhs, ~rhs)
        ctx.scope[lhs] = ctx(rhs)
        (ctx.scope[lhs],)
    elseif @capture ex table(~tns, ~idxs...)
        return tns.val
    elseif @capture ex reformat(~tns, reorder(relabel(~arg::isalias, ~idxs_1...), ~idxs_2...))
        copyto!(tns.val, swizzle(ctx.scope[arg], map(idx -> findfirst(isequal(idx), idxs_1), idxs_2)...))
    elseif @capture ex reformat(~tns, mapjoin(~args...))
        z = default(tns.val)
        ctx(reformat(tns, aggregate(initwrite(z), immediate(z), mapjoin(args...))))
    elseif @capture ex reformat(~tns, aggregate(~op, ~init, ~arg, ~idxs_1...))
        idxs_2 = map(idx -> index_instance(idx.name), getfields(arg, Dict()))
        idxs_3 = map(idx -> index_instance(idx.name), setdiff(getfields(arg, Dict()), idxs_1))
        res = tag_instance(variable_instance(:res), tns.val)
        lhs = access_instance(res, literal_instance(updater), idxs_3...)
        rhs = finch_pointwise_logic_to_program(ctx.scope, arg)
        body = assign_instance(lhs, literal_instance(op.val), rhs)
        for idx in idxs_2
            body = loop_instance(idx, dimless, body)
        end
        body = block_instance(declare_instance(res, literal_instance(default(tns.val))), body, yieldbind_instance(res))
        #display(body) # wow it's really satisfying to uncomment this and type finch ops at the repl.
        execute(body).res
    elseif @capture ex produces(~args...)
        return map(arg -> ctx.scope[arg], args)
    elseif @capture ex plan(~head)
        ctx(head)
    elseif @capture ex plan(~head, ~tail...)
        ctx(head)
        return ctx(plan(tail...))
    else
        error("Unrecognized logic: $(ex)")
    end
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

struct DefaultOptimizer
    ctx
end

default_optimizer = DefaultOptimizer(FinchInterpreter())

"""
    lazy(arg)

Create a lazy tensor from an argument. All operations on lazy tensors are
lazy, and will not be executed until `compute` is called on their result.

for example,
```julia
x = lazy(rand(10))
y = lazy(rand(10))
z = x + y
z = z + 1
z = compute(z)
```
will not actually compute `z` until `compute(z)` is called, so the execution of `x + y`
is fused with the execution of `z + 1`.
"""
lazy(arg) = LazyTensor(arg)

function propagate_map_queries(root)
    rets = []
    for node in PostOrderDFS(root)
        if @capture node produces(~args...)
            append!(rets, args)
        end
    end
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

"""
    compute(args..., ctx=default_optimizer) -> Any

Compute the value of a lazy tensor. The result is the argument itself, or a
tuple of arguments if multiple arguments are passed.
"""
compute(args...; ctx=default_optimizer) = compute(arg, default_optimizer)
compute(arg; ctx=default_optimizer) = compute_impl((arg,), ctx)[1]
compute(args::Tuple; ctx=default_optimizer) = compute_impl(args, ctx)
function compute_impl(args::Tuple, ctx::DefaultOptimizer)
    args = collect(args)
    vars = map(arg -> alias(gensym(:A)), args)
    bodies = map((arg, var) -> query(var, arg.data), args, vars)
    prgm = plan(bodies, produces(vars))

    prgm = lift_subqueries(prgm)

    #At this point in the program, all statements should be unique, so the
    #isolate calls that name things to lift them should be okay.
    prgm = isolate_reformats(prgm)
    prgm = isolate_aggregates(prgm)
    prgm = isolate_tables(prgm)
    prgm = lift_subqueries(prgm)

    prgm = simplify_queries(prgm)
    prgm = propagate_copy_queries(prgm)
    prgm = propagate_map_queries(prgm)
    prgm = pretty_labels(prgm)
    prgm = propagate_fields(prgm)
    prgm = push_fields(prgm)
    prgm = concordize(prgm)
    prgm = fuse_reformats(prgm)
    prgm = propagate_fields(prgm)
    prgm = push_labels(prgm)
    prgm = propagate_copy_queries(prgm)
    bindings = getbindings(prgm)
    prgm = format_queries(bindings)(prgm)
    prgm = normalize_names(prgm)
    FinchInterpreter(Dict())(prgm)
end
