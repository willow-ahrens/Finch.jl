abstract type MesaIndexNode end
abstract type MesaIndexStatement <: MesaIndexNode end
abstract type MesaIndexExpression <: MesaIndexNode end
abstract type MesaIndexTerminal <: MesaIndexExpression end

const tab = "  "

function Base.show(io::IO, mime::MIME"text/plain", stmt::MesaIndexStatement)
	println(io, "\"\"\"")
	show_statement(io, mime, stmt, 0)
	println(io, "\"\"\"")
end

function Base.show(io::IO, mime::MIME"text/plain", ex::MesaIndexExpression)
	print(io, "\"")
	show_expression(io, mime, ex)
	print(io, "\"")
end

function Base.show(io::IO, ex::MesaIndexNode)
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

struct MesaLiteral{val} <: MesaIndexTerminal
end

mesaliteral(tns) = MesaLiteral{tns}()

virtualize(ex, ::Type{MesaLiteral{val}}) where {val} = Literal(val)

TermInterface.istree(::Type{<:MesaLiteral}) = false

show_expression(io, mime, ex::MesaLiteral{val}) where {val} = print(io, val)

struct MesaPass{Tns} <: MesaIndexStatement
    tns::Tns
end
Base.:(==)(a::MesaPass, b::MesaPass) = a.tns == b.tns

mesapass(tns) = MesaPass(tns)

virtualize(ex, ::Type{MesaPass{Tns}}) where {Tns} = Pass(virtualize(:($ex.tns), Tns))

TermInterface.istree(::Type{<:MesaPass}) = true
TermInterface.operation(stmt::MesaPass) = mesapass
TermInterface.arguments(stmt::MesaPass{tns}) where {tns} = Any[stmt.tns]
TermInterface.similarterm(::MesaIndexNode, ::typeof(mesapass), args, T...) = mesapass(args...)

function show_statement(io, mime, stmt::MesaPass, level)
    print(io, tab^level * "(")
    show_expression(io, mime, stmt.tns)
    print(io, ")")
end

struct MesaName{name} <: MesaIndexTerminal end

mesaname(name) = MesaName{name}()

TermInterface.istree(::Type{<:MesaName}) = false

show_expression(io, mime, ex::MesaName{name}) where {name} = print(io, name)

virtualize(ex, ::Type{MesaName{name}}) where {name} = Name(name)

struct MesaWith{Cons, Prod} <: MesaIndexStatement
	cons::Cons
	prod::Prod
end
Base.:(==)(a::MesaWith, b::MesaWith) = a.cons == b.cons && a.prod == b.prod

mesawith(cons, prod) = With(cons, prod)

TermInterface.istree(::Type{<:MesaWith}) = true
TermInterface.operation(stmt::MesaWith) = mesawith
TermInterface.arguments(stmt::MesaWith) = Any[stmt.cons, stmt.prod]
TermInterface.similarterm(::MesaIndexNode, ::typeof(mesawith), args, T...) = mesawith(args...)

function show_statement(io, mime, stmt::MesaWith, level)
    print(io, tab^level * "(\n")
    show_statement(io, mime, stmt.cons, level + 1)
    print(io, tab^level * ") where (\n")
    show_statement(io, mime, stmt.prod, level + 1)
    print(io, tab^level * ")\n")
end

virtualize(ex, ::Type{MesaWith{Cons, Prod}}) where {Cons, Prod} = With(virtualize(:($ex.cons), Cons), virtualize(:($ex.prod), Prod))

struct MesaLoop{Idxs<:Tuple, Body} <: MesaIndexStatement
	idxs::Idxs
	body::Body
end
Base.:(==)(a::MesaLoop, b::MesaLoop) = a.idxs == b.idxs && a.body == b.body

mesaloop(args...) = MesaLoop((args[1:end-1]...,), args[end])

TermInterface.istree(::Type{<:MesaLoop}) = true
TermInterface.operation(stmt::MesaLoop) = mesaloop
TermInterface.arguments(stmt::MesaLoop) = Any[stmt.idxs; stmt.body]
TermInterface.similarterm(::MesaIndexNode, ::typeof(mesaloop), args, T...) = mesaloop(args...)

