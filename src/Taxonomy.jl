module Taxonomy
using AbstractTrees
import DataAPI,
       DataAPI.All,
       DataAPI.Between,
       DataAPI.Cols
export CanonicalRank,
       AbstractTaxon, Taxon, UnclassifiedTaxon,
       Lineage,
       taxid, name, rank, parent, children, lca,
       reformat, print_lineage, isdescendant, isancestor,
       PhyloTree,
       topolgoy,
       children, parent, print_tree,
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