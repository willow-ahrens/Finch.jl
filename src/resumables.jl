"""
    Resumable(ctx, root, style, meta)

Struct to hold a paused compilation. Holds the compiler state in `ctx`, a FinchNode in root, the compiler style in style, and a dict of meta data in meta.
"""
@kwdef struct Resumable
    ctx
    root
    style
    meta 
end

function Base.show(io::IO, mime::MIME"text/plain", node::Resumable)
    if length(node.meta) == 0
        println("@finch")
        show(io, mime, node.root)
    else
        println("@finch")
        show(io, mime, node.meta)
        show(io, mime, node.root)
    end
end

show_with_indent(io, node, indent, prec) = (print("@finch("); Base.show_unquoted(io, node, indent, prec); print(")"))
function show_with_indent(io, node::FinchNode, indent, prec)
    indent = fld(indent, 2) + 1
    if Finch.FinchNotation.isstateful(node)
        println("@finch begin")
        Finch.FinchNotation.display_statement(io, MIME"text/plain"(), node, indent)
        println()
        print("  "^(indent - 1), "end")
    else
        print("@finch("); Finch.FinchNotation.display_expression(io, MIME"text/plain"(), node); print(")")
    end
end

function show_with_indent_meta(io, node::FinchNode, indent, prec, meta)
    indent = fld(indent, 2) + 1
    if Finch.FinchNotation.isstateful(node)
        print("@finch begin")
        println(meta)
        Finch.FinchNotation.display_statement(io, MIME"text/plain"(), node, indent)
        println()
        print("  "^(indent - 1), "end")
    else
        print("@finch("); print(meta); Finch.FinchNotation.display_expression(io, MIME"text/plain"(), node); print(")")
    end
end

function show_with_indent_meta(io, node, indent, prec, meta)
    indent = fld(indent, 2) + 1
    print("@finch("); print(meta); Finch.FinchNotation.display_expression(io, MIME"text/plain"(), node); print(")")
end

dictkeys(d::Dict) = (collect(keys(d))...,)
dictvalues(d::Dict) = (collect(values(d))...,)

namedtuple(d::Dict{Symbol,T}) where {T} =
    NamedTuple{dictkeys(d)}(dictvalues(d))

function Base.show_unquoted(io::IO, node::Resumable, indent::Int, prec::Int)
    if length(node.meta) == 0
        show_with_indent(io, node.root, indent, prec)
    else
        show_with_indent_meta(io, node.root, indent, prec, namedtuple(node.meta))
    end
end



function Base.show(io::IO, node::Resumable)
    if length(node.meta) == 0
        println("@finch")
        show(io, MIME"text/plain"(), node.root)
    else
        println("@finch")
        show(io, MIME"text/plain"(), namedtuple(node.meta))
        show(io, MIME"text/plain"(), node.root)
    end
end


function number_resumables(code)
    counter = 0
    Postwalk(node -> 
                    if node isa Resumable 
                        node.meta[:Number] = counter
                        counter+=1 
                        node
                    else
                        node
                    end )(code)
end

function record_methods(code)
    Postwalk(node -> 
    if node isa Resumable 
        loc = which(lower, (typeof(node.root), typeof(node.ctx), typeof(node.style)))
         node.meta[:Which] = (string(loc.file), loc.line)
        node
    else
        node
    end )(code)
end


abstract type AbstractLoweringControl end

"""
    should_resume(c :: AbstractLoweringControl, ctx, node, style, meta)

Determines if a control wants to resume lowering a Resumable. 
Should return true or false. Defaults to true.
"""
function should_resume(c :: AbstractLoweringControl, ctx, node, style, meta)
   true
end

"""
    update_meta(c :: AbstractLoweringControl, ctx, node, style)

Returns recomputed metadata for a resumable in the event that it is not resumed. 
    Defaults to the identity.
"""
function update_meta(c:: AbstractLoweringControl, ctx, node, style, meta)
   meta
end

"""
    should_pause(c :: AbstractLoweringControl, ctx, node, style)

Determines if a control wants to pause on a particular lowering of a particular FinchNode.
Should return true or false. Defaults to false.
"""
function should_pause(c:: AbstractLoweringControl, ctx, node, style)
    false
end

"""
    init_meta(c :: AbstractLoweringControl, ctx, node, style)

Returns recomputed metadata for a resumable in the event that it is not resumed. 
Defaults to the empty dict.
"""
function init_meta(c:: AbstractLoweringControl, ctx, node, style)
    Dict{Symbol,Any}()
end


"""
    evolve_control(c :: AbstractLoweringControl, ctx, node, style)

In the event that control does not pause on a Finch node, we evolve the control,
resulting in a new `AbstractLoweringControl`.
"""
function evolve_control(c:: AbstractLoweringControl, ctx, node, style)
    c
end

@kwdef struct DebugContext{T<:AbstractLoweringControl} <: AbstractCompiler
    ctx=LowerJulia()
    control::T
end

shallowcopy(x::DebugContext) = DebugContext(shallowcopy(x.ctx), x.control)

#Sad but true
function Base.getproperty(ctx::DebugContext, name::Symbol)
    if name === :control
        return getfield(ctx, :control)
    elseif name === :ctx
        return getfield(ctx, :ctx)
    end
    getproperty(ctx.ctx, name)
end

function Base.setproperty!(ctx::DebugContext, name::Symbol, x)
    setproperty!(ctx.ctx, name, x)
end


function (ctx::DebugContext)(node, style)
    if node isa Resumable
        error("This should not occur!")
    elseif should_pause(ctx.control, ctx, node, style)
        return Resumable(ctx.ctx, node, style, init_meta(ctx.control, ctx.ctx, node, style))
    else
        control = evolve_control(ctx.control, ctx, node, style)
        nxt = lower(node, DebugContext(ctx.ctx, control), style)
        return nxt
    end
