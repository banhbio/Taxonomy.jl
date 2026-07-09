using Taxonomy
using Documenter

const DOCTEST_DB_DIR = joinpath(@__DIR__, "src", "assets", "doctest-db")

DocMeta.setdocmeta!(
    Taxonomy,
    :DocTestSetup,
    quote
        using Taxonomy
        using Taxonomy.AbstractTrees
        _DOCTEST_DB_DIR = $(DOCTEST_DB_DIR)
        db = Taxonomy.DB(
            joinpath(_DOCTEST_DB_DIR, "nodes.dmp"),
            joinpath(_DOCTEST_DB_DIR, "names.dmp"),
        )
        human = Taxon(9606, db)
        lineage = Lineage(human)
        seven_rank = [:domain, :phylum, :class, :order, :family, :genus, :species]
    end;
    recursive=true,
)

function sync_readme_to_index!()
    readme_path = joinpath(@__DIR__, "..", "README.md")
    index_path = joinpath(@__DIR__, "src", "index.md")

    readme = read(readme_path, String)
    index = replace(readme, "![](docs/src/img" => "![](img")

    if !isfile(index_path) || read(index_path, String) != index
        write(index_path, index)
    end
    return nothing
end

sync_readme_to_index!()

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
        "Usage" => "man/usage.md",
        "API Reference" => "man/api.md",
    ],
)

deploydocs(;
    repo="github.com/banhbio/Taxonomy.jl.git",
    devbranch="main",
)
