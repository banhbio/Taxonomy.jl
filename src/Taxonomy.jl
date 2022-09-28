module Taxonomy
using AbstractTrees
import DataAPI,
       DataAPI.All,
       DataAPI.Between,
       DataAPI.Cols
export Rank, CanonicalRank, UnCanonicalRank, CanonicalRankSet, CanonicalRanks,
       AbstractTaxon, Taxon, UnclassifiedTaxon,
       Lineage,
       print_tree,
       taxid, name, rank, parent, get, children, lca, source,
       reformat, print_lineage, isdescendant, isancestor,
       All, Between, Cols,
       From, Until

include("DataAPI.jl")
include("database.jl")
include("taxon.jl")
include("rank.jl")
include("lineage.jl")
include("lca.jl")

end