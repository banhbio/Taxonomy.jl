using Taxonomy
using Documenter

DocMeta.setdocmeta!(Taxonomy, :DocTestSetup, :(using Taxonomy); recursive=true)

function readme2index()
    readme_path = "README.md"
    index_path = "docs/src/index.md" 
    f = open(readme_path)
    g = open(index_path)
    try
        readme = read(f,String)
        replace!(readme,"![](docs/src/img" => "![](img")
        write(g,readme)
    finally
        close(f)
        close(g)
    end
end

readme2index()

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
    devbranch="main",
)
