# Taxonomy.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://banhbio.github.io/Taxonomy.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://banhbio.github.io/Taxonomy.jl/dev)

[![CI](https://github.com/banhbio/Taxonomy.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/banhbio/Taxonomy.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/banhbio/Taxonomy.jl/branch/main/graph/badge.svg?token=2A8WQRHRLC)](https://codecov.io/gh/banhbio/Taxonomy.jl)

Taxonomy.jl is a julia package to handle NCBI-formatted taxonomic databases.
The main features are:
- Convert a name to taxids
- Filter taxa by rank
- Evaluate ancestor/descendant relationships between two taxa
- Construct taxonomic lineage of the given taxon
- Reformat lineage according to canonical ranks
- Construct a `DataFrame` from lineages
- Traverse taxonomic subtrees from a given taxon
- Compute the lowest common ancestor (LCA) of given taxons

Now, this package only supports `scientific name`.

## Installation
Install Taxonomy.jl as follows:
```
julia -e 'using Pkg; Pkg.add("Taxonomy")'
```

## Download database
You need to download taxonomic data from NCBI's servers.
```
wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
tar xzvf taxdump.tar.gz
```

## Usage
```julia
# Load the package
julia> using Taxonomy

julia> db = Taxonomy.DB("db/nodes.dmp","db/names.dmp") # Create a Taxonomy.DB objext from the path to each file
```

```julia
# species Homo sapiens
julia> human = Taxon(9606, db)
9606 [species] Homo sapiens

# omitting db automatically calls currnent_db()
julia> human = Taxon(9606)
9606 [species] Homo sapiens

julia> taxid(human)
9606

julia> name(human)
"Homo sapiens"

julia> rank(human)
:species
```

```julia
julia> ["Homo", "Viruses", "Drosophila"] .|> name2taxids |> Iterators.flatten .|> Taxon
5-element Vector{Taxon}:
 9605 [genus] Homo
 10239 [superkingdom] Viruses
 7215 [genus] Drosophila
 2081351 [genus] Drosophila
 32281 [subgenus] Drosophila
```

```julia
julia> gorilla = Taxon(9592);

julia> lca(human, gorilla)
207598 [subfamily] Homininae
```

```julia
julia> homininae = lca(human, gorilla)

julia> print_tree(homininae)
207598 [subfamily] Homininae
├─ 9596 [genus] Pan
│  ├─ 9597 [species] Pan paniscus
│  └─ 9598 [species] Pan troglodytes
│     ├─ 37010 [subspecies] Pan troglodytes schweinfurthii
│     ├─ 37011 [subspecies] Pan troglodytes troglodytes
│     ├─ 1294088 [subspecies] Pan troglodytes verus x troglodytes
│     ├─ 91950 [subspecies] Pan troglodytes vellerosus
│     ├─ 756884 [subspecies] Pan troglodytes ellioti
│     └─ 37012 [subspecies] Pan troglodytes verus
├─ 9605 [genus] Homo
│  ├─ 9606 [species] Homo sapiens
│  │  ├─ 63221 [subspecies] Homo sapiens neanderthalensis
│  │  └─ 741158 [subspecies] Homo sapiens subsp. 'Denisova'
│  ├─ 1425170 [species] Homo heidelbergensis
│  └─ 2665952 [no rank] environmental samples
│     └─ 2665953 [species] Homo sapiens environmental sample
└─ 9592 [genus] Gorilla
   ├─ 499232 [species] Gorilla beringei
   │  ├─ 1159185 [subspecies] Gorilla beringei beringei
   │  └─ 46359 [subspecies] Gorilla beringei graueri
   └─ 9593 [species] Gorilla gorilla
      ├─ 183511 [subspecies] Gorilla gorilla uellensis
      ├─ 406788 [subspecies] Gorilla gorilla diehli
      └─ 9595 [subspecies] Gorilla gorilla gorilla
```

### Lineage

Lineage information can be acquired by using `Lineage()`.

```julia
julia> lineage = Lineage(gorilla)
32-element Lineage:
 1 [no rank] root
 131567 [no rank] cellular organisms
 2759 [superkingdom] Eukaryota
 33154 [clade] Opisthokonta
 33208 [kingdom] Metazoa
 6072 [clade] Eumetazoa
 33213 [clade] Bilateria
 ⋮
 314293 [infraorder] Simiiformes
 9526 [parvorder] Catarrhini
 314295 [superfamily] Hominoidea
 9604 [family] Hominidae
 207598 [subfamily] Homininae
 9592 [genus] Gorilla
 9593 [species] Gorilla gorilla
```

Struct `Lineage` stores linage informaction in `Vector`-like format.

```julia
julia> lineage[1]
1 [no rank] root

julia> lineage[9]
7711 [phylum] Chordata

julia> lineage[end]
9593 [species] Gorilla gorilla
```

You can also access a `Taxon` in the `Lineage` using `Symbol`, such as `:superkingdom`, `:family`, `:genus`, `:species` and etc.(Only Symbols in `CanonicalRanks` can be used).

```julia
julia> lineage[:order]
9443 [order] Primates

julia> lineage[:genus]
9592 [genus] Gorilla
```

You can use `Between`, `From`, `Until`, `Cols` and `All` selectors in more complex rank selection scenarios.

```julia
julia> lineage[Between(:order,:genus)]
8-element Lineage:
 9443 [order] Primates
 376913 [suborder] Haplorrhini
 314293 [infraorder] Simiiformes
 9526 [parvorder] Catarrhini
 314295 [superfamily] Hominoidea
 9604 [family] Hominidae
 207598 [subfamily] Homininae
 9592 [genus] Gorilla

julia> lineage[From(:family)]
4-element Lineage:
 9604 [family] Hominidae
 207598 [subfamily] Homininae
 9592 [genus] Gorilla
 9593 [species] Gorilla gorilla

julia> lineage[Until(:class)]
19-element Lineage:
 1 [no rank] root
 131567 [no rank] cellular organisms
 2759 [superkingdom] Eukaryota
 33154 [clade] Opisthokonta
 33208 [kingdom] Metazoa
 6072 [clade] Eumetazoa
 33213 [clade] Bilateria
 ⋮
 117570 [clade] Teleostomi
 117571 [clade] Euteleostomi
 8287 [superclass] Sarcopterygii
 1338369 [clade] Dipnotetrapodomorpha
 32523 [clade] Tetrapoda
 32524 [clade] Amniota
 40674 [class] Mammalia
```

Reformation of the lineage to your ranks can be performed by using `reformat()`.

```julia
julia> myrank = [:superkingdom, :phylum, :class, :order, :family, :genus, :species]

julia> reformat(lineage, myrank)
7-element Lineage:
 2759 [superkingdom] Eukaryota
 7711 [phylum] Chordata
 40674 [class] Mammalia
 9443 [order] Primates
 9604 [family] Hominidae
 9592 [genus] Gorilla
 9593 [species] Gorilla gorilla
```

If there is no corresponding taxon in the lineage to your ranks, then `UnclassifiedTaxon` will be stored.

```julia
julia> uncultured_bacillales = Taxon(157472,db)
57472 [species] uncultured Bacillales bacterium

julia> reformated = reformat(Lineage(uncultured_bacillales), myrank)
7-element Lineage:
 2 [superkingdom] Bacteria
 1239 [phylum] Firmicutes
 91061 [class] Bacilli
 1385 [order] Bacillales
 Unclassified [family] unclassified Bacillales family
 Unclassified [genus] unclassified Bacillales genus
 157472 [species] uncultured Bacillales bacterium
```
