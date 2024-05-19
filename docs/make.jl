#!/usr/bin/env julia
if abspath(PROGRAM_FILE) == @__FILE__
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.develop(PackageSpec(path = joinpath(@__DIR__, "..")))
    Pkg.resolve()
    Pkg.instantiate()
end

using Documenter
using Documenter.Remotes
using Finch

DocMeta.setdocmeta!(Finch, :DocTestSetup, :(using Finch; using SparseArrays); recursive=true)

makedocs(;
    modules=[Finch],
    authors="Willow Ahrens",
    repo=Remotes.GitHub("willow-ahrens", "Finch.jl"),
    sitename="Finch.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://willow-ahrens.github.io/Finch.jl",
        assets=["assets/favicon.ico"],
        size_threshold = 1_000_000,
    ),
    pages=[
        "Home" => "index.md",
        #"Getting Started" => "getting_started.md",
        #"Practical Tutorials and Use Cases" => "tutorials_use_cases/tutorials_use_cases.md",
        "Comprehensive Guides" => [
            "Calling Finch" => "guides/calling_finch.md",
            "Tensor Formats" => "guides/tensor_formats.md",
            "Sparse and Structured Utilities" => "guides/sparse_utils.md",
            "The Finch Language" => "guides/finch_language.md",
            "Dimensionalization" => "guides/dimensionalization.md",
            #"Tensor Lifecycles" => "guides/tensor_lifecycles.md",
            "Index Sugar" => "guides/index_sugar.md",
            "Mask Sugar" => "guides/mask_sugar.md",
            "Iteration Protocols" => "guides/iteration_protocols.md",
            "Custom Operators" => "guides/custom_operators.md",
            "High-Level Array API" => "guides/array_api.md",
            #"Parallelization and Architectures" => "guides/parallelization.md",
            "FileIO" => "guides/fileio.md",
            "Interoperability" => "guides/interoperability.md",
            "Optimization Tips" => "guides/optimization_tips.md",
            "Benchmarking Tips" => "guides/benchmarking_tips.md",
            #"Debugging Tips" => "guides/debugging_tips.md",
        ],
        "Technical Reference" => [
        #    "Finch Core API" => "reference/core_api.md",
            "Documentation Listing" => "reference/listing.md",
            "Advanced Implementation Details" => [
                "Internals" => "reference/advanced_implementation/internals.md",
        #        "Looplets and Coiteration" => "reference/advanced_implementation/looplets_coiteration.md",
        #        "Concordization" => "reference/advanced_implementation/concordization.md",
        #        "Local Variables and Constant Propagation" => "reference/advanced_implementation/local_variables.md",
                "Tensor Interface" => "reference/advanced_implementation/tensor_interface.md",
        #        "Looplet Interface" => "reference/advanced_implementation/looplet_interface.md",
            ],
        ],
        "Community and Contributions" => "CONTRIBUTING.md",
        "Appendices and Additional Resources" => [
            #"Glossary" => "appendices/glossary.md",
            #"FAQs" => "appendices/faqs.md",
            "Directory Structure" => "appendices/directory_structure.md",
            #"Changelog" => "appendices/changelog.md",
            #"Publications and Articles" => "appendices/publications_articles.md",
        ],
    ],
    warnonly=[:missing_docs],
)

deploydocs(;
    repo="github.com/willow-ahrens/Finch.jl",
    devbranch="main",
)
