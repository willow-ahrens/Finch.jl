#TODO use MacroTools?

const incs = Dict(:+= => :+, :*= => :*, :&= => :&, :|= => :|)

const program_nodes = (
    pass = pass,
    loop = loop,
    chunk = chunk,
    with = with,
    sieve = sieve,
    multi = multi,
    assign = assign,
    call = call,
    access = access,
    protocol = protocol,
    reader = reader,
    updater = updater,
    index = index,
    label = (ex) -> :(index_terminal($(esc(ex)))),
    literal = literal,
    value = (ex) -> :(index_terminal($(esc(ex)))),
)

const instance_nodes = (
    pass = pass_instance,
    loop = loop_instance,
    chunk = :(throw(NotImplementedError("TODO"))),
    with = with_instance,
    sieve = sieve_instance,
    multi = multi_instance,
    assign = assign_instance,
    call = call_instance,
    access = access_instance,
    protocol = protocol_instance,
    index = index_instance,
    reader = reader_instance,
    updater = updater_instance,
    label = (ex) -> :($label_instance($(QuoteNode(ex)), $index_terminal_instance($(esc(ex))))),
    literal = literal_instance,
    value = (ex) -> :($index_terminal_instance($(esc(ex))))
)

and() = true
and(x) = x
and(x, y, tail...) = x && and(y, tail...)
or() = false
or(x) = x
or(x, y, tail...) = x || or(y, tail...)
right(l, m, r...) = right(m, r)
right(l, r) = r