function show_statement(io, mime, stmt::MesaLoop, level)
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

function virtualize(ex, ::Type{MesaLoop{Idxs, Body}}) where {Idxs, Body}
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($ex.idxs[$n]), Idx)
    end
    body = virtualize(:($ex.body), Body)
    MesaLoop(idxs, body)
end

struct MesaAssign{Lhs, Op, Rhs} <: MesaIndexStatement
	lhs::Lhs
	op::Op
	rhs::Rhs
end
Base.:(==)(a::MesaAssign, b::MesaAssign) = a.lhs == b.lhs && a.op == b.op && a.rhs == b.rhs

mesaassign(lhs, rhs) = MesaAssign(lhs, nothing, rhs)
mesaassign(lhs, op, rhs) = MesaAssign(lhs, op, rhs)

TermInterface.istree(::Type{<:MesaAssign})= true
TermInterface.operation(stmt::MesaAssign) = mesaassign
function TermInterface.arguments(stmt::MesaAssign)
    if stmt.op === nothing
        Any[stmt.lhs, stmt.rhs]
    else
        Any[stmt.lhs, stmt.op, stmt.rhs]
    end
end
TermInterface.similarterm(::MesaIndexNode, ::typeof(mesaassign), args, T...) = mesaassign(args...)

function show_statement(io, mime, stmt::MesaAssign, level)
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

function virtualize(ex, ::Type{MesaAssign{Lhs, Nothing, Rhs}}) where {Lhs, Rhs}
    Assign(virtualize(:($ex.lhs), Lhs), nothing, virtualize(:($ex.rhs), Rhs))
end

function virtualize(ex, ::Type{MesaAssign{Lhs, Op, Rhs}}) where {Lhs, Op, Rhs}
    Assign(virtualize(:($ex.lhs), Lhs), virtualize(:($ex.op), Op), virtualize(:($ex.rhs), Rhs))
end

struct MesaCall{Op, Args<:Tuple} <: MesaIndexExpression
    op::Op
    args::Args
end
Base.:(==)(a::MesaCall, b::MesaCall) = a.op == b.op && a.args == b.args

mesacall(op, args...) = MesaCall(op, args)

TermInterface.istree(::Type{<:MesaCall}) = true
TermInterface.operation(ex::MesaCall) = mesacall
TermInterface.arguments(ex::MesaCall) = Any[ex.op; ex.args]
TermInterface.similarterm(::MesaIndexNode, ::typeof(mesacall), args, T...) = mesacall(args...)

function show_expression(io, mime, ex::MesaCall)
    show_expression(io, mime, ex.op)
    print(io, "(")
    for arg in ex.args[1:end-1]
        show_expression(io, mime, arg)
        print(io, ", ")
    end
    show_expression(io, mime, ex.args[end])
    print(io, ")")
end

function virtualize(ex, ::Type{MesaCall{Op, Args}}) where {Op, Args}
    op = virtualize(:($ex.op), Op)
    args = map(enumerate(Args.parameters)) do (n, Arg)
        virtualize(:($ex.args[$n]), Arg)
    end
    Call(op, args)
end

struct MesaAccess{Tns, Mode, Idxs} <: MesaIndexExpression
    tns::Tns
    mode::Mode
    idxs::Idxs
end
Base.:(==)(a::MesaAccess, b::MesaAccess) = a.tns == b.tns && a.mode == b.mode && a.idxs == b.idxs

mesaaccess(tns, mode, idxs...) = MesaAccess(tns, mode, idxs)

TermInterface.istree(::Type{<:MesaAccess}) = true
TermInterface.operation(ex::MesaAccess) = mesaaccess
TermInterface.arguments(ex::MesaAccess) = Any[ex.tns; ex.mode; ex.idxs]
TermInterface.similarterm(::MesaIndexNode, ::typeof(mesaaccess), args, T...) = mesaaccess!(args)

function show_expression(io, mime, ex::MesaAccess)
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

function virtualize(ex, ::Type{MesaAccess{Tns, Mode, Idxs}}) where {Tns, Mode, Idxs}
    tns = virtualize(:($ex.tns), Tns)
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($ex.idxs[$n]), Idx)
    end
    Access(tns, _virtualize_mode(Mode), idxs)
