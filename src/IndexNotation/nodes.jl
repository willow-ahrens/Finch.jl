abstract type IndexNode end
abstract type IndexStatement <: IndexNode end
abstract type IndexExpression <: IndexNode end
abstract type IndexTerminal <: IndexExpression end

const tab = "  "

function Base.show(io::IO, mime::MIME"text/plain", stmt::IndexStatement)
	println(io, "\"\"\"")
	show_statement(io, mime, stmt, 0)
	println(io, "\"\"\"")
end

function Base.show(io::IO, mime::MIME"text/plain", ex::IndexExpression)
	print(io, "\"")
	show_expression(io, mime, ex)
	print(io, "\"")
end

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
        error()
        invoke(hash, Tuple{Any, UInt}, a, h)
    end
end

Finch.isliteral(ex::IndexNode) = false
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

struct Literal <: IndexTerminal
    val
end

SyntaxInterface.istree(::Literal) = false
Base.hash(ex::Literal, h::UInt) = hash(Literal, hash(ex.val, h))
show_expression(io, mime, ex::Literal) = print(io, ex.val)
Finch.isliteral(ex::Literal) = true
Finch.getvalue(ex::Literal) = ex.val

struct Virtual{T} <: IndexTerminal
    ex
end

Base.:(==)(a::Virtual, b::Virtual) = false
Base.:(==)(a::Virtual{T}, b::Virtual{T}) where {T} = a.ex == b.ex
Base.hash(ex::Virtual{T}, h::UInt) where {T} = hash(Virtual{T}, hash(ex.ex, h))

SyntaxInterface.istree(::Virtual) = false

isliteral(::Virtual) = false

struct Pass <: IndexStatement
	tnss::Vector{Any}
end
Base.:(==)(a::Pass, b::Pass) = Set(a.tnss) == Set(b.tnss) #TODO This feels... not quite right

pass(args...) = pass!(vcat(args...))
pass!(args) = Pass(args)

SyntaxInterface.istree(stmt::Pass) = true
SyntaxInterface.operation(stmt::Pass) = pass
SyntaxInterface.arguments(stmt::Pass) = stmt.tnss
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(pass), args) = pass!(args)

function show_statement(io, mime, stmt::Pass, level)
    print(io, tab^level * "(")
    for tns in arguments(stmt)[1:end-1]
        show_expression(io, mime, tns)
        print(io, ", ")
    end
    if length(arguments(stmt)) >= 1
        show_expression(io, mime, last(arguments(stmt)))
    end
    print(io, ")")
end

Finch.getresults(stmt::Pass) = stmt.tnss

struct Workspace <: IndexTerminal
    n
end

SyntaxInterface.istree(::Workspace) = false
Base.hash(ex::Workspace, h::UInt) = hash((Workspace, ex.n), h)

function show_expression(io, ex::Workspace)
    print(io, "{")
    show_expression(io, mime, ex.n)
    print(io, "}[...]")
end

setname(tns::Workspace, name) = Workspace(name)

struct Name <: IndexTerminal
    name
end

SyntaxInterface.istree(::Name) = false
Base.hash(ex::Name, h::UInt) = hash((Name, ex.name), h)

show_expression(io, mime, ex::Name) = print(io, ex.name)

Finch.getname(ex::Name) = ex.name
Finch.setname(ex::Name, name) = Name(name)
Finch.getunbound(ex::Name) = [ex.name]

struct Protocol{Idx, Val} <: IndexExpression
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

function show_expression(io, mime, ex::Protocol)
    show_expression(io, mime, ex.idx)
    print(io, "::")
    show_expression(io, mime, ex.val)
end

struct With <: IndexStatement
	cons::Any
	prod::Any
end
Base.:(==)(a::With, b::With) = a.cons == b.cons && a.prod == b.prod

with(args...) = with!(vcat(args...))
with!(args) = With(args[1], args[2])

SyntaxInterface.istree(::With) = true
SyntaxInterface.operation(stmt::With) = with
SyntaxInterface.arguments(stmt::With) = Any[stmt.cons, stmt.prod]
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(with), args) = with!(args)

function show_statement(io, mime, stmt::With, level)
    print(io, tab^level * "(\n")
    show_statement(io, mime, stmt.cons, level + 1)
    print(io, tab^level * ") where (\n")
    show_statement(io, mime, stmt.prod, level + 1)
    print(io, tab^level * ")\n")
end

