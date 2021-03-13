struct Taxon
    taxid::Int
    name::String
    rank::Symbol
    db::DB
end

Base.show(io::IO, taxon::Taxon) = print(io, "$(taxon.taxid) [$(String(taxon.rank))] $(taxon.name)")
AbstractTrees.printnode(io::IO, taxon::Taxon) = print(io, taxon)

function Taxon(taxid::Int, db::DB)
    name = db.names[taxid]
    rank = get(db.ranks, taxid, Symbol("no rank"))
    return Taxon(taxid, name, rank, db)
end

function Taxon(name::String, db::DB)
    taxid_canditates = findall(isequal(name), db.names)
    length(taxid_canditates) == 0 && error("There is no candidates for ",name)
    length(taxid_canditates) == 1 && return Taxon(taxid_canditates[1],db)
    length(taxid_canditates) > 1 && error("There are several candidates for ",name)
end

function Base.get(taxid::Int, db::DB, default)
    try
        return Taxon(taxid, db)
    catch
        return default
    end
end

function Base.get(name::String, db::DB, default)
    try
        return Taxon(name, db)
    catch
        return default
    end
end

AbstractTrees.nodetype(::Taxon) = Taxon

function Base.parent(taxon::Taxon)
   parent_taxid = get(taxon.db.parents, taxon.taxid, nothing)
   if parent_taxid === nothing
        return nothing
   end
   parent = Taxon(parent_taxid, taxon.db)
   return parent
end

function AbstractTrees.children(taxon::Taxon)
    children_taxid = findall(isequal(taxon.taxid), taxon.db.parents)
    children_taxon = map(x -> Taxon(x, taxon.db), children_taxid)
    return children_taxon
end

function rank(taxon::Taxon)
    taxon.rank
end