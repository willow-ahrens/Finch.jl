tab = "  "

const IS_TREE = 1
const IS_STATEFUL = 2
const ID = 4

"""
    IndexHead

An IndexNode type represents many different Finch IR nodes, and an IndexHead
enum is used to differentiate which kind of node is represented.
"""
@enum IndexHead begin
    value    =  1ID
    virtual  =  2ID
    literal  =  3ID
    index    =  4ID
    protocol =  5ID | IS_TREE
    access   =  6ID | IS_TREE 
    reader   =  7ID | IS_TREE
    updater  =  8ID | IS_TREE
    modify   =  9ID | IS_TREE
    create   = 10ID | IS_TREE
    call     = 11ID | IS_TREE
    assign   = 12ID | IS_TREE | IS_STATEFUL
    with     = 13ID | IS_TREE | IS_STATEFUL
    multi    = 14ID | IS_TREE | IS_STATEFUL
    loop     = 15ID | IS_TREE | IS_STATEFUL
    chunk    = 16ID | IS_TREE | IS_STATEFUL
    sieve    = 17ID | IS_TREE | IS_STATEFUL
    pass     = 18ID | IS_TREE | IS_STATEFUL
    lifetime = 19ID | IS_TREE | IS_STATEFUL
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
    index(name)

Finch AST expression for an index named `name`. Each index must be quantified by a corresponding `loop`
which iterates over all values of the index.
"""
index

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
    with(cons, prod)

Finch AST statement that runs `cons` with the tensors produced by `prod`.
"""
with

"""
    multi(bodies...)

Finch AST statement that runs `bodies...` independently and returns all their results.
"""
multi

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

#TODO get rid of access expressions in pass
"""
    pass(tnss...)

Finch AST statement that initializes, freezes, and returns each tensor in `tnss...`.
"""
pass

#TODO figure this one out already
"""
    lifetime(body)

Finch AST statement that initializes and freezes all results in `body`. Most
finch programs are wrapped by an outer `lifetime`.
"""
lifetime

"""
    IndexNode

A Finch IR node. Finch uses a variant of Concrete Index Notation as an
intermediate representation. Consult the documentation of each node kind
for more information.
"""
struct IndexNode
    kind::IndexHead
    val::Any
    type::Any
    children::Vector{IndexNode}
end

isvalue(node::IndexNode) = node.kind === value
#TODO Delete this one when you can
isvalue(node) = false

"""
    isstateful(node)

Returns true if the node is an index statement, and false if the node is an
index expression. Typically, index statements specify control flow and 
index expressions describe values.
"""
isstateful(node::IndexNode) = Int(node.kind) & IS_STATEFUL != 0

SyntaxInterface.istree(node::IndexNode) = Int(node.kind) & IS_TREE != 0
SyntaxInterface.arguments(node::IndexNode) = node.children
SyntaxInterface.operation(node::IndexNode) = node.kind

#TODO clean this up eventually
function SyntaxInterface.similarterm(::Type{IndexNode}, op::IndexHead, args)
    @assert istree(IndexNode(op, nothing, nothing, []))
    IndexNode(op, nothing, nothing, args)
end

function IndexNode(kind::IndexHead, args::Vector)
    if kind === value
        if length(args) == 1
            return IndexNode(value, args[1], Any, IndexNode[])
        elseif length(args) == 2
            return IndexNode(value, args[1], args[2], IndexNode[])
        else
            error("wrong number of arguments to value(...)")
        end
    elseif kind === literal
        if length(args) == 1
            return IndexNode(kind, args[1], nothing, IndexNode[])
        else
            error("wrong number of arguments to $kind(...)")
        end
    elseif kind === index
        if length(args) == 1
            return IndexNode(kind, args[1], nothing, IndexNode[])
        else
            error("wrong number of arguments to $kind(...)")
        end
    elseif kind === virtual
        if length(args) == 1
            return IndexNode(kind, args[1], nothing, IndexNode[])
        else
            error("wrong number of arguments to $kind(...)")
        end
    elseif kind === with
        if length(args) == 2
            return IndexNode(with, nothing, nothing, args)
        else
            error("wrong number of arguments to with(...)")
        end
    elseif kind === multi
        return IndexNode(multi, nothing, nothing, args)
    elseif kind === access
        if length(args) >= 2
            return IndexNode(access, nothing, nothing, args)
        else
            error("wrong number of arguments to access(...)")
        end
    elseif kind === protocol
        if length(args) == 2
            return IndexNode(protocol, nothing, nothing, args)
        else
            error("wrong number of arguments to protocol(...)")
        end
    elseif kind === call
        if length(args) >= 1
            return IndexNode(call, nothing, nothing, args)
        else
            error("wrong number of arguments to call(...)")
        end
    elseif kind === loop
        if length(args) == 2
            return IndexNode(loop, nothing, nothing, args)
        else
            error("wrong number of arguments to loop(...)")
        end
    elseif kind === chunk
        if length(args) == 3
            return IndexNode(chunk, nothing, nothing, args)
        else
            error("wrong number of arguments to chunk(...)")
        end
    elseif kind === sieve
        if length(args) == 2
            return IndexNode(sieve, nothing, nothing, args)
        else
            error("wrong number of arguments to sieve(...)")
        end
    elseif kind === assign
        if length(args) == 3
            return IndexNode(assign, nothing, nothing, args)
        else
            error("wrong number of arguments to assign(...)")
        end
    elseif kind === pass
        return IndexNode(pass, nothing, nothing, args)
    elseif kind === reader
        if length(args) == 0
            return IndexNode(kind, nothing, nothing, IndexNode[])
        else
            error("wrong number of arguments to reader()")
        end
    elseif kind === updater
        if length(args) == 1
            return IndexNode(updater, nothing, nothing, args)
        else
            error("wrong number of arguments to updater(...)")
        end
    elseif kind === modify
        if length(args) == 0
            return IndexNode(kind, nothing, nothing, IndexNode[])
        else
            error("wrong number of arguments to modify()")
        end
    elseif kind === create
        if length(args) == 0
            return IndexNode(kind, nothing, nothing, IndexNode[])
        else
            error("wrong number of arguments to create()")
        end
    else
        error("unimplemented")
    end