Finch.getresults(stmt::With) = Finch.getresults(stmt.cons)

struct Multi <: IndexStatement
    bodies
end
Base.:(==)(a::Multi, b::Multi) = a.bodies == b.bodies

multi(args...) = multi!(vcat(args...))
multi!(args) = Multi(args)

SyntaxInterface.istree(::Multi) = true
SyntaxInterface.operation(stmt::Multi) = multi
SyntaxInterface.arguments(stmt::Multi) = stmt.bodies
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(multi), args) = multi!(args)

function show_statement(io, mime, stmt::Multi, level)
    print(io, tab^level * "begin\n")
    for body in stmt.bodies
        show_statement(io, mime, body, level + 1)
    end
    print(io, tab^level * "end\n")
end

Finch.getresults(stmt::Multi) = mapreduce(Finch.getresults, vcat, stmt.bodies)

Base.@kwdef struct Chunk <: IndexStatement
	idx::Any
    ext::Any
	body::Any
end
Base.:(==)(a::Chunk, b::Chunk) = a.idx == b.idx && a.ext == b.ext && a.body == b.body

chunk(args...) = chunk!(vcat(args...))
chunk!(args) = Chunk(args[1], args[2], args[3])

SyntaxInterface.istree(::Chunk) = true
SyntaxInterface.operation(stmt::Chunk) = chunk
SyntaxInterface.arguments(stmt::Chunk) = Any[stmt.idx, stmt.ext, stmt.body]
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(chunk), args) = chunk!(args)
Finch.getunbound(ex::Chunk) = setdiff(union(getunbound(ex.body), getunbound(ex.ext)), getunbound(ex.idx))

function show_statement(io, mime, stmt::Chunk, level)
    print(io, tab^level * "@∀ ")
    show_expression(io, mime, stmt.idx)
    print(io, " : ")
    show_expression(io, mime, stmt.ext)
    print(io," (\n")
    show_statement(io, mime, stmt.body, level + 1)
    print(io, tab^level * ")\n")
end

Finch.getresults(stmt::Chunk) = Finch.getresults(stmt.body)

struct Loop <: IndexStatement
	idx::Any
	body::Any
end
Base.:(==)(a::Loop, b::Loop) = a.idx == b.idx && a.body == b.body

loop(args...) = loop!(args)
loop!(args) = foldr(Loop, args)

SyntaxInterface.istree(::Loop) = true
SyntaxInterface.operation(stmt::Loop) = loop
SyntaxInterface.arguments(stmt::Loop) = Any[stmt.idx; stmt.body]
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(loop), args) = loop!(args)

Finch.getunbound(ex::Loop) = setdiff(getunbound(ex.body), getunbound(ex.idx))

function show_statement(io, mime, stmt::Loop, level)
    print(io, tab^level * "@∀ ")
    while stmt isa Loop
        show_expression(io, mime, stmt.idx)
        print(io," ")
        stmt = stmt.body
    end
    print(io," (\n")
    show_statement(io, mime, stmt, level + 1)
    print(io, tab^level * ")\n")
end

Finch.getresults(stmt::Loop) = Finch.getresults(stmt.body)


struct Sieve <: IndexStatement
	cond::Any
	body::Any
end
Base.:(==)(a::Sieve, b::Sieve) = a.cond == b.cond && a.body == b.body

sieve(args...) = sieve!(args)
sieve!(args) = foldr(Sieve, args)

SyntaxInterface.istree(::Sieve) = true
SyntaxInterface.operation(stmt::Sieve) = sieve
SyntaxInterface.arguments(stmt::Sieve) = Any[stmt.cond; stmt.body]
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(sieve), args) = sieve!(args)

Finch.getunbound(ex::Sieve) = setdiff(getunbound(ex.body), getunbound(ex.cond))

function show_statement(io, mime, stmt::Sieve, level)
    print(io, tab^level * "if ")
    while stmt isa Sieve
        show_expression(io, mime, stmt.cond)
        print(io," && ")
        stmt = stmt.body
    end
    print(io,"\n")
    show_statement(io, mime, stmt, level + 1)
    print(io, tab^level * "end\n")
end

Finch.getresults(stmt::Sieve) = Finch.getresults(stmt.body)

struct Assign{Lhs} <: IndexStatement
	lhs::Lhs
	op::Any
	rhs::Any
end
Base.:(==)(a::Assign, b::Assign) = a.lhs == b.lhs && a.op == b.op && a.rhs == b.rhs

