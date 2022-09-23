module IndexNotation
    using MacroTools, SyntaxInterface, Finch

    export IndexNode, IndexStatement, IndexExpression, IndexTerminal, index_terminal
    export Literal
    export Name
    export Value
    export Workspace
    export Pass, pass
    export With, with
    export Multi, multi
    export Loop, loop
    export Chunk, chunk
    export Assign, assign
    export Call, call
    export Access, Read, Write, Update, access, access
    export Protocol, protocol
    export Sieve, sieve
    export value

    export Follow, follow
    export Walk, walk
    export FastWalk, fastwalk
    export Gallop, gallop
    export Extrude, extrude
    export Laminate, laminate

    export @f, @_f, @finch_program, @finch_program_instance

    export isliteral, Virtual

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