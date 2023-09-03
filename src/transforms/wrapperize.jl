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
#        (@rule access(~A, ~m, ~i...) => access(unwrap(A), m, i...)),
        (@rule access(~A, ~m, ~i1..., call(~proto::isliteral, ~j), ~i2...) => if isprotocol(proto.val)
            protos = ([nothing for _ in i1]..., proto.val, [nothing for _ in i2]...)
            access(call(protocolize, A, protos...), m, i1..., j, i2...)
        end),
        (@rule call(protocolize, call(protocolize, ~A, ~protos_1...), ~protos_2...) => begin
            protos_3 = map(protos_1, protos_2) do proto_1, proto_2
                something(proto_1, proto_2, Some(nothing)) 
            end
            call(protocolize, A, protos_3...)
        end),
        (@rule call(protocolize, call(swizzle, ~A, ~sigma...), ~protos...) =>
            call(swizzle, call(protocolize, A, protos[invperm(getval.(sigma))]...), sigma...)),
        (@rule access(~A, ~m, ~i1..., call($(~), ~j), ~i2...) => begin
            dims = ([false for _ in i1]..., true, [false for _ in i2]...)
            access(call(permissive, A, dims...), m, i1..., j, i2...)
        end),
        (@rule call(permissive, call(permissive, ~A, ~dims_1...), ~dims_2...) =>
            call(permissive, A, (dims_1 .| dims_2)...)),
        (@rule call(permissive, call(swizzle, ~A, ~sigma...), ~dims...) =>
            call(swizzle, call(permissive, A, dims[invperm(getval.(sigma))]...), sigma...)),
        (@rule access(~A, ~m, ~i1..., call(-, ~j, ~k), ~i2...) =>
            access(A, m, i1..., call(+, j, call(-, k)), i2...)),
        (@rule access(~A, ~m, ~i1..., call(+, ~j), ~i2...) =>
            access(A, m, i1..., j, i2...)),
        (@rule access(~A, ~m, ~i1..., call(+, ~j1..., ~k, ~j2...), ~i2...) => begin
            if (!isempty(j1) || !isempty(j2))
                k_2 = call(+, ~j1..., ~j2...)
                if depth(k_2) < depth(k) && depth(k_2) != 0
                    access(call(toeplitz, A, length(i1) + 1), m, i1..., k, k_2, i2...)
                end
            end
        end),
        (@rule call(toeplitz, call(swizzle, ~A, ~sigma...), ~dim...) => begin
            sigma = getval.(sigma)
            idim = invperm(sigma)[dim]
            call(swizzle, call(toeplitz, A, idim), sigma[1:idim-1]..., sigma[idim], sigma[idim], sigma[idim+1:end]...)
        end),
        (@rule access(~A, ~m, ~i1..., call(+, ~j1..., ~k, ~j2...), ~i2...) => begin
            if !isempty(j1) || !isempty(j2) 
                k_2 = call(+, ~j1..., ~j2...)
                if depth(k_2) == 0
                    delta = ([0 for _ in i1]..., k_2, [0 for _ in i2]...)
                    access(call(offset, A, delta...), m, i1..., k, i2...)
                end
            end
        end),
        (@rule call(offset, call(offset, ~A, ~delta_1...), ~delta_2...) => begin
            delta_3 = map(delta_1, delta_2) do proto_1, proto_2
                call(+, delta_1, delta_2) 
            end
            call(offset, A, delta_3...)
        end),
        (@rule call(offset, call(swizzle, ~A, ~sigma...), ~delta...) =>
            call(swizzle, call(offset, A, delta[invperm(getval.(sigma))]...), sigma...)),
        (@rule access(~A, ~m, ~i1..., access(call(extent, ~start, ~stop), reader(), ~k), ~i2...) => begin
            A_2 = call(window, A, [nothing for _ in i1]..., call(extent, start, stop), [nothing for _ in i2]...)
            A_3 = call(offset, A_2, [0 for _ in i1]..., call(-, start, 1), [0 for _ in i2]...)
            access(A_3, m, i1..., k, i2...)
        end),
        (@rule access(~A, ~m, ~i1..., access(~I::isvirtual, reader(), ~k), ~i2...) => if I.val isa Extent
            A_2 = call(window, A, [nothing for _ in i1]..., I, [nothing for _ in i2]...)
            A_3 = call(offset, A_2, [0 for _ in i1]..., call(-, getstart(I), 1), [0 for _ in i2]...)
            access(A_3, m, i1..., k, i2...)
        end),
        (@rule assign(access(~a, updater(), ~i...), initwrite, ~rhs) => begin
            assign(access(a, updater(), i...), call(initwrite, call(default, a)), rhs)
        end),
        (@rule call(swizzle, call(swizzle, ~A, ~sigma_1...), ~sigma_2...) =>
            call(swizzle, A, sigma_1[getval.(sigma_2)]...)),
        (@rule access(call(swizzle, ~A, ~sigma...), ~m, ~i...) =>
            access(A, m, i[getval.(sigma)]...)),
        (@rule block(~s1..., define(~x, call(swizzle, ~A, ~sigma...)), ~s2...) => begin
            x_2 = variable(freshen(ctx.code, x))
            s2_2 = Rewrite(Postwalk(@rule x => call(swizzle, x, sigma...)))(block(s2...))
            block(s1..., define(x, A), s2_2)
        end),
    ]
end

"""
    wrapperize(root, ctx)

Convert index expressions in the program `root` to wrapper arrays, according to
the rules in `get_wrapper_rules`. By default, the following transformations are
performed:

```julia
A[i - j] => A[i + (-j)]
A[i + 1] => OffsetArray(A, (1,))[i]
A[i + j] => ToeplitzArray(A, 1)[i, j]
A[~i] => PermissiveArray(A, 1)[i, j]
```

The loop binding order may be used to determine which index comes first in an
expression like `A[i + j]`. Thus, `for i=:,j=:; ... A[i + j]` will result in
`ToeplitzArray(A, 1)[j, i]`, but `for j=:,i=:; ... A[i + j]` results in
`ToeplitzArray(A, 1)[i, j]`. `wrapperize` runs before dimensionalization, so
resulting raw indices may participate in dimensionalization according to the
semantics of the wrapper.
"""
function wrapperize(root, ctx::AbstractCompiler)
    depth = depth_calculator(root)
    root = unevaluate_partial(root, ctx)
    root = Rewrite(Fixpoint(Chain([
        Postwalk(Fixpoint(Chain(get_wrapper_rules(ctx.algebra, depth, ctx))))
    ])))(root)
    evaluate_partial(root, ctx)
end