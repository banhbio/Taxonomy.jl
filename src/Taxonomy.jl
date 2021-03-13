module Taxonomy

using AbstractTrees
import DataAPI,
       DataAPI.All,
       DataAPI.Between,
       DataAPI.Cols
export CanonicalRank,
       Taxon,
       Lineage,
       parent, children, rank, lca,
       reformat,
       PhyloTree,
       topolgoy,
       children, print_tree, Leaves,
       All, Between, Cols,
       From, Until

include("exDataAPI.jl")
include("Utils.jl")
include("tree.jl")

end