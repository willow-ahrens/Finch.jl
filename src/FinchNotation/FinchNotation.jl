module FinchNotation
    using RewriteTools, SyntaxInterface, Finch

    using Finch: default

    export finch_leaf
    export literal
    export index
    export variable
    export value
    export loop
    export Chunk, chunk
    export assign
    export call
    export reader, updater, create, modify, access
    export declare, thaw, freeze, forget
    export sequence
    export protocol
    export sieve
    export FinchNode, value, isvalue

    export Follow, follow
    export Walk, walk
    export Gallop, gallop
    export Extrude, extrude
    export Laminate, laminate

    export @f, @finch_program, @finch_program_instance

    export isliteral, is_constant, virtual
    export isvirtual

    export overwrite, initwrite

    """
        isliteral(ex)

    Return a boolean indicating whether the expression is a literal. If an
    expression is a literal, `getvalue(ex)` should return the literal value it
    corresponds to. `getvalue` defaults to the identity.
    TODO this is out of date

    See also: [`getvalue`](@ref)
    """
    isliteral(ex) = true


    include("nodes.jl")
    include("instances.jl")
    include("protocols.jl")
    include("syntax.jl")

    isvirtual(ex::FinchNode) = ex.kind === virtual
end