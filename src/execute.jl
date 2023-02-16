execute(ex) = execute(ex, DefaultAlgebra())
function register(algebra)
    Base.eval(Finch, quote
        @generated function execute(ex, a::$algebra)
            execute_code(:ex, ex, a())
        end
    end)
end

function execute_code(ex, T, algebra = DefaultAlgebra())
    prgm = nothing
    code = contain(LowerJulia(algebra = algebra)) do ctx
        quote
            $(begin
                prgm = virtualize(ex, T, ctx)
                prgm = TransformSSA(Freshen())(prgm)
                prgm = ThunkVisitor(ctx)(prgm) #TODO this is a bit of a hack.
                (prgm, dims) = dimensionalize!(prgm, ctx)
                #The following call separates tensor and index names from environment symbols.
                #TODO we might want to keep the namespace around, and/or further stratify index
                #names from tensor names
                contain(ctx) do ctx_2
                    prgm2 = InstantiateTensors(ctx = ctx_2)(prgm)
                    prgm2 = ThunkVisitor(ctx_2)(prgm2) #TODO this is a bit of a hack.
                    prgm2 = simplify(prgm2, ctx_2)
                    ctx_2(prgm2)
                end
            end)
            $(contain(ctx) do ctx_2
                :(($(map(getresults(prgm)) do acc
                    @assert acc.tns.kind === variable
                    name = acc.tns.name
                    tns = trim!(ctx.bindings[acc.tns], ctx_2)
                    :($name = $(ctx_2(tns)))
                end...), ))
            end)
        end
    end
    #=
    code = quote
        @inbounds begin
            $code
        end
    end
    =#
    code = code |>
        lower_caches |>
        lower_cleanup
    #quote
    #    println($(QuoteNode(code |>         striplines |>
    #    unblock |>
    #    unquote_literals)))
    #    $code
    #end
end

macro finch(args_ex...)
    @assert length(args_ex) >= 1
    (args, ex) = (args_ex[1:end-1], args_ex[end])
    results = Set()
    prgm = FinchNotation.finch_parse_instance(ex, results)
    thunk = quote
        res = $execute($prgm, $(map(esc, args)...))
    end
    for tns in results
        push!(thunk.args, quote
            $(esc(tns)) = res.$tns
        end)
    end
    push!(thunk.args, quote
        res
    end)
    thunk
end

macro finch_code(args_ex...)
    @assert length(args_ex) >= 1
    (args, ex) = (args_ex[1:end-1], args_ex[end])
    prgm = FinchNotation.finch_parse_instance(ex)
    return quote
        $execute_code(:ex, typeof($prgm), $(map(esc, args)...)) |>
        striplines |>
        unblock |>
        unquote_literals
    end
end

"""
    initialize!(tns, ctx)

Melt and initialize the read-only virtual tensor `tns` in the context `ctx` and return it.
After melting, the tensor is update-only.
"""
initialize!(tns, ctx) = tns

"""
    get_reader(tns, ctx, protos...)
    
Return an object (usually a looplet nest) capable of reading the read-only
virtual tensor `tns`.  As soon as a read-only tensor enters scope, each
subsequent read access will be initialized with a separate call to
`get_reader`. `protos` is the list of protocols in each case.
"""
get_reader(tns, ctx, protos...) = tns

"""
    get_updater(tns, ctx, protos...)
    
Return an object (usually a looplet nest) capable of updating the update-only
virtual tensor `tns`.  As soon as an update only tensor enters scope, each
subsequent update access will be initialized with a separate call to
`get_updater`.  `protos` is the list of protocols in each case.
"""
get_updater(tns, ctx, protos...) = tns

"""
    freeze!(tns, ctx)

Freeze the update-only virtual tensor `tns` in the context `ctx` and return it. After
freezing, the tensor is read-only.
"""
freeze!(tns, ctx) = tns

"""
    trim!(tns, ctx)

Before returning a tensor from the finch program, trim any excess overallocated memory.
"""
trim!(tns, ctx) = tns