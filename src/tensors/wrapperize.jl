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
    #depth = CalculateDepth()(root)
    depth = Dict()
    Rewrite(Fixpoint(Chain([
        Prewalk(Fixpoint(Chain(get_wrapper_rules(ctx.algebra, depth, ctx)))),
        Postwalk(Fixpoint(Chain(get_wrapper_rules(ctx.algebra, depth, ctx))))
    ])))(root)
end