# Usage

## Construct Database

```julia
# Load the package
julia> using Taxonomy

# Construct a Taxonomy.DB objext from the path to each file
julia> db = Taxonomy.DB("db/nodes.dmp","db/names.dmp")
Taxonomy.DB("db/nodes.dmp","db/names.dmp")

# Taxonomy.DB object is automatically stored in current_db()
julia> current_db()
Taxonomy.DB("db/nodes.dmp","db/names.dmp")
```

## Get taxonomic information from `Taxon`

```julia
## Construct a Taxon from taxid and Taxonomy.DB
julia> human = Taxon(9606, db)
9606 [species] Homo sapiens

## Or, you can omit db from argument (current_db() loaded)
julia> human = Taxon(9606)
9606 [species] Homo sapiens

julia> taxid(human)
9606

julia> name(human)
"Homo sapiens"

julia> rank(human)
:species
```

## Construct `Taxon`s from names

Name must match to the scientific name excatly
```julia
julia> ["Homo", "Viruses", "Drosophila"] .|> name2taxids |> Iterators.flatten .|> Taxon
5-element Vector{Taxon}:
 9605 [genus] Homo
 10239 [superkingdom] Viruses
 7215 [genus] Drosophila
 2081351 [genus] Drosophila
 32281 [subgenus] Drosophila
```

## 

## Traverse taxonomic subtrees from a given `Taxon`

```julia
julia> children(human)
2-element Vector{Taxon}:
 741158 [subspecies] Homo sapiens subsp. 'Denisova'
 63221 [subspecies] Homo sapiens neanderthalensis

julia> AbstractTrees.parent(human)
9605 [genus] Homo

# Collect all Taxon in subtree using PreOderDFS iterator from AbstractTrees.jl
julia> collect(AbastractTrees.PreOrderDFS(human))
3-element Vector{Taxon}:
 9606 [species] Homo sapiens
 741158 [subspecies] Homo sapiens subsp. 'Denisova'
 63221 [subspecies] Homo sapiens neanderthalensis

# print subtree
julia> print_tree(Taxon(9604))
9604 [family] Hominidae
├─ 2922387 [no rank] unclassified Hominidae
│  └─ 2922388 [species] Hominidae sp.
├─ 607660 [subfamily] Ponginae
│  └─ 9599 [genus] Pongo
│     ├─ 502961 [species] Pongo abelii x pygmaeus
│     ├─ 9600 [species] Pongo pygmaeus
│     │  ├─ 9602 [subspecies] Pongo pygmaeus pygmaeus
│     │  ├─ 2753605 [subspecies] Pongo pygmaeus morio
│     │  └─ 2753606 [subspecies] Pongo pygmaeus wurmbii
│     ├─ 9601 [species] Pongo abelii
│     ├─ 2624844 [no rank] unclassified Pongo
│     │  └─ 9603 [species] Pongo sp.
│     └─ 2051901 [species] Pongo tapanuliensis
├─ 2883640 [no rank] Hominidae intergeneric hybrids
│  └─ 2883641 [species] Homo sapiens x Pan troglodytes tetraploid cell line
└─ 207598 [subfamily] Homininae
   ├─ 9596 [genus] Pan
   │  ├─ 9597 [species] Pan paniscus
   │  └─ 9598 [species] Pan troglodytes
   │     ├─ 37011 [subspecies] Pan troglodytes troglodytes
   │     ├─ 37010 [subspecies] Pan troglodytes schweinfurthii
   │     ├─ 756884 [subspecies] Pan troglodytes ellioti
   │     ├─ 1294088 [subspecies] Pan troglodytes verus x troglodytes
   │     └─ 37012 [subspecies] Pan troglodytes verus
   ├─ 9605 [genus] Homo
   │  ├─ 2665952 [no rank] environmental samples
   │  │  └─ 2665953 [species] Homo sapiens environmental sample
   │  ├─ 2813598 [no rank] unclassified Homo
   │  │  └─ 2813599 [species] Homo sp.
   │  ├─ 9606 [species] Homo sapiens
   │  │  ├─ 741158 [subspecies] Homo sapiens subsp. 'Denisova'
   │  │  └─ 63221 [subspecies] Homo sapiens neanderthalensis
   │  └─ 1425170 [species] Homo heidelbergensis
   └─ 9592 [genus] Gorilla
      ├─ 9593 [species] Gorilla gorilla
      │  ├─ 183511 [subspecies] Gorilla gorilla uellensis
      │  ├─ 406788 [subspecies] Gorilla gorilla diehli
      │  └─ 9595 [subspecies] Gorilla gorilla gorilla
      └─ 499232 [species] Gorilla beringei
         ├─ 46359 [subspecies] Gorilla beringei graueri
         └─ 1159185 [subspecies] Gorilla beringei beringei
```
**Note:** Use the child-to-parent traverse as much as possible since the parent-to-child is very slow compared to the child-to-parent

