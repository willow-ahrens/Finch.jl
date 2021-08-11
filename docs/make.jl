using Thrush
using Documenter

DocMeta.setdocmeta!(Thrush, :DocTestSetup, :(using Thrush); recursive=true)

makedocs(;
    modules=[Thrush],
    authors="Peter Ahrens",
    repo="https://github.com/peterahrens/Thrush.jl/blob/{commit}{path}#{line}",
    sitename="Thrush.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://peterahrens.github.io/Thrush.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/peterahrens/Thrush.jl",
)
