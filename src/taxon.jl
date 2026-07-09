abstract type AbstractTaxon end

"""
    Taxon(taxid::Int, db::Taxonomy.DB)
    Taxon(taxid::Int)

Construct a `Taxon` from its `taxid`.
Omitting `db` automatically calls `current_db()`, which is usually the database that was last created.

# Examples

```jldoctest
julia> Taxon(9606)
9606 [species] Homo sapiens

julia> Taxon(9606, db)
9606 [species] Homo sapiens
```
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

# Examples

```jldoctest
julia> name2taxids("Homo")
1-element Vector{Int64}:
 9605

julia> name2taxids("ThisNameDoesNotExist")
Int64[]
```
"""
function name2taxids(name::AbstractString, db::DB)
    mapping = name2taxids_db(db)
    return get(mapping, name, Int[])
end

name2taxids(name::AbstractString) = name2taxids(name, current_db())

"""
    similarnames(query::AbstractString, db::Taxonomy.DB; distance::StringDistances.StringDistance=StringDistances.Levenshtein(), threshold::Float64=0.8)
    similarnames(query::AbstractString; distance::StringDistances.StringDistance=StringDistances.Levenshtein(), threshold::Float64=0.8)

Find names similar to the `query` and return a `Vector` of `NamedTuple`s with taxid, name, and similarity.
The similarities are calculated by the Levenshtein distance by default.
It can also be changed to other distances defined in the `StringDistances` package by specifying it in the distance argument.
Omitting `db` automatically calls `current_db()`, which is usually the database that was last created.

# Examples

```jldoctest
julia> result = first(similarnames("Homo sapiens"));

julia> result.taxid
9606

julia> result.name
"Homo sapiens"

julia> result.similarity
1.0
```
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

# Examples

```jldoctest
julia> taxid(Taxon(9606))
9606
```
"""
taxid(taxon::Taxon) = taxon.taxid

"""
    name(taxon::AbstractTaxon)

Return the name of the given `Taxon` object.
It also works for an `UnclassifiedTaxon` object.

# Examples

```jldoctest
julia> name(Taxon(9606))
"Homo sapiens"

julia> name(UnclassifiedTaxon(:subspecies, Taxon(9606)))
"unclassified Homo sapiens subspecies"
```
"""
name(taxon::Taxon) = taxon.db.names[taxid(taxon)]

"""
    rank(taxon::AbstractTaxon)

Return the rank of the given `Taxon` object.
It also works for an `UnclassifiedTaxon` object.

# Examples

```jldoctest
julia> rank(Taxon(9606))
:species

julia> rank(UnclassifiedTaxon(:subspecies, Taxon(9606)))
:subspecies
```
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

# Examples

```jldoctest
julia> AbstractTrees.parent(Taxon(9606))
9605 [genus] Homo
```
"""
function AbstractTrees.parent(taxon::Taxon)
   parent_taxid = get(taxon.db.parents, taxon.taxid, nothing)
   if parent_taxid == taxon.taxid
        return nothing
   end
   parent = Taxon(parent_taxid, taxon.db)
   return parent
end

"""
    children(taxon::Taxon)

Return the vector of `Taxon` objects that are children of the given `Taxon` object.

# Examples

```jldoctest
julia> sort(taxid.(children(Taxon(9606)))) == [63221, 741158]
true
```
"""
function AbstractTrees.children(taxon::Taxon)
    children_taxid = get(children_db(taxon.db), taxon.taxid, Int[])
    children_taxon = map(x -> Taxon(x, taxon.db), children_taxid)
    return children_taxon
end

Base.show(io::IO, taxon::Taxon) = print(io, "$(taxid(taxon)) [$(rank(taxon))] $(name(taxon))")
AbstractTrees.printnode(io::IO, taxon::Taxon) = print(io, taxon)

"""
    get(db::Taxonomy.DB, taxid::Int, default)

Return the `Taxon` object stored for the given taxid, or the given default value if no mapping for the taxid is present.

# Examples

```jldoctest
julia> get(db, 9606, nothing)
9606 [species] Homo sapiens

julia> get(db, 99999999, nothing) === nothing
true
```
"""
function Base.get(db::DB, taxid::Int, default)
    haskey(db.names, taxid) || return default
    return Taxon(taxid, db)
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

"""
    source(taxon::UnclassifiedTaxon)

Return the source `Taxon` used to construct an `UnclassifiedTaxon`.

# Examples

```jldoctest
julia> source(UnclassifiedTaxon(:subspecies, Taxon(9606)))
9606 [species] Homo sapiens
```
"""
source(taxon::UnclassifiedTaxon) = taxon.source
