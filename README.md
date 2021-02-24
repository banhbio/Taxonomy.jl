# Taxonomy.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://banhbio.github.io/Taxonomy.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://banhbio.github.io/Taxonomy.jl/dev)
[![Build Status](https://travis-ci.com/banhbio/Taxonomy.jl.svg?token=TnLbrgdWxoQMPrAZynWc&branch=main)](https://travis-ci.com/banhbio/Taxonomy.jl)

Taxonomy.jl is a julia package to handle NCBI-formatted taxonomic databases.

Installation
------------
Install Taxonomy.jl as follows:
```
julia -e 'using Pkg; Pkg.add("Taxonomy")'
```

Usage
-----
First, you need to download taxonomic data from NCBI's servers (ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz).
```julia
# Load the package
julia> using Taxonomy
#
julia> db = TaxonomyDatabase("db/nodes.dmp","db/names.dmp")
#
julia> db = TaxonomyDatabase("/your/path/to/db","nodes.dmp","names.dmp")
```

You can construct a `Taxon` object from its taxonomic identifier and the `TaxonomyDatabase` object.


```julia
julia> human = Taxon(9606, db) # species Homo sapiens
Taxon(9606, "Homo sapiens")

julia> wgorilla = Taxon(9593, db) # species Gorilla gorilla
Taxon(9593, "Gorilla gorilla")

julia> bacillus = Taxon(1386,db) # genus Bacillus
Taxon(1386, "Bacillus")
```
Each `Taxon` object has 3-field `taxid`, `name` and `db`. The filed `db` is hidden in the `print()` fuction, etc.

```julia
julia> @show human.taxid
human.taxid = 9606

julia> @show human.name
human.name = "Homo sapiens"
```
You can get a variety of information, such as rank, parent, lineage and children by using functions.
```julia
julia> rank(gorilla)
"species"

julia> parent(gorilla)
Taxon(9592, "Gorilla")
```
```julia
julia> lineage(gorilla)
32-element Array{Taxon,1}:
 Taxon(9593, "Gorilla gorilla")
 Taxon(9592, "Gorilla")
 Taxon(207598, "Homininae")
 Taxon(9604, "Hominidae")
 Taxon(314295, "Hominoidea")
 ⋮
 Taxon(33154, "Opisthokonta")
 Taxon(2759, "Eukaryota")
 Taxon(131567, "cellular organisms")
 Taxon(1, "root")
```
```julia
julia> children(bacillus)
 Taxon(427072, "Bacillus chagannorensis")
 Taxon(904295, "Bacillus ginsengisoli")
 Taxon(1522318, "Bacillus kwashiorkori")
 Taxon(1245522, "Bacillus thermophilus")
 Taxon(1178786, "Bacillus thaonhiensis")
 ⋮
 Taxon(324768, "Bacillus idriensis")
 Taxon(745819, "Bacillus alkalicola")
 Taxon(170350, "Bacillus deramificans")
 Taxon(1522308, "Bacillus niameyensis")
 Taxon(324767, "Bacillus infantis")
```
```julia
julia> l = [human, gorilla]
julia> lca(l)
Taxon(207598, "Homininae")
```

Fuctions from `AbstractTrees` can also be used.
```julia
julia> hominiae = Taxon(207598,db)
julia> print_tree(hominae)
Taxon(207598, "Homininae")
├─ Taxon(9596, "Pan")
│  ├─ Taxon(9597, "Pan paniscus")
│  └─ Taxon(9598, "Pan troglodytes")
│     ├─ Taxon(37010, "Pan troglodytes schweinfurthii")
│     ├─ Taxon(37011, "Pan troglodytes troglodytes")
│     ├─ Taxon(1294088, "Pan troglodytes verus x troglodytes")
│     ├─ Taxon(91950, "Pan troglodytes vellerosus")
│     ├─ Taxon(756884, "Pan troglodytes ellioti")
│     └─ Taxon(37012, "Pan troglodytes verus")
├─ Taxon(9605, "Homo")
│  ├─ Taxon(9606, "Homo sapiens")
│  │  ├─ Taxon(63221, "Homo sapiens neanderthalensis")
│  │  └─ Taxon(741158, "Homo sapiens subsp. 'Denisova'")
│  ├─ Taxon(1425170, "Homo heidelbergensis")
│  └─ Taxon(2665952, "environmental samples")
│     └─ Taxon(2665953, "Homo sapiens environmental sample")
└─ Taxon(9592, "Gorilla")
   ├─ Taxon(499232, "Gorilla beringei")
   │  ├─ Taxon(1159185, "Gorilla beringei beringei")
   │  └─ Taxon(46359, "Gorilla beringei graueri")
   └─ Taxon(9593, "Gorilla gorilla")
      ├─ Taxon(183511, "Gorilla gorilla uellensis")
      ├─ Taxon(406788, "Gorilla gorilla diehli")
      └─ Taxon(9595, "Gorilla gorilla gorilla")
```