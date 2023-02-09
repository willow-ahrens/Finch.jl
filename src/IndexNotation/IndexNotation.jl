module IndexNotation
    using RewriteTools, SyntaxInterface, Finch

    export index_leaf
    export literal
    export index
    export variable
    export value
#    export Workspace
    export pass
    export with
    export multi
    export loop
    export Chunk, chunk
    export assign
    export call
    export reader, updater, create, modify, access
    export protocol
    export sieve
    export IndexNode, value, isvalue

    export Follow, follow
    export Walk, walk
    export FastWalk, fastwalk
    export Gallop, gallop
    export Extrude, extrude
    export Laminate, laminate

    export @f, @finch_program, @finch_program_instance

    export isliteral, is_constant, virtual

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
end