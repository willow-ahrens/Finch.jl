const IS_TREE = 1
const ID = 2

@enum LogicNodeKind begin
    literal  =  0ID
    value    =  1ID
    index    =  2ID
    variable =  3ID
    access   =  4ID | IS_TREE
    define   =  5ID | IS_TREE
    mapped   =  6ID | IS_TREE
    reduced  =  7ID | IS_TREE
    reorder  =  8ID | IS_TREE
    reformat =  9ID | IS_TREE
    result   = 10ID | IS_TREE
    evaluate = 11ID | IS_TREE
end

"""
    literal(val)

Logical AST expression for the literal value `val`.
"""
literal

"""
    value(val, type)

Logical AST expression for host code `val` expected to evaluate to a value of type
`type`.
"""
value

"""
    index(name)

Logical AST expression for an index named `name`.
"""
index

"""
    variable(name)

Logical AST expression for a variable named `name`.
"""
variable

"""
    access(tns, idxs...)

Logical AST expression for a tensor object `val`, indexed by indices `idxs...`.
"""
access

"""
    define(lhs, rhs, body)

Logical AST statement that defines `lhs` as having the value `rhs` in `body`. 
"""
define

"""
    mapped(op, args...)

Logical AST expression for mapping the function `op` across `args...`.
"""
mapped

"""
    reduced(op, init, arg, idxs...)

Logical AST statement that reduces dimensions `idxs...` of `arg` using `op`, starting with `init`.
"""
reduced

"""
    reorder(arg, idxs...)

Logical AST statement that reorders the dimensions of `arg` to be `idxs...`
"""
reorder

"""
    reformat(tns, arg)

Logical AST statement that reformats `arg` into the tensor `val`.
"""
reformat

"""
    result(args...)

Logical AST statement that returns `args...` from the current scope, halting the program.
"""
result

"""
    evaluate(arg)

Logical AST statement that evaluates arg into a tensor. Not semantically meaninful for the result.
"""
evaluate

"""
    LogicNode

A Finch Logic IR node. Finch uses a variant of Concrete Index Notation as an
intermediate representation. 

The LogicNode struct represents many different Finch IR nodes. The nodes are
differentiated by a `FinchLogic.LogicNodeKind` enum.
"""
mutable struct LogicNode
    kind::LogicNodeKind
    val::Any
    type::Any
    children::Vector{LogicNode}
end

"""
    isliteral(node)

Returns true if the node is a finch literal
"""
isliteral(ex::LogicNode) = ex.kind === literal

"""
    isvalue(node)

Returns true if the node is a finch value
"""
isvalue(ex::LogicNode) = ex.kind === value

"""
    isvariable(node)

Returns true if the node is a finch variable
"""
isvariable(ex::LogicNode) = ex.kind === variable

"""
    isindex(node)

Returns true if the node is a finch index
"""
isindex(ex::LogicNode) = ex.kind === index

SyntaxInterface.istree(node::LogicNode) = Int(node.kind) & IS_TREE != 0
AbstractTrees.children(node::LogicNode) = node.children
SyntaxInterface.arguments(node::LogicNode) = node.children
SyntaxInterface.operation(node::LogicNode) = node.kind

function SyntaxInterface.similarterm(::Type{LogicNode}, op::LogicNodeKind, args)
    @assert Int(op) & IS_TREE != 0
    LogicNode(op, nothing, nothing, args)
end

function LogicNode(kind::LogicNodeKind, args::Vector)
    if (kind === value || kind === literal || kind === index || kind === variable) && length(args) == 1
        return LogicNode(kind, args[1], Any, LogicNode[])
    elseif kind === value && length(args) == 2
        return LogicNode(kind, args[1], args[2], LogicNode[])
    elseif (kind === access && length(args) >= 1) ||
        (kind === define && length(args) == 3) ||
        (kind === mapped && length(args) >= 1) ||
        (kind === reduced && length(args) >= 3) ||
        (kind === reorder && length(args) >= 1) ||
        (kind === reformat && length(args) == 2) ||
        (kind === result) ||
        (kind === evaluate && length(args) == 1)
        return LogicNode(kind, nothing, nothing, args)
    else
        error("wrong number of arguments to $kind(...)")
    end
end

function (kind::LogicNodeKind)(args...)
    LogicNode(kind, Any[args...,])
end

