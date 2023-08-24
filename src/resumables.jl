"""
    Resumable(ctx, root, style, meta)

Struct to hold a paused compilation. Holds the compiler state in `ctx`, a
FinchNode in `root`, and the compiler style in `style`. If the resumable
is in an expression context. The `meta` field is a Dict
of metadata about the resumable.
"""
@kwdef struct Resumable
    ctx
    root
    style
    meta
end


function show_resumable(io, node::Resumable, indent, prec)
    print(io, "@finch");
    if !isempty(node.meta)
        print(io, "{")
        meta_tags = []
        if haskey(node.meta, :number)
            push!(meta_tags, "#$(node.meta[:number])")
        end
        if haskey(node.meta, :which)
            push!(meta_tags, "$(node.meta[:which][1]):$(node.meta[:which][2])")
        end
        join(io, meta_tags, ",")
        print(io, "}")
    end
    if node.root isa FinchNode && Finch.FinchNotation.isstateful(node.root)
        println(io, " begin")
        Finch.FinchNotation.display_statement(io, MIME"text/plain"(), node.root, indent + 2);
        println(io)
        print(io, " "^indent*"end")
    else
        print(io, "("); show(io, MIME"text/plain"(), node.root); print(io, ")")
    end
end


function Base.show_unquoted(io::IO, node::Resumable, indent::Int, prec::Int)
    show_resumable(io, node, indent, prec)
end

function Base.show(io::IO, mime::MIME"text/plain", node::Resumable)
    show_resumable(io, node, 0, 0)
end



function number_resumables(code)
    counter = 0
    Rewrite(Postwalk(node -> 
        if node isa Resumable 
            node.meta[:number] = counter
            counter+=1 
            node
        end
    ))(code)
end

function record_methods(code)
    Rewrite(Postwalk(node ->
        if node isa Resumable 
            loc = which(lower, (typeof(node.root), typeof(node.ctx), typeof(node.style)))
            node.meta[:which] = (splitpath(string(loc.file))[end], loc.line)
            node
        else
            node
        end
    ))(code)
end

"""
    AbstractLoweringControl

An abtract type for managing incremental lowering of Finch code. 
"""
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

function contain(f, ctx::DebugContext)
    contain(ctx.ctx) do ctx_2
        f(DebugContext(ctx_2, ctx.control))
    end
end

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
        if :number in keys(meta) 
            should = meta[:number] in c.resumeLocations
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


 function clean_partial_code(pcode:: PartialCode; sdisplay=false)
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

 """
    begin_debug(code; algebra = DefaultAlgebra(), sdisplay=false)

Takes a Finch Program and stages it within a DebugContext, defined within a particualr algebra.
 """
function begin_debug(code; algebra = DefaultAlgebra(),  sdisplay=false)
    ctx = DebugContext(LowerJulia(algebra = algebra), SimpleStepControl(step=0))
    code = execute_code(:ex, typeof(code), algebra, ctx=ctx)
    control = StepOnlyControl(step=step, resumeLocations = [0])
    clean_partial_code(PartialCode(control, code), sdisplay=sdisplay)
end

"""
    step_all_code(code::PartialCode; step=1, sdisplay=false)

Experimental feature: Do not use explictly."""
function step_all_code(code::PartialCode; step=1, sdisplay=false)
    newcode = resume_lowering(SimpleStepControl(step=step), code.code)
    clean_partial_code(PartialCode(SimpleStepControl(step=step), newcode), sdisplay=sdisplay)
end
"""
    repeat_step_code(code::PartialCode; control=nothing, sdisplay=false)

Experimental feature: Do not use explictly."""
function repeat_step_code(code::PartialCode; control=nothing, sdisplay=false)
    if isnothing(control)
        newcode = resume_lowering(code.lastControl, code.code)
        clean_partial_code(PartialCode(code.lastControl, newcode),sdisplay=sdisplay)
    else
        newcode = resume_lowering(control, code.code)
        clean_partial_code(PartialCode(control, newcode), sdisplay=sdisplay)
    end
end

"""
    step_some_code(code::PartialCode; step=1, resumeLocations=nothing, resumeStyles=nothing, resumeFilter=nothing, sdisplay=false)

Experimental feature: Do not use explictly."""
function step_some_code(code::PartialCode; step=1, resumeLocations=nothing, resumeStyles=nothing, resumeFilter=nothing, sdisplay=false)
    control = StepOnlyControl(step=step, resumeLocations = resumeLocations, resumeStyles=resumeStyles, resumeFilter=resumeFilter)
    repeat_step_code(code, control=control, sdisplay=sdisplay)
end

"""
    step_code(code::PartialCode; step=1, sdisplay=false)

Advance the compiler on `code` for `step`, displaying the code at the end if `sdisplay`.
"""
function step_code(code::PartialCode; step=1, sdisplay=false)
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
        end
    )(code)
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