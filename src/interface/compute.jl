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

function simplify_queries(bindings)
    Rewrite(Fixpoint(Postwalk(Chain([
        (@rule aggregate(~op, ~init, ~arg) => mapjoin(op, init, arg)),
        (@rule mapjoin(overwrite, ~lhs, ~rhs) =>
            reorder(rhs, getfields(mapjoin(overwrite, ~lhs, ~rhs), bindings)...)),
    ]))))
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
end

function concordize(root, bindings)
    needed_swizzles = Dict()
    root = Rewrite(Postwalk(
        @rule reorder(relabel(~a::isalias, ~idxs_2...), ~idxs...) => begin
            idxs_3 = getfields(a, bindings)
            reidx = Dict(map(Pair, idxs_2, idxs_3)...)
            idxs_4 = map(idx -> get(reidx, idx, idx), idxs)
            relabel(reorder(a, idxs_4...), idxs...)
        end
    ))(root)
    root = Rewrite(Postwalk(Chain([
        (@rule reorder(~a::isalias, ~idxs...) => begin
            idxs_2 = getfields(a, bindings)
            idxs_3 = intersect(idxs, idxs_2)
            if !issubsequence(idxs_3, idxs_2)
                res = reorder(get!(get!(needed_swizzles, a, Dict()), idxs_3, alias(gensym(:A))), idxs...)
                println(res)
                res
            end
        end),
    ])))(root)
    root = Rewrite(Postwalk(Chain([
        (@rule query(~a, ~b) => begin
            if haskey(needed_swizzles, a)
                idxs = getfields(a, bindings)
                swizzle_queries = map(collect(needed_swizzles[a])) do (idxs_2, c)
                    idxs_3 = withsubsequence(idxs_2, idxs)
                    bindings[c] = reorder(a, idxs_3...)
                    query(c, reorder(relabel(a, idxs), idxs_3...))
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
        ##Assumes concordant mapjoin arguments, probably okay
        return map_rep(ex.op.val, map(ctx, ex.args)...)
    elseif ex.kind === aggregate
        idxs = getfields(ex.arg, ctx.bindings)
        return aggregate_rep(ex.op.val, ex.init.val, ctx(ex.arg), map(idx->findfirst(isequal(idx), idxs), ex.idxs))
    elseif ex.kind === reorder
        idxs = getfields(ex.arg, ctx.bindings)
        return permutedims_rep(ctx(ex.arg), map(idx->findfirst(isequal(idx), ex.idxs), idxs))
    elseif ex.kind === relabel
        return ctx(ex.arg)
    elseif ex.kind === reformat
        return data_rep(ex.tns.val)
    else
        error("Unrecognized expression: $(ex.kind)")
    end
end

compute(arg) = compute((arg,))
#compute(arg) = compute((arg,))[1]
function compute(args::Tuple)
    args = collect(args)
    vars = map(arg -> alias(gensym(:A)), args)
    bodies = map((arg, var) -> query(var, arg.data), args, vars)
    prgm = plan(bodies, produces(vars))
    display(prgm)
    prgm = lift_subqueries(prgm)
    #At this point in the program, all statements should be unique, so the
    #isolate calls that name things to lift them should be okay.
    prgm = isolate_reformats(prgm)
    prgm = isolate_aggregates(prgm)
    prgm = isolate_tables(prgm)
    prgm = lift_subqueries(prgm)
    bindings = getbindings(prgm)
    prgm = simplify_queries(bindings)(prgm)
    prgm = propagate_copy_queries(prgm)
    prgm = pretty_labels(prgm)
    bindings = getbindings(prgm)
    display(prgm)
    prgm = push_labels(prgm, bindings)
    prgm = push_reorders(prgm, bindings)
    display(prgm)
    prgm = concordize(prgm, bindings)
    display(prgm)
    prgm = fuse_reformats(prgm)
    display(prgm)
    prgm = pad_labels(prgm)
    prgm = push_labels(prgm, bindings)
    prgm = propagate_copy_queries(prgm)
    prgm = format_queries(bindings)(prgm)
    display(prgm)
    FinchInterpreter(Dict())(prgm)
end

"""
    FinchInterpreter

The finch interpreter is a simple interpreter for finch logic programs. The interpreter is
only capable of executing programs of the form:
REORDER = relabel(reorder(tns::isalias, idxs_1...), idxs_2...)
ACCESS = relabel(reorder(tns::isalias, idxs_1...), idxs_2...) where issubsequence(idxs_1, idxs_2)
POINTWISE = ACCESS | mapjoin(f, arg::POINTWISE...)
MAPREDUCE = POINTWISE | aggregate(op, init, arg::POINTWISE, idxs...)
TABLE = table(tns, idxs...)
COMPUTE_QUERY = query(lhs, reformat(tns, arg::(REORDER | MAPREDUCE)))
INPUT_QUERY = query(lhs, TABLE)
ROOT = PLAN(args::(COMPUTE_QUERY | INPUT_QUERY | produces(args...))...)
"""
struct FinchInterpreter
    scope::Dict
end

FinchInterpreter() = FinchInterpreter(Dict())

using Finch.FinchNotation: block_instance, declare_instance, call_instance, loop_instance, index_instance, variable_instance, tag_instance, access_instance, assign_instance, literal_instance

function finch_pointwise_logic_to_program(scope, ex)
    if @capture ex mapjoin(~op, ~args...)
        call_instance(op.val, map(arg -> finch_pointwise_logic_to_program(scope, arg), args)...)
    elseif (@capture ex reorder(relabel(~arg::isalias, ~idxs_1...), ~idxs_2...)) && issubsequence(idxs_1, idxs_2)
        idxs_3 = map(enumerate(idxs_1)) do (n, idx)
            idx in idxs_2 ? index_instance(idx.name) : first(axes(arg)[n])
        end
        access_instance(tag_instance(variable_instance(arg.name), scope[arg]), literal_instance(reader), idxs_3...)
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
        body = block_instance(declare_instance(res, literal_instance(default(tns.val))), body)
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