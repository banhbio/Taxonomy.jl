# Taxonomy.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://banhbio.github.io/Taxonomy.jl/dev)

[![CI](https://github.com/banhbio/Taxonomy.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/banhbio/Taxonomy.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/banhbio/Taxonomy.jl/branch/main/graph/badge.svg?token=2A8WQRHRLC)](https://codecov.io/gh/banhbio/Taxonomy.jl)

[![DOI](https://zenodo.org/badge/341212699.svg)](https://zenodo.org/badge/latestdoi/341212699)

Taxonomy.jl is a julia package to handle the NCBI Taxonomy database.
The main features are:
- Get various information on a given taxon (name, rank, parent-child relationships, etc.)
- Convert a name to Taxids
- Traverse taxonomic subtrees from a given taxon
- Compute the lowest common ancestor (LCA) of given taxa
- Evaluate ancestor-descendant relationships between two taxa
- Filter taxa by a rank range
- Construct taxonomic lineage of the given taxon
- Reformat lineage according to canonical ranks
- Construct a `DataFrame` from lineages

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