assign(args...) = assign!(vcat(args...))
function assign!(args)
    if length(args) == 2
        Assign(args[1], nothing, args[2])
    elseif length(args) == 3
        Assign(args[1], args[2], args[3])
    else
        throw(ArgumentError("wrong number of arguments to assign"))
    end
end

SyntaxInterface.istree(::Assign)= true
SyntaxInterface.operation(stmt::Assign) = assign
function SyntaxInterface.arguments(stmt::Assign)
    if stmt.op === nothing
        Any[stmt.lhs, stmt.rhs]
    else
        Any[stmt.lhs, stmt.op, stmt.rhs]
    end
end
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(assign), args) = assign!(args)

function show_statement(io, mime, stmt::Assign, level)
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

Finch.getresults(stmt::Assign) = Finch.getresults(stmt.lhs)

struct Call <: IndexExpression
    op::Any
    args::Vector{Any}
end
Base.:(==)(a::Call, b::Call) = a.op == b.op && a.args == b.args

call(args...) = call!(vcat(args...))
call!(args) = Call(popfirst!(args), args)

SyntaxInterface.istree(::Call) = true
SyntaxInterface.operation(ex::Call) = call
SyntaxInterface.arguments(ex::Call) = Any[ex.op; ex.args]
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(call), args) = call!(args)

function show_expression(io, mime, ex::Call)
    show_expression(io, mime, ex.op)
    print(io, "(")
    for arg in ex.args[1:end-1]
        show_expression(io, mime, arg)
        print(io, ", ")
    end
    show_expression(io, mime, ex.args[end])
    print(io, ")")
end

struct Read <: IndexTerminal end
struct Write <: IndexTerminal end
struct Update <: IndexTerminal end

struct Access{T, M} <: IndexExpression
    tns::T
    mode::M
    idxs::Vector
end
Base.:(==)(a::Access, b::Access) = a.tns == b.tns && a.idxs == b.idxs

access(args...) = access!(vcat(Any[], args...))
access!(args) = Access(popfirst!(args), popfirst!(args), args)

SyntaxInterface.istree(::Access) = true
SyntaxInterface.operation(ex::Access) = access
SyntaxInterface.arguments(ex::Access) = Any[ex.tns; ex.mode; ex.idxs]
SyntaxInterface.similarterm(::Type{<:IndexNode}, ::typeof(access), args) = access!(args)

function show_expression(io, mime, ex::Access)
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

Finch.getresults(stmt::Access) = [stmt.tns]

show_expression(io, mime, ex) = print(io, ex)

struct Lexicography{T}
    arg::T
end

function Base.isless(a::Lexicography, b::Lexicography)
    @assert which(priority, Tuple{typeof(a)}) != which(priority, Tuple{typeof(b)}) || priority(a) == priority(b)
    if a.arg != b.arg
        a_key = (priority(a.arg), comparators(a.arg)...)
        b_key = (priority(b.arg), comparators(b.arg)...)
        @assert a_key < b_key || b_key < a_key
        return a_key < b_key
    end
    return false
end

priority(::Number) = (1, 1)
comparators(x::Number) = (x, sizeof(x), typeof(x))

priority(::Function) = (1, 2)
comparators(x::Function) = (string(x),)

priority(::Symbol) = (2, 0)
comparators(x::Symbol) = (x,)

priority(::Expr) = (2, 1)
comparators(x::Expr) = (x.head, map(Lexicography, x.args)...)

priority(::Name) = (3,0)
comparators(x::Name) = (x.name,)

priority(::Literal) = (3,1)
comparators(x::Literal) = (Lexicography(x.val),)

priority(::Read) = (3,2,1)
comparators(x::Read) = ()

priority(::Write) = (3,2,2)
comparators(x::Write) = ()

priority(::Update) = (3,2,3)
comparators(x::Update) = ()

priority(::Workspace) = (3,3)
comparators(x::Workspace) = (x.n,)

priority(::Virtual) = (3,4)
comparators(x::Virtual) = (typeof(x), Lexicography(x.ex))

priority(::IndexNode) = (3,Inf)
comparators(x::IndexNode) = (@assert istree(x); (string(operation(x)), map(Lexicography, arguments(x))...))

#TODO these are nice defaults if we want to allow nondeterminism
#priority(::Any) = (Inf,)
#comparators(x::Any) = hash(x)