const incs = Dict(:+= => :+, :*= => :*, :&= => :&, :|= => :|, :(:=) => :overwrite)
const evaluable_exprs = [:Inf, :Inf16, :Inf32, :Inf64, :(-Inf), :(-Inf16), :(-Inf32), :(-Inf64), :NaN, :NaN16, :NaN32, :NaN64, :nothing, :missing, :Eps]

const program_nodes = (
    index = index,
    loop = loop,
    sieve = sieve,
    block = block,
    define = define,
    declare = declare,
    freeze = freeze,
    thaw = thaw,
    assign = assign,
    call = call,
    access = access,
    reader = literal(reader),
    updater = literal(updater),
    variable = variable,
    tag = (ex) -> :(finch_leaf($(esc(ex)))),
    literal = literal,
    leaf = (ex) -> :(finch_leaf($(esc(ex)))),
    dimless = :(finch_leaf(dimless))
)

const instance_nodes = (
    index = index_instance,
    loop = loop_instance,
    sieve = sieve_instance,
    block = block_instance,
    define = define_instance,
    declare = declare_instance,
    freeze = freeze_instance,
    thaw = thaw_instance,
    assign = assign_instance,
    call = call_instance,
    access = access_instance,
    reader = literal_instance(reader),
    updater = literal_instance(updater),
    variable = variable_instance,
    tag = (ex) -> :($tag_instance($(variable_instance(ex)), $finch_leaf_instance($(esc(ex))))),
    literal = literal_instance,
    leaf = (ex) -> :($finch_leaf_instance($(esc(ex)))),
    dimless = :($finch_leaf_instance(dimless))
)

d() = 1
d(args...) = 0
and() = true
and(x) = x
and(x, y, tail...) = x && and(y, tail...)
or() = false
or(x) = x
or(x, y, tail...) = x || or(y, tail...)

struct InitWriter{D} end

(f::InitWriter{D})(x) where {D} = x
@inline function (f::InitWriter{D})(x, y) where {D}
    @debug begin
        @assert isequal(x, D)
    end
    y
end

"""
    initwrite(z)(a, b)

`initwrite(z)` is a function which may assert that `a`
[`isequal`](https://docs.julialang.org/en/v1/base/base/#Base.isequal) to `z`,
and `returns `b`.  By default, `lhs[] = rhs` is equivalent to `lhs[]
<<initwrite(default(lhs))>>= rhs`.
"""
initwrite(z) = InitWriter{z}()

"""
    overwrite(z)(a, b)

`overwrite(z)` is a function which returns `b` always. `lhs[] := rhs` is equivalent to
`lhs[] <<overwrite>>= rhs`.

```jldoctest setup=:(using Finch)
julia> a = Tensor(SparseList(Element(0.0)), [0, 1.1, 0, 4.4, 0])
SparseList (0.0) [1:5]
├─[2]: 1.1
├─[4]: 4.4

julia> x = Scalar(0.0); @finch for i=_; x[] <<overwrite>>= a[i] end;

julia> x[]
0.0
```
"""
overwrite(l, r) = r

struct Dimensionless end
const dimless = Dimensionless()
function extent end
function realextent end

struct FinchParserVisitor
    nodes
    results
end

function (ctx::FinchParserVisitor)(ex::Symbol)
    if ex == :_ || ex == :(:)
        return :($dimless)
    elseif ex in evaluable_exprs 
        return ctx.nodes.literal(@eval($ex))
    else
        ctx.nodes.tag(ex)
    end
end
(ctx::FinchParserVisitor)(ex::QuoteNode) = ctx.nodes.literal(ex.value)
(ctx::FinchParserVisitor)(ex) = ctx.nodes.literal(ex)

struct FinchSyntaxError msg end

