module Taxonomy

using AbstractTrees
export Taxon
export parent, children, rank, lineage, lca
export PhyloTree
export topolgoy
export children, print_tree, Leaves 

include("Utils.jl")
include("tree.jl")

end