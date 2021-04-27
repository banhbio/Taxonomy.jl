using Taxonomy
using Documenter

DocMeta.setdocmeta!(Taxonomy, :DocTestSetup, :(using Taxonomy); recursive=true)

makedocs(;
    modules=[Taxonomy],
    authors="banhbio <ban@kuicr.kyoto-u.ac.jp>",
    repo="https://github.com/banhbio/Taxonomy.jl/blob/{commit}{path}#{line}",
    sitename="Taxonomy.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://banhbio.github.io/Taxonomy.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/banhbio/Taxonomy.jl.git",
    latest="main",
)
