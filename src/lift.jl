struct Typified{Op, Args}
	op::Op
	args::Args
end

function typify(node)
	if istree(node)
		return Typified(operation(node), (map(typify, arguments(node))...))
	else
		return node
	end
end

function typify(node::Literal)
	return Typified(Literal, node)
end

function typify(node::Name)
	return Typified(Name, node)
end