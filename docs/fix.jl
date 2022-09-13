using Test, Documenter, Finch

DocMeta.setdocmeta!(Finch, :DocTestSetup, :(using Finch; using SparseArrays); recursive=true)

doctest(Finch, fix=true)