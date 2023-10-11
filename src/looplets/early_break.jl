@kwdef struct BrakeVisitor
    ctx
end

function (ctx::BrakeVisitor)(node::FinchNode)
    if @capture node assign(access(~tns::isvirtual, ~m, ~i...), ~op, ~rhs)
        get_brakes(tns.val, ctx.ctx, op)
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
        []
    end
end

get_brakes(node, ctx, op) = []