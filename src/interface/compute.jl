flatten_plans = Rewrite(Postwalk(Chain([
    (@rule plan(~a1..., plan(~b..., produces(~c...)), ~a2...) => plan(a1..., b..., a2...)),
    (@rule plan(~a1..., plan(~b...), ~a2...) => plan(a1..., b..., a2...)),
])))

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
    Rewrite(Fixpoint(Postwalk(Chain([
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
    ]))))(root)
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
            if haskey(needed_swizzles, a)
                idxs = getfields(a, bindings)
                swizzle_queries = map(collect(needed_swizzles[a])) do (idxs_2, c)
                    idxs_3 = copy(idxs)
                    view(idxs_3, findall(idx -> idx in idxs_2, idxs)) .= idxs_2
                    bindings[c] = reorder(a, idxs_3...)
                    query(c, reorder(a, idxs_3...))
                end
                plan(query(a, b), swizzle_queries...)
            end
        end),
    ])))(root)
    root = flatten_plans(root)
end

compute(arg) = compute((arg,))
#compute(arg) = compute((arg,))[1]
function compute(args::Tuple)
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
    bindings = getbindings(prgm)
    display(pretty_labels(prgm))
    prgm = push_labels(prgm, bindings)
    display(pretty_labels(prgm))
    prgm = concordize(prgm, bindings)
    prgm = fuse_reformats(prgm)
    prgm = pad_with_aggregate(prgm)
    display(pretty_labels(prgm))
end