## Find lowest common ancestor (LCA)
```julia
julia> human = Taxon(9606); gorilla = Taxon(9592); orangutan = Taxon(9600);

juliia> lca(human, gorilla)
207598 [subfamily] Homininae

julia> lca(human, gorilla, orangutan)
9604 [family] Hominidae
s
julia> lca([human, gorilla, orangutan])
9604 [family] Hominidae
```


## Evaluate ancestor/descendant relationships between two `Taxon`s
```julia
julia> viruses = Taxon(10239)
10239 [superkingdom] Viruses

julia> sars_cov2 = Taxon(2697049)
2697049 [no rank] Severe acute respiratory syndrome coronavirus 2

julia> isancestor(viruses, sars_cov2)
true

julia> isdescendant(human, viruses)
false
```

## Filter `Taxon`s from rank range
```julia
julia> taxa = [2759, 33208, 7711, 40674, 9443, 9604, 9605, 9606] .|> Taxon
8-element Vector{Taxon}:
 2759 [superkingdom] Eukaryota
 33208 [kingdom] Metazoa
 7711 [phylum] Chordata
 40674 [class] Mammalia
 9443 [order] Primates
 9604 [family] Hominidae
 9605 [genus] Homo
 9606 [species] Homo sapiens

# Filter `Taxon`s lower than a given rank
julia> filter(taxa) do taxon
           taxon < Rank(:class)
       end
4-element Vector{Taxon}:
 9443 [order] Primates
 9604 [family] Hominidae
 9605 [genus] Homo
 9606 [species] Homo sapiens

julia> filter(taxa) do taxon
           taxon <= Rank(:species)
       end
1-element Vector{Taxon}:
 9606 [species] Homo sapiens
```

## Treat taxonomic `Lineage`

```julia
julia> lineage = Lineage(human)
32-element Lineage{Taxon}:
 1 [no Rank] root
 131567 [no rank] cellular organisms
 2759 [superkingdom] Eukaryota
 33154 [clade] Opisthokonta
 33208 [kingdom] Metazoa
 6072 [clade] Eumetazoa
 33213 [clade] Bilateria
 33511 [clade] Deuterostomia
 7711 [phylum] Chordata
 ⋮
 9443 [order] Primates
 376913 [suborder] Haplorrhini
 314293 [infraorder] Simiiformes
 9526 [parvorder] Catarrhini
 314295 [superfamily] Hominoidea
 9604 [family] Hominidae
 207598 [subfamily] Homininae
 9605 [genus] Homo
 9606 [species] Homo sapiens
```

`Taxon` information are stored in `Vector`-like format
```julia
julia> lineage[1]
1 [no Rank] root

julia> lineage[9]
7711 [phylum] Chordata

julia> lineage[end]
9606 [species] Homo sapiens
```

