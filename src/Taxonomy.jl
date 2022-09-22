module Taxonomy
using AbstractTrees
using InteractiveUtils
import DataAPI,
       DataAPI.All,
       DataAPI.Between,
       DataAPI.Cols
export Rank, CanonicalRank, UnCanonicalRank,
       species, genus, family, order, class, phylum, kingdom, superkingdom,
       AbstractTaxon, Taxon, UnclassifiedTaxon,
       Lineage,
       print_tree,
       taxid, name, rank, parent, get, children, lca,
       reformat, print_lineage, isdescendant, isancestor,
       All, Between, Cols,
       From, Until

include("DataAPI.jl")
include("rank.jl")
include("database.jl")
include("taxon.jl")
include("lineage.jl")
include("lca.jl")

end