function (ctx::FinchParserVisitor)(ex::Expr)
    islinenum(ex) = ex isa LineNumberNode
    if @capture ex :if(~cond, ~body)
        return :($(ctx.nodes.sieve)($(ctx(cond)), $(ctx(body))))
    elseif @capture ex :if(~cond, ~body, ~tail)
        throw(FinchSyntaxError("Finch does not support else, elseif, or the ternary operator. Consider using multiple if blocks, or the ifelse() function instead."))
    elseif @capture ex :elseif(~args...)
        throw(FinchSyntaxError("Finch does not support elseif."))
    elseif @capture ex :(.=)(~tns, ~init)
        return :($(ctx.nodes.declare)($(ctx(tns)), $(ctx(init))))
    elseif @capture ex :macrocall($(Symbol("@freeze")), ~ln::islinenum, ~tns)
        return :($(ctx.nodes.freeze)($(ctx(tns))))
    elseif @capture ex :macrocall($(Symbol("@thaw")), ~ln::islinenum, ~tns)
        return :($(ctx.nodes.thaw)($(ctx(tns))))
    elseif @capture ex :for(:block(), ~body)
        return ctx(body)
    elseif @capture ex :for(:block(:(=)(~idx, ~ext), ~tail...), ~body)
        if isempty(tail)
            return ctx(:(for $idx = $ext; $body end))
        else
            return ctx(:(for $idx = $ext; $(Expr(:for, Expr(:block, tail...), body)) end))
        end
    elseif @capture ex :for(:(=)(~idx, ~ext), ~body)
        ext = ctx(ext)
        body = ctx(body)
        if idx isa Symbol
            return quote
                let $(esc(idx)) = $(ctx.nodes.index(idx))
                    $(ctx.nodes.loop)($(esc(idx)), $ext, $body)
                end
            end
        else
            return quote
                $(ctx.nodes.loop)($(ctx(idx)), $ext, $body)
            end
        end
    elseif @capture ex :let(:block(), ~body)
        return ctx(body)
    elseif @capture ex :let(:block(:(=)(~lhs, ~rhs), ~tail...), ~body)
        if isempty(tail)
            return ctx(:(for $lhs = $rhs; $body end))
        else
            return ctx(:(for $lhs = $rhs; $(Expr(:let, Expr(:block, tail...), body)) end))
        end
    elseif @capture ex :let(:(=)(~lhs, ~rhs), ~body)
        rhs = ctx(rhs)
        body = ctx(body)
        if lhs isa Symbol
            return quote
                let $(esc(lhs)) = $(ctx.nodes.variable(lhs))
                    $(ctx.nodes.define)($(esc(lhs)), $rhs, $body)
                end
            end
        else
            return quote
                $(ctx.nodes.define)($(ctx(lhs)), $rhs, $body)
            end
        end
    elseif @capture ex :block(~bodies...)
        bodies = filter(!islinenum, bodies)
        if length(bodies) == 1
            return ctx(:($(bodies[1])))
        else
            return :($(ctx.nodes.block)($(map(ctx, bodies)...)))
        end
    elseif @capture ex :ref(~tns, ~idxs...)
        mode = ctx.nodes.reader
        return :($(ctx.nodes.access)($(ctx(tns)), $mode, $(map(ctx, idxs)...)))
    elseif (@capture ex (~op)(~lhs, ~rhs)) && haskey(incs, op)
        return ctx(:($lhs << $(incs[op]) >>= $rhs))
    elseif @capture ex :(=)(:ref(~tns, ~idxs...), ~rhs)
        tns isa Symbol && push!(ctx.results, tns)
        mode = ctx.nodes.updater
        lhs = :($(ctx.nodes.access)($(ctx(tns)), $mode, $(map(ctx, idxs)...)))
        op = :($(ctx.nodes.literal)($initwrite))
        return :($(ctx.nodes.assign)($lhs, $op, $(ctx(rhs))))
    elseif @capture ex :>>=(:call(:<<, :ref(~tns, ~idxs...), ~op), ~rhs)
        tns isa Symbol && push!(ctx.results, tns)
        mode = ctx.nodes.updater
        lhs = :($(ctx.nodes.access)($(ctx(tns)), $mode, $(map(ctx, idxs)...)))
        return :($(ctx.nodes.assign)($lhs, $(ctx(op)), $(ctx(rhs))))
    elseif @capture ex :>>=(:call(:<<, ~lhs, ~op), ~rhs)
        error("Finch doesn't support incrementing definitions of variables")
    elseif @capture ex :(=)(~lhs, ~rhs)
        error("Finch doesn't support variable bindings outside of let statements")
    elseif @capture ex :tuple(~args...)
        return ctx(:(tuple($(args...))))
    elseif @capture ex :comparison(~a, ~cmp, ~b)
        return ctx(:($cmp($a, $b)))
    elseif @capture ex :comparison(~a, ~cmp, ~b, ~tail...)
        return ctx(:($cmp($a, $b) && $(Expr(:comparison, b, tail...))))
    elseif @capture ex :&&(~a, ~b)
        return ctx(:($and($a, $b)))
    elseif @capture ex :||(~a, ~b)
        return ctx(:($or($a, $b)))
    elseif @capture ex :call(~op, ~args...)
        if op == :(:)
            return :($(ctx.nodes.call)($(ctx(:extent)), $(map(ctx, args)...)))
        else
            return :($(ctx.nodes.call)($(ctx(op)), $(map(ctx, args)...)))
        end
    elseif @capture ex :(...)(~arg)
        return esc(ex)
    elseif @capture ex :$(~arg)
        return esc(arg)
    elseif ex in evaluable_exprs
        return ctx.nodes.literal(@eval(ex))
    else
        return ctx.nodes.leaf(ex)
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
    return :(
        let
            $(finch_parse_instance(ex))
        end
    )