function finch_parse(ex, nodes=program_nodes, results=Set())
    islinenum(x) = x isa LineNumberNode
    #extra sugar
    if Finch.RewriteTools.@capture ex :macrocall($(Symbol("@∀")), ~ln::islinenum, ~idxs..., ~body)
        return finch_parse(:(@loop($(idxs...), $body)), nodes, results)
    elseif Finch.RewriteTools.@capture ex :block(~bodies...)
        bodies = filter(!islinenum, bodies)
        if length(bodies) == 1
            return finch_parse(:($(bodies[1])), nodes, results)
        else
            return finch_parse(:(@multi($(bodies...),)), nodes, results)
        end
    elseif (Finch.RewriteTools.@capture ex (~op)(~lhs, ~rhs)) && haskey(incs, op)
        return finch_parse(:($lhs << $(incs[op]) >>= $rhs), nodes, results)
    elseif Finch.RewriteTools.@capture ex :comparison(~a, ~cmp, ~b)
        return finch_parse(:($cmp($a, $b)), nodes, results)
    elseif Finch.RewriteTools.@capture ex :comparison(~a, ~cmp, ~b, ~tail...)
        return finch_parse(:($cmp($a, $b) && $(Expr(:comparison, b, tail...))), nodes, results)
    elseif Finch.RewriteTools.@capture ex :&&(~a, ~b)
        return finch_parse(:($and($a, $b)), nodes, results)
    elseif Finch.RewriteTools.@capture ex :||(~a, ~b)
        return finch_parse(:($or($a, $b)), nodes, results)
    end

    if Finch.RewriteTools.@capture ex :macrocall($(Symbol("@pass")), ~ln::islinenum, ~args...)
        args = map(arg -> finch_parse(arg, nodes, results), args)
        return :($(nodes.pass)($(args...)))
    elseif Finch.RewriteTools.@capture ex :macrocall($(Symbol("@sieve")), ~ln::islinenum, ~cond, ~body)
        cond = finch_parse(cond, nodes, results)
        body = finch_parse(body, nodes, results)
        return :($(nodes.sieve)($cond, $body))
    elseif Finch.RewriteTools.@capture ex :macrocall($(Symbol("@loop")), ~ln::islinenum, ~idxs..., ~body)
        preamble = Expr(:block)
        idxs = map(idxs) do idx
            if idx isa Symbol
                push!(preamble.args, :($(esc(idx)) = $(nodes.index(idx))))
                esc(idx)
            else
                finch_parse(idx, nodes, results)
            end
        end
        body = finch_parse(body, nodes, results)
        return quote
            let
                $preamble
                $(nodes.loop)($(idxs...), $body)
            end
        end
    elseif Finch.RewriteTools.@capture ex :macrocall($(Symbol("@chunk")), ~ln::islinenum, ~idx, ~ext, ~body)
        preamble = Expr(:block)
        if idx isa Symbol
            push!(preamble.args, :($(esc(idx)) = $(nodes.index(idx))))
            esc(idx)
        else
            finch_parse(idx, nodes, results)
        end
        ext = finch_parse(idx, nodes, results)
        body = finch_parse(body, nodes, results)
        return quote
            let
                $preamble
                $(nodes.chunk)($idx, $ext, $body)
            end
        end
    elseif Finch.RewriteTools.@capture ex :where(~cons, ~prod)
        cons = finch_parse(cons, nodes, results)
        prod = finch_parse(prod, nodes)
        return :($(nodes.with)($cons, $prod))
    elseif Finch.RewriteTools.@capture ex :macrocall($(Symbol("@multi")), ~ln::islinenum, ~bodies...)
        bodies = map(arg -> finch_parse(arg, nodes, results), bodies)
        return :($(nodes.multi)($(bodies...)))
    elseif Finch.RewriteTools.@capture ex :ref(~tns, ~idxs...)
        tns = finch_parse(tns, nodes, results)
        idxs = map(idx->finch_parse(idx, nodes, results), idxs)
        mode = :($(nodes.reader)())
        return :($(nodes.access)($tns, $mode, $(idxs...)))
    elseif Finch.RewriteTools.@capture ex :(=)(:ref(~tns, ~idxs...), ~rhs)
        return finch_parse(:($tns[$(idxs...)] << $right >>= $rhs), nodes, results)
    elseif Finch.RewriteTools.@capture ex :(=)(:ref(:call(:!, ~tns), ~idxs...), ~rhs)
        return finch_parse(:(!$tns[$(idxs...)] << $right >>= $rhs), nodes, results)
    elseif Finch.RewriteTools.@capture ex :>>=(:call(:<<, :ref(~tns, ~idxs...), ~op), ~rhs)
        tns isa Symbol && push!(results, tns)
        tns = finch_parse(tns, nodes, results)
        op = finch_parse(op, nodes, results)
        mode = :($(nodes.updater)($(nodes.literal(false))))
        idxs = map(idx->finch_parse(idx, nodes, results), idxs)
        rhs = finch_parse(rhs, nodes, results)
        lhs = :($(nodes.access)($tns, $mode, $(idxs...)))
        return :($(nodes.assign)($lhs, $op, $rhs))
    elseif Finch.RewriteTools.@capture ex :>>=(:call(:<<, :call(:!, :ref(~tns, ~idxs...)), ~op), ~rhs)
        tns isa Symbol && push!(results, tns)
        tns = finch_parse(tns, nodes, results)
        op = finch_parse(op, nodes, results)
        mode = :($(nodes.updater)($(nodes.literal(true))))
        idxs = map(idx->finch_parse(idx, nodes, results), idxs)
        rhs = finch_parse(rhs, nodes, results)
        lhs = :($(nodes.access)($tns, $mode, $(idxs...)))
        return :($(nodes.assign)($lhs, $op, $rhs))
    elseif Finch.RewriteTools.@capture ex :call(~op, ~args...)
        op = finch_parse(op, nodes, results)
        args = map(arg->finch_parse(arg, nodes, results), args)
        return :($(nodes.call)($op, $(args...)))
    elseif Finch.RewriteTools.@capture ex :(::)(~idx, ~proto)
        idx = finch_parse(idx, nodes, results)
        return :($(nodes.protocol)($idx, $(esc(proto))))
    elseif Finch.RewriteTools.@capture ex :(...)(~arg)
        return esc(ex)
    elseif Finch.RewriteTools.@capture ex :$(~arg)
        return esc(arg)
    elseif ex isa Symbol
        return nodes.label(ex)
    elseif ex isa Expr
        return nodes.value(ex)
    elseif ex isa QuoteNode
        return nodes.literal(ex.value)
    else
        return nodes.literal(ex)
    end
end

finch_parse_program(ex, results=Set()) = finch_parse(ex, program_nodes, results)
finch_parse_instance(ex, results=Set()) = finch_parse(ex, instance_nodes, results)

macro finch_program(ex)
    return finch_parse_program(ex)
end

macro f(ex)
    return finch_parse_program(ex)
end

macro finch_program_instance(ex)
    return finch_parse_instance(ex)
end