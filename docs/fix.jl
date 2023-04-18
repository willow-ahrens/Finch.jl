using Test, Documenter, Literate, Finch, TOML

root = joinpath(@__DIR__, "..")

FINCHVERSION = "v$(TOML.parsefile(joinpath(root, "Project.toml"))["version"])"

function update_FINCHVERSION(content)
    content = replace(content, "FINCHVERSION" => FINCHVERSION)
    return content
end

DocMeta.setdocmeta!(Finch, :DocTestSetup, :(using Finch; using SparseArrays); recursive=true)

mdkwargs = (flavor = Literate.CommonMarkFlavor(),
    postprocess = update_FINCHVERSION,
    credit = false)

Literate.markdown(joinpath(root, "README.jl"), root; mdkwargs...)

Literate.notebook(joinpath(@__DIR__, "src/interactive.jl"), joinpath(@__DIR__, "src"), credit = false)

doctest(Finch, fix=true)