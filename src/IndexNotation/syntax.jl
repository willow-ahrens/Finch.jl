#TODO use MacroTools?

const incs = Dict(:+= => :+, :*= => :*, :&= => :&, :|= => :|)

const program_nodes = (
    pass = pass,
    loop = loop,
    chunk = chunk,
    with = with,
    multi = multi,
    assign = assign,
    call = call,
    access = access,
    name = Name,
    label = esc,
    value = esc,
)

const instance_nodes = (
    pass = pass_instance,
    loop = loop_instance,
    chunk = :(throw(NotImplementedError("TODO"))),
    with = with_instance,
    multi = multi_instance,
    assign = assign_instance,
    call = call_instance,
    access = access_instance,
    name = name_instance,
    label = (ex) -> :($label_instance($(QuoteNode(ex)), $value_instance($(esc(ex))))),
    value = (ex) -> :($value_instance($(esc(ex))))
)

function capture_index(ex, ctx)
    #extra sugar
    if ex isa Expr && ex.head == :macrocall && length(ex.args) >= 3 && ex.args[1] == Symbol("@∀")
        idxs = ex.args[3:end-1]; body = ex.args[end]
        return capture_index(:(@loop($(idxs...), $body)), ctx)
    elseif ex isa Expr && ex.head == :block
        bodies = filter(arg->!(arg isa LineNumberNode), ex.args)
        return capture_index(:(@multi($(bodies...),)), ctx)
    elseif ex isa Expr && haskey(incs, ex.head)
        (lhs, rhs) = ex.args; op = incs[ex.head]
        return capture_index(:($lhs << $op >>= $rhs), ctx)
    elseif false && ex isa Expr && ex.head == :comparison #TODO
        @assert length(ex.args) >= 3
        (a, cmp, b, tail...) = ex.args
        ex = :($cmp($a, $b))
        if isempty(tail)
            return capture_index(:($cmp($a, $b)), ctx)
        else
            return capture_index(:($cmp($a, $b) && Expr(:comparison, b, tail...)), ctx)
        end
    elseif ex isa Expr && ex.head == :&&
        (a, b) = ex.args
        return capture_index(:($a & $b), ctx)
    elseif ex isa Expr && ex.head == :||
        (a, b) = ex.args
        return capture_index(:($a | $b), ctx)
    end

    if @capture ex (@pass(args__))
        args = map(arg -> capture_index(arg, (ctx..., namify=false)), args)
        return :($(ctx.nodes.pass)($(args...)))
    elseif @capture ex (@loop idxs__ body_)
        idxs = map(idx -> capture_index(idx, (ctx..., namify=true)), idxs)
        body = capture_index(body, ctx)
        return :($(ctx.nodes.loop)($(idxs...), $body))
    elseif @capture ex (@chunk idx_ ext_ body_)
        idx = capture_index(idx, ctx)
        ext = capture_index(ext, (ctx..., namify=false))
        body = capture_index(body, ctx)
        return :($(ctx.nodes.chunk)($idx, $ext, $body))
    elseif @capture ex (cons_ where prod_)
        cons = capture_index(cons, ctx)
        prod = capture_index(prod, (ctx..., results=Set()))
        return :($(ctx.nodes.with)($cons, $prod))
    elseif @capture ex (@multi bodies__)
        bodies = map(arg -> capture_index(arg, ctx), bodies)
        return :($(ctx.nodes.multi)($(bodies...)))
    elseif @capture ex (lhs_ = rhs_)
        lhs = capture_index(lhs, (ctx..., mode=Write()))
        rhs = capture_index(rhs, ctx)
        return :($(ctx.nodes.assign)($lhs, $rhs))
    elseif @capture ex (lhs_ << op_ >>= rhs_)
        lhs = capture_index(lhs, (ctx..., mode=Update()))
        rhs = capture_index(rhs, ctx)
        op = capture_index(op, (ctx..., namify=false))
        return :($(ctx.nodes.assign)($lhs, $op, $rhs))
    elseif @capture ex (op_(args__))
        op = capture_index(op, (ctx..., namify=false, mode=Read()))
        args = map(arg->capture_index(arg, (ctx..., mode=Read())), args)
        return :($(ctx.nodes.call)($op, $(args...)))
    elseif @capture ex (tns_[idxs__])
        if ctx.mode isa Union{Write, Update} && tns isa Symbol
            push!(ctx.results, tns)
        end
        tns = capture_index(tns, (ctx..., namify=false, mode=Read()))
        idxs = map(idx->capture_index(idx, (ctx..., namify=true, mode=Read())), idxs)
        return :($(ctx.nodes.access)($tns, $(ctx.mode), $(idxs...)))
    elseif @capture ex (idx_::proto_)
        idx = capture_index(idx, ctx)
        return :($(esc(proto))($idx))
    elseif ex isa Expr && ex.head == :$ && length(ex.args) == 1
        return esc(ex.args[1])
    elseif ex isa Symbol && ctx.namify
        return ctx.nodes.name(ex)
    elseif ex isa Symbol
        return ctx.nodes.label(ex)
    else
        return ctx.nodes.value(ex)
    end
