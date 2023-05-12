tab = "  "

const IS_TREE = 1
const IS_STATEFUL = 2
const IS_CONST = 4
const ID = 8

"""
    FinchNodeKind

An FinchNode type represents many different Finch IR nodes, and an FinchNodeKind
enum is used to differentiate which kind of node is represented.
"""
@enum FinchNodeKind begin
    variable =  0ID
    value    =  1ID | IS_CONST
    virtual  =  2ID
    literal  =  3ID | IS_CONST
    index    =  4ID
    protocol =  5ID | IS_TREE
    access   =  6ID | IS_TREE 
    reader   =  7ID | IS_TREE
    updater  =  8ID | IS_TREE
    modify   =  9ID | IS_TREE
    create   = 10ID | IS_TREE
    call     = 11ID | IS_TREE
    cached   = 12ID | IS_TREE
    assign   = 13ID | IS_TREE | IS_STATEFUL
    loop     = 15ID | IS_TREE | IS_STATEFUL
    chunk    = 16ID | IS_TREE | IS_STATEFUL
    sieve    = 17ID | IS_TREE | IS_STATEFUL
    declare  = 20ID | IS_TREE | IS_STATEFUL
    thaw     = 21ID | IS_TREE | IS_STATEFUL
    freeze   = 22ID | IS_TREE | IS_STATEFUL
    forget   = 23ID | IS_TREE | IS_STATEFUL
    sequence = 24ID | IS_TREE | IS_STATEFUL
end


"""
    value(val, type)

Finch AST expression for host code `val` expected to evaluate to a value of type `type`.
"""
value

"""
    virtual(val)

Finch AST expression for an object `val` which has special meaning to the compiler. This
type allows users to substitute their own ASTs, etc. into Finch expressions.
"""
virtual

"""
    literal(val)

Finch AST expression for the literal value `val`.
"""
literal

"""
    cached(val, ref)

Finch AST expression `val`, equivalent to the quoted expression `ref`
"""
cached

"""
    index(name)

Finch AST expression for an index named `name`. Each index must be quantified by a corresponding `loop`
which iterates over all values of the index.
"""
index

"""
    variable(name)

Finch AST expression for a variable named `name`. The variable can be looked up in the context.
"""
variable

"""
    protocol(idx, mode)

Finch AST expression marking an indexing expression `idx` with the protocol `mode`.
These usually reside at the toplevel of an indexing expression to an access.
"""
protocol

"""
    access(tns, mode, idx...)

Finch AST expression representing the value of tensor `tns` at the indices
`idx...`. The `mode` differentiates between reads or updates and whether the
access is in-place.
"""
access

"""
    reader()

Finch AST expression for an access mode that is read-only.
"""
reader

"""
    updater(mode)

Finch AST expression for an access mode that may modify the tensor. The `mode`
field specifies whether this access returns this tensor (initializing and
finalizing) or modifies it in place.
"""
updater

"""
    create()

Finch AST expression for an "allocating" update. This access will
initialize and freeze the tensor, and we can be sure that any values
the tensor held before have been forgotten.
"""
create

"""
    modify()

Finch AST expression for an "in place" update. The access will not
initialize or freeze the tensor, but can modify it's existing values.
"""
modify

"""
    call(op, args...)

Finch AST expression for the result of calling the function `op` on `args...`.
"""
call

"""
    loop(idxs..., body) 

Finch AST statement that runs `body` for each value of `idxs...`.
"""
loop

"""
    chunk(idx, ext, body) 

Finch AST statement that runs `body` for each value of `idx` in `ext`. Tensors
in `body` must have ranges that agree with `ext`. This is an internal node.
"""
chunk

"""
    sieve(cond, body)

Finch AST statement that only executes `body` if `cond` is true.
"""
sieve

"""
    assign(lhs, op, rhs)

Finch AST statement that updates the value of `lhs` to `op(lhs, rhs)`. The
tensors of `lhs` are returned.  Overwriting is accomplished with the function
`right(lhs, rhs) = rhs`.
"""
assign

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
    forget(tns)

Finch AST statement that marks the end of the lifetime of `tns`, at least until it is declared again.
"""
forget

"""
    sequence(bodies...)

