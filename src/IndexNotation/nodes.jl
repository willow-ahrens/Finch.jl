tab = "  "

abstract type IndexNode end
abstract type IndexStatement <: IndexNode end
abstract type IndexExpression <: IndexNode end
abstract type IndexTerminal <: IndexExpression end

@enum CINHead begin
    value=1
    virtual=2
    name=3
    literal=4
    with=5
    access=6
    loop=7
    chunk=8
    sieve=9
    assign=10
end

struct CINNode <: IndexNode
    head::CINHead
    val::Any
    type::Any
    args::Vector{IndexNode}
end

isvalue(node::CINNode) = node.head === value
#TODO Delete this one when you can
isvalue(node) = false


SyntaxInterface.istree(node::CINNode) = node.head > literal
SyntaxInterface.arguments(node::CINNode) = node.args
SyntaxInterface.operation(node::CINNode) = node.head

#TODO clean this up eventually
function SyntaxInterface.similarterm(::Type{<:Union{IndexNode, CINNode}}, op::CINHead, args)
    @assert istree(CINNode(op, nothing, nothing, []))
    CINNode(op, nothing, nothing, args)
end

function CINNode(op::CINHead, args::Vector)
    if op === value
        if length(args) == 1
            return CINNode(value, args[1], Any, IndexNode[])
        elseif length(args) == 2
            return CINNode(value, args[1], args[2], IndexNode[])
        else
            error("wrong number of arguments to value(...)")
        end
    elseif op === literal
        if length(args) == 1
            return CINNode(op, args[1], nothing, IndexNode[])
        else
            error("wrong number of arguments to $op(...)")
        end
    elseif op === name
        if length(args) == 1
            return CINNode(op, args[1], nothing, IndexNode[])
        else
            error("wrong number of arguments to $op(...)")
        end
    elseif op === virtual
        if length(args) == 1
            return CINNode(op, args[1], nothing, IndexNode[])
        else
            error("wrong number of arguments to $op(...)")
        end
    elseif op === with
        if length(args) == 2
            return CINNode(with, nothing, nothing, args)
        else
            error("wrong number of arguments to with(...)")
        end
    elseif op === access
        if length(args) >= 2
            return CINNode(access, nothing, nothing, args)
        else
            error("wrong number of arguments to access(...)")
        end
    elseif op === loop
        if length(args) == 2
            return CINNode(loop, nothing, nothing, args)
        else
            error("wrong number of arguments to loop(...)")
        end
    elseif op === chunk
        if length(args) == 3
            return CINNode(chunk, nothing, nothing, args)
        else
            error("wrong number of arguments to chunk(...)")
        end
    elseif op === sieve
        if length(args) == 2
            return CINNode(sieve, nothing, nothing, args)
        else
            error("wrong number of arguments to sieve(...)")
        end
    elseif op === assign
        if length(args) == 2
            return CINNode(assign, nothing, nothing, [args[1], literal(nothing), args[2]])
        elseif length(args) == 3
            return CINNode(assign, nothing, nothing, args)
        else
            error("wrong number of arguments to assign(...)")
        end
    else
        error("unimplemented")
    end
end

function (op::CINHead)(args...)
    CINNode(op, Any[args...,])
end

