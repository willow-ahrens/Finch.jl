module IndexNotation
    using RewriteTools, SyntaxInterface, Finch

    export IndexNode, IndexStatement, IndexExpression, IndexTerminal
    export Literal
    export Name
    export Workspace
    export Pass, pass
    export With, with
    export Loop, loop
    export Assign, assign
    export Call, call
    export Access, Read, Write, Update, access, access

    export Follow, follow
    export Walk, walk
    export Extrude, extrude
    export Laminate, laminate

    export @i, @index_program, @index_program_instance

    include("nodes.jl")
    include("instances.jl")
    include("protocols.jl")
    include("syntax.jl")
end