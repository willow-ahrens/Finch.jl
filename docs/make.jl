using Finch
using Documenter

DocMeta.setdocmeta!(Finch, :DocTestSetup, :(using Finch; using SparseArrays); recursive=true)

makedocs(;
    modules=[Finch],
    authors="Willow Ahrens",
    repo="https://github.com/willowahrens/Finch.jl/blob/{commit}{path}#{line}",
    sitename="Finch.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://willowahrens.github.io/Finch.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "Level Formats" => "level.md",
        "The Deets" => "listing.md",
        "Embedding" => "embed.md",
    ],
)

deploydocs(;
    repo="github.com/willowahrens/Finch.jl",
    devbranch="main",
)
