struct Reader end
struct Updater end

const reader = Reader()
const updater = Updater()

const IS_TREE = 1
const IS_STATEFUL = 2
const IS_CONST = 4
const ID = 8

@enum LogicNodeKind begin
    literal  =  0ID | IS_CONST
    value    =  1ID | IS_CONST
    index    =  2ID
    variable =  3ID
    virtual  =  4ID
    tag      =  5ID | IS_TREE
    call     =  6ID | IS_TREE
    access   =  7ID | IS_TREE 
    cached   = 10ID | IS_TREE
    assign   = 11ID | IS_TREE | IS_STATEFUL
    loop     = 12ID | IS_TREE | IS_STATEFUL
    sieve    = 13ID | IS_TREE | IS_STATEFUL
    define   = 14ID | IS_TREE | IS_STATEFUL
    declare  = 15ID | IS_TREE | IS_STATEFUL
    thaw     = 16ID | IS_TREE | IS_STATEFUL
    freeze   = 17ID | IS_TREE | IS_STATEFUL
    block    = 18ID | IS_TREE | IS_STATEFUL
end

"""
    literal(val)

Finch AST expression for the literal value `val`.
"""
literal

"""
    value(val, type)

Finch AST expression for host code `val` expected to evaluate to a value of type
`type`.
"""
value

"""
    index(name)

Finch AST expression for an index named `name`. Each index must be quantified by
a corresponding `loop` which iterates over all values of the index.
"""
index

"""
    variable(name)

Finch AST expression for a variable named `name`. The variable can be looked up
in the context.
"""
variable

"""
    virtual(val)

Finch AST expression for an object `val` which has special meaning to the
compiler. This type is typically used for tensors, as it allows users to
specify the tensor's shape and data type.
"""
virtual

"""
    tag(var, bind)

Finch AST expression for a global variable `var` with the value `bind`.
Because the finch compiler cannot pass variable state from the program domain to
the type domain directly, the `tag` type represents a value `bind`
referred to by a variable named `bind`. All `tag` in the same program
must agree on the value of variables, and only one value will be virtualized.
"""
tag

"""
    call(op, args...)

Finch AST expression for the result of calling the function `op` on `args...`.
"""
call

"""
    access(tns, mode, idx...)

Finch AST expression representing the value of tensor `tns` at the indices
`idx...`. The `mode` differentiates between reads or updates and whether the
access is in-place.
"""
access

"""
    cached(val, ref)

Finch AST expression `val`, equivalent to the quoted expression `ref`
"""
cached

"""
    loop(idx, ext, body) 

Finch AST statement that runs `body` for each value of `idx` in `ext`. Tensors
in `body` must have ranges that agree with `ext`.
A new scope is introduced to evaluate `body`.
"""
loop

"""
    sieve(cond, body)

Finch AST statement that only executes `body` if `cond` is true.
A new scope is introduced to evaluate `body`.
"""
sieve

"""
    assign(lhs, op, rhs)

Finch AST statement that updates the value of `lhs` to `op(lhs, rhs)`.
Overwriting is accomplished with the function `overwrite(lhs, rhs) = rhs`.
"""
assign

"""
    define(lhs, rhs, body)

Finch AST statement that defines `lhs` as having the value `rhs` in `body`. 
A new scope is introduced to evaluate `body`.
"""
define

"""
    declare(tns, init)

Finch AST statement that declares `tns` with an initial value `init` in the current scope.
"""
declare

"""
    freeze(tns)

Finch AST statement that freezes `tns` in the current scope.
"""
freeze

"""
    thaw(tns)

Finch AST statement that thaws `tns` in the current scope.
"""
thaw

"""
    block(bodies...)

Finch AST statement that executes each of it's arguments in turn. If the body is
not a block, replaces accesses to tensors in the body with
instantiate.
"""
block

"""
    LogicNode

A Finch IR node. Finch uses a variant of Concrete Index Notation as an
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
    isstateful(node)

Returns true if the node is a finch statement, and false if the node is an
index expression. Typically, statements specify control flow and 
expressions describe values.
"""
isstateful(node::LogicNode) = Int(node.kind) & IS_STATEFUL != 0

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
    isconstant(node)

Returns true if the node can be expected to be constant within the current finch context
"""
isconstant(node::LogicNode) = Int(node.kind) & IS_CONST != 0

"""
    isvirtual(node)

