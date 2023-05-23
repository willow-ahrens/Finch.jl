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

function Base.show_unquoted(io::IO, node::Resumable, indent::Int, prec::Int)
    if length(node.meta) == 0
        show_with_indent(io, node.root, indent, prec)
    else
        show_with_indent(io, node.meta, indent, prec)
        show_with_indent(io, node.root, indent, prec)
    end
end


function Base.show(io::IO, node::Resumable)
    if length(node.meta) == 0
        println("@finch")
        show(io, MIME"text/plain"(), node.root)
    else
        println("@finch")
        show(io, MIME"text/plain"(), node.meta)
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
                    end )(code)
end

function record_methods(code)
    Postwalk(node -> 
    if node isa Resumable 
        loc = which(lower, (typeof(node.root), typeof(node.ctx), typeof(node.style)))
         node.meta[:Which] = (loc.file, loc.line)
        node
    end )(code)
end


abstract type AbstractLoweringControl end

function should_resume(c :: AbstractLoweringControl, ctx, node, style, meta)
   true
end

function update_meta(c:: AbstractLoweringControl, ctx, node, style, meta)
   meta
end

function should_pause(c:: AbstractLoweringControl, ctx, node, style)
    false
end

function init_meta(c:: AbstractLoweringControl, ctx, node, style)
    Dict{Symbol,Any}()
end

function evolve_control(c:: AbstractLoweringControl, ctx, node, style)
    c
end

@kwdef struct DebugContext{T<:AbstractLoweringControl} <: AbstractCompiler
    ctx=LowerJulia()
    control::T
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
        if should_resume(ctx.control, ctx, node.root, style, node.meta)
            node.ctx(node.root)
        else
            Resumable(ctx.ctx, node.root, style, update_meta(ctx.control, ctx, node.root, style, node.meta))
        end
    elseif should_pause(ctx.control, ctx, node, style)
        Resumable(ctx.ctx, node, style, init_meta(ctx.control, ctx, node, style))
    else
        control = evolve_control(ctx.control, ctx, node, style)
        lower(node, DebugContext(ctx.ctx, control), style)
    end
end

function (ctx::DebugContext)(code:: Expr)
    Postwalk(node -> 
    if node isa Resumable 
        (ctx::DebugContext)(node.root, node.style)
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
    StepExceptControl(step=c.step - 1, resumeLocations=c.resumeLocations,
    resumeStyles=c.resumeStyles, resumeFilter=c.resumeFilter)
end

function should_resume(c :: StepOnlyControl, ctx, node, style, meta)
    should = false
    if !isnothing(c.resumeLocations) && !isnothing(meta)
        if :Number in meta 
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


 struct PartialCode
    lastCtx::DebugContext
    code
    algebra
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
    ret = PartialCode(pcode.lastCtx, code, pcode.algebra)
    if sdisplay
        display(ret)
    end
    ret
 end

function stage_execute(code; algebra = DefaultAlgebra(),  sdisplay=true)
    ctx = DebugContext(LowerJulia(), SimpleStepControl(step=0))
    code = execute_code(:ex, typeof(code), algebra, ctx)
    clean_partial_code(PartialCode(ctx, code, algebra), sdisplay=sdisplay)
end

function step_code(code::PartialCode; step=1, sdisplay=true)
    ctx = DebugContext(code.lastCtx.ctx, SimpleStepControl(step=step))
    newcode = ctx(code.code)
    clean_partial_code(PartialCode(code.lastCtx, newcode, code.algebra), sdisplay=sdisplay)
end

function step_again_code(code::PartialCode; ctx=nothing, sdisplay=true)
    if isnothing(ctx)
        clean_partial_code(PartialCode(code.lastCtx, code.lastCtx(code.code), code.algebra),sdisplay=sdisplay)
    else
        clean_partial_code(PartialCode(ctx, ctx(code.code), code.algebra), sdisplay=sdisplay)
    end
end

function step_some_code(code::PartialCode; step=1, resumeLocations=nothing, resumeStyles=nothing, resumeFilter=nothing, sdisplay=true)
    control = StepOnlyControl(step=step, resumeLocations = resumeLocations, resumeStyles=resumeStyles, resumeFilter=resumeFilter)
    ctx = DebugContext(code.lastCtx.ctx, control)
    step_again_code(code, ctx=ctx, sdisplay=sdisplay)
end

function step_first_code(code::PartialCode; step=1)
    control = StepOnlyControl(step=step, resumeLocations = [1])
    ctx = DebugContext(code.lastCtx.ctx, control)
    step_again_code(code, ctx=ctx, sdisplay=sdisplay)
end

function iscompiled(code:: Expr)
    found = false
    Postwalk(node -> 
                    if node isa Resumable 
                        found = true
                        node
                    end )(code)
    !found
end

function collect_resumables()
end

function end_debug(code:: PartialCode)
    if iscompiled(code.code)
        return code.code
    else
        error("Can't exit debug mode: There are still unresume resumables!")
    end
end 