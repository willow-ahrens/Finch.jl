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
        #"Getting Started" => "getting_started.md",
        #"Practical Tutorials and Use Cases" => "tutorials_use_cases/tutorials_use_cases.md",
        "Comprehensive Guides" => [
            "Calling Finch" => "comprehensive_guides/calling_finch.md",
            "The Finch Language" => "comprehensive_guides/finch_language.md",
            "Exploration of Tensor Formats" => "comprehensive_guides/tensor_formats.md",
            #"Dimensionalization" => "comprehensive_guides/dimensionalization.md",
            #"Tensor Lifecycles" => "comprehensive_guides/tensor_lifecycles.md",
            #"Special Tensors" => [
            #    "Overview" => "comprehensive_guides/special_tensors/overview.md",
            #    "Wrapper Tensors" => "comprehensive_guides/special_tensors/wrapper_tensors.md",
            #    "Symbolic Tensors" => "comprehensive_guides/special_tensors/symbolic_tensors.md",
            #    "Early Break Strategies" => "comprehensive_guides/special_tensors/early_break.md",
            #],
            #"Index Sugar" => "comprehensive_guides/index_sugar.md",
            "Simplification and Custom Operators" => "comprehensive_guides/algebra.md",
            #"Parallelization and Architectures" => "comprehensive_guides/parallelization.md",
            "FileIO" => "comprehensive_guides/FileIO.md",
            "Interoperability" => "comprehensive_guides/interoperability.md",
            "Optimization Tips" => "comprehensive_guides/optimization_tips.md",
            "Benchmarking Tips" => "comprehensive_guides/benchmarking_tips.md",
            #"Debugging Tips" => "comprehensive_guides/debugging_tips.md",
        ],
        "Technical Reference" => [
            "Finch Core API" => "technical_reference/core_api.md",
            "Function and Method Reference" => "technical_reference/function_method_ref.md",
            "Advanced Implementation Details" => [
                "Internals" => "technical_reference/advanced_implementation/internals.md",
                "Looplets and Coiteration" => "technical_reference/advanced_implementation/looplets_coiteration.md",
                "Concordization" => "technical_reference/advanced_implementation/concordization.md",
                "Local Variables and Constant Propagation" => "technical_reference/advanced_implementation/local_variables.md",
                "Tensor Interface" => "technical_reference/advanced_implementation/tensor_interface.md",
                "Looplet Interface" => "technical_reference/advanced_implementation/looplet_interface.md",
            ],
        ],
        "Community and Contributions" => "../CONTRIBUTING.md",
        "Appendices and Additional Resources" => [
            "Glossary" => "appendices/glossary.md",
            "FAQs" => "appendices/faqs.md",
            "Directory Structure" => "appendices/directory_structure.md",
            "Changelog" => "appendices/changelog.md",
            "Publications and Articles" => "appendices/publications_articles.md",
        ],
    ],
    warnonly=[:missing_docs],
)

deploydocs(;
    repo="github.com/willow-ahrens/Finch.jl",
    devbranch="main",
)
