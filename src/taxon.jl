abstract type AbstractTaxon end

"""
    Taxon(taxid::Int, db::Taxonomy.DB)
    Taxon(taxid::Int)

Construct a `Taxon` from its `taxid`.
Omitting `db` automatically calls `current_db()`, which is usually the database that was last created.
"""
struct Taxon <: AbstractTaxon 
    taxid::Int
    db::DB
    function Taxon(idx::Int, db::DB)
        haskey(db.names, idx) || KeyError(idx) |> throw
        return new(idx, db)
    end
end
Taxon(idx::Int) = Taxon(idx, current_db())

"""
    name2taxids(name::AbstractString, db::Taxonomy.DB)
    name2taxids(name::AbstractString)

Return a `Vector` of taxid from its `name`. `name` must match to the scientific name exactly.
If multiple hits are found, return a multi-element `Vector`. If not, 1- or 0-element `Vector`. 
Omitting `db` automatically calls `current_db()`, which is usually the database that was last created.
"""
name2taxids(name::AbstractString, db::DB) = findall(isequal(name), db.names)
name2taxids(name::AbstractString) = name2taxids(name, current_db())

"""
    similarnames(query::AbstractString, db::Taxonomy.DB; distance::StringDistances.StringDistance=StringDistances.Levenshtein(), threshold::Float64=0.8)
    similarnames(query::AbstractString; distance::StringDistances.StringDistance=StringDistances.Levenshtein(), threshold::Float64=0.8)

Find names similar to the `query` and return a `Vector` of `NamedTuple`s with taxid, name, and similarity.
The similarities are calculated by the Lavenshtein distance by default.
It can also be changed to other distances defined in `StringDistaces` package by specifying it in the distance argument.
Omitting `db` automatically calls `current_db()`, which is usually the database that was last created.
"""
function similarnames(query::AbstractString, db::DB; distance::StringDistance=StringDistances.Levenshtein(), threshold::Float64=0.8)
    result = @NamedTuple{taxid::Int, name::String, similarity::Float64}[]
    for (key, name) in db.names
        similarity = compare(query, name, distance)
        if similarity >= threshold
            push!(result, (taxid=key, name=name, similarity=similarity))
        end
    end
    return result
end

similarnames(query::AbstractString ; kwargs... ) = similarnames(query, current_db(); kwargs...)

"""
    taxid(taxon::Taxon)

Return the taxid of the given `Taxon` object.
"""
taxid(taxon::Taxon) = taxon.taxid

"""
    name(taxon::AbstractTaxon)

Return the name of the given `Taxon` object.
It also works for an `UnclassifiedTaxon` object.
"""
name(taxon::Taxon) = taxon.db.names[taxid(taxon)]

"""
    rank(taxon::AbstractTaxon)

Return the rank of the given `Taxon` object.
It also works for an `UnclassifiedTaxon` object.
"""
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
rank(taxon::UnclassifiedTaxon) = taxon.rank
name(taxon::UnclassifiedTaxon) = taxon.name

source(taxon::UnclassifiedTaxon) = taxon.source
