
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
+ 1]` to array combinator expressions like `ShiftArray(A, (1,))`. The rules have
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
        #(@rule access(~A::isvirtual, ~m, ~i1..., call(+, ~a::isconstant, ~j::isindex), ~i2...) =>
        #    access(ShiftArray(A.val, ([0 for _ in i1]..., a, [0 for _ in i2]...)), m, i1..., j, i2...)),
        #(@rule access(~A::isvirtual, ~m, ~i1..., call(+, ~j::isindex, ~a::isconstant), ~i2...) =>
        #    access(ShiftArray(A.val, ([0 for _ in i1]..., a, [0 for _ in i2]...)), m, i1..., j, i2...)),
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

function (ctx::ConcordizeVisitor)(node::FinchNode)
    isbound(x) = x in ctx.scope
    selects = []

    if node.kind === loop || node.kind === assign || node.kind === define || node.kind === sieve
        node = Rewrite(Postwalk(Fixpoint(@rule access(~tns, ~mode, ~i..., ~j, ~k::All(isbound)...) => if !isindex(j)
            if all(x->(isbound(x) || isconstant(x) || isvirtual(x)), Leaves(j))
                j_2 = index(ctx.freshen(:s))
                push!(selects, j_2 => j)
                push!(ctx.scope, j_2)
                access(tns, mode, i..., j_2, k...)
            end
        end)))(node)
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
    root = ConcordizeVisitor(ctx.freshen, [])(root)
    if reorder
        depth = depth_calculator(root)
        root = Rewrite(Postwalk(Fixpoint(@rule access(~tns, ~mode, ~i..., ~j::isindex, ~k...) => begin
            if depth(j) < maximum(depth.(k), init=0)
                access(~tns, ~mode, ~i..., call(identity, j), ~k...)
            end
        end)))(root)
        root = ConcordizeVisitor(ctx.freshen, [])(root)
    end
    root
end