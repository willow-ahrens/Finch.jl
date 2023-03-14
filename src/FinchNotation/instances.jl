abstract type FinchNodeInstance end

struct LiteralInstance{val} <: FinchNodeInstance
end

@inline literal_instance(val) = LiteralInstance{val}()

Base.show(io::IO, node::LiteralInstance{val}) where {val} = print(io, "literal_instance(", val, ")")

struct IndexInstance{name} <: FinchNodeInstance end

@inline index_instance(name) = IndexInstance{name}()

Base.show(io::IO, node::IndexInstance{name}) where {name} = print(io, "index_instance(:", name, ")")

struct ProtocolInstance{Idx, Mode} <: FinchNodeInstance
	idx::Idx
	mode::Mode
end

Base.:(==)(a::ProtocolInstance, b::ProtocolInstance) = a.idx == b.idx && a.mode == b.mode

@inline protocol_instance(idx, mode) = ProtocolInstance(idx, mode)

struct DeclareInstance{Tns, Init} <: FinchNodeInstance
	tns::Tns
	init::Init
end
Base.:(==)(a::DeclareInstance, b::DeclareInstance) = a.tns == b.tns && a.init == b.init

@inline declare_instance(tns, init) = DeclareInstance(tns, init)

Base.show(io::IO, node::DeclareInstance) = print(io, "declare_instance(", node.tns, node.init, ")")

struct FreezeInstance{Tns} <: FinchNodeInstance
	tns::Tns
end
Base.:(==)(a::FreezeInstance, b::FreezeInstance) = a.tns == b.tns

@inline freeze_instance(tns) = FreezeInstance(tns)

Base.show(io::IO, node::FreezeInstance) = print(io, "freeze_instance(", node.tns, ")")

struct ThawInstance{Tns} <: FinchNodeInstance
	tns::Tns
end
Base.:(==)(a::ThawInstance, b::ThawInstance) = a.tns == b.tns

@inline thaw_instance(tns) = ThawInstance(tns)

Base.show(io::IO, node::ThawInstance) = print(io, "thaw_instance(", node.tns, ")")

struct ForgetInstance{Tns} <: FinchNodeInstance
	tns::Tns
end
Base.:(==)(a::ForgetInstance, b::ForgetInstance) = a.tns == b.tns

@inline forget_instance(tns) = ForgetInstance(tns)

Base.show(io::IO, node::ForgetInstance) = print(io, "forget_instance(", node.tns, ")")

struct SequenceInstance{Bodies} <: FinchNodeInstance
    bodies::Bodies
end
Base.:(==)(a::SequenceInstance, b::SequenceInstance) = all(a.bodies .== b.bodies)

sequence_instance(bodies...) = SequenceInstance(bodies)

Base.show(io::IO, node::SequenceInstance) = (print(io, "sequence_instance("); join(io, node.bodies, ", "); println(io, ")"))

struct LoopInstance{Idx, Body} <: FinchNodeInstance
	idx::Idx
	body::Body
end

Base.:(==)(a::LoopInstance, b::LoopInstance) = a.idx == b.idx && a.body == b.body

@inline loop_instance(idx, body) = LoopInstance(idx, body)
@inline loop_instance(body) = body
@inline loop_instance(idx, args...) = LoopInstance(idx, loop_instance(args...))

Base.show(io::IO, node::LoopInstance) = print(io, "loop_instance(", node.idx, ", ", node.body, ")")

struct SieveInstance{Cond, Body} <: FinchNodeInstance
	cond::Cond
	body::Body
end

Base.:(==)(a::SieveInstance, b::SieveInstance) = a.cond == b.cond && a.body == b.body

@inline sieve_instance(cond, body) = SieveInstance(cond, body)
@inline sieve_instance(body) = body
@inline sieve_instance(cond, args...) = SieveInstance(cond, sieve_instance(args...))

Base.show(io::IO, node::SieveInstance) = print(io, "sieve_instance(", node.cond, ", ", node.body, ")")

