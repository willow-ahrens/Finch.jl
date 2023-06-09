const incs = Dict(:+= => :+, :*= => :*, :&= => :&, :|= => :|, :(:=) => :overwrite)
const evaluable_exprs = [:Inf, :Inf16, :Inf32, :Inf64, :(-Inf), :(-Inf16), :(-Inf32), :(-Inf64), :NaN, :NaN16, :NaN32, :NaN64, :nothing, :missing]

const program_nodes = (
    index = index,
    loop = loop,
    sieve = sieve,
    sequence = sequence,
    define = define,
    declare = declare,
    freeze = freeze,
    thaw = thaw,
    forget = forget,
    assign = assign,
    call = call,
    access = access,
    reader = reader,
    updater = updater,
    modify = modify,
    create = create,
    variable = variable,
    tag = (ex) -> :(finch_leaf($(esc(ex)))),
    literal = literal,
    value = (ex) -> :(finch_leaf($(esc(ex)))),
)

const instance_nodes = (
    index = index_instance,
    loop = loop_instance,
    sieve = sieve_instance,
    sequence = sequence_instance,
    define = define_instance,
    declare = declare_instance,
    freeze = freeze_instance,
    thaw = thaw_instance,
    forget = forget_instance,
    assign = assign_instance,
    call = call_instance,
    access = access_instance,
    reader = reader_instance,
    updater = updater_instance,
    modify = modify_instance,
    create = create_instance,
    variable = variable_instance,
    tag = (ex) -> :($tag_instance($(QuoteNode(ex)), $finch_leaf_instance($(esc(ex))))),
    literal = literal_instance,
    value = (ex) -> :($finch_leaf_instance($(esc(ex))))
)

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
julia> a = @fiber(sl(e(0.0)), [0, 1.1, 0, 4.4, 0])
SparseList (0.0) [1:5]
├─[2]: 1.1
├─[4]: 4.4

julia> x = Scalar(0.0); @finch @loop i x[] <<overwrite>>= a[i];

julia> x[]
0.0
```
"""
overwrite(l, r) = r


struct FinchParserVisitor
    nodes
    results
end

function (ctx::FinchParserVisitor)(ex::Symbol)
    if ex == :_ || ex == :(:)
        return ctx.nodes.index(:(:))
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
    islinenum(x) = x isa LineNumberNode

    if @capture ex :if(~cond, ~body)
        return :($(ctx.nodes.sieve)($(ctx(cond)), $(ctx(body))))
    elseif @capture ex :if(~cond, ~body, ~tail)
        throw(FinchSyntaxError("Finch does not support else, elseif, or the ternary operator. Consider using multiple if blocks, or the ifelse() function instead."))
    elseif @capture ex :elseif(~args...)
        throw(FinchSyntaxError("Finch does not support elseif."))
    elseif @capture ex :(.=)(~tns, ~init)
        return :($(ctx.nodes.declare)($(ctx(tns)), $(ctx(init))))
    elseif @capture ex :macrocall($(Symbol("@declare")), ~ln::islinenum, ~tns, ~init)
        return :($(ctx.nodes.declare)($(ctx(tns)), $(ctx(init))))
    elseif @capture ex :macrocall($(Symbol("@freeze")), ~ln::islinenum, ~tns)
        return :($(ctx.nodes.freeze)($(ctx(tns))))
    elseif @capture ex :macrocall($(Symbol("@thaw")), ~ln::islinenum, ~tns)
        return :($(ctx.nodes.thaw)($(ctx(tns))))
    elseif @capture ex :macrocall($(Symbol("@forget")), ~ln::islinenum, ~tns)
        return :($(ctx.nodes.forget)($(ctx(tns))))
    elseif @capture ex :for(:(=)(~idx, ~ext), ~body)
        ext == :(:) || ext == :_ || throw(FinchSyntaxError("Finch doesn't support non-automatic loop bounds currently"))
        return ctx(:(@loop($idx = $ext, $body)))
    elseif @capture ex :for(:block(:(=)(~idx, ~ext), ~tail...), ~body)
        ext == :(:) || ext == :_ || throw(FinchSyntaxError("Finch doesn't support non-automatic loop bounds currently"))
        if isempty(tail)
            return ctx(:(@loop($idx = $ext, $body)))
        else
            return ctx(:(@loop($idx = $ext, $(Expr(:for, Expr(:block, tail...), body)))))
        end
    elseif @capture ex :macrocall($(Symbol("@loop")), ~ln::islinenum, ~body)
        ctx(body)
    elseif @capture ex :macrocall($(Symbol("@loop")), ~ln::islinenum, ~idx, ~tail..., ~body)
        if !(@capture idx :(=)(~idx, ~ext))
            ext = :_
        end
        ext = ctx(ext)
        body = isempty(tail) ? ctx(body) : ctx(:(@loop($(tail...), $body)))
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
        tns isa Symbol && push!(ctx.results, tns)
        mode = :($(ctx.nodes.updater)($(ctx.nodes.create)()))
        lhs = :($(ctx.nodes.access)($(ctx(tns)), $mode, $(map(ctx, idxs)...)))
        op = :($(ctx.nodes.literal)($initwrite($default($(esc(tns))))))
        return :($(ctx.nodes.assign)($lhs, $op, $(ctx(rhs))))
    elseif @capture ex :>>=(:call(:<<, :ref(~tns, ~idxs...), ~op), ~rhs)
        tns isa Symbol && push!(ctx.results, tns)
        mode = :($(ctx.nodes.updater)($(ctx.nodes.create)()))
        lhs = :($(ctx.nodes.access)($(ctx(tns)), $mode, $(map(ctx, idxs)...)))
        return :($(ctx.nodes.assign)($lhs, $(ctx(op)), $(ctx(rhs))))
    elseif @capture ex :(=)(~lhs, ~rhs)
        res = :($(ctx.nodes.define)($(esc(lhs)), $(ctx(rhs))))
        #TODO in the future would be nice if this was a let
        if lhs isa Symbol
            push!(ctx.results, lhs)
            res = quote
                begin
                    $(esc(lhs)) = $(ctx.nodes.variable(lhs))
                    $res
                end
            end
        end
        return res
    elseif @capture ex :>>=(:call(:<<, ~lhs, ~op), ~rhs)
        error("Finch doesn't support incrementing definitions of variables")
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
        return :($(ctx.nodes.call)($(ctx(op)), $(map(ctx, args)...)))
    elseif @capture ex :(...)(~arg)
        return esc(ex)
    elseif @capture ex :$(~arg)
        return esc(arg)
    elseif ex in evaluable_exprs
        return ctx.nodes.literal(@eval(ex))
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
    return :(
        let
            $(finch_parse_instance(ex))
        end
    )
end