`Symbol`s such as `:phylum`, `:genus` and `:species` (`Symbol`s in `CanonicalRanks`) are available to access each `Taxon`
```julia
julia> lineage[:phylum]
7711 [phylum] Chordata

julia> lineage[:genus]
9605 [genus] Homo

julia> lineage[:species]
9606 [species] Homo sapiens
```

`Between`, `From`, `Until`, `Cols` and `All` selectors are available in more complex rank selection scenarios.

## Reformat `Lineage`
Reformation of `Linage` to your ranks can be performed by using `reformat()`.
```julia
julia> seven_rank = [:superkingdom, :phylum, :class, :order, :family, :genus, :species];

julia> reformat(lineage, seven_rank)
7-element Lineage{Taxon}:
 2759 [superkingdom] Eukaryota
 7711 [phylum] Chordata
 40674 [class] Mammalia
 9443 [order] Primates
 9604 [family] Hominidae
 9605 [genus] Homo
 9606 [species] Homo sapiens
```

If there is no corresponding taxon in the lineage to your ranks, then `UnclassifiedTaxon` will be stored.
```julia
julia> uncultured_bacillales = Taxon(157472,db)
57472 [species] uncultured Bacillales bacterium

julia> reformatted_bacillales_lineage = reformat(Lineage(uncultured_bacillales), seven_rank)
7-element Lineage:
 2 [superkingdom] Bacteria
 1239 [phylum] Firmicutes
 91061 [class] Bacilli
 1385 [order] Bacillales
 Unclassified [family] unclassified Bacillales family
 Unclassified [genus] unclassified Bacillales genus
 157472 [species] uncultured Bacillales bacterium
```

Once reformatted, `Lineage` cannnot be reformatted again.
```julia
julia> isreformatted(reformatted_bacillales_lineage)
true

julia> reformat(reformatted_bacillales_lineage, seven_rank)
ERROR: It is already reformatted.
Stacktrace:
 [1] _LR()
   @ Taxonomy ~/.julia/dev/Taxonomy.jl/src/lineage.jl:7
 [2] reformat(l::Lineage{Union{Taxon, UnclassifiedTaxon}}, ranks::Vector{Symbol})
   @ Taxonomy ~/.julia/dev/Taxonomy.jl/src/lineage.jl:135
 [3] top-level scope
   @ REPL[103]:1
```

## Convert `Lineage`s to `DataFrame`

`Lineage` can be converted to `NamedTuple`, using `namedtuple`.

