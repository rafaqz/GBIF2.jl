using GBIF2
using Documenter

DocMeta.setdocmeta!(GBIF2, :DocTestSetup, :(using GBIF2); recursive=true)

makedocs(;
    modules=[GBIF2],
    authors="Rafael Schouten <rafaelschouten@gmail.com>",
    repo="https://github.com/EcoJulia/GBIF2.jl/blob/{commit}{path}#{line}",
    sitename="GBIF2.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://docs.EcoJulia.org/GBIF2.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/EcoJulia/GBIF2.jl",
    devbranch="main",
)
