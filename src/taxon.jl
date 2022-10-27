abstract type AbstractTaxon end

struct Taxon <: AbstractTaxon 
    taxid::Int
    db::DB
    function Taxon(idx::Int, db::DB)
        haskey(db.names, idx) || KeyError(idx) |> throw
        return new(idx, db)
    end
end

function Taxon(name::String, db::DB)
    taxid_canditates = findall(isequal(name), db.names)
    length(taxid_canditates) == 0 && error("There is no candidates for ",name)
    length(taxid_canditates) == 1 && return new(only(taxid_canditates), db)
    length(taxid_canditates) > 1 && error("There are several candidates for ",name)
end 

"""
    taxid(taxon::Taxon)

Return the taxid of the given `Taxon` object.
"""
taxid(taxon::Taxon) = taxon.taxid
name(taxon::Taxon) = taxon.db.names[taxid(taxon)]
rank(taxon::Taxon) = get(taxon.db.ranks, taxon.taxid, Symbol("no Rank"))

# define Traits
AbstractTrees.ParentLinks(::Type{Taxon}) = StoredParents()
AbstractTrees.ChildIndexing(::Type{Taxon}) = IndexedChildren()
AbstractTrees.NodeType(::Type{Taxon}) = HasNodeType()
AbstractTrees.nodetype(::Type{Taxon}) = Taxon

"""
    AbstractTrees.parent(taxon::Taxon)

Return the `Taxon` object that is the parent of the given `Taxon` object.
"""
function AbstractTrees.parent(taxon::Taxon)
   parent_taxid = get(taxon.db.parents, taxon.taxid, nothing)
   if parent_taxid === nothing
        return nothing
   end
   parent = Taxon(parent_taxid, taxon.db)
   return parent
end

"""
    children(taxon::Taxon)

Return the vector of `Taxon` objects that are children of the given `Taxon` object.
"""
function AbstractTrees.children(taxon::Taxon)
    children_taxid = findall(isequal(taxon.taxid), taxon.db.parents)
    children_taxon = map(x -> Taxon(x, taxon.db), children_taxid)
    return children_taxon
end

Base.show(io::IO, taxon::Taxon) = print(io, "$(taxid(taxon)) [$(rank(taxon))] $(name(taxon))")
AbstractTrees.printnode(io::IO, taxon::Taxon) = print(io, taxon)

"""
    get(db::Taxonomy.DB, taxid::Int, default)

Return the `Taxon` object stored for the given taxid, or the given default value if no mapping for the taxid is present.
"""
function Base.get(db::DB, taxid::Int, default)
    try
        return Taxon(taxid, db)
    catch
        return default
    end
end

"""
    get(db::Taxonomy.DB, name::String, default)

Return the `Taxon` object stored for the given name, or the given default value if no mapping for the name is present.
"""
function Base.get(db::DB, name::String, default)
    try
        return Taxon(name, db)
    catch
        return default
    end
end

struct UnclassifiedTaxon <:AbstractTaxon
    name::String
    rank::Symbol
    source::Taxon
end

function UnclassifiedTaxon(rank, source::Taxon)
    namae = "unclassified " * name(source) * " " * String(rank)
    UnclassifiedTaxon(namae, rank, source)
end

function UnclassifiedTaxon(rank, source::UnclassifiedTaxon)
    namae = "unclassified " * name(source.source) * " " * String(rank)
    UnclassifiedTaxon(namae, rank, source.source)
end

Base.show(io::IO, taxon::UnclassifiedTaxon) = print(io, "Unclassified [$(rank(taxon))] $(taxon.name)")

"""
    rank(taxon::AbstractTaxon)

Return the rank of the given `Taxon` object.
It also works for an `UnclassifiedTaxon` object.
"""
rank(taxon::UnclassifiedTaxon) = taxon.rank

"""
    name(taxon::AbstractTaxon)

Return the name of the given `Taxon` object.
It also works for an `UnclassifiedTaxon` object.
"""
name(taxon::UnclassifiedTaxon) = taxon.name

source(taxon::UnclassifiedTaxon) = taxon.source