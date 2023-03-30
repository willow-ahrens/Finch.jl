module FinchNotation
    using RewriteTools, SyntaxInterface, Finch

    using Finch: default

    export finch_leaf
    export literal
    export index
    export variable
    export virtual
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

    export isliteral, isvalue, isconstant, isvirtual, isvariable

    export overwrite, initwrite

    include("nodes.jl")
    include("instances.jl")
    include("protocols.jl")
    include("syntax.jl")

    isliteral(ex::FinchNode) = ex.kind === literal
    isvalue(ex::FinchNode) = ex.kind === value
    isconstant(ex::FinchNode) = isliteral(ex) || isvalue(ex)
    isvirtual(ex::FinchNode) = ex.kind === virtual
    isvariable(ex::FinchNode) = ex.kind === variable
end