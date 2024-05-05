using Finch.FinchNotation: block_instance, declare_instance, call_instance, loop_instance, index_instance, variable_instance, tag_instance, access_instance, assign_instance, literal_instance, yieldbind_instance

function finch_pointwise_logic_to_program(scope, ex)
    if @capture ex mapjoin(~op, ~args...)
        call_instance(literal_instance(op.val), map(arg -> finch_pointwise_logic_to_program(scope, arg), args)...)
    elseif (@capture ex reorder(relabel(~arg::isalias, ~idxs_1...), ~idxs_2...))
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

@kwdef struct LogicMachine
    scope = Dict{Any, Any}()
    verbose = false
    mode = :fast
end

function (ctx::LogicMachine)(ex)
    if ex.kind === alias
        ex.scope[ex]
    elseif @capture ex query(~lhs, ~rhs)
        ctx.scope[lhs] = ctx(rhs)
        (ctx.scope[lhs],)
    elseif @capture ex table(~tns, ~idxs...)
        return tns.val
    elseif @capture ex reformat(~tns, reorder(relabel(~arg::isalias, ~idxs_1...), ~idxs_2...))
        loop_idxs = map(idx -> index_instance(idx.name), withsubsequence(intersect(idxs_1, idxs_2), idxs_2))
        lhs_idxs = map(idx -> index_instance(idx.name), idxs_2)
        res = tag_instance(variable_instance(:res), tns.val)
        lhs = access_instance(res, literal_instance(updater), lhs_idxs...)
        rhs = finch_pointwise_logic_to_program(ctx.scope, reorder(relabel(arg, idxs_1...), idxs_2...))
        body = assign_instance(lhs, literal_instance(initwrite(default(tns.val))), rhs)
        for idx in loop_idxs
            body = loop_instance(idx, dimless, body)
        end
        body = block_instance(declare_instance(res, literal_instance(default(tns.val))), body, yieldbind_instance(res))
        if ctx.verbose
            print("Running: ")
            display(body)
        end
        execute(body, mode = ctx.mode).res
    elseif @capture ex reformat(~tns, mapjoin(~args...))
        z = default(tns.val)
        ctx(reformat(tns, aggregate(initwrite(z), immediate(z), mapjoin(args...))))
    elseif @capture ex reformat(~tns, aggregate(~op, ~init, ~arg, ~idxs_1...))
        idxs_2 = map(idx -> index_instance(idx.name), getfields(arg))
        idxs_3 = map(idx -> index_instance(idx.name), setdiff(getfields(arg), idxs_1))
        res = tag_instance(variable_instance(:res), tns.val)
        lhs = access_instance(res, literal_instance(updater), idxs_3...)
        rhs = finch_pointwise_logic_to_program(ctx.scope, arg)
        body = assign_instance(lhs, literal_instance(op.val), rhs)
        for idx in idxs_2
            body = loop_instance(idx, dimless, body)
        end
        body = block_instance(declare_instance(res, literal_instance(default(tns.val))), body, yieldbind_instance(res))
        if ctx.verbose
            print("Running: ")
            display(body)
        end
        execute(body, mode = ctx.mode).res
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

"""
    LogicInterpreter(scope = Dict(), verbose = false, mode = :fast)

The LogicInterpreter is a simple interpreter for finch logic programs. The interpreter is
only capable of executing programs of the form:
      REORDER := reorder(relabel(ALIAS, FIELD...), FIELD...)
       ACCESS := reorder(relabel(ALIAS, idxs_1::FIELD...), idxs_2::FIELD...) where issubsequence(idxs_1, idxs_2)
    POINTWISE := ACCESS | mapjoin(IMMEDIATE, POINTWISE...) | reorder(IMMEDIATE, FIELD...) | IMMEDIATE
    MAPREDUCE := POINTWISE | aggregate(IMMEDIATE, IMMEDIATE, POINTWISE, FIELD...)
       TABLE  := table(IMMEDIATE, FIELD...)
COMPUTE_QUERY := query(ALIAS, reformat(IMMEDIATE, arg::(REORDER | MAPREDUCE)))
  INPUT_QUERY := query(ALIAS, TABLE)
         STEP := COMPUTE_QUERY | INPUT_QUERY | produces(ALIAS...)
         ROOT := PLAN(STEP...)
"""
@kwdef struct LogicInterpreter
    verbose = false
    mode = :fast
end

function (ctx::LogicInterpreter)(prgm)
    prgm = format_queries(prgm)
    LogicMachine(verbose = ctx.verbose, mode = ctx.mode)(prgm)
end