Finch AST statement that executes each of it's arguments in turn. If the body is
not a sequence, replaces accesses to read-only tensors in the body with
get_reader and accesses to update-only tensors in the body with get_updater.
"""
sequence

"""
    FinchNode

A Finch IR node. Finch uses a variant of Concrete Index Notation as an
intermediate representation. Consult the documentation of each node kind
for more information.
"""
mutable struct FinchNode
    kind::FinchNodeKind
    val::Any
    type::Any
    children::Vector{FinchNode}
end

"""
    isstateful(node)

Returns true if the node is a finch statement, and false if the node is an
index expression. Typically, statements specify control flow and 
expressions describe values.
"""
isstateful(node::FinchNode) = Int(node.kind) & IS_STATEFUL != 0

"""
    isliteral(node)

Returns true if the node is a finch literal
"""
isliteral(ex::FinchNode) = ex.kind === literal

"""
    isvalue(node)

Returns true if the node is a finch value
"""
isvalue(ex::FinchNode) = ex.kind === value

"""
    isconstant(node)

Returns true if the node can be expected to be constant within the current finch context
"""
isconstant(node::FinchNode) = Int(node.kind) & IS_CONST != 0

"""
    isvirtual(node)

Returns true if the node is a finch virtual
"""
isvirtual(ex::FinchNode) = ex.kind === virtual

"""
    isvariable(node)

