using Finch
using Documenter

DocMeta.setdocmeta!(Finch, :DocTestSetup, :(using Finch); recursive=true)

makedocs(;
    modules=[Finch],
    authors="Peter Ahrens",
    repo="https://github.com/peterahrens/Finch.jl/blob/{commit}{path}#{line}",
    sitename="Finch.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://peterahrens.github.io/Finch.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "The Deets" => "listing.md",
    ],
)

deploydocs(;
    repo="github.com/peterahrens/Finch.jl",
    devbranch="main",
)
