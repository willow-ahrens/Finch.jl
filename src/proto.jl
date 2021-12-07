abstract type ProtoIndexNode end
abstract type ProtoIndexStatement <: ProtoIndexNode end
abstract type ProtoIndexExpression <: ProtoIndexNode end
abstract type ProtoIndexTerminal <: ProtoIndexExpression end

const tab = "  "

function Base.show(io::IO, mime::MIME"text/plain", stmt::ProtoIndexStatement)
	println(io, "\"\"\"")
	show_statement(io, mime, stmt, 0)
	println(io, "\"\"\"")
end

function Base.show(io::IO, mime::MIME"text/plain", ex::ProtoIndexExpression)
	print(io, "\"")
	show_expression(io, mime, ex)
	print(io, "\"")
end

function Base.show(io::IO, ex::ProtoIndexNode)
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

struct ProtoLiteral{val} <: ProtoIndexTerminal
end

protoliteral(tns) = ProtoLiteral{tns}()

virtualize(ex, ::Type{ProtoLiteral{val}}) where {val} = Literal(val)

TermInterface.istree(::Type{<:ProtoLiteral}) = false

show_expression(io, mime, ex::ProtoLiteral{val}) where {val} = print(io, val)

struct ProtoPass{Tns} <: ProtoIndexStatement
    tns::Tns
end
Base.:(==)(a::ProtoPass, b::ProtoPass) = a.tns == b.tns

protopass(tns) = ProtoPass(tns)

virtualize(ex, ::Type{ProtoPass{Tns}}) where {Tns} = Pass(virtualize(:($ex.tns), Tns))

TermInterface.istree(::Type{<:ProtoPass}) = true
TermInterface.operation(stmt::ProtoPass) = protopass
TermInterface.arguments(stmt::ProtoPass{tns}) where {tns} = Any[stmt.tns]
TermInterface.similarterm(::ProtoIndexNode, ::typeof(protopass), args, T...) = protopass(args...)

function show_statement(io, mime, stmt::ProtoPass, level)
    print(io, tab^level * "(")
    show_expression(io, mime, stmt.tns)
    print(io, ")")
end

struct ProtoName{name} <: ProtoIndexTerminal end

TermInterface.istree(::Type{<:ProtoName}) = false

show_expression(io, mime, ex::ProtoName{name}) where {name} = print(io, name)

virtualize(ex, ::Type{ProtoName{name}}) where {name} = Name()

struct ProtoWith{Cons, Prod} <: ProtoIndexStatement
	cons::Cons
	prod::Prod
end
Base.:(==)(a::ProtoWith, b::ProtoWith) = a.cons == b.cons && a.prod == b.prod

protowith(cons, prod) = With(cons, prod)

TermInterface.istree(::Type{<:ProtoWith}) = true
TermInterface.operation(stmt::ProtoWith) = protowith
TermInterface.arguments(stmt::ProtoWith) = Any[stmt.cons, stmt.prod]
TermInterface.similarterm(::ProtoIndexNode, ::typeof(protowith), args, T...) = protowith(args...)

function show_statement(io, mime, stmt::ProtoWith, level)
    print(io, tab^level * "(\n")
    show_statement(io, mime, stmt.cons, level + 1)
    print(io, tab^level * ") where (\n")
    show_statement(io, mime, stmt.prod, level + 1)
    print(io, tab^level * ")\n")
end

virtualize(ex, ::Type{ProtoWith{Cons, Prod}}) where {Cons, Prod} = With(virtualize(:($ex.cons), Cons), virtualize(:($ex.prod), Prod))

struct ProtoLoop{Idxs<:Tuple, Body} <: ProtoIndexStatement
	idxs::Idxs
	body::Body
end
Base.:(==)(a::ProtoLoop, b::ProtoLoop) = a.idxs == b.idxs && a.body == b.body

protoloop(args...) = ProtoLoop((args[1:end-1]...,), args[end])

TermInterface.istree(::Type{<:ProtoLoop}) = true
TermInterface.operation(stmt::ProtoLoop) = protoloop
TermInterface.arguments(stmt::ProtoLoop) = Any[stmt.idxs; stmt.body]
TermInterface.similarterm(::ProtoIndexNode, ::typeof(protoloop), args, T...) = protoloop(args...)

function show_statement(io, mime, stmt::ProtoLoop, level)
    print(io, tab^level * "@∀ ")
    if !isempty(stmt.idxs)
        show_expression(io, mime, stmt.idxs[1])
        for idx in stmt.idxs[2:end]
            print(io," ")
            show_expression(io, mime, idx)
        end
    end
    print(io," (\n")
    show_statement(io, mime, stmt.body, level + 1)
    print(io, tab^level * ")\n")
end

