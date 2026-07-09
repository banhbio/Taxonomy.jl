# Usage

```@meta
DocTestSetup = quote
    using Taxonomy
    using Taxonomy.AbstractTrees

    _ROOT = dirname(dirname(pathof(Taxonomy)))
    _DB_DIR = joinpath(_ROOT, "docs", "src", "assets", "doctest-db")
    db = Taxonomy.DB(joinpath(_DB_DIR, "nodes.dmp"), joinpath(_DB_DIR, "names.dmp"))
    human = Taxon(9606, db)
    lineage = Lineage(human)
    seven_rank = [:domain, :phylum, :class, :order, :family, :genus, :species]
end
```

## Construct a Database

```julia
# Load the package
julia> using Taxonomy

# Construct a Taxonomy.DB object from the path to each file
julia> db = Taxonomy.DB("db/nodes.dmp","db/names.dmp")
Taxonomy.DB("db/nodes.dmp","db/names.dmp")

# Taxonomy.DB object is automatically stored in current_db()
julia> current_db()
Taxonomy.DB("db/nodes.dmp","db/names.dmp")
```

`DB` validates that both input files exist and throws `ArgumentError` if either path is missing.
Name lookup and child traversal indexes are built lazily on first use and cached per `DB` object.

## Get taxonomic information from `Taxon`

```jldoctest
julia> human = Taxon(9606, db)
9606 [species] Homo sapiens

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

Name must match to the scientific name exactly
```jldoctest
julia> name2taxids("Homo")
1-element Vector{Int64}:
 9605

julia> Taxon.(name2taxids("Viruses"), Ref(db))
1-element Vector{Taxon}:
 10239 [acellular root] Viruses
```

`name2taxids(name, db)` uses the given `DB`; `name2taxids(name)` uses `current_db()`.
Name lookup returns taxids, not `Taxon` objects, because one scientific name can map to multiple taxids.
Use `Taxon.(name2taxids(name, db), Ref(db))` when `Taxon` objects are needed.

## Traverse taxonomic subtrees from a given `Taxon`

```jldoctest
julia> sort(taxid.(children(human))) == [63221, 741158]
true

julia> AbstractTrees.parent(human)
9605 [genus] Homo

julia> sort(taxid.(collect(AbstractTrees.PreOrderDFS(human)))) == [9606, 63221, 741158]
true
```

```julia
# Print subtree
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
**Note:** The first parent-to-child traversal builds a lazy child index for the database.
Subsequent calls to `children` and tree iterators from `AbstractTrees.jl` reuse that index.

## Find lowest common ancestor (LCA)
```jldoctest
julia> human = Taxon(9606); gorilla = Taxon(9592); orangutan = Taxon(9600);

julia> lca(human, gorilla)
207598 [subfamily] Homininae

julia> lca(human, gorilla, orangutan)
9604 [family] Hominidae

julia> lca([human, gorilla, orangutan])
9604 [family] Hominidae

julia> lca(human)
9606 [species] Homo sapiens
```

`lca` requires at least one `Taxon`; `lca()` and `lca(Taxon[])` throw `ArgumentError`.

## Evaluate ancestor-descendant relationships between two `Taxon`s
```jldoctest
julia> viruses = Taxon(10239)
10239 [acellular root] Viruses

julia> sars_cov2 = Taxon(2697049)
2697049 [no rank] Severe acute respiratory syndrome coronavirus 2

julia> isancestor(viruses, sars_cov2)
true

julia> isdescendant(human, viruses)
false
```

## Filter `Taxon`s by a rank range
```jldoctest
julia> taxa = [2759, 33208, 7711, 40674, 9443, 9604, 9605, 9606] .|> Taxon
8-element Vector{Taxon}:
 2759 [domain] Eukaryota
 33208 [kingdom] Metazoa
 7711 [phylum] Chordata
 40674 [class] Mammalia
 9443 [order] Primates
 9604 [family] Hominidae
 9605 [genus] Homo
 9606 [species] Homo sapiens

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
 2759 [domain] Eukaryota
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

`Taxon` objects are stored in `Vector`-like format
```julia
julia> lineage[1]
1 [no Rank] root

julia> lineage[9]
7711 [phylum] Chordata

julia> lineage[end]
9606 [species] Homo sapiens
```

`Symbol`s such as `:phylum`, `:genus` and `:species` (`Symbol`s in `CanonicalRanks`) can be used to access each `Taxon`
`CanonicalRanks` also supports `:domain`, `:superkingdom`, and `:realm`.
`:domain`, `:superkingdom`, and `:realm` are treated as the same top-rank slot.
Use one of them in a reformatted lineage; they are aliases for the top rank, not separate columns to request together.
```julia
julia> lineage[:phylum]
7711 [phylum] Chordata

julia> lineage[:genus]
9605 [genus] Homo

