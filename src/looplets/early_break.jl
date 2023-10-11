@kwdef struct Switch
    guard
    body
end

FinchNotation.finch_leaf(x::Brake) = virtual(x)

@kwdef struct BrakeVisitor
    ctx
end

function (ctx::BrakeVisitor)(node::FinchNode)
    if node.kind === virtual
        get_brakes(node.val, ctx.ctx)
    if istree(node)
        results = []
        for n, arg in enumerate(arguments(node))
            append!(results, map(ctx(arg)) do (guard, body)
                args_2 = copy(arguments(node))
                args_2[n] = body
                guard => similarterm(node, operation(node), args_2)
            end)
        end
    else
        [(literal(true) => node)]
    end
end

get_brakes(node::Brake, ctx::BrakeVisitor) = node.guard => node.body