function Base.getproperty(node::LogicNode, sym::Symbol)
    if sym === :kind || sym === :val || sym === :type || sym === :children
        return Base.getfield(node, sym)
    elseif node.kind === index && sym === :name node.val::Symbol
    elseif node.kind === variable && sym === :name node.val::Symbol
    elseif node.kind === access && sym === :tns node.children[1]
    elseif node.kind === access && sym === :idxs @view node.children[2:end]
    elseif node.kind === define && sym === :lhs node.children[1]
    elseif node.kind === define && sym === :rhs node.children[2]
    elseif node.kind === define && sym === :body node.children[3]
    elseif node.kind === mapped && sym === :op node.children[1]
    elseif node.kind === mapped && sym === :args @view node.children[2:end]
    elseif node.kind === reduced && sym === :op node.children[1]
    elseif node.kind === reduced && sym === :init node.children[2]
    elseif node.kind === reduced && sym === :arg node.children[3]
    elseif node.kind === reduced && sym === :idxs @view node.children[4:end]
    elseif node.kind === reorder && sym === :arg node.children[1]
    elseif node.kind === reorder && sym === :idxs @view node.children[2:end]
    elseif node.kind === reformat && sym === :tns node.children[1]
    elseif node.kind === reformat && sym === :arg node.children[2]
    elseif node.kind === result && sym === :args node.children
    elseif node.kind === evaluate && sym === :arg node.children[1]
    else
        error("type LogicNode($(node.kind), ...) has no property $sym")
    end
end

function Base.show(io::IO, node::LogicNode) 
    if node.kind === literal || node.kind === index || node.kind === variable
        print(io, node.kind, "(", node.val, ")")
    elseif node.kind === value
        print(io, node.kind, "(", node.val, ", ", node.type, ")")
    else
        print(io, node.kind, "("); join(io, node.children, ", "); print(io, ")")
    end
end

function Base.show(io::IO, mime::MIME"text/plain", node::LogicNode) 
    print(io, "Finch Logic: ")
    display_expression(io, mime, node, 0)
end

function display_expression(io, mime, node, indent)
    if operation(node) === literal
        print(io, node.val)
    elseif operation(node) === value
        print(io, summary(node.val))
        if node.type !== Any
            print(io, "::")
            print(io, node.type)
        end
    elseif operation(node) === index
        print(io, node.name)
    elseif operation(node) === variable
        print(io, node.name)
    elseif istree(node)
        println(io, operation(node), "(")
        for child in node.children
            print(io, " " ^ (indent + 2))
            display_expression(io, mime, child, indent + 2)
            println(io, ", ")
        end
        print(io, " " ^ indent, ")")
    else
        error("unimplemented")
    end
end

function Base.:(==)(a::LogicNode, b::LogicNode)
    if a.kind === value
        return b.kind === value && a.val == b.val && a.type === b.type
    elseif a.kind === literal
        return b.kind === literal && isequal(a.val, b.val)
    elseif a.kind === index
        return b.kind === index && a.name == b.name
    elseif a.kind === variable
        return b.kind === variable && a.name == b.name
    elseif istree(a)
        return a.kind === b.kind && a.children == b.children
    else
        error("unimplemented")
    end
end

function Base.hash(a::LogicNode, h::UInt)
    if a.kind === value
        return hash(value, hash(a.val, hash(a.type, h)))
    elseif a.kind === literal || a.kind === index || a.kind === variable
        return hash(a.kind, hash(a.val, h))
    elseif istree(a)
        return hash(a.kind, hash(a.children, h))
    else
        error("unimplemented")
    end
end

"""
    logic_leaf(x)

Return a terminal finch node wrapper around `x`. A convenience function to
determine whether `x` should be understood by default as a literal, value, or
virtual.
"""
logic_leaf(arg) = literal(arg)
logic_leaf(arg::Type) = literal(arg)
logic_leaf(arg::Function) = literal(arg)
logic_leaf(arg::LogicNode) = arg

Base.convert(::Type{LogicNode}, x) = logic_leaf(x)
Base.convert(::Type{LogicNode}, x::LogicNode) = x

#overload RewriteTools pattern constructor so we don't need
#to wrap leaf nodes.
finch_pattern(arg) = logic_leaf(arg)
finch_pattern(arg::RewriteTools.Slot) = arg
finch_pattern(arg::RewriteTools.Segment) = arg
finch_pattern(arg::RewriteTools.Term) = arg
function RewriteTools.term(f::LogicNodeKind, args...; type = nothing)
    RewriteTools.Term(f, [finch_pattern.(args)...])
end
