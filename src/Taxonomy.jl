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
       All, Between, Cols,
       From, Until

include("exDataAPI.jl")
include("Utils.jl")
include("tree.jl")

end