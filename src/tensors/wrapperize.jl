
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

function concordize(root, ctx::AbstractCompiler; reorder=false)
    root_idx = index(ctx.freshen(:root))
    root = loop(root_idx, nothing, root)
    depth = depth_calculator(root)
    expand = variable_expander(root)
    selects = Dict()
    root = Rewrite(Postwalk(
        @rule access(~tns, ~mode, ~idxs...) => begin
            idxs_2 = map(enumerate(idxs)) do (n, idx)
                if !isindex(idx) || (reorder && depth(idx) <= maximum(depth, expand.(idxs[n + 1:end]), init=0))
                    idx_2 = index(ctx.freshen(:s))
                    trigger = argmax(depth, filter(isindex, collect(PostOrderDFS(sequence(root_idx, idxs[n:end]...)))))
                    push!(get!(selects, trigger, []), idx_2 => idx)
                    idx_2
                else
                    idx
                end
            end
            access(tns, mode, idxs_2...)
        end))(root)
    root = Rewrite(Postwalk(@rule loop(~trigger, ~ext, ~body) => begin
        for (select_idx, idx_ex) in get(selects, trigger, [])
            var = variable(ctx.freshen(:v))
            body = sequence(
                define(var, idx_ex),
                loop(select_idx, Extent(var, var), body)
            )
        end
        loop(trigger, ext, body)
    end))(root)
    root.body
end