end

function (kind::IndexHead)(args...)
    IndexNode(kind, Any[args...,])
end

function Base.getproperty(node::IndexNode, sym::Symbol)
    if sym === :kind || sym === :val || sym === :type || sym === :children
        return Base.getfield(node, sym)
    elseif node.kind === value ||
            node.kind === literal || 
            node.kind === virtual
        error("type IndexNode($(node.kind), ...) has no property $sym")
    elseif node.kind === index
        if sym === :name
            return node.val::Symbol
        else
            error("type IndexNode(index, ...) has no property $sym")
        end
    elseif node.kind === reader
        error("type IndexNode(reader, ...) has no property $sym")
    elseif node.kind === updater
        if sym === :mode
            return node.children[1]
        else
            error("type IndexNode(updater, ...) has no property $sym")
        end
    elseif node.kind === with
        if sym === :cons
            return node.children[1]
        elseif sym === :prod
            return node.children[2]
        else
            error("type IndexNode(with, ...) has no property $sym")
        end
    elseif node.kind === multi
        if sym === :bodies
            return node.children
        else
            error("type IndexNode(multi, ...) has no property $sym")
        end
    elseif node.kind === access
        if sym === :tns
            return node.children[1]
        elseif sym === :mode
            return node.children[2]
        elseif sym === :idxs
            return @view node.children[3:end]
        else
            error("type IndexNode(access, ...) has no property $sym")
        end
    elseif node.kind === call
        if sym === :op
            return node.children[1]
        elseif sym === :args
            return @view node.children[2:end]
        else
            error("type IndexNode(call, ...) has no property $sym")
        end
    elseif node.kind === protocol
        if sym === :idx
            return node.children[1]
        elseif sym === :mode
            return node.children[2]
        else
            error("type IndexNode(protocol, ...) has no property $sym")
        end
    elseif node.kind === loop
        if sym === :idx
            return node.children[1]
        elseif sym === :body
            return node.children[2]
        else
            error("type IndexNode(loop, ...) has no property $sym")
        end
    elseif node.kind === chunk
        if sym === :idx
            return node.children[1]
        elseif sym === :ext
            return node.children[2]
        elseif sym === :body
            return node.children[3]
        else
            error("type IndexNode(chunk, ...) has no property $sym")
        end
    elseif node.kind === sieve
        if sym === :cond
            return node.children[1]
        elseif sym === :body
            return node.children[2]
        else
            error("type IndexNode(sieve, ...) has no property $sym")
        end
    elseif node.kind === assign
        if sym === :lhs
            return node.children[1]
        elseif sym === :op
            return node.children[2]
        elseif sym === :rhs
            return node.children[3]
        else
            error("type IndexNode(assign, ...) has no property $sym")
        end
    elseif node.kind === pass
        #TODO move op into updater
        if sym === :tnss
            return node.children
        else
            error("type IndexNode(pass, ...) has no property $sym")
        end
    else
        error("type IndexNode has no property $sym")
    end
end

function Finch.getunbound(ex::IndexNode)
    if ex.kind === index
        return [ex.name]
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

function Base.show(io::IO, node::IndexNode) 
    if node.kind === literal || node.kind == index || node.kind === virtual
        print(io, node.kind, "(", node.val, ")")
    elseif node.kind === value
        print(io, node.kind, "(", node.val, ", ", node.type, ")")
    else
        print(io, node.kind, "("); join(io, node.children, ", "); print(io, ")")
    end
end

function Base.show(io::IO, mime::MIME"text/plain", node::IndexNode) 
    if isstateful(node)
        display_statement(io, mime, node, 0)
    else
        display_expression(io, mime, node)
    end
end

function display_expression(io, mime, node::IndexNode)
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
    elseif node.kind === reader
        print(io, "reader()")
    elseif node.kind === updater
        print(io, "updater(")
        display_expression(io, node.mode)
        print(io, ")")
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
        display_expression(io, mime, node.args[end])
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

