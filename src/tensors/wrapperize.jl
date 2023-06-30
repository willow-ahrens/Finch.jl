
struct DepthCalculator
    rec
end

depth_calculator(root) = DepthCalculator(DepthCalculatorVisitor()(root))

(ctx::DepthCalculator)(node::FinchNode) = maximum(node -> get(ctx.rec, node, 0), PostOrderDFS(node))

@kwdef struct DepthCalculatorVisitor
    depth = 1
    rec = Dict()
end

function (ctx::DepthCalculatorVisitor)(node::FinchNode)
    if node.kind === loop
        ctx(node.ext)
        ctx.rec[node.idx] = ctx.depth
        ctx_2 = DepthCalculatorVisitor(depth=ctx.depth+1, rec=ctx.rec)
        ctx_2(node.body)
    elseif node.kind === define
        ctx.rec[node.lhs] = ctx.depth
    elseif istree(node)
        for child in children(node)
            ctx(child)
        end
    end
    return ctx.rec
end

struct VariableExpander
    bindings
end

function variable_expander(root)
    bindings = Dict()
    for node in PostOrderDFS(root)
        if node.kind === define
            bindings[node.lhs] = node.rhs
        end
    end
    return VariableExpander(bindings)
end

(ctx::VariableExpander)(node::FinchNode) = Rewrite(Fixpoint(@rule ~var::isvariable => bindings[var]))(node)
"""
    get_wrapper_rules(alg, shash)

Return the wrapperizing rule set for Finch, which converts expressions like `A[i
+ 1]` to array combinator expressions like `OffsetArray(A, (1,))`. The rules have
access to the algebra `alg` and the depth lookup `depth`` One can dispatch on
the `alg` trait to specialize the rule set for different algebras. These rules run
after simplification so one can expect constants to be folded.
"""
function get_wrapper_rules(alg, depth, ctx)
    return [
        (@rule access(~A::isvariable, ~m, ~i...) => access(RootArray(A), m, i...)),
        (@rule access(~A::isvirtual, ~m, ~i1..., call(~proto::isliteral, ~j), ~i2...) => if isprotocol(proto.val)
            body = A.val
            protos = ([nothing for _ in i1]..., proto.val, [nothing for _ in i2]...)
            if body isa VirtualProtocolizedArray
                protos = something.(body.protos, protos)
                body = body.body
            end
            access(VirtualProtocolizedArray(body, protos), m, i1..., j, i2...)
        end),
        (@rule access(~A::isvirtual, ~m, ~i1..., call($(~), ~j), ~i2...) => begin
            body = A.val
            dims = ([false for _ in i1]..., true, [false for _ in i2]...)
            if body isa VirtualPermissiveArray
                dims = body.dims .| dims
                body = body.body
            end
            access(VirtualPermissiveArray(body, dims), m, i1..., j, i2...)
        end),
        (@rule access(~A::isvirtual, ~m, ~i1..., call(+, ~j1..., ~k, ~j2...), ~i2...) => begin
            if !isempty(j1) || !isempty(j2) 
                body = A.val
                k_2 = call(+, ~j1..., ~j2...)
                if depth(k_2) == 0
                    delta = ([0 for _ in i1]..., k_2, [0 for _ in i2]...)
                    if body isa VirtualOffsetArray
                        delta = map((a, b) -> call(+, a, b), body.delta, delta)
                        body = body.body
                    end
                    access(VirtualOffsetArray(body, delta), m, i1..., k, i2...)
                end
            end
        end),
        (@rule access(~A::isvirtual, ~m, ~i1..., call(+, ~j1..., ~k, ~j2...), ~i2...) => begin
            if (!isempty(j1) || !isempty(j2))
                k_2 = call(+, ~j1..., ~j2...)
                if depth(k_2) < depth(k) && depth(k_2) != 0
                    access(VirtualToeplitzArray(A.val, length(i1) + 1), m, i1..., k, k_2, i2...)
                end
            end
        end),
        (@rule access(~A::isvirtual, ~m, ~i1..., access(~I::isvirtual, reader(), ~k), ~i2...) => begin
            I = ctx.bindings[getroot(I.val)] #TODO do we like this pattern?
            if I isa VirtualAbstractUnitRange
                A_2 = VirtualWindowedArray(A.val, ([nothing for _ in i1]..., I.target, [nothing for _ in i2]...))
                A_3 = VirtualOffsetArray(A_2, ([0 for _ in i1]..., call(-, getstart(I.target), 1), [0 for _ in i2]...))
                access(A_3, m, i1..., k, i2...)
            end
        end),
        (@rule call(-, ~i, ~j) => call(+, i, call(-, j))),
        (@rule call(+, ~i1..., call(+, ~j...), ~i2...) => call(+, i1..., j..., i2...)),
        (@rule call(+, ~i) => i),
    ]
end


function wrapperize(root, ctx::AbstractCompiler)
    depth = depth_calculator(root)
    Rewrite(Fixpoint(Chain([
        Prewalk(Fixpoint(Chain(get_wrapper_rules(ctx.algebra, depth, ctx)))),
        Postwalk(Fixpoint(Chain(get_wrapper_rules(ctx.algebra, depth, ctx))))
    ])))(root)
end

struct ConcordizeVisitor
    freshen
    scope
end

bind

function (ctx::ConcordizeVisitor)(node::FinchNode)
    function isbound(x::FinchNode)
        if isconstant(x) || x in ctx.scope
            return true
        elseif @capture x access(~tns, ~mode, ~idxs...)
            return getroot(tns) in ctx.scope && all(isbound, idxs)
        elseif istree(x)
            return all(isbound, arguments(x))
        else
            return false
        end
    end
    isboundindex(x) = isindex(x) && isbound(x)
    isboundnotindex(x) = !isindex(x) && isbound(x)
        
    selects = []

    if node.kind === loop || node.kind === assign || node.kind === define || node.kind === sieve
        node = Rewrite(Postwalk(Fixpoint(
            @rule access(~tns, ~mode, ~i..., ~j::isboundnotindex, ~k::All(isboundindex)...) => begin
                j_2 = index(ctx.freshen(:s))
                push!(selects, j_2 => j)
                push!(ctx.scope, j_2)
                access(tns, mode, i..., j_2, k...)
            end
        )))(node)
    end

    if node.kind === loop
        ctx_2 = ConcordizeVisitor(ctx.freshen, union(ctx.scope, [node.idx]))
        node = loop(node.idx, node.ext, ctx_2(node.body))
    elseif node.kind === define
        push!(ctx.scope, node.lhs)
    elseif node.kind === declare
        push!(ctx.scope, node.tns)
    elseif istree(node)
        node = similarterm(node, operation(node), map(ctx, children(node)))
    end

    for (select_idx, idx_ex) in reverse(selects)
        var = variable(ctx.freshen(:v))

        node = sequence(
            define(var, idx_ex),
            loop(select_idx, Extent(var, var), node)
        )
    end

    node
end

function concordize(root, ctx::AbstractCompiler; reorder = false)
    depth = depth_calculator(root)
    root = Rewrite(Postwalk(Fixpoint(@rule access(~tns, ~mode, ~i..., ~j::isindex, ~k...) => begin
        if depth(j) < maximum(depth.(k), init=0)
            access(~tns, ~mode, ~i..., call(identity, j), ~k...)
        end
    end)))(root)
    ConcordizeVisitor(ctx.freshen, collect(keys(ctx.bindings)))(root)
end