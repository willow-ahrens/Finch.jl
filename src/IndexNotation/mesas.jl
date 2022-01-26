abstract type MesaIndexNode end
abstract type MesaIndexStatement <: MesaIndexNode end
abstract type MesaIndexExpression <: MesaIndexNode end
abstract type MesaIndexTerminal <: MesaIndexExpression end

struct MesaLiteral{val} <: MesaIndexTerminal
end

@inline mesaliteral(tns) = MesaLiteral{tns}()

struct MesaPass{Tns} <: MesaIndexStatement
    tns::Tns
end
Base.:(==)(a::MesaPass, b::MesaPass) = a.tns == b.tns

@inline mesapass(tns) = MesaPass(tns)

struct MesaName{name} <: MesaIndexTerminal end

@inline mesaname(name) = MesaName{name}()

struct MesaWith{Cons, Prod} <: MesaIndexStatement
	cons::Cons
	prod::Prod
end
Base.:(==)(a::MesaWith, b::MesaWith) = a.cons == b.cons && a.prod == b.prod

@inline mesawith(cons, prod) = With(cons, prod)

struct MesaLoop{Idxs<:Tuple, Body} <: MesaIndexStatement
	idxs::Idxs
	body::Body
end
Base.:(==)(a::MesaLoop, b::MesaLoop) = a.idxs == b.idxs && a.body == b.body

@inline mesaloop(args...) = MesaLoop((args[1:end-1]...,), args[end])

struct MesaAssign{Lhs, Op, Rhs} <: MesaIndexStatement
	lhs::Lhs
	op::Op
	rhs::Rhs
end
Base.:(==)(a::MesaAssign, b::MesaAssign) = a.lhs == b.lhs && a.op == b.op && a.rhs == b.rhs

@inline mesaassign(lhs, rhs) = MesaAssign(lhs, nothing, rhs)
@inline mesaassign(lhs, op, rhs) = MesaAssign(lhs, op, rhs)

struct MesaCall{Op, Args<:Tuple} <: MesaIndexExpression
    op::Op
    args::Args
end
Base.:(==)(a::MesaCall, b::MesaCall) = a.op == b.op && a.args == b.args

@inline mesacall(op, args...) = MesaCall(op, args)

struct MesaAccess{Tns, Mode, Idxs} <: MesaIndexExpression
    tns::Tns
    mode::Mode
    idxs::Idxs
end
Base.:(==)(a::MesaAccess, b::MesaAccess) = a.tns == b.tns && a.mode == b.mode && a.idxs == b.idxs

@inline mesaaccess(tns, mode, idxs...) = MesaAccess(tns, mode, idxs)

struct MesaLabel{tag, Tns} <: MesaIndexExpression
    tns::Tns
end
Base.:(==)(a::MesaLabel, b::MesaLabel) = false
Base.:(==)(a::MesaLabel{tag}, b::MesaLabel{tag}) where {tag} = a.tns == b.tns

@inline mesalabel(tag, tns) = MesaLabel{tag, typeof(tns)}(tns)

struct MesaValue{arg} end

@inline mesavalue(arg) = isbits(arg) ? MesaValue{arg}() : arg
@inline mesavalue(arg::Symbol) = MesaValue{arg}()