using Base: Symbol
using SymbolicUtils
using SymbolicUtils: arguments, operation, istree
using SymbolicUtils: Fixpoint, Chain, Postwalk

abstract type ConcreteNode end
abstract type ConcreteStatement <: ConcreteNode end
abstract type ConcreteExpression <: ConcreteNode end

const tab = "  "

function Base.show(io::IO, stmt::ConcreteStatement)
	print(io, "\"\"\"\n")
	show_statement(io, stmt, 0)
	print(io, "\"\"\"\n")
end

function Base.show(io::IO, ex::ConcreteExpression)
	print(io, "\"")
	show_expression(io, ex)
	print(io, "\"")
end

function postorder(f, node::ConcreteNode)
    if istree(node)
        f(operation(node)(map(child->postorder(f, child), arguments(node))...))
    else
        f(node)
    end
end
function postorder(f, node::SymbolicUtils.Term)
    f(term(operation(node), map(child->postorder(f, child), arguments(node))...))
end
Base.map(f, node::ConcreteNode) = postorder(f, node)

termify(node::SymbolicUtils.Term) = node
function termify(node::ConcreteNode)
    if istree(node)
        return term(operation(node), map(termify, arguments(node))...)
    else
        return node
    end
end

determify(node) = node
determify(node::SymbolicUtils.Term) = operation(node)(map(determify, arguments(node))...)

struct Forall <: ConcreteStatement
	idx
	body
end

Forall(idx1, idx2, args...) = Forall(idx1, Forall(idx2, args...))

SymbolicUtils.istree(stmt::Forall) = true
SymbolicUtils.operation(stmt::Forall) = Forall
SymbolicUtils.arguments(stmt::Forall) = [stmt.idx, stmt.body]

function show_statement(io, stmt::Forall, level)
    print(io, tab^level * "∀ ")
    show_expression(io, stmt.idx)
    print(io," \n")
    show_statement(io, stmt.body, level + 1)
end

struct Index <: ConcreteExpression
    name
end

SymbolicUtils.istree(ex::Index) = false

show_expression(io, ex::Index) = print(io, ex.name)

struct Where <: ConcreteStatement
	cons
	prod
end

SymbolicUtils.istree(stmt::Where) = true
SymbolicUtils.operation(stmt::Where) = Where
SymbolicUtils.arguments(stmt::Where) = [stmt.cons, stmt.prod]

function show_statement(io, stmt::Where, level)
    print(io, tab^level * "(\n")
    show_statement(io, stmt.cons, level + 1)
    print(io, "\n" * tab^level * "where\n")
    show_statement(io, stmt.prod, level + 1)
    print(io, tab^level * ")\n")
end

struct Assign <: ConcreteStatement
	lhs
	op
	rhs
    Assign(lhs, op, rhs) = new(lhs, op, rhs)
    Assign(lhs, rhs) = new(lhs, nothing, rhs)
end

SymbolicUtils.istree(stmt::Assign) = true
SymbolicUtils.operation(stmt::Assign) = Assign
function SymbolicUtils.arguments(stmt::Assign)
    if stmt.op === nothing
        [stmt.lhs, stmt.rhs]
    else
        [stmt.lhs, stmt.op, stmt.rhs]
    end
end

function show_statement(io, stmt::Assign, level)
    print(io, tab^level)
    show_expression(io, stmt.lhs)
    print(io, " ")
    if stmt.op !== nothing
        show_expression(io, stmt.op)
    end
    print(io, "= ")
    show_expression(io, stmt.rhs)
    print(io, "\n")
end

struct Operator <: ConcreteExpression
    name
end

SymbolicUtils.istree(ex::Operator) = false
Base.nameof(ex::Operator) = typeof(ex)
Base.isbinaryoperator(::Type{Operator}) = false

show_expression(io, ex::Operator) = print(io, ex.name)

struct Call <: ConcreteExpression
    f
    args
    Call(f, args...) = new(f, args)
end

(f::Operator)(args...) = Call(f, args...)

SymbolicUtils.istree(ex::Call) = true
SymbolicUtils.operation(ex::Call) = ex.f
SymbolicUtils.arguments(ex::Call) = [ex.args...]

function show_expression(io, ex::Call)
    show_expression(io, ex.f)
    print(io, "(")
    for arg in ex.args[1:end-1]
        show_expression(io, arg)
        print(io, ", ")
    end
    show_expression(io, ex.args[end])
    print(io, ")")
end

struct Tensor <: ConcreteExpression
    name
    fmt
end

SymbolicUtils.istree(ex::Tensor) = false
Base.nameof(ex::Tensor) = typeof(ex)
Base.isbinaryoperator(::Type{Tensor}) = false

show_expression(io, ex::Tensor) = print(io, ex.name)

struct Access <: ConcreteExpression
    tns
    idxs
    Access(tns, idxs...) = new(tns, idxs)
end

(tns::Tensor)(idxs...) = Access(tns, idxs...)

SymbolicUtils.istree(ex::Access) = true
SymbolicUtils.operation(ex::Access) = ex.tns
SymbolicUtils.arguments(ex::Access) = [ex.idxs...]

function show_expression(io, ex::Access)
    show_expression(io, ex.tns)
    print(io, "[")
    if length(ex.idxs) >= 1
        for idx in ex.idxs[1:end-1]
            show_expression(io, idx)
            print(io, ", ")
        end
        show_expression(io, ex.idxs[end])
    end
    print(io, "]")
end

show_expression(io, ex) = print(io, ex)