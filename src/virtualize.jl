struct Virtual{T}
    ex
end

virtualize(ex, T; kwargs...) = Virtual{T}(ex)

TermInterface.istree(::Type{<:Virtual}) = false

Pigeon.isliteral(::Virtual) = false

abstract type MesaIndexNode end
abstract type MesaIndexStatement <: MesaIndexNode end
abstract type MesaIndexExpression <: MesaIndexNode end
abstract type MesaIndexTerminal <: MesaIndexExpression end

struct MesaLiteral{val} <: MesaIndexTerminal
end

mesaliteral(tns) = MesaLiteral{tns}()

virtualize(ex, ::Type{MesaLiteral{val}}; kwargs...) where {val} = Literal(val)

struct MesaPass{Tns} <: MesaIndexStatement
    tns::Tns
end
Base.:(==)(a::MesaPass, b::MesaPass) = a.tns == b.tns

mesapass(tns) = MesaPass(tns)

virtualize(ex, ::Type{MesaPass{Tns}}; kwargs...) where {Tns} = Pass(virtualize(:($ex.tns), Tns))

struct MesaName{name} <: MesaIndexTerminal end

mesaname(name) = MesaName{name}()

virtualize(ex, ::Type{MesaName{name}}; kwargs...) where {name} = Name(name)

struct MesaWith{Cons, Prod} <: MesaIndexStatement
	cons::Cons
	prod::Prod
end
Base.:(==)(a::MesaWith, b::MesaWith) = a.cons == b.cons && a.prod == b.prod

mesawith(cons, prod) = With(cons, prod)

virtualize(ex, ::Type{MesaWith{Cons, Prod}}; kwargs...) where {Cons, Prod} = With(virtualize(:($ex.cons), Cons), virtualize(:($ex.prod), Prod))

struct MesaLoop{Idxs<:Tuple, Body} <: MesaIndexStatement
	idxs::Idxs
	body::Body
end
Base.:(==)(a::MesaLoop, b::MesaLoop) = a.idxs == b.idxs && a.body == b.body

mesaloop(args...) = MesaLoop((args[1:end-1]...,), args[end])

function virtualize(ex, ::Type{MesaLoop{Idxs, Body}}; kwargs...) where {Idxs, Body}
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($ex.idxs[$n]), Idx)
    end
    body = virtualize(:($ex.body), Body)
    Loop(idxs, body)
end

struct MesaAssign{Lhs, Op, Rhs} <: MesaIndexStatement
	lhs::Lhs
	op::Op
	rhs::Rhs
end
Base.:(==)(a::MesaAssign, b::MesaAssign) = a.lhs == b.lhs && a.op == b.op && a.rhs == b.rhs

mesaassign(lhs, rhs) = MesaAssign(lhs, nothing, rhs)
mesaassign(lhs, op, rhs) = MesaAssign(lhs, op, rhs)

function virtualize(ex, ::Type{MesaAssign{Lhs, Nothing, Rhs}}; kwargs...) where {Lhs, Rhs}
    Assign(virtualize(:($ex.lhs), Lhs), nothing, virtualize(:($ex.rhs), Rhs))
end

function virtualize(ex, ::Type{MesaAssign{Lhs, Op, Rhs}}; kwargs...) where {Lhs, Op, Rhs}
    Assign(virtualize(:($ex.lhs), Lhs), virtualize(:($ex.op), Op), virtualize(:($ex.rhs), Rhs))
end

struct MesaCall{Op, Args<:Tuple} <: MesaIndexExpression
    op::Op
    args::Args
end
Base.:(==)(a::MesaCall, b::MesaCall) = a.op == b.op && a.args == b.args

mesacall(op, args...) = MesaCall(op, args)

function virtualize(ex, ::Type{MesaCall{Op, Args}}; kwargs...) where {Op, Args}
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

show_expression(io, mime, ex) = print(io, ex)

function virtualize(ex, ::Type{MesaAccess{Tns, Mode, Idxs}}; kwargs...) where {Tns, Mode, Idxs}
    tns = virtualize(:($ex.tns), Tns)
    idxs = map(enumerate(Idxs.parameters)) do (n, Idx)
        virtualize(:($ex.idxs[$n]), Idx)
    end
    Access(tns, virtualize(:($ex.mode), Mode), idxs)
end

virtualize(ex, ::Type{Read}; kwargs...) = Read()
virtualize(ex, ::Type{Write}; kwargs...) = Write()
virtualize(ex, ::Type{Update}; kwargs...) = Update()

struct MesaLabel{tag, Tns} <: MesaIndexExpression
    tns::Tns
end
Base.:(==)(a::MesaLabel, b::MesaLabel) = false
Base.:(==)(a::MesaLabel{tag}, b::MesaLabel{tag}) where {tag} = a.tns == b.tns

mesalabel(tag, tns) = MesaLabel{tag, typeof(tns)}(tns)

function virtualize(ex, ::Type{MesaLabel{tag, Tns}}; kwargs...) where {tag, Tns}
    return virtualize(:($ex.tns), Tns, tag=tag)
end

struct MesaValue{arg} end

mesavalue(arg) = isbits(arg) ? MesaValue{arg}() : arg
mesavalue(arg::Symbol) = MesaValue{arg}()

virtualize(ex, ::Type{MesaValue{arg}}; kwargs...) where {arg} = arg

#TODO following code should be merged with the code in Pigeon. Not good to copy
#paste. We'll do this when we reorganize Finch to be the package which defines
#index expressions.

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
        return :(mesacall($op, $(map(arg->capture_index(arg; ctx..., namify=true, mode=Read()), ex.args[2:end])...)))
    elseif ex isa Expr && ex.head == :ref && length(ex.args) >= 1
        tns = capture_index(ex.args[1]; ctx..., namify=false, mode=Read())
        return :(mesaaccess($tns, $(values(ctx).mode), $(map(arg->capture_index(arg; ctx..., namify=true, mode=Read()), ex.args[2:end])...)))
    elseif ex isa Expr && ex.head == :$ && length(ex.args) == 1
        return esc(ex.args[1])
    elseif ex isa Symbol && values(ctx).namify
        return mesaname(ex)
    elseif ex isa Symbol
        return :(mesalabel($(QuoteNode(ex)), mesavalue($(esc(ex)))))
    else
        return :(mesavalue($(esc(ex))))
    end
end

macro I(ex)
    return capture_index(ex; namify=true, slot = true, mode = Read())
end