end

function resume_lowering(control::AbstractLoweringControl, code:: Expr)
    if iscompiled(code)
        return code
    end
    Postwalk(node -> 
    if node isa Resumable 
        if should_resume(control, node.ctx, node.root, node.style, node.meta)
            ctx = DebugContext(node.ctx, control)
            ret = ctx(node.root, node.style)
        else
            ret = Resumable(node.ctx, node.root, node.style, update_meta(control, node.ctx, node.root, node.style, node.meta))
        end
        return ret
    else
        node
    end )(code)
end


@kwdef struct SimpleStepControl <: AbstractLoweringControl
    step=1
end
function evolve_control(c:: SimpleStepControl, ctx, node, style)
    SimpleStepControl(step = c.step - 1)
end

function should_pause(c:: SimpleStepControl, ctx, node, style)
    c.step == 0
end


@kwdef struct StepOnlyControl <: AbstractLoweringControl
    step= 1
    resumeLocations = nothing
    resumeStyles = nothing
    resumeFilter = nothing
end

function evolve_control(c:: StepOnlyControl, ctx, node, style)
    StepOnlyControl(step=c.step - 1, resumeLocations=c.resumeLocations,
    resumeStyles=c.resumeStyles, resumeFilter=c.resumeFilter)
end

function should_resume(c :: StepOnlyControl, ctx, node, style, meta)
    should = false
    if !isnothing(c.resumeLocations) && !isnothing(meta)
        if :Number in keys(meta) 
            should = meta[:Number] in c.resumeLocations
        end
    end
    if !isnothing(c.resumeStyles)
        should = should || style in c.resumeStyles
    end
    if !isnothing(c.resumeFilter)
        should = should || c.resumeFilter(node)
    end
    should
 end

 function should_pause(c:: StepOnlyControl, ctx, node, style)
    c.step == 0
end

"""
    PartialCode(lastControl :: AbstractLoweringControl, code)

Essentially a debugging context that holds the code that we are working on and the `AbstractLoweringControl`.
"""
struct PartialCode
    lastControl :: AbstractLoweringControl
    code
 end


function Base.show(io::IO, mime::MIME"text/plain", code:: PartialCode)
    show(io, mime, code.code)
end

function Base.show(io::IO, code::PartialCode)
    show(io, code.code)
end


 function clean_partial_code(pcode:: PartialCode; sdisplay=true)
    code = striplines(pcode.code)
    code = unblock(code)
    code = number_resumables(code)
    code = record_methods(code)
    ret = PartialCode(pcode.lastControl, code)
    if sdisplay
        display(ret)
    end
    ret
 end

function stage_code(code; algebra = DefaultAlgebra(),  sdisplay=true)
    ctx = DebugContext(LowerJulia(), SimpleStepControl(step=0))
    code = execute_code(:ex, typeof(code), algebra, ctx)
    control = StepOnlyControl(step=step, resumeLocations = [0])
    clean_partial_code(PartialCode(control, code), sdisplay=sdisplay)
end

"""
    step_all_code(code::PartialCode; step=1, sdisplay=true)

Experimental feature: Do not use explictly."""
function step_all_code(code::PartialCode; step=1, sdisplay=true)
    newcode = resume_lowering(SimpleStepControl(step=step), code.code)
    clean_partial_code(PartialCode(SimpleStepControl(step=step), newcode), sdisplay=sdisplay)
end
"""
    repeat_step_code(code::PartialCode; control=nothing, sdisplay=true)

Experimental feature: Do not use explictly."""
function repeat_step_code(code::PartialCode; control=nothing, sdisplay=true)
    if isnothing(control)
        newcode = resume_lowering(code.lastControl, code.code)
        clean_partial_code(PartialCode(code.lastControl, newcode),sdisplay=sdisplay)
    else
        newcode = resume_lowering(control, code.code)
        clean_partial_code(PartialCode(control, newcode), sdisplay=sdisplay)
    end
end

"""
    step_some_code(code::PartialCode; step=1, resumeLocations=nothing, resumeStyles=nothing, resumeFilter=nothing, sdisplay=true)

Experimental feature: Do not use explictly."""
function step_some_code(code::PartialCode; step=1, resumeLocations=nothing, resumeStyles=nothing, resumeFilter=nothing, sdisplay=true)
    control = StepOnlyControl(step=step, resumeLocations = resumeLocations, resumeStyles=resumeStyles, resumeFilter=resumeFilter)
    repeat_step_code(code, control=control, sdisplay=sdisplay)
end

"""
    step_code(code::PartialCode; step=1, sdisplay=true)

Advance the compiler on `code` for `step`, displaying the code at the end if `sdisplay`.
"""
function step_code(code::PartialCode; step=1, sdisplay=true)
    control = StepOnlyControl(step=step, resumeLocations = [0])
    repeat_step_code(code, control=control, sdisplay=sdisplay)
end


"""
    iscompiled(code:: Expr)

Checks if Julia AST has any Resumables in it.
"""
function iscompiled(code:: Expr)
    found = false
    Postwalk(node -> 
                    if node isa Resumable 
                        found = true
                        node
                    end )(code)
    !found
end

"""
    end_debug(code:: PartialCode)

Returns a finished Julia AST from a `PartialCode`` if it has no Resumables in it. Throws an error otherwise.
"""
function end_debug(code:: PartialCode)
    if iscompiled(code.code)
        return code.code
    else
        error("Can't exit debug mode: There are still unresume resumables!")
    end
end 