function Base.getproperty(node::CINNode, sym::Symbol)
    if sym === :head || sym === :val || sym === :type || sym === :args
        return Base.getfield(node, sym)
    elseif node.head === value
        error("type CINNode(value, ...) has no property $sym")
    elseif node.head === literal
        error("type CINNode(literal, ...) has no property $sym")
    elseif node.head === virtual
        error("type CINNode(virtual, ...) has no property $sym")
    elseif node.head === name
        if sym === :name
            return node.val::Symbol
        else
            error("type CINNode(virtual, ...) has no property $name")
        end
    elseif node.head === with
        if sym === :cons
            return node.args[1]
        elseif sym === :prod
            return node.args[2]
        else
            error("type CINNode(with, ...) has no property $sym")
        end
    elseif node.head === access
        if sym === :tns
            return node.args[1]
        elseif sym === :mode
            return node.args[2]
        elseif sym === :idxs
            return @view node.args[3:end]
        else
            error("type CINNode(access, ...) has no property $sym")
        end
    elseif node.head === loop
        if sym === :idx
            return node.args[1]
        elseif sym === :body
            return node.args[2]
        else
            error("type CINNode(loop, ...) has no property $sym")
        end
    elseif node.head === chunk
        if sym === :idx
            return node.args[1]
        elseif sym === :ext
            return node.args[2]
        elseif sym === :body
            return node.args[3]
        else
            error("type CINNode(chunk, ...) has no property $sym")
        end
    elseif node.head === sieve
        if sym === :cond
            return node.args[1]
        elseif sym === :body
            return node.args[2]
        else
            error("type CINNode(sieve, ...) has no property $sym")
        end
    elseif node.head === assign
        #TODO move op into update
        if sym === :lhs
            return node.args[1]
        elseif sym === :op
            return node.args[2]
        elseif sym === :rhs
            return node.args[3]
        else
            error("type CINNode(assign, ...) has no property $sym")
        end
    else
        error("type CINNode has no property $sym")
    end
end

function Base.show(io::IO, mime::MIME"text/plain", node::CINNode) 
    if node.head === with
        display_statement(io, mime, node, 0)
    else
        display_expression(io, mime, node)
    end
end


function Finch.getunbound(ex::CINNode)
    if ex.head === name
        return [ex.name]
    elseif ex.head === loop
        return setdiff(getunbound(ex.body), getunbound(ex.idx))
    elseif ex.head === chunk
        return setdiff(union(getunbound(ex.body), getunbound(ex.ext)), getunbound(ex.idx))
    elseif istree(ex)
        return mapreduce(Finch.getunbound, union, arguments(ex), init=[])
    else
        return []
    end
end

function display_expression(io, mime, node::CINNode)
    if get(io, :compact, false)
        print(io, "@finch(…)")
    elseif node.head === value
        print(io, node.val)
        if node.type !== Any
            print(io, "::")
            print(io, node.type)
        end
    elseif node.head === literal
        print(io, node.val)
    elseif node.head === name
        print(io, node.name)
    elseif node.head === virtual
        print(io, "virtual(")
        print(io, node.val)
        print(io, ")")
    elseif node.head === access
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
    #elseif istree(node)
    #    print(io, operation(node))
    #    print(io, "(")
    #    for arg in arguments(node)[1:end-1]
    #        print(io, arg)
    #        print(io, ",")
    #    end
    #    print(arguments(node)[end])
    else
        error("unimplemented")
    end
end

function display_statement(io, mime, node::CINNode, level)
    if node.head === with
        print(io, tab^level * "(\n")
        display_statement(io, mime, node.cons, level + 1)
        print(io, tab^level * ") where (\n")
        display_statement(io, mime, node.prod, level + 1)
        print(io, tab^level * ")\n")
    elseif node.head === loop
        print(io, tab^level * "@∀ ")
        while node.body.head === loop
            display_expression(io, mime, node.idx)
            print(io," ")
            node = node.body
        end
        print(io,"(\n")
        display_statement(io, mime, node, level + 1)
        print(io, tab^level * ")\n")
    elseif node.head === chunk
        print(io, tab^level * "@∀ ")
        display_expression(io, mime, node.idx)
        print(io, " : ")
        display_expression(io, mime, node.ext)
        print(io," (\n")
        display_statement(io, mime, node.body, level + 1)
        print(io, tab^level * ")\n")
    elseif node.head === sieve
        print(io, tab^level * "@sieve ")
        while node.body.head === sieve
            display_expression(io, mime, node.cond)
            print(io," && ")
            node = node.body
        end
        display_expression(io, mime, node.cond)
        node = node.body
        print(io," (\n")
        display_statement(io, mime, node, level + 1)
        print(io, tab^level * ")\n")
    elseif node.head === assign
        print(io, tab^level)
        display_expression(io, mime, node.lhs)
        print(io, " ")
        if (node.op !== nothing && node.op != literal(nothing)) #TODO this feels kinda garbage.
            display_expression(io, mime, node.op)
        end
        print(io, "= ")
        display_expression(io, mime, node.rhs)
        print(io, "\n")
    else
        error("unimplemented")
    end
