module Taxonomy
using AbstractTrees
using OrderedCollections: OrderedDict
using StringDistances
export AbstractTrees, StringDistances,
       current_db, current_db!,
       Rank, CanonicalRank, UnCanonicalRank, CanonicalRankSet, CanonicalRanks,
       AbstractTaxon, Taxon, UnclassifiedTaxon,
       Lineage, isreformatted,
       print_tree,
       taxid, name, rank, parent, get, name2taxids, similarnames, children, lca, source,
       reformat, namedtuple, print_lineage, isdescendant, isancestor, 
       All, Between, Cols,
       From, Until,
       LineageReformatError, LineageIndexError, UnCanonicalRankError, RankAliasError

include("selector.jl")
include("database.jl")
include("taxon.jl")
include("rank.jl")
include("lineage.jl")
include("lca.jl")

end
