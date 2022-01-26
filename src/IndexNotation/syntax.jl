#TODO use MacroTools?

function capture_index(ex; ctx...)
    incs = Dict(:+= => :+, :*= => :*, :/= => :/, :^= => :^)

    if ex isa Expr && ex.head == :macrocall && length(ex.args) >= 2 && ex.args[1] == Symbol("@pass")
        args = map(arg -> capture_index(arg; ctx..., namify=true), ex.args[3:end])
        return :(pass($(args...)))
    elseif ex isa Expr && ex.head == :macrocall && length(ex.args) >= 3 && ex.args[1] in [Symbol("@loop"), Symbol("@∀")]
        idxs = map(arg -> capture_index(arg; ctx..., namify=true), ex.args[3:end-1])
        body = capture_index(ex.args[end]; ctx...)
        return :(loop($(idxs...), $body))
    elseif ex isa Expr && ex.head == :where && length(ex.args) == 2
        cons = capture_index(ex.args[1]; ctx...)
        prod = capture_index(ex.args[2]; ctx...)
        return :(with($cons, $prod))
    elseif ex isa Expr && ex.head == :(=) && length(ex.args) == 2
        lhs = capture_index(ex.args[1]; ctx..., mode=Write())
        rhs = capture_index(ex.args[2]; ctx...)
        return :(assign($lhs, $rhs))
    elseif ex isa Expr && haskey(incs, ex.head) && length(ex.args) == 2
        lhs = capture_index(ex.args[1]; ctx..., mode=Update())
        rhs = capture_index(ex.args[2]; ctx...)
        op = capture_index(incs[ex.head]; ctx..., namify=false, literalize=true)
        return :(assign($lhs, $op, $rhs))
    elseif ex isa Expr && ex.head == :comparison && length(ex.args) == 5 && ex.args[2] == :< && ex.args[4] == :>=
        lhs = capture_index(ex.args[1]; ctx..., mode=Update())
        op = capture_index(ex.args[3]; ctx..., namify=false, literalize=true)
        rhs = capture_index(ex.args[5]; ctx...)
        return :(assign($lhs, $op, $rhs))
    elseif values(ctx).slot && ex isa Expr && ex.head == :call && length(ex.args) == 2 && ex.args[1] == :~ &&
        ex.args[2] isa Symbol
        return esc(ex)
    elseif values(ctx).slot && ex isa Expr && ex.head == :call && length(ex.args) == 2 && ex.args[1] == :~ &&
        ex.args[2] isa Expr && ex.args[2].head == :call && length(ex.args[2].args) == 2 && ex.args[2].args[1] == :~ &&
        ex.args[2].args[2] isa Symbol
        return esc(ex)
    elseif ex isa Expr && ex.head == :call && length(ex.args) >= 1
        op = capture_index(ex.args[1]; ctx..., namify=false, mode=Read())
        return :(call($op, $(map(arg->capture_index(arg; ctx..., namify=true, mode=Read()), ex.args[2:end])...)))
    elseif ex isa Expr && ex.head == :ref && length(ex.args) >= 1
        tns = capture_index(ex.args[1]; ctx..., namify=false, mode=Read())
        return :(access($tns, $(values(ctx).mode), $(map(arg->capture_index(arg; ctx..., namify=true, mode=Read()), ex.args[2:end])...)))
    elseif ex isa Expr && ex.head == :$ && length(ex.args) == 1
        return esc(ex.args[1])
    elseif ex isa Symbol && values(ctx).namify
        return Name(ex)
    else
        return esc(ex)
    end
end

macro i(ex)
    return capture_index(ex; namify=false, slot = true, mode = Read())
end

function capture_virtual_index(ex; ctx...)
    incs = Dict(:+= => :+, :*= => :*, :/= => :/, :^= => :^)

    if ex isa Expr && ex.head == :macrocall && length(ex.args) >= 2 && ex.args[1] == Symbol("@pass")
        args = map(arg -> capture_virtual_index(arg; ctx...), ex.args[3:end])
        return :(mesapass($(args...)))
    elseif ex isa Expr && ex.head == :macrocall && length(ex.args) >= 3 && ex.args[1] in [Symbol("@loop"), Symbol("@∀")]
        idxs = map(arg -> capture_virtual_index(arg; ctx..., namify=true), ex.args[3:end-1])
        body = capture_virtual_index(ex.args[end]; ctx...)
        return :(mesaloop($(idxs...), $body))
    elseif ex isa Expr && ex.head == :where && length(ex.args) == 2
        cons = capture_virtual_index(ex.args[1]; ctx...)
        prod = capture_virtual_index(ex.args[2]; ctx...)
        return :(mesawith($cons, $prod))
    elseif ex isa Expr && ex.head == :(=) && length(ex.args) == 2
        lhs = capture_virtual_index(ex.args[1]; ctx..., mode=Write())
        rhs = capture_virtual_index(ex.args[2]; ctx...)
        return :(mesaassign($lhs, $rhs))
    elseif ex isa Expr && haskey(incs, ex.head) && length(ex.args) == 2
        lhs = capture_virtual_index(ex.args[1]; ctx..., mode=Update())
        rhs = capture_virtual_index(ex.args[2]; ctx...)
        op = capture_virtual_index(incs[ex.head]; ctx..., namify=false, literalize=true)
        return :(mesaassign($lhs, $op, $rhs))
    elseif ex isa Expr && ex.head == :comparison && length(ex.args) == 5 && ex.args[2] == :< && ex.args[4] == :>=
        lhs = capture_virtual_index(ex.args[1]; ctx..., mode=Update())
        op = capture_virtual_index(ex.args[3]; ctx..., namify=false, literalize=true)
        rhs = capture_virtual_index(ex.args[5]; ctx...)
        return :(mesaassign($lhs, $op, $rhs))
    elseif values(ctx).slot && ex isa Expr && ex.head == :call && length(ex.args) == 2 && ex.args[1] == :~ &&
        ex.args[2] isa Symbol
        return esc(ex)
    #TODO add ellipsis syntax
    elseif values(ctx).slot && ex isa Expr && ex.head == :call && length(ex.args) == 2 && ex.args[1] == :~ &&
        ex.args[2] isa Expr && ex.args[2].head == :call && length(ex.args[2].args) == 2 && ex.args[2].args[1] == :~ &&
        ex.args[2].args[2] isa Symbol
        return esc(ex)
    elseif ex isa Expr && ex.head == :call && length(ex.args) >= 1
        op = capture_virtual_index(ex.args[1]; ctx..., namify=false, mode=Read())
        return :(mesacall($op, $(map(arg->capture_virtual_index(arg; ctx..., namify=true, mode=Read()), ex.args[2:end])...)))
    elseif ex isa Expr && ex.head == :ref && length(ex.args) >= 1
        tns = capture_virtual_index(ex.args[1]; ctx..., namify=false, mode=Read())
        return :(mesaaccess($tns, $(values(ctx).mode), $(map(arg->capture_virtual_index(arg; ctx..., namify=true, mode=Read()), ex.args[2:end])...)))
    elseif ex isa Expr && ex.head == :(::) && length(ex.args) == 2
        return :($(esc(ex.args[2]))($(capture_virtual_index(ex.args[1]; ctx...))))
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
    return capture_virtual_index(ex; namify=false, slot = true, mode = Read())
end