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
    label = (ex) -> :($(esc(:dollar))(index_terminal($(esc(ex))))),
    literal = literal,
    value = (ex) -> :($(esc(:dollar))(index_terminal($(esc(ex))))),
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
    #extra sugar
    if ex isa Expr && ex.head == :macrocall && length(ex.args) >= 3 && ex.args[1] == Symbol("@∀")
        idxs = ex.args[3:end-1]; body = ex.args[end]
        return finch_parse(:(@loop($(idxs...), $body)), nodes, results)
    elseif ex isa Expr && ex.head == :block
        bodies = filter(arg->!(arg isa LineNumberNode), ex.args)
        if length(bodies) == 1
            return finch_parse(:($(bodies[1])), nodes, results)
        else
            return finch_parse(:(@multi($(bodies...),)), nodes, results)
        end
    elseif ex isa Expr && haskey(incs, ex.head)
        (lhs, rhs) = ex.args; op = incs[ex.head]
        return finch_parse(:($lhs << $op >>= $rhs), nodes, results)
    elseif ex isa Expr && ex.head == :comparison
        @assert length(ex.args) >= 3
        (a, cmp, b, tail...) = ex.args
        ex = :($cmp($a, $b))
        if isempty(tail)
            return finch_parse(:($cmp($a, $b)), nodes, results)
        else
            return finch_parse(:($cmp($a, $b) && $(Expr(:comparison, b, tail...))), nodes, results)
        end
    elseif ex isa Expr && ex.head == :&&
        (a, b) = ex.args
        return finch_parse(:($and($a, $b)), nodes, results)
    elseif ex isa Expr && ex.head == :||
        (a, b) = ex.args
        return finch_parse(:($or($a, $b)), nodes, results)
    end

    if @capture ex (@pass(args__))
        args = map(arg -> finch_parse(arg, nodes, results), args)
        return :($(nodes, results.nodes.pass)($(args...)))
    elseif @capture ex (@sieve cond_ body_)
        cond = finch_parse(cond, nodes, results)
        body = finch_parse(body, nodes, results)
        return :($(nodes, results.nodes.sieve)($cond, $body))
    elseif @capture ex (@loop idxs__ body_)
        preamble = Expr(:block)
        idxs = map(idxs) do idx
            if idx isa Symbol
                push!(preamble.args, :($(esc(idx)) = $(nodes, results.nodes.index(idx))))
                esc(idx)
            else
                finch_parse(idx, nodes, results)
            end
        end
        body = finch_parse(body, nodes, results)
        return quote
            let
                $preamble
                $(nodes, results.nodes.loop)($(idxs...), $body)
            end
        end
    elseif @capture ex (@chunk idx_ ext_ body_)
        preamble = Expr(:block)
        if idx isa Symbol
            push!(preamble.args, :($(esc(idx)) = $(nodes, results.nodes.index(idx))))
            esc(idx)
        else
            finch_parse(idx, nodes, results)
        end
        ext = finch_parse(idx, nodes, results)
        body = finch_parse(body, nodes, results)
        return quote
            let
                $preamble
                $(nodes, results.nodes.chunk)($idx, $ext, $body)
            end
        end
    elseif @capture ex (@chunk idx_ ext_ body_)
        idx = finch_parse(idx, nodes, results)
        ext = finch_parse(ext, nodes, results)
        body = finch_parse(body, nodes, results)
        return :($(nodes, results.nodes.chunk)($idx, $ext, $body))
    elseif @capture ex (cons_ where prod_)
        cons = finch_parse(cons, nodes, results)
        prod = finch_parse(prod, nodes)
        return :($(nodes, results.nodes.with)($cons, $prod))
    elseif @capture ex (@multi bodies__)
        bodies = map(arg -> finch_parse(arg, nodes, results), bodies)
        return :($(nodes, results.nodes.multi)($(bodies...)))
    elseif @capture ex (tns_[idxs__])
        tns = finch_parse(tns, nodes, results)
        idxs = map(idx->finch_parse(idx, nodes, results), idxs)
        mode = :($(nodes, results.nodes.reader)())
        return :($(nodes, results.nodes.access)($tns, $mode, $(idxs...)))
    elseif @capture ex (tns_[idxs__] = rhs_)
        return finch_parse(:($tns[$(idxs...)] << $right >>= $rhs), nodes, results)
    elseif @capture ex (!tns_[idxs__] = rhs_)
        return finch_parse(:(!$tns[$(idxs...)] << $right >>= $rhs), nodes, results)
    elseif @capture ex (tns_[idxs__] <<op_>>= rhs_)
        tns isa Symbol && push!(nodes, results.results, tns)
        tns = finch_parse(tns, nodes, results)
        op = finch_parse(op, nodes, results)
        mode = :($(nodes, results.nodes.updater)($(ctx.nodes.literal(false))))
        idxs = map(idx->finch_parse(idx, nodes, results), idxs)
        rhs = finch_parse(rhs, nodes, results)
        lhs = :($(nodes, results.nodes.access)($tns, $mode, $(idxs...)))
        return :($(nodes, results.nodes.assign)($lhs, $op, $rhs))
    elseif @capture ex (!tns_[idxs__] <<op_>>= rhs_)
        tns isa Symbol && push!(nodes, results.results, tns)
        tns = finch_parse(tns, nodes, results)
        op = finch_parse(op, nodes, results)
        mode = :($(nodes, results.nodes.updater)($(ctx.nodes.literal(true))))
        idxs = map(idx->finch_parse(idx, nodes, results), idxs)
        rhs = finch_parse(rhs, nodes, results)
        lhs = :($(nodes, results.nodes.access)($tns, $mode, $(idxs...)))
        return :($(nodes, results.nodes.assign)($lhs, $op, $rhs))
    elseif @capture ex (op_(args__))
        op = finch_parse(op, nodes, results)
        args = map(arg->finch_parse(arg, nodes, results), args)
        return :($(nodes, results.nodes.call)($op, $(args...)))
    elseif @capture ex (idx_::proto_)
        idx = finch_parse(idx, nodes, results)
        return :($(nodes, results.nodes.protocol)($idx, $(esc(proto))))
    elseif ex isa Expr && ex.head == :...
        return esc(ex)
    elseif ex isa Expr && ex.head == :$ && length(ex.args) == 1
        return esc(ex.args[1])
    elseif ex isa Symbol
        return nodes, results.nodes.label(ex)
    elseif ex isa Expr
        return nodes, results.nodes.value(ex)
    elseif ex isa QuoteNode
        return nodes, results.nodes.literal(ex.value)
    else
        return nodes, results.nodes.literal(ex)
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