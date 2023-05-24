#!/usr/bin/env julia
if abspath(PROGRAM_FILE) == @__FILE__
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.instantiate()
end

using Test
using Documenter
using Literate
using Finch

root = joinpath(@__DIR__, "..")

DocMeta.setdocmeta!(Finch, :DocTestSetup, :(using Finch; using SparseArrays); recursive=true)

Literate.notebook(joinpath(@__DIR__, "src/interactive.jl"), joinpath(@__DIR__, "src"), credit = false)
Literate.markdown(joinpath(@__DIR__, "src/benchmark.jl"), joinpath(@__DIR__, "src"), credit = false, execute = true)

doctest(Finch, fix=true)