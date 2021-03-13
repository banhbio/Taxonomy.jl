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

include("DataAPI.jl")
include("Utils.jl")
include("database.jl")
include("taxon.jl")
include("lineage.jl")
include("lca.jl")
include("tree.jl")

end