Returns true if the node is a finch variable
"""
isvariable(ex::FinchNode) = ex.kind === variable

getval(ex::FinchNode) = ex.val

SyntaxInterface.istree(node::FinchNode) = Int(node.kind) & IS_TREE != 0
AbstractTrees.children(node::FinchNode) = node.children
SyntaxInterface.arguments(node::FinchNode) = node.children
SyntaxInterface.operation(node::FinchNode) = node.kind

#TODO clean this up eventually
function SyntaxInterface.similarterm(::Type{FinchNode}, op::FinchNodeKind, args)
    @assert istree(FinchNode(op, nothing, nothing, []))
    FinchNode(op, nothing, nothing, args)
end

function FinchNode(kind::FinchNodeKind, args::Vector)
    if kind === value
        if length(args) == 1
            return FinchNode(value, args[1], Any, FinchNode[])
        elseif length(args) == 2
            return FinchNode(value, args[1], args[2], FinchNode[])
        else
            error("wrong number of arguments to value(...)")
        end
    elseif kind === literal
        if length(args) == 1
            return FinchNode(kind, args[1], nothing, FinchNode[])
        else
            error("wrong number of arguments to $kind(...)")
        end
    elseif kind === index
        if length(args) == 1
            return FinchNode(kind, args[1], nothing, FinchNode[])
        else
            error("wrong number of arguments to $kind(...)")
        end
    elseif kind === variable
        if length(args) == 1
            return FinchNode(kind, args[1], nothing, FinchNode[])
        else
            error("wrong number of arguments to $kind(...)")
        end
    elseif kind === virtual
        if length(args) == 1
            return FinchNode(kind, args[1], nothing, FinchNode[])
        else
            error("wrong number of arguments to $kind(...)")
        end
    elseif kind === cached
        if length(args) == 2
            return FinchNode(kind, nothing, nothing, args)
        else
            error("wrong number of arguments to $kind(...)")
        end
    elseif kind === access
        if length(args) >= 2
            return FinchNode(access, nothing, nothing, args)
        else
            error("wrong number of arguments to access(...)")
        end
    elseif kind === protocol
        if length(args) == 2
            return FinchNode(protocol, nothing, nothing, args)
        else
            error("wrong number of arguments to protocol(...)")
        end
    elseif kind === call
        if length(args) >= 1
            return FinchNode(call, nothing, nothing, args)
        else
            error("wrong number of arguments to call(...)")
        end
    elseif kind === loop
        if length(args) == 2
            return FinchNode(loop, nothing, nothing, args)
        else
            error("wrong number of arguments to loop(...)")
        end
    elseif kind === chunk
        if length(args) == 3
            return FinchNode(chunk, nothing, nothing, args)
        else
            error("wrong number of arguments to chunk(...)")
        end
    elseif kind === sieve
        if length(args) == 2
            return FinchNode(sieve, nothing, nothing, args)
        else
            error("wrong number of arguments to sieve(...)")
        end
    elseif kind === assign
        if length(args) == 3
            return FinchNode(assign, nothing, nothing, args)
        else
            error("wrong number of arguments to assign(...)")
        end
    elseif kind === declare
        if length(args) == 2
            return FinchNode(declare, nothing, nothing, args)
        else
            error("wrong number of arguments to declare(...)")
        end
    elseif kind === freeze
        if length(args) == 1
            return FinchNode(freeze, nothing, nothing, args)
        else
            error("wrong number of arguments to freeze(...)")
        end
    elseif kind === thaw
        if length(args) == 1
            return FinchNode(thaw, nothing, nothing, args)
        else
            error("wrong number of arguments to thaw(...)")
        end
    elseif kind === forget
        if length(args) == 1
            return FinchNode(forget, nothing, nothing, args)
        else
            error("wrong number of arguments to forget(...)")
        end
    elseif kind === sequence
        return FinchNode(sequence, nothing, nothing, args)
    elseif kind === reader
        if length(args) == 0
            return FinchNode(kind, nothing, nothing, FinchNode[])
        else
            error("wrong number of arguments to reader()")
        end
    elseif kind === updater
        if length(args) == 1
            return FinchNode(updater, nothing, nothing, args)
        else
            error("wrong number of arguments to updater(...)")
        end
    elseif kind === modify
        if length(args) == 0
            return FinchNode(kind, nothing, nothing, FinchNode[])
        else
            error("wrong number of arguments to modify()")
        end
    elseif kind === create
        if length(args) == 0
            return FinchNode(kind, nothing, nothing, FinchNode[])
        else
            error("wrong number of arguments to create()")
        end
    else
        error("unimplemented")
    end
end

function (kind::FinchNodeKind)(args...)
    FinchNode(kind, Any[args...,])
end

function Base.getproperty(node::FinchNode, sym::Symbol)
    if sym === :kind || sym === :val || sym === :type || sym === :children
        return Base.getfield(node, sym)
    elseif node.kind === value ||
            node.kind === literal || 
            node.kind === virtual
        error("type FinchNode($(node.kind), ...) has no property $sym")
    elseif node.kind === index
        if sym === :name
            return node.val::Symbol
        else
            error("type FinchNode(index, ...) has no property $sym")
        end
    elseif node.kind === variable
        if sym === :name
            return node.val::Symbol
        else
            error("type FinchNode(variable, ...) has no property $sym")
        end
    elseif node.kind === reader
        error("type FinchNode(reader, ...) has no property $sym")
    elseif node.kind === updater
        if sym === :mode
            return node.children[1]
        else
            error("type FinchNode(updater, ...) has no property $sym")
        end
    elseif node.kind === access
        if sym === :tns
            return node.children[1]
        elseif sym === :mode
            return node.children[2]
        elseif sym === :idxs
            return @view node.children[3:end]
        else
            error("type FinchNode(access, ...) has no property $sym")
        end
    elseif node.kind === call
        if sym === :op
            return node.children[1]
        elseif sym === :args
            return @view node.children[2:end]
        else
            error("type FinchNode(call, ...) has no property $sym")
        end
    elseif node.kind === protocol
        if sym === :idx
            return node.children[1]
        elseif sym === :mode
            return node.children[2]
        else
            error("type FinchNode(protocol, ...) has no property $sym")
        end
    elseif node.kind === loop
        if sym === :idx
            return node.children[1]
        elseif sym === :body
            return node.children[2]
        else
            error("type FinchNode(loop, ...) has no property $sym")
        end
    elseif node.kind === cached
        if sym === :arg
            return node.children[1]
        elseif sym === :ref
            return node.children[2]
        else
            error("type FinchNode(cached, ...) has no property $sym")
        end
    elseif node.kind === chunk
        if sym === :idx
            return node.children[1]
        elseif sym === :ext
            return node.children[2]
        elseif sym === :body
            return node.children[3]
        else
            error("type FinchNode(chunk, ...) has no property $sym")
        end
    elseif node.kind === sieve
        if sym === :cond
            return node.children[1]
        elseif sym === :body
            return node.children[2]
        else
            error("type FinchNode(sieve, ...) has no property $sym")
        end
    elseif node.kind === assign
        if sym === :lhs
            return node.children[1]
        elseif sym === :op
            return node.children[2]
        elseif sym === :rhs
            return node.children[3]
        else
            error("type FinchNode(assign, ...) has no property $sym")
        end
    elseif node.kind === declare
        if sym === :tns
            return node.children[1]
        elseif sym === :init
            return node.children[2]
        else
            error("type FinchNode(declare, ...) has no property $sym")
        end
    elseif node.kind === freeze
        if sym === :tns
            return node.children[1]
        else
            error("type FinchNode(freeze, ...) has no property $sym")
        end
    elseif node.kind === thaw
        if sym === :tns
            return node.children[1]
        else
            error("type FinchNode(thaw, ...) has no property $sym")
        end
    elseif node.kind === forget
        if sym === :tns
            return node.children[1]
        else
            error("type FinchNode(forget, ...) has no property $sym")
        end
    elseif node.kind === sequence
        if sym === :bodies
            return node.children
        else
            error("type FinchNode(sequence, ...) has no property $sym")
        end
    else
        error("type FinchNode has no property $sym")
    end
end

function Finch.getunbound(ex::FinchNode)
    if ex.kind === index
        return [ex]
    elseif ex.kind === loop
        return setdiff(getunbound(ex.body), getunbound(ex.idx))
    elseif ex.kind === chunk
        return setdiff(union(getunbound(ex.body), getunbound(ex.ext)), getunbound(ex.idx))
    elseif istree(ex)
        return mapreduce(Finch.getunbound, union, arguments(ex), init=[])
    else
        return []
    end
end

function Base.show(io::IO, node::FinchNode) 
    if node.kind === literal || node.kind === index || node.kind === variable || node.kind === virtual
        print(io, node.kind, "(", node.val, ")")
    elseif node.kind === value
        print(io, node.kind, "(", node.val, ", ", node.type, ")")
    else
        print(io, node.kind, "("); join(io, node.children, ", "); print(io, ")")
    end
end

function Base.show(io::IO, mime::MIME"text/plain", node::FinchNode) 
    if isstateful(node)
        display_statement(io, mime, node, 0)
    else
        display_expression(io, mime, node)
    end
end

function display_expression(io, mime, node::FinchNode)
    if get(io, :compact, false)
        print(io, "@finch(…)")
    elseif node.kind === value
        print(io, node.val)
        if node.type !== Any
            print(io, "::")
            print(io, node.type)
        end
    elseif node.kind === literal
        print(io, node.val)
    elseif node.kind === index
        print(io, node.name)
    elseif node.kind === variable
        print(io, node.name)
    elseif node.kind === reader
        print(io, "reader()")
    elseif node.kind === updater
        print(io, "updater(")
        display_expression(io, node.mode)
        print(io, ")")
    elseif node.kind === cached
        display_expression(io, node.arg)
    elseif node.kind === virtual
        print(io, "virtual(")
        print(io, node.val)
        print(io, ")")
    elseif node.kind === access
        display_expression(io, mime, node.tns)
        print(io, "[")
        if length(node.idxs) >= 1
            for idx in node.idxs[1:end-1]
                display_expression(io, mime, idx)
                print(io, ", ")
            end
            display_expression(io, mime, node.idxs[end])
        end
        print(io, "]")
    elseif node.kind === call
        display_expression(io, mime, node.op)
        print(io, "(")
        for arg in node.args[1:end-1]
            display_expression(io, mime, arg)
            print(io, ", ")
        end
        if !isempty(node.args)
            display_expression(io, mime, node.args[end])
        end
        print(io, ")")
    elseif istree(node)
        print(io, operation(node))
        print(io, "(")
        for arg in arguments(node)[1:end-1]
            print(io, arg)
            print(io, ",")
        end
        if !isempty(arguments(node))
            print(arguments(node)[end])
        end
    else
        error("unimplemented")
    end
end

function display_statement(io, mime, node::FinchNode, level)
    if node.kind === loop
        print(io, tab^level * "@∀ ")
        while node.kind === loop
            display_expression(io, mime, node.idx)
            print(io," ")
            node = node.body
        end
        print(io,"(\n")
        display_statement(io, mime, node, level + 1)
        print(io, tab^level * ")")
    elseif node.kind === chunk
        print(io, tab^level * "@∀ ")
        display_expression(io, mime, node.idx)
        print(io, " : ")
        display_expression(io, mime, node.ext)
        print(io," (\n")
        display_statement(io, mime, node.body, level + 1)
        print(io, tab^level * ")")
    elseif node.kind === sieve
        print(io, tab^level * "if ")
        while node.body.kind === sieve
            display_expression(io, mime, node.cond)
            print(io," && ")
            node = node.body
        end
        display_expression(io, mime, node.cond)
        node = node.body
        display_statement(io, mime, node, level + 1)
        print(io, tab^level * "end")
    elseif node.kind === assign
        print(io, tab^level)
        display_expression(io, mime, node.lhs)
        print(io, " <<")
        display_expression(io, mime, node.op)
        print(io, ">>= ")
        display_expression(io, mime, node.rhs)
    elseif node.kind === protocol
        display_expression(io, mime, ex.idx)
        print(io, "::")
        display_expression(io, mime, ex.mode)
    elseif node.kind === declare
        print(io, tab^level * "@declare(")
        display_expression(io, mime, node.tns)
        print(io, ", ")
        display_expression(io, mime, node.init)
        print(io, ")")
    elseif node.kind === freeze
        print(io, tab^level * "@freeze(")
        display_expression(io, mime, node.tns)
        print(io, ")")
    elseif node.kind === forget
        print(io, tab^level * "@forget(")
        display_expression(io, mime, node.tns)
        print(io, ")")
    elseif node.kind === thaw
        print(io, tab^level * "@thaw(")
        display_expression(io, mime, node.tns)
        print(io, ")")
    elseif node.kind === sequence
        print(io, tab^level * "begin\n")
        for body in node.bodies
            display_statement(io, mime, body, level + 1)
            println()
        end
        print(io, tab^level * "end")
    else
        println("oh no")
        println(node)
        error("unimplemented")
    end
end

function Base.:(==)(a::FinchNode, b::FinchNode)
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

function Base.hash(a::FinchNode, h::UInt)
    if !istree(a)
        if a.kind === value
            return hash(value, hash(a.val, hash(a.type, h)))
        elseif a.kind === literal
            return hash(literal, hash(a.val, h))
        elseif a.kind === virtual
            return hash(virtual, hash(a.val, h))
        elseif a.kind === index
            return hash(index, hash(a.name, h))
        elseif a.kind === variable
            return hash(variable, hash(a.name, h))
        else
            error("unimplemented")
        end
    elseif istree(a)
        return hash(a.kind, hash(a.children, h))
    else
        return false
    end
end

function Finch.getname(x::FinchNode)
    if x.kind === index
        return x.val
    else
        error("unimplemented")
    end
end

function Finch.setname(x::FinchNode, sym)
    if x.kind === index
        return index(sym)
    elseif x.kind === variable
        return variable(sym)
    elseif x.kind === virtual
        return Finch.setname(x.val, sym)
    else
        error("unimplemented")
    end
end

display_expression(io, mime, ex) = show(IOContext(io, :compact=>true), mime, ex)

"""
    finch_leaf(x)

Return a terminal finch node wrapper around `x`. A convenience function to
determine whether `x` should be understood by default as a literal, value, or
virtual.
"""
finch_leaf(arg) = literal(arg)
finch_leaf(arg::Type) = literal(arg)
finch_leaf(arg::Function) = literal(arg)
finch_leaf(arg::FinchNode) = arg

Base.convert(::Type{FinchNode}, x) = finch_leaf(x)
Base.convert(::Type{FinchNode}, x::FinchNode) = x
Base.convert(::Type{FinchNode}, x::Symbol) = error()

#overload RewriteTools pattern constructor so we don't need
#to wrap leaf nodes.
finch_pattern(arg) = finch_leaf(arg)
finch_pattern(arg::RewriteTools.Slot) = arg
finch_pattern(arg::RewriteTools.Segment) = arg
finch_pattern(arg::RewriteTools.Term) = arg
function RewriteTools.term(f::FinchNodeKind, args...; type = nothing)
    RewriteTools.Term(f, [finch_pattern.(args)...])
end