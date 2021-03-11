module Taxonomy

using AbstractTrees
import DataAPI,
       DataAPI.All,
       DataAPI.Between,
       DataAPI.Cols
export Taxon, Lineage,
       CanonicalRank,
       parent, children, rank, lca,
       PhyloTree,
       topolgoy,
       children, print_tree, Leaves,
       All, Between, Cols

include("Utils.jl")
include("tree.jl")

end