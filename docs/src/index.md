# Taxonomy.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://banhbio.github.io/Taxonomy.jl/dev)

[![CI](https://github.com/banhbio/Taxonomy.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/banhbio/Taxonomy.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/banhbio/Taxonomy.jl/branch/main/graph/badge.svg?token=2A8WQRHRLC)](https://codecov.io/gh/banhbio/Taxonomy.jl)

[![DOI](https://zenodo.org/badge/341212699.svg)](https://zenodo.org/badge/latestdoi/341212699)

## v0.5.1 Release Notes

### Improvements

- Added doctests to public API docstrings and usage examples.
- Fixed docstring typos and clarified several API descriptions.
- Improved local documentation builds by silencing Documenter warnings.
- Ignored the generated `docs/Manifest.toml` file.

## v0.5.0 Release Notes

### Breaking changes

- `reformat` now accepts only canonical rank symbols.
- `reformat` now throws `UnCanonicalRankError` for non-canonical ranks and `RankAliasError` when multiple aliases for the same rank slot are requested.
- `:domain`, `:superkingdom`, and `:realm` are treated as aliases for the same top-rank slot.
- Removed the `DataAPI` dependency. `All`, `Cols`, `Between`, `From`, and `Until` are now Taxonomy.jl selectors.
- Removed support for `All(args...)`; use `Cols(args...)` for selecting multiple lineage positions or ranks.

### Improvements

- `name2taxids` now uses a per-`DB` lazy cache, fixing behavior when multiple taxonomy databases are used.
- `children(taxon)` now uses a per-`DB` lazy child index for faster parent-to-child traversal.
- `lca` now handles edge cases explicitly: empty input throws `ArgumentError`, and single-taxon input returns that taxon.
- Database imports now use size-hinted vectors instead of fixed-size buffers.

## Overview

Taxonomy.jl is a Julia package to handle the NCBI Taxonomy database.
The main features are:
- Get various information on a given taxon (name, rank, parent-child relationships, etc.)
- Convert a name to taxids
- Traverse taxonomic subtrees from a given taxon
- Compute the lowest common ancestor (LCA) of given taxa
- Evaluate ancestor-descendant relationships between two taxa
- Filter taxa by a rank range
- Construct the taxonomic lineage of a given taxon
- Reformat lineage according to canonical ranks
- Construct a `DataFrame` from lineages

Currently, this package only supports `scientific name`.

## Installation
Install Taxonomy.jl as follows:
```
julia -e 'using Pkg; Pkg.add("Taxonomy")'
```

## Download the database
You need to download taxonomic data from NCBI's servers.
```
wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
tar xzvf taxdump.tar.gz
```
