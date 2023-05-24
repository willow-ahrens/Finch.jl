#!/usr/bin/env julia
if abspath(PROGRAM_FILE) == @__FILE__
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.instantiate()
end

using Documenter
using Literate
using Finch

DocMeta.setdocmeta!(Finch, :DocTestSetup, :(using Finch; using SparseArrays); recursive=true)

makedocs(;
    modules=[Finch],
    authors="Willow Ahrens",
    repo="https://github.com/willow-ahrens/Finch.jl/blob/{commit}{path}#{line}",
    sitename="Finch.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://willow-ahrens.github.io/Finch.jl",
        assets=["assets/favicon.ico"],
    ),
    pages=[
        "Home" => "index.md",
        "Usage" => "usage.md",
        "Array Formats" => "fibers.md",
        "Custom Functions" => "algebra.md",
        "Tensor File I/O" => "fileio.md",
        "C, C++, ..." => "interop.md",
        "Performance Tips" => "performance.md",
        "Internals" => "internals.md",
        "Directory Structure" => "directory_structure.md",
        "Contributing" => "CONTRIBUTING.md",
    ],
)

deploydocs(;
    repo="github.com/willow-ahrens/Finch.jl",
    devbranch="main",
)