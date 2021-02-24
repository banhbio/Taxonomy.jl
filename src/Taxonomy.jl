module Taxonomy

using AbstractTrees
export TaxonomyDatabase, Taxon
export parent, children, rank, lineage, name_lineage, taxid, lca
export PhyloTree
export topolgoy
export children, nodetype, print_tree, Leaves 

include("Utils.jl")
include("tree.jl")

end