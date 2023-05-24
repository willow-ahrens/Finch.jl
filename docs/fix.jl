#!/usr/bin/env julia
if abspath(PROGRAM_FILE) == @__FILE__
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.instantiate()
end

using Test
using Documenter
using Literate
using TOML
using Finch

root = joinpath(@__DIR__, "..")

FINCHVERSION = "v$(TOML.parsefile(joinpath(root, "Project.toml"))["version"])"

function update_FINCHVERSION(content)
    content = replace(content, "FINCHVERSION" => FINCHVERSION)
    return content
end

DocMeta.setdocmeta!(Finch, :DocTestSetup, :(using Finch; using SparseArrays); recursive=true)

mdkwargs = (flavor = Literate.CommonMarkFlavor(),
    postprocess = update_FINCHVERSION,
    execute = true,
    credit = false)

Literate.notebook(joinpath(@__DIR__, "src/interactive.jl"), joinpath(@__DIR__, "src"), credit = false)

doctest(Finch, fix=true)