end

function Base.:(==)(a::CINNode, b::CINNode)
    if !istree(a)
        if a.head === value
            return b.head === value && a.val == b.val && a.type === b.type
        elseif a.head === literal
            return b.head === literal && isequal(a.val, b.val) #TODO Feels iffy idk
        elseif a.head === name
            return b.head === name && a.name == b.name
        elseif a.head === virtual
            return b.head === virtual && a.val == b.val #TODO Feels iffy idk
        else
            error("unimplemented")
        end
    elseif istree(a)
        return a.head === b.head && a.args == b.args
    else
        return false
    end
end

function Base.hash(a::CINNode, h::UInt)
    if !istree(a)
        if a.head === value
            return hash(value, hash(a.val, hash(a.type, h)))
        elseif a.head === literal
            return hash(literal, hash(a.val, h))
        elseif a.head === virtual
            return hash(virtual, hash(a.val, h))
        elseif a.head === name
            return hash(name, hash(a.name, h))
        else
            error("unimplemented")
        end
    elseif istree(a)
        return hash(a.head, hash(a.args, h))
    else
        return false
    end
end

IndexNotation.isliteral(node::CINNode) = node.head === literal

function Finch.getvalue(ex::CINNode)
    ex.head === literal || error("expected literal")
    ex.val
end

function Finch.getresults(node::CINNode)
    if node.head === with
        Finch.getresults(node.cons)
    elseif node.head === access
        [node.tns]
    elseif node.head === loop
        Finch.getresults(node.body)
    elseif node.head === chunk
        Finch.getresults(node.body)
    elseif node.head === sieve
        Finch.getresults(node.body)
    elseif node.head === assign
        Finch.getresults(node.lhs)
    else
        error("unimplemented")
    end
end

function Finch.getname(x::CINNode)
    if x.head === name
        return x.val
    elseif x.head === virtual
        return Finch.getname(x.val)
    else
        error("unimplemented")
    end
end

function Finch.setname(x::CINNode, sym)
    if x.head === name
        return name(sym)
    elseif x.head === virtual
        return Finch.setname(x.val, sym)
    else
        error("unimplemented")
    end
end


function Base.show(io::IO, mime::MIME"text/plain", stmt::IndexStatement)
    if get(io, :compact, false)
        print(io, "@finch(…)")
    else
        display_statement(io, mime, stmt, 0)
    end
end

function Base.show(io::IO, mime::MIME"text/plain", ex::IndexExpression)
	display_expression(io, mime, ex)
end

display_expression(io, mime, ex) = show(IOContext(io, :compact=>true), mime, ex)

function Base.show(io::IO, ex::IndexNode)
    if istree(ex)
        print(io, operation(ex))
        print(io, "(")
        for arg in arguments(ex)[1:end-1]
            show(io, arg)
            print(io, ", ")
        end
        if length(arguments(ex)) >= 1
            show(io, last(arguments(ex)))
        end
        print(io, ")")
    else
        invoke(show, Tuple{IO, Any}, io, ex)
    end
end

function Base.hash(a::IndexNode, h::UInt)
    if istree(a)
        for arg in arguments(a)
            h = hash(arg, h)
        end
        hash(operation(a), h)
    else
        invoke(hash, Tuple{Any, UInt}, a, h)
    end
end

Finch.IndexNotation.isliteral(ex::IndexNode) =  false
#=
function Base.:(==)(a::T, b::T) with {T <: IndexNode}
    if istree(a) && istree(b)
        (operation(a) == operation(b)) && 
        (arguments(a) == arguments(b))
    else
        invoke(==, Tuple{Any, Any}, a, b)
    end
