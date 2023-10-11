@kwdef struct ShortCircuitVisitor
    ctx
end

function (ctx::ShortCircuitVisitor)(node::FinchNode)
    if @capture node assign(access(~tns::isvirtual, ~m, ~i...), ~op, ~rhs)
        short_circuit_cases(tns.val, ctx.ctx, op)
    elseif istree(node)
        mapreduce(vcat, enumerate(arguments(node))) do (n, arg)
            map(ctx(arg)) do (guard, body)
                args_2 = copy(arguments(node))
                args_2[n] = body
                guard => similarterm(node, operation(node), args_2)
            end
        end
    else
        []
    end
end

short_circuit_cases(node, ctx, op) = []