end
function capture_index(ex, ctx)
    #extra sugar
    if ex isa Expr && ex.head == :macrocall && length(ex.args) >= 3 && ex.args[1] == Symbol("@∀")
        idxs = ex.args[3:end-1]; body = ex.args[end]
        return capture_index(:(@loop($(idxs...), $body)), ctx)
    elseif ex isa Expr && ex.head == :block
        bodies = filter(arg->!(arg isa LineNumberNode), ex.args)
        return capture_index(:(@multi($(bodies...),)), ctx)
    elseif ex isa Expr && haskey(incs, ex.head)
        (lhs, rhs) = ex.args; op = incs[ex.head]
        return capture_index(:($lhs << $op >>= $rhs), ctx)
    elseif false && ex isa Expr && ex.head == :comparison #TODO
        @assert length(ex.args) >= 3
        (a, cmp, b, tail...) = ex.args
        ex = :($cmp($a, $b))
        if isempty(tail)
            return capture_index(:($cmp($a, $b)), ctx)
        else
            return capture_index(:($cmp($a, $b) && Expr(:comparison, b, tail...)), ctx)
        end
    elseif ex isa Expr && ex.head == :&&
        (a, b) = ex.args
        return capture_index(:($a & $b), ctx)
    elseif ex isa Expr && ex.head == :||
        (a, b) = ex.args
        return capture_index(:($a | $b), ctx)
    end

    if @capture ex (@pass(args__))
        args = map(arg -> capture_index(arg, (ctx..., namify=false)), args)
        return :($(ctx.nodes.pass)($(args...)))
    elseif @capture ex (@loop idxs__ body_)
        idxs = map(idx -> capture_index(idx, (ctx..., namify=true)), idxs)
        body = capture_index(body, ctx)
        return :($(ctx.nodes.loop)($(idxs...), $body))
    elseif @capture ex (@chunk idx_ ext_ body_)
        idx = capture_index(idx, ctx)
        ext = capture_index(ext, (ctx..., namify=false))
        body = capture_index(body, ctx)
        return :($(ctx.nodes.chunk)($idx, $ext, $body))
    elseif @capture ex (cons_ where prod_)
        cons = capture_index(cons, ctx)
        prod = capture_index(prod, (ctx..., results=Set()))
        return :($(ctx.nodes.with)($cons, $prod))
    elseif @capture ex (@multi bodies__)
        bodies = map(arg -> capture_index(arg, ctx), bodies)
        return :($(ctx.nodes.multi)($(bodies...)))
    elseif @capture ex (lhs_ = rhs_)
        lhs = capture_index(lhs, (ctx..., mode=Write()))
        rhs = capture_index(rhs, ctx)
        return :($(ctx.nodes.assign)($lhs, $rhs))
    elseif @capture ex (lhs_ << op_ >>= rhs_)
        lhs = capture_index(lhs, (ctx..., mode=Update()))
        rhs = capture_index(rhs, ctx)
        op = capture_index(op, (ctx..., namify=false))
        return :($(ctx.nodes.assign)($lhs, $op, $rhs))
    elseif @capture ex (op_(args__))
        op = capture_index(op, (ctx..., namify=false, mode=Read()))
        args = map(arg->capture_index(arg, (ctx..., mode=Read())), args)
        return :($(ctx.nodes.call)($op, $(args...)))
    elseif @capture ex (tns_[idxs__])
        if ctx.mode isa Union{Write, Update} && tns isa Symbol
            push!(ctx.results, tns)
        end
        tns = capture_index(tns, (ctx..., namify=false, mode=Read()))
        idxs = map(idx->capture_index(idx, (ctx..., namify=true, mode=Read())), idxs)
        return :($(ctx.nodes.access)($tns, $(ctx.mode), $(idxs...)))
    elseif @capture ex (idx_::proto_)
        idx = capture_index(idx, ctx)
        return :($(esc(proto))($idx))
    elseif ex isa Expr && ex.head == :$ && length(ex.args) == 1
        return esc(ex.args[1])
    elseif ex isa Symbol && ctx.namify
        return ctx.nodes.name(ex)
    elseif ex isa Symbol
        return ctx.nodes.label(ex)
    else
        return ctx.nodes.value(ex)
    end
end

capture_index_program(ex; results=Set()) = capture_index(ex, (nodes=program_nodes, namify=true, mode = Read(), results = results))
capture_index_instance(ex; results=Set()) = capture_index(ex, (nodes=instance_nodes, namify=true, mode = Read(), results = results))

macro index_program(ex)
    return capture_index_program(ex)
end

macro i(ex)
    return capture_index_program(ex)
end

macro index_program_instance(ex)
    return capture_index_instance(ex)
end