Convered `NamedTuple` can be used as input into `DataFrame`
```julia
julia> using DataFrames

julia> seven_rank = [:superkingdom, :phylum, :class, :order, :family, :genus, :species];

julia> taxa = [9606, 562, 187878, 212035, 2697049] .|> Taxon
5-element Vector{Taxon}:
 9606 [species] Homo sapiens
 562 [species] Escherichia coli
 187878 [species] Thermococcus gammatolerans
 212035 [species] Acanthamoeba polyphaga mimivirus
 2697049 [no rank] Severe acute respiratory syndrome coronavirus 2

julia> taxa .|> Lineage .|> (x -> reformat(x, seven_rank)) .|> namedtuple |> DataFrame
5×7 DataFrame
 Row │ superkingdom                   phylum                             class                             order                           family                           genus                           species                           
     │ Taxon                          Taxon                              Taxon                             Taxon                           Taxon                            Taxon                           Taxon                             
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 2759 [superkingdom] Eukaryota  7711 [phylum] Chordata             40674 [class] Mammalia            9443 [order] Primates           9604 [family] Hominidae          9605 [genus] Homo               9606 [species] Homo sapiens
   2 │ 2 [superkingdom] Bacteria      1224 [phylum] Proteobacteria       1236 [class] Gammaproteobacteria  91347 [order] Enterobacterales  543 [family] Enterobacteriaceae  561 [genus] Escherichia         562 [species] Escherichia coli
   3 │ 2157 [superkingdom] Archaea    28890 [phylum] Euryarchaeota       183968 [class] Thermococci        2258 [order] Thermococcales     2259 [family] Thermococcaceae    2263 [genus] Thermococcus       187878 [species] Thermococcus ga…
   4 │ 10239 [superkingdom] Viruses   2732007 [phylum] Nucleocytoviric…  2732523 [class] Megaviricetes     2732554 [order] Imitervirales   549779 [family] Mimiviridae      315393 [genus] Mimivirus        212035 [species] Acanthamoeba po…
   5 │ 10239 [superkingdom] Viruses   2732408 [phylum] Pisuviricota      2732506 [class] Pisoniviricetes   76804 [order] Nidovirales       11118 [family] Coronaviridae     694002 [genus] Betacoronavirus  694009 [species] Severe acute re…

# Dealing with UnclassifiedTaxon as missing value

julia> taxa = [287, 157472, 9593, 2053489] .|> Taxon

# By deafult, UnclassifiedTaxon are stored 
julia> taxa .|> Lineage .|> (x -> reformat(x, seven_rank)) .|> namedtuple |> DataFrame
4×7 DataFrame
 Row │ superkingdom                   phylum                             class                              order                              family                             genus                              species                           
     │ Taxon                          Taxon                              Abstract…                          Abstract…                          Abstract…                          Abstract…                          Taxon                             
─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 2 [superkingdom] Bacteria      1224 [phylum] Proteobacteria       1236 [class] Gammaproteobacteria   72274 [order] Pseudomonadales      135621 [family] Pseudomonadaceae   286 [genus] Pseudomonas            287 [species] Pseudomonas aerugi…
   2 │ 2 [superkingdom] Bacteria      1239 [phylum] Firmicutes           91061 [class] Bacilli              1385 [order] Bacillales            Unclassified [family] unclassifi…  Unclassified [genus] unclassifie…  157472 [species] uncultured Baci…
   3 │ 2759 [superkingdom] Eukaryota  7711 [phylum] Chordata             40674 [class] Mammalia             9443 [order] Primates              9604 [family] Hominidae            9592 [genus] Gorilla               9593 [species] Gorilla gorilla
   4 │ 2157 [superkingdom] Archaea    1655434 [phylum] Candidatus Loki…  Unclassified [class] unclassifie…  Unclassified [order] unclassifie…  Unclassified [family] unclassifi…  Unclassified [genus] unclassifie…  2053489 [species] Candidatus Lok…

# If set fill_by_missing to true in namedtuple, then missing are stored in DataFeame
julia> taxa .|> Lineage .|> (x -> reformat(x, seven_rank)) .|> (x ->  namedtuple(x; fill_by_missing=true)) |> DataFrame
4×7 DataFrame
 Row │ superkingdom                   phylum                             class                             order                          family                            genus                    species                           
     │ Taxon                          Taxon                              Taxon?                            Taxon?                         Taxon?                            Taxon?                   Taxon                             
─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 2 [superkingdom] Bacteria      1224 [phylum] Proteobacteria       1236 [class] Gammaproteobacteria  72274 [order] Pseudomonadales  135621 [family] Pseudomonadaceae  286 [genus] Pseudomonas  287 [species] Pseudomonas aerugi…
   2 │ 2 [superkingdom] Bacteria      1239 [phylum] Firmicutes           91061 [class] Bacilli             1385 [order] Bacillales        missing                           missing                  157472 [species] uncultured Baci…
   3 │ 2759 [superkingdom] Eukaryota  7711 [phylum] Chordata             40674 [class] Mammalia            9443 [order] Primates          9604 [family] Hominidae           9592 [genus] Gorilla     9593 [species] Gorilla gorilla
   4 │ 2157 [superkingdom] Archaea    1655434 [phylum] Candidatus Loki…  missing                           missing                        missing                           missing                  2053489 [species] Candidatus Lok…
```