function display_statement(io, mime, node::IndexNode, level)
    if node.kind === with
        print(io, tab^level * "(\n")
        display_statement(io, mime, node.cons, level + 1)
        print(io, tab^level * ") where (\n")
        display_statement(io, mime, node.prod, level + 1)
        print(io, tab^level * ")\n")
    elseif node.kind === multi
        print(io, tab^level * "begin\n")
        for body in node.bodies
            display_statement(io, mime, body, level + 1)
        end
        print(io, tab^level * "end\n")
    elseif node.kind === loop
        print(io, tab^level * "@∀ ")
        while node.kind === loop
            display_expression(io, mime, node.idx)
            print(io," ")
            node = node.body
        end
        print(io,"(\n")
        display_statement(io, mime, node, level + 1)
        print(io, tab^level * ")\n")
    elseif node.kind === chunk
        print(io, tab^level * "@∀ ")
        display_expression(io, mime, node.idx)
        print(io, " : ")
        display_expression(io, mime, node.ext)
        print(io," (\n")
        display_statement(io, mime, node.body, level + 1)
        print(io, tab^level * ")\n")
    elseif node.kind === sieve
        print(io, tab^level * "@sieve ")
        while node.body.kind === sieve
            display_expression(io, mime, node.cond)
            print(io," && ")
            node = node.body
        end
        display_expression(io, mime, node.cond)
        node = node.body
        print(io," (\n")
        display_statement(io, mime, node, level + 1)
        print(io, tab^level * ")\n")
    elseif node.kind === assign
        print(io, tab^level)
        display_expression(io, mime, node.lhs)
        print(io, " ")
        if node.lhs.mode.kind === updater
            #TODO add << >>
            display_expression(io, mime, node.op)
        end
        print(io, "= ")
        display_expression(io, mime, node.rhs)
        print(io, "\n")
    elseif node.kind === protocol
        display_expression(io, mime, ex.idx)
        print(io, "::")
        display_expression(io, mime, ex.mode)
    elseif node.kind === pass
        print(io, tab^level * "(")
        for tns in arguments(node)[1:end-1]
            display_expression(io, mime, tns)
            print(io, ", ")
        end
        if length(arguments(node)) >= 1
            display_expression(io, mime, last(arguments(node)))
        end
        print(io, ")")
    else
        error("unimplemented")
    end
end

function Base.:(==)(a::IndexNode, b::IndexNode)
    if !istree(a)
        if a.kind === value
            return b.kind === value && a.val == b.val && a.type === b.type
        elseif a.kind === literal
            return b.kind === literal && isequal(a.val, b.val) #TODO Feels iffy idk
        elseif a.kind === index
            return b.kind === index && a.name == b.name
        elseif a.kind === virtual
            return b.kind === virtual && a.val == b.val #TODO Feels iffy idk
        else
            error("unimplemented")
        end
    elseif a.kind === pass
        return b.kind === pass && Set(a.tnss) == Set(b.tnss) #TODO This feels... not quite right
    elseif istree(a)
        return a.kind === b.kind && a.children == b.children
    else
        return false
    end
end

function Base.hash(a::IndexNode, h::UInt)
    if !istree(a)
        if a.kind === value
            return hash(value, hash(a.val, hash(a.type, h)))
        elseif a.kind === literal
            return hash(literal, hash(a.val, h))
        elseif a.kind === virtual
            return hash(virtual, hash(a.val, h))
        elseif a.kind === index
            return hash(index, hash(a.name, h))
        else
            error("unimplemented")
        end
    elseif istree(a)
        return hash(a.kind, hash(a.children, h))
    else
        return false
    end
end

IndexNotation.isliteral(node::IndexNode) = node.kind === literal

function Finch.getvalue(ex::IndexNode)
    ex.kind === literal || error("expected literal")
    ex.val
end

function Finch.getresults(node::IndexNode)
    if node.kind === with
        Finch.getresults(node.cons)
    elseif node.kind === multi
        return mapreduce(Finch.getresults, vcat, node.bodies)
    elseif node.kind === access
        [access(node.tns, node.mode)]
    elseif node.kind === loop
        Finch.getresults(node.body)
    elseif node.kind === chunk
        Finch.getresults(node.body)
    elseif node.kind === sieve
        Finch.getresults(node.body)
    elseif node.kind === assign
        Finch.getresults(node.lhs)
    elseif node.kind === pass
        return node.tnss
    else
        error("unimplemented")
    end
end

function Finch.getname(x::IndexNode)
    if x.kind === index
        return x.val
    elseif x.kind === virtual
        return Finch.getname(x.val)
    elseif x.kind === access
        return Finch.getname(x.tns)
    else
        error("unimplemented")
    end
end

function Finch.setname(x::IndexNode, sym)
    if x.kind === index
        return index(sym)
    elseif x.kind === virtual
        return Finch.setname(x.val, sym)
    else
        error("unimplemented")
    end
end

display_expression(io, mime, ex) = show(IOContext(io, :compact=>true), mime, ex)