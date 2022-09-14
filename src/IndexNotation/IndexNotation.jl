module IndexNotation
    using MacroTools, SyntaxInterface, Finch

    export IndexNode, IndexStatement, IndexExpression, IndexTerminal
    export Literal
    export Name
    export Virtual
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

    export @f, @finch_program, @finch_program_instance

    include("nodes.jl")
    include("instances.jl")
    include("protocols.jl")
    include("syntax.jl")
end