end

display_expression(io, mime, ex) = show(IOContext(io, :compact=>true), mime, ex) # TODO virtual or value is currently determined in virtualize.
function display_expression(io, mime, node::Union{FinchNode, FinchNodeInstance})
    if operation(node) === value
        print(io, node.val)
        if node.type !== Any
            print(io, "::")
            print(io, node.type)
        end
    elseif operation(node) === literal
        print(io, node.val)
    elseif operation(node) === index
        print(io, node.name)
    elseif operation(node) === variable
        print(io, node.name)
    elseif operation(node) === cached
        print(io, "cached(")
        display_expression(io, mime, node.arg)
        print(io, ", ")
        display_expression(io, mime, node.ref.val)
        print(io, ")")
    elseif operation(node) === tag
        print(io, "tag(")
        display_expression(io, mime, node.var)
        print(io, ", ")
        display_expression(io, mime, node.bind)
        print(io, ")")
    elseif operation(node) === virtual
        print(io, "virtual(")
        #print(io, node.val)
        summary(io, node.val)
        print(io, ")")
    elseif operation(node) === access
        display_expression(io, mime, node.tns)
        print(io, "[")
        if length(node.idxs) >= 1
            for idx in node.idxs[1:end-1]
                display_expression(io, mime, idx)
                print(io, ", ")
            end
            display_expression(io, mime, node.idxs[end])
        end
        print(io, "]")
    elseif operation(node) === call
        display_expression(io, mime, node.op)
        print(io, "(")
        for arg in node.args[1:end-1]
            display_expression(io, mime, arg)
            print(io, ", ")
        end
        if !isempty(node.args)
            display_expression(io, mime, node.args[end])
        end
        print(io, ")")
    elseif istree(node)
        print(io, operation(node))
        print(io, "(")
        for arg in arguments(node)[1:end-1]
            print(io, arg)
            print(io, ",")
        end
        if !isempty(arguments(node))
            print(arguments(node)[end])
        end
    else
        error("unimplemented")
    end
end

function display_statement(io, mime, node::Union{FinchNode, FinchNodeInstance}, indent)
    if operation(node) === loop
        print(io, " "^indent * "for ")
        display_expression(io, mime, node.idx)
        print(io, " = ")
        display_expression(io, mime, node.ext)
        body = node.body
        while operation(body) === loop
            print(io, ", ")
            display_expression(io, mime, body.idx)
            print(io, " = ")
            display_expression(io, mime, body.ext)
            body = body.body
        end
        println(io)
        display_statement(io, mime, body, indent + 2)
        println(io)
        print(io, " "^indent * "end")
    elseif operation(node) === define
        print(io, " "^indent * "let ")
        display_expression(io, mime, node.lhs)
        print(io, " = ")
        display_expression(io, mime, node.rhs)
        body = node.body
        while operation(body) === define
            print(io, ", ")
            display_expression(io, mime, body.lhs)
            print(io, " = ")
            display_expression(io, mime, body.rhs)
            body = body.body
        end
        println(io)
        display_statement(io, mime, body, indent + 2)
        println(io)
        print(io, " "^indent * "end")
    elseif operation(node) === sieve
        print(io, " "^indent * "if ")
        while operation(node.body) === sieve
            display_expression(io, mime, node.cond)
            print(io," && ")
            node = node.body
        end
        display_expression(io, mime, node.cond)
        println(io)
        node = node.body
        display_statement(io, mime, node, indent + 2)
        println(io)
        print(io, " "^indent * "end")
    elseif operation(node) === assign
        print(io, " "^indent)
        display_expression(io, mime, node.lhs)
        print(io, " <<")
        display_expression(io, mime, node.op)
        print(io, ">>= ")
        display_expression(io, mime, node.rhs)
    elseif operation(node) === declare
        print(io, " "^indent)
        display_expression(io, mime, node.tns)
        print(io, " .= ")
        display_expression(io, mime, node.init)
    elseif operation(node) === freeze
        print(io, " "^indent * "@freeze(")
        display_expression(io, mime, node.tns)
        print(io, ")")
    elseif operation(node) === thaw
        print(io, " "^indent * "@thaw(")
        display_expression(io, mime, node.tns)
        print(io, ")")
    elseif operation(node) === block
        print(io, " "^indent * "begin\n")
        for body in node.bodies
            display_statement(io, mime, body, indent + 2)
            println(io)
        end
        print(io, " "^indent * "end")
    else
        println(node)
        error("unimplemented")
    end
end
