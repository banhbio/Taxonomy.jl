---
title: 'Taxonomy.jl: A Julia package to handle NCBI-formatted taxonomic databases'
tags:
  - Julia
  - taxonomy
  - NCBI
  - database
  - bioinformatics
  - ecology
authors:
  - name: Hiroki Ban
    orcid: 0000-0002-7563-7693
    affiliation: 1
  - name: Hiroyuki Ogata
    corresponding: true
    orcid: 0000-0001-6594-377X
    affiliation: 1
affiliations:
 - name: Bioinformatics Center, Institute for Chemical Research, Kyoto University, Gokasho, Uji, Kyoto, 611-0011, Japan 
   index: 1
date: XXX November 2022
bibliography: paper.bib

---

# Summary

`Taxonomy.jl` is a Julia [@bezanson2017julia] package to handle the National Center for Biotechnology Information (NCBI) Taxonomy database. `Taxonomy.jl` provides a rich set of comprehensive and essential manupliation of NCBI Taxonomy data. This package is designed not only for efficient data manipulation, but also for flexibility in interactive analysis (e.g. on Jupyter notebook [@kluyver2016jupyter]), and for integration with other Julia ecosystems such as `DataFrames.jl`.

`Taxonomy.jl` is an open-source project hosted on Github and distributed under the MIT license.

# Statement of need

The National Center for Biotechnology Information (NCBI) Taxonomy is a nomenclature and classification database for the International Nucleotide Sequence DataBase Collaboartion (INSDC) [@schoch2020ncbi]. It provides organism names and classifications for every sequence in the nucleotide and protein sequence databases of the INSDC and links between different resources. Linking taxa and sequence data is fundational for biomedical to ecological analysis.

With the development and affordability of sequencing platforms, many genetic and genomic sequences are being produced. The amount of data handled in a single study, including metagenome analysis, is exploding, and there is a need for tools that can handle the taxonomy database with lightweight performance and scalability.

`Taxonomy.jl` is a Julia package to handle the NCBI Taxonomy database. Julia is a desirable language suitable for scientific purposes in that it is high-performance with good scalability (like C/Fortran), yet highly flexible and readable and supports interactive execution (like Python/R). Julia is a relatively young programming language, but it has a growing ecosystem such as `DataFrames.jl` for general data analysis, as well as communities aiming for biological data such as BioJulia and EcoJulia. `Taxonomy.jl` bridges the NCBI Taxonomy database and Julia's ecosystem, enabling efficient downstream computation and interactive analysis (e.g. on Jupyter notebook).

# Features

Manipulation of taxon data is basically done by querying the database for various information and parent-child relationships by taxon identifier or name. This can be accomplished in two major ways: by accessing the database via a web application programming interface (API), or by directly parsing the dump files provided by NCBI (ftp://ftp.ncbi.nih.gov/pub/taxonomy/). Some tools, including the CLI tool `E-utilities` [@sayers2010general] and the R package `Taxize` [@chamberlain2013taxize], access data through a web API, but this way is not suitable for large queries due to the limited speed of Internet connections. Therefore, `Taxonomy.jl` employs a way similar to the Python package `Taxopy` [@antonio_camargo_2022_7010602] and the CLI tool `Taxonkit` [@shen2021taxonkit], which parses the dump files directly and load it all into random access memory (RAM). The dump files are small enough for modern computers (about 400MB total) to load the entire data into RAM, allowing real-time query operations to be performed much faster. This way also has a speed advantage over the way employed by the `NCBITaxa` module of the Python package `ETE`, which creates SQLite database from the dump files and accesses the data with each query.

`Taxonomy.jl` provides a convenient set of types and functions to query the database and store the obtained information. The core of the system is of two types, `Taxonomy.DB` and `Taxon`. `Taxonomy.DB` type, as the name implies, is the type that represents the taxonomy database and stores all data parsed from the dump files and loaded into RAM. The `Taxon` type represents a single taxon in the database. It stores a taxonomic identifier (Taxid) and a reference to the database.

The `Taxonomy.DB` object is created as follows by specifying the paths to `nodes.dmp` (links the Taxids to taxonomic ranks and parent Taxids) and `names.dmp` (links the Taxids to taxonomy names) in the file downloaded from the NCBI FTP site:

In Julia REPL
```julia
julia> using Taxonomy

julia> db = Taxonomy.DB("./db/nodes.dmp", "./db/names.dmp");
```

One feature of `Taxonomy.jl` is that once a database object is created, it can be called without explicitly specifying it. Since most analyses use only one database, this approach is effective and allows users to write simple, readable code. For example, you can omit the database argument when constructing the `Taxon` object as follows:

```julia
julia> Taxon(9606, db)
9606 [species] Homo sapiens

julia> Taxon(9606)
9606 [species] Homo sapiens
```

The following operations are defined as functions with `Taxon` or `Taxonomy.DB`:
- Get various information on a given taxon (name, rank and parent-child relationships, etc.)
- Convert a name to taxids
- Compute the lowest common ancestor (LCA) of given taxa
- Evaluate ancestor-descendant relationships between two taxa
- Filter taxa by a rank range

The hierarchical structure of the NCBI Taxonomy is organized as a rooted tree with each taxonomy as a node. Therefore, the `Taxonomy.DB` type can also be viewed as a rooted tree with the `Taxon` type as a node. We defined an interface to handle the tree structures using `AbstractTrees.jl`. This allows users to use the functions defined in `AbstractTrees.jl`, as in the example below, and to traverse the tree in a user-defined way.

Example:
```julia
julia> AbstractTrees.print_tree(Taxon(207598))
207598 [subfamily] Homininae
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

Population composition analysis, including metagenomic analysis, uses tables that represent the relative composition of each taxon. In NCBI Taxonomy, superkingdom, kingdom, phylum, class, order, family, genus, species, subspecies, and strain are used as canonical ranks. However, given that kingdom applies only to eukaryotes, that lineages, including many viruses and environmental samples, lack some ranks, that there is a mixture of subspecies and strains with ranks below species, and that there are many taxa that do not have canonical ranks, the NCBI Taxonomy lineages cannot be used as is and must be standardized.

`Taxonomy.jl` provides a `Lineage` type, an interface to lineage information. The `Lineage` type is a subtype of the `AbstractVector` type and can be treated as a Vector with `Taxon` elements. The `getindex` methods of the Lineage type are extended to also access Taxon using the rank symbol. The subspecies/strain are treated as the same internally, so you can ignore ambiguities in each lineage. This makes it possible to handle lineage information consistently.

In addition, `Taxonomy.jl` provide a `reformat` function to convert a `Lineage` to the given rank e.g., the 7-level format (superkingdom, phylum, class, order, family, genus, and species) or 8-level format with an additional strain/subspecies rank. If there is no taxon corresponding to the rank in the lineage, the `UnclassifiedTaxon` object with the name of the taxon of the higher rank will be stored. This allows the standardization of multiple lineages to have consistent ranks.

The `Lineage` type can be converted to the `NamedTuple` type with rank as the key via the `namedtuple` function. This NamedTuple can be used as input to a `DataFrame` type in `DataFrames.jl`, for example, allowing for downstream analysis and visualization.

# Acknowledgments

This work was supported by JST, the establishment of university fellowships towards the creation of science technology innovation, Grant Number JPMJFS2123.

# References