end
=#

struct Pass <: IndexStatement
	tnss::Vector{IndexNode}
end
Base.:(==)(a::Pass, b::Pass) = Set(a.tnss) == Set(b.tnss) #TODO This feels... not quite right

pass(args...) = pass!(vcat(args...))
pass!(args) = Pass(args)

SyntaxInterface.istree(stmt::Pass) = true
SyntaxInterface.operation(stmt::Pass) = pass
SyntaxInterface.arguments(stmt::Pass) = stmt.tnss
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(pass), args) = pass!(args)

function display_statement(io, mime, stmt::Pass, level)
    print(io, tab^level * "(")
    for tns in arguments(stmt)[1:end-1]
        display_expression(io, mime, tns)
        print(io, ", ")
    end
    if length(arguments(stmt)) >= 1
        display_expression(io, mime, last(arguments(stmt)))
    end
    print(io, ")")
end

Finch.getresults(stmt::Pass) = stmt.tnss

struct Workspace <: IndexTerminal
    n
end

SyntaxInterface.istree(::Workspace) = false
Base.hash(ex::Workspace, h::UInt) = hash((Workspace, ex.n), h)

function display_expression(io, ex::Workspace)
    print(io, "{")
    display_expression(io, mime, ex.n)
    print(io, "}[...]")
end

setname(tns::Workspace, name) = Workspace(name)



struct Protocol{Idx<:IndexNode, Val} <: IndexExpression
    idx::Idx
    val::Val
end
Base.:(==)(a::Protocol, b::Protocol) = a.idx == b.idx && a.val == b.val

protocol(args...) = protocol!(vcat(args...))
protocol!(args) = Protocol(args[1], args[2])

Finch.getname(ex::Protocol) = Finch.getname(ex.idx)
SyntaxInterface.istree(::Protocol) = true
SyntaxInterface.operation(ex::Protocol) = protocol
SyntaxInterface.arguments(ex::Protocol) = Any[ex.idx, ex.val]
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(protocol), args) = protocol!(args)

function display_expression(io, mime, ex::Protocol)
    display_expression(io, mime, ex.idx)
    print(io, "::")
    display_expression(io, mime, ex.val)
end

struct Multi <: IndexStatement
    bodies::Vector{IndexNode}
end
Base.:(==)(a::Multi, b::Multi) = a.bodies == b.bodies

multi(args...) = multi!(vcat(args...))
multi!(args) = Multi(args)

SyntaxInterface.istree(::Multi) = true
SyntaxInterface.operation(stmt::Multi) = multi
SyntaxInterface.arguments(stmt::Multi) = stmt.bodies
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(multi), args) = multi!(args)

function display_statement(io, mime, stmt::Multi, level)
    print(io, tab^level * "begin\n")
    for body in stmt.bodies
        display_statement(io, mime, body, level + 1)
    end
    print(io, tab^level * "end\n")
end

Finch.getresults(stmt::Multi) = mapreduce(Finch.getresults, vcat, stmt.bodies)

struct Call <: IndexExpression
    op::IndexNode
    args::Vector{IndexNode}
end
Base.:(==)(a::Call, b::Call) = a.op == b.op && a.args == b.args

call(args...) = call!(vcat(args...))
call!(args) = Call(popfirst!(args), args)

SyntaxInterface.istree(::Call) = true
SyntaxInterface.operation(ex::Call) = call
SyntaxInterface.arguments(ex::Call) = Any[ex.op; ex.args]
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(call), args) = call!(args)

function display_expression(io, mime, ex::Call)
    display_expression(io, mime, ex.op)
    print(io, "(")
    for arg in ex.args[1:end-1]
        display_expression(io, mime, arg)
        print(io, ", ")
    end
    display_expression(io, mime, ex.args[end])
    print(io, ")")
end

struct Read <: IndexTerminal end
struct Write <: IndexTerminal end
struct Update <: IndexTerminal end
