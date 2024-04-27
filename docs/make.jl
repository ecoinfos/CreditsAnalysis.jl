using CreditsAnalysis
using Documenter

DocMeta.setdocmeta!(CreditsAnalysis, :DocTestSetup, :(using CreditsAnalysis); recursive=true)

makedocs(;
    modules=[CreditsAnalysis],
    authors="Kwang-Seuk <kjeong@bhug.ac.kr> and contributors",
    sitename="CreditsAnalysis.jl",
    format=Documenter.HTML(;
        canonical="https://ecoinfos.github.io/CreditsAnalysis.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ecoinfos/CreditsAnalysis.jl",
    devbranch="master",
)