Returns true if the node is a finch virtual
"""
isvirtual(ex::LogicNode) = ex.kind === virtual

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

getval(ex::LogicNode) = ex.val

SyntaxInterface.istree(node::LogicNode) = Int(node.kind) & IS_TREE != 0
AbstractTrees.children(node::LogicNode) = node.children
SyntaxInterface.arguments(node::LogicNode) = node.children
SyntaxInterface.operation(node::LogicNode) = node.kind

#TODO clean this up eventually
function SyntaxInterface.similarterm(::Type{LogicNode}, op::LogicNodeKind, args)
    @assert istree(LogicNode(op, nothing, nothing, []))
    LogicNode(op, nothing, nothing, args)
end

function LogicNode(kind::LogicNodeKind, args::Vector)
    if (kind === value || kind === literal || kind === index || kind === variable || kind === virtual) && length(args) == 1
        return LogicNode(kind, args[1], Any, LogicNode[])
    elseif (kind === value || kind === literal || kind === index || kind === variable || kind === virtual) && length(args) == 2
        return LogicNode(kind, args[1], args[2], LogicNode[])
    elseif (kind === cached && length(args) == 2) ||
        (kind === access && length(args) >= 2) ||
        (kind === tag && length(args) == 2) ||
        (kind === call && length(args) >= 1) ||
        (kind === loop && length(args) == 3) ||
        (kind === sieve && length(args) == 2) ||
        (kind === assign && length(args) == 3) ||
        (kind === define && length(args) == 3) ||
        (kind === declare && length(args) == 2) ||
        (kind === freeze && length(args) == 1) ||
        (kind === thaw && length(args) == 1) ||
        (kind === block)
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
    elseif node.kind === tag && sym === :var node.children[1]
    elseif node.kind === tag && sym === :bind node.children[2]
    elseif node.kind === access && sym === :tns node.children[1]
    elseif node.kind === access && sym === :mode node.children[2]
    elseif node.kind === access && sym === :idxs @view node.children[3:end]
    elseif node.kind === call && sym === :op node.children[1]
    elseif node.kind === call && sym === :args @view node.children[2:end]
    elseif node.kind === cached && sym === :arg node.children[1]
    elseif node.kind === cached && sym === :ref node.children[2]
    elseif node.kind === loop && sym === :idx node.children[1]
    elseif node.kind === loop && sym === :ext node.children[2]
    elseif node.kind === loop && sym === :body node.children[3]
    elseif node.kind === sieve && sym === :cond node.children[1]
    elseif node.kind === sieve && sym === :body node.children[2]
    elseif node.kind === assign && sym === :lhs node.children[1]
    elseif node.kind === assign && sym === :op node.children[2]
    elseif node.kind === assign && sym === :rhs node.children[3]
    elseif node.kind === define && sym === :lhs node.children[1]
    elseif node.kind === define && sym === :rhs node.children[2]
    elseif node.kind === define && sym === :body node.children[3]
    elseif node.kind === declare && sym === :tns node.children[1]
    elseif node.kind === declare && sym === :init node.children[2]
    elseif node.kind === freeze && sym === :tns node.children[1]
    elseif node.kind === thaw && sym === :tns node.children[1]
    elseif node.kind === block && sym === :bodies node.children
    else
        error("type LogicNode($(node.kind), ...) has no property $sym")
    end
end

function Base.show(io::IO, node::LogicNode) 
    if node.kind === literal || node.kind === index || node.kind === variable || node.kind === virtual
        print(io, node.kind, "(", node.val, ")")
    elseif node.kind === value
        print(io, node.kind, "(", node.val, ", ", node.type, ")")
    else
        print(io, node.kind, "("); join(io, node.children, ", "); print(io, ")")
    end
end

function Base.show(io::IO, mime::MIME"text/plain", node::LogicNode) 
    print(io, "Finch program: ")
    if isstateful(node)
        display_statement(io, mime, node, 0)
    else
        display_expression(io, mime, node)
    end
end

function Base.:(==)(a::LogicNode, b::LogicNode)
    if !istree(a)
        if a.kind === value
            return b.kind === value && a.val == b.val && a.type === b.type
        elseif a.kind === literal
            return b.kind === literal && isequal(a.val, b.val) #TODO Feels iffy idk
        elseif a.kind === index
            return b.kind === index && a.name == b.name
        elseif a.kind === variable
            return b.kind === variable && a.name == b.name
        elseif a.kind === virtual
            return b.kind === virtual && a.val == b.val #TODO Feels iffy idk
        else
            error("unimplemented")
        end
    elseif istree(a)
        return a.kind === b.kind && a.children == b.children
    else
        return false
    end
end

function Base.hash(a::LogicNode, h::UInt)
    if !istree(a)
        if a.kind === value
            return hash(value, hash(a.val, hash(a.type, h)))
        elseif a.kind === literal || a.kind === virtual || a.kind === index || a.kind === variable
            return hash(a.kind, hash(a.val, h))
        else
            error("unimplemented")
        end
    elseif istree(a)
        return hash(a.kind, hash(a.children, h))
    else
        return false
    end
end

function getname(x::LogicNode)
    if x.kind === index
        return x.val
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
logic_leaf(arg::Reader) = literal(arg)
logic_leaf(arg::Updater) = literal(arg)
logic_leaf(arg::LogicNode) = arg

Base.convert(::Type{LogicNode}, x) = logic_leaf(x)
Base.convert(::Type{LogicNode}, x::LogicNode) = x
#Base.convert(::Type{LogicNode}, x::Symbol) = error() # useful for debugging if we wanted to enforce conversion of symbols to value, etc.

#overload RewriteTools pattern constructor so we don't need
#to wrap leaf nodes.
finch_pattern(arg) = logic_leaf(arg)
finch_pattern(arg::RewriteTools.Slot) = arg
finch_pattern(arg::RewriteTools.Segment) = arg
finch_pattern(arg::RewriteTools.Term) = arg
function RewriteTools.term(f::LogicNodeKind, args...; type = nothing)
    RewriteTools.Term(f, [finch_pattern.(args)...])
end
