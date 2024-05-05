"""
    FinchCompiler

The finch compiler is a simple compiler for finch logic programs. The interpreter is
only capable of executing programs of the form:
      REORDER := reorder(relabel(ALIAS, FIELD...), FIELD...)
       ACCESS := reorder(relabel(ALIAS, idxs_1::FIELD...), idxs_2::FIELD...) where issubsequence(idxs_1, idxs_2)
    POINTWISE := ACCESS | mapjoin(IMMEDIATE, POINTWISE...) | reorder(IMMEDIATE, FIELD...) | IMMEDIATE
    MAPREDUCE := POINTWISE | aggregate(IMMEDIATE, IMMEDIATE, POINTWISE, FIELD...)
       TABLE  := table(IMMEDIATE | DEFERRED, FIELD...)
COMPUTE_QUERY := query(ALIAS, reformat(IMMEDIATE, arg::(REORDER | MAPREDUCE)))
  INPUT_QUERY := query(ALIAS, TABLE)
         STEP := COMPUTE_QUERY | INPUT_QUERY | produces(ALIAS...)
         ROOT := PLAN(STEP...)
"""
struct FinchCompiler end

function finch_pointwise_logic_to_code(ex)
    if @capture ex mapjoin(~op, ~args...)
        :($(op.val)($(map(arg -> finch_pointwise_logic_to_code(arg), args)...)))
    elseif (@capture ex reorder(relabel(~arg::isalias, ~idxs_1...), ~idxs_2...))
        :($(arg.name)[$(map(idx -> idx.name, idxs_1)...)])
    elseif (@capture ex reorder(~arg::isimmediate, ~idxs...))
        arg.val
    elseif ex.kind === immediate
        ex.val
    else
        error("Unrecognized logic: $(ex)")
    end
end

function compile_logic_constant(node)
    if node.kind === immediate
        node.val
    elseif node.kind === deferred
        :($(node.ex)::$(node.type))
    else
        error()
    end
end

function logic_constant_type(node)
    if node.kind === immediate
        typeof(node.val)
    elseif node.kind === deferred
        node.type
    else
        error()
    end
end

function (ctx::FinchCompiler)(ex)
    if @capture ex query(~lhs::isalias, table(~tns, ~idxs...))
        :($(lhs.name) = $(compile_logic_constant(tns)))
    elseif @capture ex query(~lhs::isalias, reformat(~tns, reorder(relabel(~arg::isalias, ~idxs_1...), ~idxs_2...)))
        loop_idxs = map(idx -> idx.name, withsubsequence(intersect(idxs_1, idxs_2), idxs_2))
        lhs_idxs = map(idx -> idx.name, idxs_2)
        rhs = finch_pointwise_logic_to_code(reorder(relabel(arg, idxs_1...), idxs_2...))
        body = :($(lhs.name)[$(lhs_idxs...)] = $rhs)
        for idx in loop_idxs
            body = :(for $idx = _
                $body
            end)
        end
        quote
            $(lhs.name) = $(compile_logic_constant(tns))
            @finch begin
                $(lhs.name) .= $(default(logic_constant_type(tns)))
                $body
                return $(lhs.name)
            end
        end
    elseif @capture ex query(~lhs::isalias, reformat(~tns, mapjoin(~args...)))
        z = default(logic_constant_type(tns))
        ctx(query(lhs, reformat(tns, aggregate(initwrite(z), immediate(z), mapjoin(args...)))))
    elseif @capture ex query(~lhs, reformat(~tns, aggregate(~op, ~init, ~arg, ~idxs_1...)))
        idxs_2 = map(idx -> idx.name, getfields(arg))
        idxs_3 = map(idx -> idx.name, setdiff(getfields(arg), idxs_1))
        rhs = finch_pointwise_logic_to_code(arg)
        body = :($(lhs.name)[$(idxs_3...)] <<$(compile_logic_constant(op))>>= $rhs)
        for idx in idxs_2
            body = :(for $idx = _
                $body
            end)
        end
        quote
            $(lhs.name) = $(compile_logic_constant(tns))
            @finch begin
                $(lhs.name) .= $(default(logic_constant_type(tns)))
                $body
                return $(lhs.name)
            end
        end
    elseif @capture ex produces(~args...)
        return :(return ($(map(arg -> arg.name, args)...),))
    elseif @capture ex plan(~bodies...)
        Expr(:block, map(ctx, bodies)...)
    else
        error("Unrecognized logic: $(ex)")
    end
end

"""
    defer_tables(root::LogicNode)

Replace immediate tensors with deferred expressions assuming the original program structure
is given as input to the program.
"""
function defer_tables(ex, node::LogicNode)
    if @capture node table(~tns::isimmediate, ~idxs...)
        table(deferred(:($ex.tns.val), typeof(tns.val)), map(enumerate(node.idxs)) do (i, idx)
            defer_tables(:($ex.idxs[$i]), idx)
        end)
    elseif istree(node)
        similarterm(node, operation(node), map(enumerate(node.children)) do (i, child)
            defer_tables(:($ex.children[$i]), child)
        end)
    else
        node
    end
end

"""
    cache_deferred(ctx, root::LogicNode, seen)

Replace deferred expressions with simpler expressions, and cache their evaluation in the preamble.
"""
function cache_deferred!(ctx, root::LogicNode)
    seen::Dict{Any, LogicNode} = Dict{Any, LogicNode}()
    return Rewrite(Postwalk(node -> if isdeferred(node)
        get!(seen, node.val) do
            var = freshen(ctx, :V)
            push!(ctx.preamble, :($var = $(node.ex)::$(node.type)))
            deferred(var, node.type)
        end
    end))(root)
end



        prgm = optimize(prgm)
        prgm = format_queries(prgm, true)
        FinchCompiler()(prgm)