function virtualize(ex, ::Type{ProtoLoop{Idxs, Body}}) where {Idxs, Body}
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($ex.idxs[$n]), Idx)
    end
    body = virtualize(:($ex.body), Body)
    ProtoLoop(idxs, body)
end

struct ProtoAssign{Lhs, Op, Rhs} <: ProtoIndexStatement
	lhs::Lhs
	op::Op
	rhs::Rhs
end
Base.:(==)(a::ProtoAssign, b::ProtoAssign) = a.lhs == b.lhs && a.op == b.op && a.rhs == b.rhs

protoassign(lhs, rhs) = ProtoAssign(lhs, nothing, rhs)
protoassign(lhs, op, rhs) = ProtoAssign(lhs, op, rhs)

TermInterface.istree(::Type{<:ProtoAssign})= true
TermInterface.operation(stmt::ProtoAssign) = protoassign
function TermInterface.arguments(stmt::ProtoAssign)
    if stmt.op === nothing
        Any[stmt.lhs, stmt.rhs]
    else
        Any[stmt.lhs, stmt.op, stmt.rhs]
    end
end
TermInterface.similarterm(::ProtoIndexNode, ::typeof(protoassign), args, T...) = protoassign(args...)

function show_statement(io, mime, stmt::ProtoAssign, level)
    print(io, tab^level)
    show_expression(io, mime, stmt.lhs)
    print(io, " ")
    if stmt.op !== nothing
        show_expression(io, mime, stmt.op)
    end
    print(io, "= ")
    show_expression(io, mime, stmt.rhs)
    print(io, "\n")
end

function virtualize(ex, ::Type{ProtoAssign{Lhs, Nothing, Rhs}}) where {Lhs, Rhs}
    Assign(virtualize(:($ex.lhs), Lhs), nothing, virtualize(:($ex.rhs), Rhs)
end

function virtualize(ex, ::Type{ProtoAssign{Lhs, Op, Rhs}}) where {Lhs, Op, Rhs}
    Assign(virtualize(:($ex.lhs), Lhs), virtualize(:($ex.op), Op), virtualize(:($ex.rhs), Rhs)
end

struct ProtoCall{Op, Args<:Tuple} <: ProtoIndexExpression
    op::Op
    args::Args
end
Base.:(==)(a::ProtoCall, b::ProtoCall) = a.op == b.op && a.args == b.args

protocall(op, args...) = ProtoCall(op, args)

TermInterface.istree(::Type{<:ProtoCall}) = true
TermInterface.operation(ex::ProtoCall) = protocall
TermInterface.arguments(ex::ProtoCall) = Any[ex.op; ex.args]
TermInterface.similarterm(::ProtoIndexNode, ::typeof(protocall), args, T...) = protocall(args...)

function show_expression(io, mime, ex::ProtoCall)
    show_expression(io, mime, ex.op)
    print(io, "(")
    for arg in ex.args[1:end-1]
        show_expression(io, mime, arg)
        print(io, ", ")
    end
    show_expression(io, mime, ex.args[end])
    print(io, ")")
end

function virtualize(ex, ::Type{ProtoCall{Op, Args}}) where {Op, Args}
    op = virtualize(:($ex.op), Op)
    args = map(enumerate(Args.parameters)) do (n, Arg)
        virtualize(:($ex.args[$n]), Arg)
    end
    ProtoCall(op, args)
end

struct ProtoAccess{Tns, Mode, Idxs} <: ProtoIndexExpression
    tns::Tns
    mode::Mode
    idxs::Idxs
end
Base.:(==)(a::ProtoAccess, b::ProtoAccess) = a.tns == b.tns && a.mode == b.mode && a.idxs == b.idxs

protoaccess(tns, mode, idxs...) = ProtoAccess(tns, mode, idxs...)

TermInterface.istree(::Type{<:ProtoAccess}) = true
TermInterface.operation(ex::ProtoAccess) = protoaccess
TermInterface.arguments(ex::ProtoAccess) = Any[ex.tns; ex.mode; ex.idxs]
TermInterface.similarterm(::ProtoIndexNode, ::typeof(protoaccess), args, T...) = protoaccess!(args)

function show_expression(io, mime, ex::ProtoAccess)
    show_expression(io, mime, ex.tns)
    print(io, "[")
    if length(ex.idxs) >= 1
        for idx in ex.idxs[1:end-1]
            show_expression(io, mime, idx)
            print(io, ", ")
        end
        show_expression(io, mime, ex.idxs[end])
    end
    print(io, "]")
end

show_expression(io, mime, ex) = print(io, ex)

function virtualize(ex, ::Type{ProtoAccess{Tns, Idxs}}) where {Tns, Idxs}
    tns = virtualize(:($ex.tns), Tns)
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($ex.idxs[$n]), Idx)
    end
    ProtoCall(tns, idxs)
end