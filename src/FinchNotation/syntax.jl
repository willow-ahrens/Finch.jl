const incs = Dict(:+= => :+, :*= => :*, :&= => :&, :|= => :|)

const program_nodes = (
    index = index,
    pass = pass,
    loop = loop,
    chunk = chunk,
    sieve = sieve,
    sequence = sequence,
    declare = declare,
    freeze = freeze,
    assign = assign,
    call = call,
    access = access,
    protocol = protocol,
    reader = reader,
    updater = updater,
    modify = modify,
    create = create,
    variable = (ex) -> :(index_leaf($(esc(ex)))),
    literal = literal,
    value = (ex) -> :(index_leaf($(esc(ex)))),
)

const instance_nodes = (
    index = index_instance,
    pass = pass_instance,
    loop = loop_instance,
    chunk = :(throw(NotImplementedError("TODO"))),
    sieve = sieve_instance,
    sequence = sequence_instance,
    declare = declare_instance,
    freeze = freeze_instance,
    assign = assign_instance,
    call = call_instance,
    access = access_instance,
    protocol = protocol_instance,
    reader = reader_instance,
    updater = updater_instance,
    modify = modify_instance,
    create = create_instance,
    variable = (ex) -> :($variable_instance($(QuoteNode(ex)), $index_leaf_instance($(esc(ex))))),
    literal = literal_instance,
    value = (ex) -> :($index_leaf_instance($(esc(ex))))
)

and() = true
and(x) = x
and(x, y, tail...) = x && and(y, tail...)
or() = false
or(x) = x
or(x, y, tail...) = x || or(y, tail...)
right(l, m, r...) = right(m, r)
right(l, r) = r

struct FinchParserVisitor
    nodes
    results
end

(ctx::FinchParserVisitor)(ex::Symbol) = ctx.nodes.variable(ex)
(ctx::FinchParserVisitor)(ex::QuoteNode) = ctx.nodes.literal(ex.value)
(ctx::FinchParserVisitor)(ex) = ctx.nodes.literal(ex)
function (ctx::FinchParserVisitor)(ex::Expr)
    islinenum(x) = x isa LineNumberNode

    if @capture ex :macrocall($(Symbol("@pass")), ~ln::islinenum, ~args...)
        return :($(ctx.nodes.pass)($(map(ctx, args)...)))
    elseif @capture ex :macrocall($(Symbol("@sieve")), ~ln::islinenum, ~cond, ~body)
        return :($(ctx.nodes.sieve)($(ctx(cond)), $(ctx(body))))
    elseif @capture ex :macrocall($(Symbol("@declare")), ~ln::islinenum, ~tns)
        return :($(ctx.nodes.declare)($(ctx(tns))))
    elseif @capture ex :macrocall($(Symbol("@freeze")), ~ln::islinenum, ~tns)
        return :($(ctx.nodes.freeze)($(ctx(tns))))
    elseif @capture ex :macrocall($(Symbol("@∀")), ~ln::islinenum, ~idxs..., ~body)
        return ctx(:(@loop($(idxs...), $body)))
    elseif @capture ex :macrocall($(Symbol("@loop")), ~ln::islinenum, ~idxs..., ~body)
        return quote
            let $((:($(esc(idx)) = $(ctx.nodes.index(idx))) for idx in idxs if idx isa Symbol)...)
                $(ctx.nodes.loop)($((idx isa Symbol ? esc(idx) : ctx(idx) for idx in idxs)...), $(ctx(body)))
            end
        end
    elseif @capture ex :macrocall($(Symbol("@chunk")), ~ln::islinenum, ~idx, ~ext, ~body)
        return quote
            let $(idx isa Symbol ? :($(esc(idx)) = $(ctx.nodes.index(idx))) : quote end)
                $(ctx.nodes.chunk)($(idx isa Symbol ? esc(idx) : ctx(idx)), $(ctx(ext)), $(ctx(body)))
            end
        end
    elseif @capture ex :block(~bodies...)
        bodies = filter(!islinenum, bodies)
        if length(bodies) == 1
            return ctx(:($(bodies[1])))
        else
            return ctx(:(@sequence($(bodies...),)))
        end
    elseif @capture ex :macrocall($(Symbol("@sequence")), ~ln::islinenum, ~bodies...)
        return :($(ctx.nodes.sequence)($(map(ctx, bodies)...)))
    elseif @capture ex :ref(~tns, ~idxs...)
        mode = :($(ctx.nodes.reader)())
        return :($(ctx.nodes.access)($(ctx(tns)), $mode, $(map(ctx, idxs)...)))
    elseif (@capture ex (~op)(~lhs, ~rhs)) && haskey(incs, op)
        return ctx(:($lhs << $(incs[op]) >>= $rhs))
    elseif @capture ex :(=)(:ref(~tns, ~idxs...), ~rhs)
        return ctx(:($tns[$(idxs...)] << $right >>= $rhs))
    elseif @capture ex :>>=(:call(:<<, :ref(~tns, ~idxs...), ~op), ~rhs)
        tns isa Symbol && push!(ctx.results, tns)
        mode = :($(ctx.nodes.updater)($(ctx.nodes.create)()))
        lhs = :($(ctx.nodes.access)($(ctx(tns)), $mode, $(map(ctx, idxs)...)))
        return :($(ctx.nodes.assign)($lhs, $(ctx(op)), $(ctx(rhs))))
    elseif @capture ex :comparison(~a, ~cmp, ~b)
        return ctx(:($cmp($a, $b)))
    elseif @capture ex :comparison(~a, ~cmp, ~b, ~tail...)
        return ctx(:($cmp($a, $b) && $(Expr(:comparison, b, tail...))))
    elseif @capture ex :&&(~a, ~b)
        return ctx(:($and($a, $b)))
    elseif @capture ex :||(~a, ~b)
        return ctx(:($or($a, $b)))
    elseif @capture ex :call(~op, ~args...)
        return :($(ctx.nodes.call)($(ctx(op)), $(map(ctx, args)...)))
    elseif @capture ex :(::)(~idx, ~mode)
        return :($(ctx.nodes.protocol)($(ctx(idx)), $(esc(mode))))
    elseif @capture ex :(...)(~arg)
        return esc(ex)
    elseif @capture ex :$(~arg)
        return esc(arg)
    else
        return ctx.nodes.value(ex)
    end
end

finch_parse_program(ex, results=Set()) = FinchParserVisitor(program_nodes, results)(ex)
finch_parse_instance(ex, results=Set()) = FinchParserVisitor(instance_nodes, results)(ex)

macro finch_program(ex)
    return finch_parse_program(ex)
end

macro f(ex)
    return finch_parse_program(ex)
end

macro finch_program_instance(ex)
    return finch_parse_instance(ex)
end