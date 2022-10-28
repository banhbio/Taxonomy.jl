module Taxonomy
using AbstractTrees
using OrderedCollections: OrderedDict
import DataAPI,
       DataAPI.All,
       DataAPI.Between,
       DataAPI.Cols
export current_db, current_db!,
       Rank, CanonicalRank, UnCanonicalRank, CanonicalRankSet, CanonicalRanks,
       AbstractTaxon, Taxon, UnclassifiedTaxon,
       Lineage, isformatted,
       print_tree,
       taxid, name, rank, parent, get, children, lca, source,
       reformat, namedtuple, print_lineage, isdescendant, isancestor, 
       All, Between, Cols,
       From, Until,
       LineageReformatError, LineageIndexError

include("DataAPI.jl")
include("database.jl")
include("taxon.jl")
include("rank.jl")
include("lineage.jl")
include("lca.jl")

end