julia> lineage[:species]
9606 [species] Homo sapiens
```

Taxonomy.jl provides `Between`, `From`, `Until`, `Cols` and `All` selectors for more complex rank selection scenarios.
Use `All()` to select the full lineage, and use `Cols(...)` to select multiple positions or ranks.
These selectors are provided by Taxonomy.jl itself.
```julia
julia> lineage[All()]
32-element Lineage{Taxon}:
 1 [no Rank] root
 131567 [no rank] cellular organisms
 2759 [domain] Eukaryota
 ⋮
 9605 [genus] Homo
 9606 [species] Homo sapiens

julia> lineage[Between(:order, :family)]
6-element Lineage{Taxon}:
 9443 [order] Primates
 376913 [suborder] Haplorrhini
 314293 [infraorder] Simiiformes
 9526 [parvorder] Catarrhini
 314295 [superfamily] Hominoidea
 9604 [family] Hominidae

julia> lineage[From(:family)]
4-element Lineage{Taxon}:
 9604 [family] Hominidae
 207598 [subfamily] Homininae
 9605 [genus] Homo
 9606 [species] Homo sapiens

julia> lineage[Until(:kingdom)]
5-element Lineage{Taxon}:
 1 [no Rank] root
 131567 [no rank] cellular organisms
 2759 [domain] Eukaryota
 33154 [clade] Opisthokonta
 33208 [kingdom] Metazoa

julia> lineage[Cols(:superkingdom, :genus, :species)]
3-element Lineage{Taxon}:
 2759 [domain] Eukaryota
 9605 [genus] Homo
 9606 [species] Homo sapiens
```

For viral lineages, `:domain`, `:superkingdom`, and `:realm` all select the same top-rank slot.
The returned taxon can therefore have rank `:realm`.
```jldoctest
julia> sars_cov2_lineage = Lineage(Taxon(2697049));

julia> sars_cov2_lineage[:superkingdom] == sars_cov2_lineage[:realm]
true

julia> sars_cov2_lineage[:realm]
2559587 [realm] Riboviria
```

## Reformat `Lineage`
Reformat `Lineage` by providing a vector of canonical rank symbols.
The rank symbols `:domain`, `:superkingdom`, and `:realm` share the same top-rank slot.
The rank symbols `:subspecies` and `:strain` share the same below-species slot.
Only canonical rank symbols are supported. Use only one symbol from each alias group in a reformatted lineage.
```jldoctest
julia> seven_rank = [:domain, :phylum, :class, :order, :family, :genus, :species];

julia> reformat(lineage, seven_rank)
7-element Lineage{Taxon}:
 2759 [domain] Eukaryota
 7711 [phylum] Chordata
 40674 [class] Mammalia
 9443 [order] Primates
 9604 [family] Hominidae
 9605 [genus] Homo
 9606 [species] Homo sapiens
```

The `:subspecies` and `:strain` aliases let users ignore ambiguity in ranks below species.
```jldoctest
julia> eight_rank = [:domain, :phylum, :class, :order, :family, :genus, :species, :strain];

julia> denisova = Taxon(741158); l = Lineage(denisova);

julia> rl = reformat(l, eight_rank)
8-element Lineage{Taxon}:
 2759 [domain] Eukaryota
 7711 [phylum] Chordata
 40674 [class] Mammalia
 9443 [order] Primates
 9604 [family] Hominidae
 9605 [genus] Homo
 9606 [species] Homo sapiens
 741158 [subspecies] Homo sapiens subsp. 'Denisova'

julia> rl[:subspecies] == rl[:strain]
true
```

If there is no corresponding taxon to the requested canonical rank slot in the lineage, then `UnclassifiedTaxon` will be stored.
```julia
julia> uncultured_bacillales = Taxon(157472)
57472 [species] uncultured Bacillales bacterium

julia> reformatted_bacillales_lineage = reformat(Lineage(uncultured_bacillales), seven_rank)
7-element Lineage:
 2 [domain] Bacteria
 1239 [phylum] Firmicutes
 91061 [class] Bacilli
 1385 [order] Bacillales
 Unclassified [family] unclassified Bacillales family
 Unclassified [genus] unclassified Bacillales genus
 157472 [species] uncultured Bacillales bacterium
```

Once reformatted, `Lineage` cannot be reformatted again.
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

Non-canonical ranks are rejected:
```julia
julia> reformat(lineage, [:superkingdom, :clade, :species])
ERROR: Non-canonical ranks are not supported in reformat: [:clade]
```

Aliases for the same rank slot cannot be requested together:
```julia
julia> reformat(lineage, [:domain, :superkingdom, :phylum])
ERROR: Rank aliases cannot be requested together in reformat: [:domain, :superkingdom, :phylum]
```

## Convert `Lineage`s to `DataFrame`

`Lineage` can be converted to a `NamedTuple` using `namedtuple`.

The resulting `NamedTuple` can be passed to `DataFrame`
When a top-rank alias such as `:domain` is requested, viral lineages may store a `realm` taxon in that column.
```julia
julia> using DataFrames

julia> seven_rank = [:domain, :phylum, :class, :order, :family, :genus, :species];

