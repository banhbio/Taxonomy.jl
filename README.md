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
julia> db = Taxonomy.DB("db/nodes.dmp","db/names.dmp")
#
julia> db = Taxonomy.DB("/your/path/to/db","nodes.dmp","names.dmp")
```

You can construct a `Taxon` object from its taxonomic identifier and the `TaxonomyDatabase` object.


```julia
julia> human = Taxon(9606, db) # species Homo sapiens
9606 [species] Homo sapiens

julia> gorilla = Taxon(9593, db) # species Gorilla gorilla
9593 [species] Gorilla gorilla

julia> bacillus = Taxon(1386,db) # genus Bacillus
1386 [genus] Bacillus
```
Each `Taxon` object has 4-field `taxid`, `name`, `rank` and `db`. The filed `db` is hidden in the `print()` fuction, etc.

```julia
julia> @show human.taxid
human.taxid = 9606

julia> @show human.name
human.name = "Homo sapiens"

julia> @show human.rank
human.rank = :species
```
You can get a variety of information, such as rank, parent and children by using functions.
```julia
julia> rank(gorilla)
:species

julia> parent(gorilla)
9592 [genus] Gorilla
```
```julia
julia> children(bacillus)
249-element Array{Taxon,1}:
 427072 [species] Bacillus chagannorensis
 904295 [species] Bacillus ginsengisoli
 1522318 [species] Bacillus kwashiorkori
 1245522 [species] Bacillus thermophilus
 1178786 [species] Bacillus thaonhiensis
 1805474 [species] Bacillus mediterraneensis
 ⋮
 324768 [species] Bacillus idriensis
 745819 [species] Bacillus alkalicola
 170350 [species] Bacillus deramificans
 1522308 [species] Bacillus niameyensis
 324767 [species] Bacillus infantis
```
```julia
julia> lca(human, gorilla)
207598 [subfamily] Homininae
```

Fuctions from `AbstractTrees` can also be used.
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
Lineage information can be acquired by using `Lineage()`.
```julia
julia> Lineage(gorilla)
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
struct Lineage stores linage 