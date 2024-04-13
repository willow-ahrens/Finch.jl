for pattern in [
    r"\bget_point_body\(",
    r"\bget_run_body\(",
    r"\bStylize\(",
    r"\bis_concurrent\(",
    r"\bis_level_concurrent\(",
    r"\bget_wrapper_rules\(",
    r"\bunwrap_roots\(",
    #=
    r"\binstantiate\(",
    r"\bresolve\(",
    r"\bprove\(",
    r"lower\(",
    r"\bdeclare!\(",
    r"\bfreeze!\(",
    r"\bthaw!\(",
    r"\bunfurl\(",
    r"\bstylize_access\(",
    r"\bis_injective\(",
    r"\bis_atomic\(",
    r"\bopen_scope\(",
    r"\blower_global\(",
    r"\bsimplify\(",
    r"\bdimensionalize\(",
    r"\bconcordize\(",
    r"\bevaluate_partial\(",
    r"\bwrapperize\(",
    r"\bget_point_body\(",
    r"\bjumper_seek\(",
    r"\bjumper_body\(",
    r"\bjumper_range\(",
    r"\bstepper_seek\(",
    r"\bstepper_body\(",
    r"\bstepper_range\(",
    r"\bphase_range\(",
    r"\bphase_body\(",
    r"\bget_point_body\(",
    r"\bget_acceptrun_body\(",
    r"\bshort_circuit_cases\(",
    r"\bget_spike_body\(",
    r"\bget_spike_tail\(",
    r"\btruncate\(",
    r"\bthunk_access\(",
    r"\bis_level_injective\(",
    r"\bis_level_atomic\(",
    r"\bvirtual_level_size\(",
    r"\bvirtual_level_resize!\(",
    r"\bdeclare_level!\(",
    r"\bthaw_level!\(",
    r"\bfreeze_level!\(",
    r"\bassemble_level!\(",
    r"\bvirtual_moveto\(",
    r"\bvirtual_moveto_level\(",
    r"\bvirtual_call\(",
    r"\bis_laminable\(",
    =#
]
    for file in ARGS
        #if file in ["src/symbolic/analyze_bounds.jl"] || file[1:9] == "benchmark"
        #    continue
        #end
        content = read(file, String)
        newcontent = read(file, String)
        matches = eachmatch(pattern, content)
        for match in matches
            start = match.offset + length(match.match)
            if content[match.offset-4:match.offset - 1] == "Pkg."
                continue
            end
            next = start
            args = []
            while true
                while true
                    foo = findnext(r"[,)]", content, next + 1)
                    if foo == nothing
                        error("Error: $file")
                    end
                    next = first(foo)
                    try 
                        arg, _ = Base.Meta.parse(content[start:next-1], 1, greedy=true)
                        if !(arg isa Expr && arg.head == :incomplete)
                            break
                        end
                    catch
                    end
                end
                push!(args, lstrip(content[start:next-1]))
                if content[next] == ')'
                    break
                else
                    start = next + 1
                end
            end
            #=
            if length(args) == 3
                newcontent = replace(newcontent, content[match.offset:next] => "virtualize($(args[3]), $(args[1]), $(args[2]))")
            elseif length(args) == 4
                newcontent = replace(newcontent, content[match.offset:next] => "virtualize($(args[3]), $(args[1]), $(args[2]), $(args[4]))")
            =#
            if length(args) == 2
                newcontent = replace(newcontent, content[match.offset:next] => "$(match.match)$(args[2]), $(args[1]))")
            elseif length(args) > 2
                newcontent = replace(newcontent, content[match.offset:next] => "$(match.match)$(args[2]), $(args[1]), $(join(args[3:end], ", ")))")
            else
                println("Error: $file $(match.match) $(args)")
                error()
            end
        end
        write(file, newcontent)
    end
end