julia> taxa = [9606, 562, 187878, 212035, 2697049] .|> Taxon
5-element Vector{Taxon}:
 9606 [species] Homo sapiens
 562 [species] Escherichia coli
 187878 [species] Thermococcus gammatolerans
 212035 [species] Acanthamoeba polyphaga mimivirus
 2697049 [no rank] Severe acute respiratory syndrome coronavirus 2

julia> taxa .|> Lineage .|> (x -> reformat(x, seven_rank)) .|> namedtuple |> DataFrame
5×7 DataFrame
 Row │ domain                         phylum                             class                             order                           family                           genus                           species
     │ Taxon                          Taxon                              Taxon                             Taxon                           Taxon                            Taxon                           Taxon
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 2759 [domain] Eukaryota  7711 [phylum] Chordata             40674 [class] Mammalia            9443 [order] Primates           9604 [family] Hominidae          9605 [genus] Homo               9606 [species] Homo sapiens
   2 │ 2 [domain] Bacteria      1224 [phylum] Proteobacteria       1236 [class] Gammaproteobacteria  91347 [order] Enterobacterales  543 [family] Enterobacteriaceae  561 [genus] Escherichia         562 [species] Escherichia coli
   3 │ 2157 [domain] Archaea    28890 [phylum] Euryarchaeota       183968 [class] Thermococci        2258 [order] Thermococcales     2259 [family] Thermococcaceae    2263 [genus] Thermococcus       187878 [species] Thermococcus ga…
   4 │ 2732004 [realm] Varidnaviria   2732007 [phylum] Nucleocytoviric…  2732523 [class] Megaviricetes     2732554 [order] Imitervirales   549779 [family] Mimiviridae      315393 [genus] Mimivirus        3047343 [species] Mimivirus bra…
   5 │ 2559587 [realm] Riboviria      2732408 [phylum] Pisuviricota      2732506 [class] Pisoniviricetes   76804 [order] Nidovirales       11118 [family] Coronaviridae     694002 [genus] Betacoronavirus  3418604 [species] Betacoronavir…

# Dealing with UnclassifiedTaxon as missing value

julia> taxa = [287, 157472, 9593, 2053489] .|> Taxon

# By default, UnclassifiedTaxon objects are stored
julia> taxa .|> Lineage .|> (x -> reformat(x, seven_rank)) .|> namedtuple |> DataFrame
4×7 DataFrame
 Row │ domain                         phylum                             class                              order                              family                             genus                              species
     │ Taxon                          Taxon                              Abstract…                          Abstract…                          Abstract…                          Abstract…                          Taxon
─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 2 [domain] Bacteria      1224 [phylum] Proteobacteria       1236 [class] Gammaproteobacteria   72274 [order] Pseudomonadales      135621 [family] Pseudomonadaceae   286 [genus] Pseudomonas            287 [species] Pseudomonas aerugi…
   2 │ 2 [domain] Bacteria      1239 [phylum] Firmicutes           91061 [class] Bacilli              1385 [order] Bacillales            Unclassified [family] unclassifi…  Unclassified [genus] unclassifie…  157472 [species] uncultured Baci…
   3 │ 2759 [domain] Eukaryota  7711 [phylum] Chordata             40674 [class] Mammalia             9443 [order] Primates              9604 [family] Hominidae            9592 [genus] Gorilla               9593 [species] Gorilla gorilla
   4 │ 2157 [domain] Archaea    1655434 [phylum] Candidatus Loki…  Unclassified [class] unclassifie…  Unclassified [order] unclassifie…  Unclassified [family] unclassifi…  Unclassified [genus] unclassifie…  2053489 [species] Candidatus Lok…

# If fill_by_missing is set to true in namedtuple, then missing are stored in DataFrame
julia> taxa .|> Lineage .|> (x -> reformat(x, seven_rank)) .|> (x ->  namedtuple(x; fill_by_missing=true)) |> DataFrame
4×7 DataFrame
 Row │ domain                         phylum                             class                             order                          family                            genus                    species
     │ Taxon                          Taxon                              Taxon?                            Taxon?                         Taxon?                            Taxon?                   Taxon
─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │ 2 [domain] Bacteria      1224 [phylum] Proteobacteria       1236 [class] Gammaproteobacteria  72274 [order] Pseudomonadales  135621 [family] Pseudomonadaceae  286 [genus] Pseudomonas  287 [species] Pseudomonas aerugi…
   2 │ 2 [domain] Bacteria      1239 [phylum] Firmicutes           91061 [class] Bacilli             1385 [order] Bacillales        missing                           missing                  157472 [species] uncultured Baci…
   3 │ 2759 [domain] Eukaryota  7711 [phylum] Chordata             40674 [class] Mammalia            9443 [order] Primates          9604 [family] Hominidae           9592 [genus] Gorilla     9593 [species] Gorilla gorilla
   4 │ 2157 [domain] Archaea    1655434 [phylum] Candidatus Loki…  missing                           missing                        missing                           missing                  2053489 [species] Candidatus Lok…
```