end

_virtualize_mode(::Type{Read}) = Read()
_virtualize_mode(::Type{Write}) = Write()
_virtualize_mode(::Type{Update}) = Update()

struct MesaValue{arg} end

mesavalue(arg) = isbits(arg) ? MesaValue{arg}() : arg
mesavalue(arg::Symbol) = MesaValue{arg}()

TermInterface.istree(::Type{<:MesaValue}) = false

virtualize(ex, ::Type{MesaValue{arg}}) where {arg} = arg

#TODO following code should be merged with code in Pigeon

function capture_index(ex; ctx...)
    incs = Dict(:+= => :+, :*= => :*, :/= => :/, :^= => :^)

    if ex isa Expr && ex.head == :macrocall && length(ex.args) >= 2 && ex.args[1] == Symbol("@pass")
        args = map(arg -> capture_index(arg; ctx..., namify=true), ex.args[3:end])
        return :(mesapass($(args...)))
    elseif ex isa Expr && ex.head == :macrocall && length(ex.args) >= 3 && ex.args[1] in [Symbol("@loop"), Symbol("@∀")]
        idxs = map(arg -> capture_index(arg; ctx..., namify=true), ex.args[3:end-1])
        body = capture_index(ex.args[end]; ctx...)
        return :(mesaloop($(idxs...), $body))
    elseif ex isa Expr && ex.head == :where && length(ex.args) == 2
        cons = capture_index(ex.args[1]; ctx...)
        prod = capture_index(ex.args[2]; ctx...)
        return :(mesawith($cons, $prod))
    elseif ex isa Expr && ex.head == :(=) && length(ex.args) == 2
        lhs = capture_index(ex.args[1]; ctx..., mode=Write())
        rhs = capture_index(ex.args[2]; ctx...)
        return :(mesaassign($lhs, $rhs))
    elseif ex isa Expr && haskey(incs, ex.head) && length(ex.args) == 2
        lhs = capture_index(ex.args[1]; ctx..., mode=Update())
        rhs = capture_index(ex.args[2]; ctx...)
        op = capture_index(incs[ex.head]; ctx..., namify=false, literalize=true)
        return :(mesaassign($lhs, $op, $rhs))
    elseif ex isa Expr && ex.head == :comparison && length(ex.args) == 5 && ex.args[2] == :< && ex.args[4] == :>=
        lhs = capture_index(ex.args[1]; ctx..., mode=Update())
        op = capture_index(ex.args[3]; ctx..., namify=false, literalize=true)
        rhs = capture_index(ex.args[5]; ctx...)
        return :(mesaassign($lhs, $op, $rhs))
    elseif values(ctx).slot && ex isa Expr && ex.head == :call && length(ex.args) == 2 && ex.args[1] == :~ &&
        ex.args[2] isa Symbol
        return esc(ex)
    elseif values(ctx).slot && ex isa Expr && ex.head == :call && length(ex.args) == 2 && ex.args[1] == :~ &&
        ex.args[2] isa Expr && ex.args[2].head == :call && length(ex.args[2].args) == 2 && ex.args[2].args[1] == :~ &&
        ex.args[2].args[2] isa Symbol
        return esc(ex)
    elseif ex isa Expr && ex.head == :call && length(ex.args) >= 1
        op = capture_index(ex.args[1]; ctx..., namify=false, mode=Read())
        println(op)
        return :(mesacall($op, $(map(arg->capture_index(arg; ctx..., namify=true, mode=Read()), ex.args[2:end])...)))
    elseif ex isa Expr && ex.head == :ref && length(ex.args) >= 1
        tns = capture_index(ex.args[1]; ctx..., namify=false, mode=Read())
        return :(mesaaccess($tns, $(values(ctx).mode), $(map(arg->capture_index(arg; ctx..., namify=true, mode=Read()), ex.args[2:end])...)))
    elseif ex isa Expr && ex.head == :$ && length(ex.args) == 1
        return esc(ex.args[1])
    elseif ex isa Symbol && values(ctx).namify
        return mesaname(ex)
    else
        return :(mesavalue($(esc(ex))))
    end
end

macro I(ex)
    return capture_index(ex; namify=true, slot = true, mode = Read())
end