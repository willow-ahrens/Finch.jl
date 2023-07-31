abstract type FinchNodeInstance end

struct LiteralInstance{val} <: FinchNodeInstance
end

@inline literal_instance(val) = LiteralInstance{val}()

Base.show(io::IO, node::LiteralInstance{val}) where {val} = print(io, "literal_instance(", val, ")")

struct IndexInstance{name} <: FinchNodeInstance end

@inline index_instance(name) = IndexInstance{name}()

Base.show(io::IO, node::IndexInstance{name}) where {name} = print(io, "index_instance(", Symbol(name), ")")

struct DefineInstance{Lhs, Rhs} <: FinchNodeInstance
	lhs::Lhs
	rhs::Rhs
end
Base.:(==)(a::DefineInstance, b::DefineInstance) = a.lhs == b.lhs && a.rhs == b.rhs

@inline define_instance(lhs, rhs) = DefineInstance(lhs, rhs)

Base.show(io::IO, node::DefineInstance) = print(io, "define_instance(", node.lhs, ", ", node.rhs, ")")

struct DeclareInstance{Tns, Init} <: FinchNodeInstance
	tns::Tns
	init::Init
end
Base.:(==)(a::DeclareInstance, b::DeclareInstance) = a.tns == b.tns && a.init == b.init

@inline declare_instance(tns, init) = DeclareInstance(tns, init)

Base.show(io::IO, node::DeclareInstance) = print(io, "declare_instance(", node.tns, ", ", node.init, ")")

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

struct SequenceInstance{Bodies} <: FinchNodeInstance
    bodies::Bodies
end
Base.:(==)(a::SequenceInstance, b::SequenceInstance) = all(a.bodies .== b.bodies)

sequence_instance(bodies...) = SequenceInstance(bodies)

Base.show(io::IO, node::SequenceInstance) = (print(io, "sequence_instance("); join(io, node.bodies, ", "); println(io, ")"))

struct LoopInstance{Idx, Ext, Body} <: FinchNodeInstance
	idx::Idx
	ext::Ext
	body::Body
end

Base.:(==)(a::LoopInstance, b::LoopInstance) = a.idx == b.idx && a.ext == b.ext && a.body == b.body

@inline loop_instance(idx, ext, body) = LoopInstance(idx, ext, body)
@inline loop_instance(body) = body

Base.show(io::IO, node::LoopInstance) = print(io, "loop_instance(", node.idx, ", ", node.ext, ", ", node.body, ")")

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

struct VariableInstance{tag} <: FinchNodeInstance
end

Base.:(==)(a::VariableInstance, b::VariableInstance) = false
Base.:(==)(a::VariableInstance{tag}, b::VariableInstance{tag}) where {tag} = true

@inline variable_instance(tag) = VariableInstance{tag}()

Base.show(io::IO, node::VariableInstance{tag}) where {tag} = print(io, "variable_instance(:", tag, ")")

struct ReaderInstance end

reader_instance() = ReaderInstance()

Base.:(==)(a::ReaderInstance, b::ReaderInstance) = true

Base.show(io::IO, node::ReaderInstance) = print(io, "reader_instance()")

struct UpdaterInstance end

updater_instance() = UpdaterInstance()

Base.:(==)(a::UpdaterInstance, b::UpdaterInstance) = true

Base.show(io::IO, node::UpdaterInstance) = print(io, "updater_instance()")

"""
	TagInstance{tag, Tns}(tns)

Because the finch compiler cannot pass variable state from the program domain to
the type domain directly, the `TagInstance` type represents a value `tns`
referred to by a variable named `tag`. All `TagInstance` in the same program
must agree on the value of variables, and only one value will be virtualized.
"""
struct TagInstance{tag, Tns} <: FinchNodeInstance
    tns::Tns
end

Base.:(==)(a::TagInstance, b::TagInstance) = false
Base.:(==)(a::TagInstance{tag}, b::TagInstance{tag}) where {tag} = a.tns == b.tns

@inline tag_instance(tag, tns) = TagInstance{tag, typeof(tns)}(tns)
@inline tag_instance(tag, tns::IndexInstance) = tns
@inline tag_instance(tag, tns::VariableInstance) = tns

Base.show(io::IO, node::TagInstance{tag}) where {tag} = print(io, "tag_instance(:", tag, ", ", tag, ")")

@inline finch_leaf_instance(arg::Type) = literal_instance(arg)
@inline finch_leaf_instance(arg::Function) = literal_instance(arg)
@inline finch_leaf_instance(arg::FinchNodeInstance) = arg
@inline finch_leaf_instance(arg) = arg