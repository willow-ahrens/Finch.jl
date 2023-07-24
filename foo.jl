using RewriteTools
using AbstractTrees

AbstractTrees.children(node::Expr) = node.args

is_function_def(node) =
    (@capture node :function(~args...)) ||
    (@capture node :->(~args...)) ||
    (@capture node (:(=))(:call(~f, ~args...), ~body)) ||
    (@capture node (:(=))(:where(:call(~f, ~args...), ~types), ~body))

has_function_def(root) = any(is_function_def, PostOrderDFS(root))

staged_defs = []

"""
    Finch.@staged

This function is used internally in Finch in lieu of @generated functions.  It
ensures the first Finch invocation runs in the latest world, and leaves hooks so
that subsequent calls to [`Finch.refresh`](@ref) can update the world and
invalidate old versions.
"""
macro staged(def)
    (@capture def :function(:call(~name, ~args...), ~body)) || throw(ArgumentError("unrecognized function definition in @staged"))

    called = gensym(Symbol(name, :_called))
    name_2 = gensym(Symbol(name, :_eval_invokelatest))
    name_3 = gensym(Symbol(name, :_evaled))

    def = quote
        $called = false

        function $name_2($(args...))
            println("hi")
            global $called
            if !$called
                code = let ($(args...),) = ($(map((arg)->:(typeof($arg)), args)...),)
                    $body
                end
                def = quote
                    function $($(QuoteNode(name_3)))($($(map(QuoteNode, args)...)))
                        $code
                    end
                end
                ($@__MODULE__).eval(def)
                $called = true
            end
            Base.invokelatest(($@__MODULE__).$name_3, $(args...))
        end

        @generated function $name($(args...))
            # Taken from https://github.com/NHDaly/StagedFunctions.jl/blob/6fafbc560421f70b05e3df330b872877db0bf3ff/src/StagedFunctions.jl#L116
            body_2 = () -> begin
                code = $(body)
                if has_function_def(macroexpand($@__MODULE__, code))
                    :($($(name_2))($($args...)))
                else 
                    quote
                        println("bye")
                        $code
                    end
                end
            end
            Core._apply_pure(body_2, ())
            #=quote
                println($(QuoteNode(res)))
            end=#
        end

    end

    return esc(quote
        push!(staged_defs, $(QuoteNode(def)))
        $(def)
    end)
end

@staged function f(x)
    quote
        a = 0
        println($x)
        Threads.@threads for i in 1:10
            a += x
        end
        return a
    end
end

@staged function g(x)
    quote
        a = 0
        for i in 1:10
            a += x
        end
        return a
    end
end

println(f(1))
println(g(1))