struct AssignInstance{Lhs, Op, Rhs} <: FinchNodeInstance
	lhs::Lhs
	op::Op
	rhs::Rhs
end

Base.:(==)(a::AssignInstance, b::AssignInstance) = a.lhs == b.lhs && a.op == b.op && a.rhs == b.rhs

@inline assign_instance(lhs, op, rhs) = AssignInstance(lhs, op, rhs)

Base.show(io::IO, node::AssignInstance) = print(io, "assign_instance(", node.lhs, ", ", node.op, ", ", node.rhs, ")")

struct CallInstance{Op, Args<:Tuple} <: FinchNodeInstance
    op::Op
    args::Args
end

Base.:(==)(a::CallInstance, b::CallInstance) = a.op == b.op && a.args == b.args

@inline call_instance(op, args...) = CallInstance(op, args)

Base.show(io::IO, node::CallInstance) = print(io, "call_instance(", node.op, ", ", join(node.args, ", "), ")")

struct AccessInstance{Tns, Mode, Idxs} <: FinchNodeInstance
    tns::Tns
    mode::Mode
    idxs::Idxs
end

Base.:(==)(a::AccessInstance, b::AccessInstance) = a.tns == b.tns && a.mode == b.mode && a.idxs == b.idxs

Base.show(io::IO, node::AccessInstance) = print(io, "access_instance(", node.tns, ", ", node.mode, ", ", join(node.idxs, ", "), ")")

@inline access_instance(tns, mode, idxs...) = AccessInstance(tns, mode, idxs)

struct VariableInstance{tag, Tns} <: FinchNodeInstance
    tns::Tns
end

Base.:(==)(a::VariableInstance, b::VariableInstance) = false
Base.:(==)(a::VariableInstance{tag}, b::VariableInstance{tag}) where {tag} = a.tns == b.tns

@inline variable_instance(tag, tns) = VariableInstance{tag, typeof(tns)}(tns)
@inline variable_instance(tag, tns::IndexInstance) = tns #TODO this should be syntactic

Base.show(io::IO, node::VariableInstance{tag}) where {tag} = print(io, "variable_instance(:", tag, ", ", tag, ")")

struct ReaderInstance end

reader_instance() = ReaderInstance()

Base.:(==)(a::ReaderInstance, b::ReaderInstance) = true

Base.show(io::IO, node::ReaderInstance) = print(io, "reader_instance()")

struct UpdaterInstance{Mode}
	mode::Mode
end

@inline updater_instance(mode) = UpdaterInstance(mode)

Base.:(==)(a::UpdaterInstance, b::UpdaterInstance) = a.mode == b.mode

Base.show(io::IO, node::UpdaterInstance) = print(io, "updater_instance(", node.mode, ")")

struct ModifyInstance end

modify_instance() = ModifyInstance()

Base.:(==)(a::ModifyInstance, b::ModifyInstance) = true

Base.show(io::IO, node::ModifyInstance) = print(io, "modify_instance()")

struct CreateInstance end

create_instance() = CreateInstance()

Base.:(==)(a::CreateInstance, b::CreateInstance) = true

Base.show(io::IO, node::CreateInstance) = print(io, "create_instance()")

@inline finch_leaf_instance(arg::Type) = literal_instance(arg)
@inline finch_leaf_instance(arg::Function) = literal_instance(arg)
@inline finch_leaf_instance(arg::FinchNodeInstance) = arg
@inline finch_leaf_instance(arg) = arg #TODO ValueInstance

@inline finch_leaf(arg::Type) = literal(arg)
@inline finch_leaf(arg::Function) = literal(arg)
@inline finch_leaf(arg::FinchNode) = arg
@inline finch_leaf(arg) = isliteral(arg) ? literal(arg) : virtual(arg)

Base.convert(::Type{FinchNode}, x) = finch_leaf(x)
Base.convert(::Type{FinchNode}, x::FinchNode) = x
Base.convert(::Type{FinchNode}, x::Symbol) = error()