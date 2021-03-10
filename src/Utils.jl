struct DB
    nodes_dmp::String
    names_dmp::String
    parents::Dict{Int,Int}
    ranks::Dict{Int,Symbol}
    names::Dict{Int,String}
end

function DB(nodes_dmp::String, names_dmp::String)
    @assert isfile(nodes_dmp)
    @assert isfile(names_dmp)

    parents, ranks = _importnodes(nodes_dmp)
    namaes = _importnames(names_dmp)

    return DB(nodes_dmp, names_dmp, parents, ranks, namaes)
end

function _importnodes(nodes_dmp_path::String)
    parents = Dict{Int,Int}()
    ranks = Dict{Int,Symbol}()

    f = open(nodes_dmp_path, "r")
    for line in readlines(f)
        lines = split(line, "\t")
        taxid = parse(Int, lines[1])
        parent = parse(Int, lines[3])
        rank = x -> x == "no rank" ? Symbol("norank") : Symbol(lines[5])

        parent != taxid || continue

        parents[taxid] = parent
        ranks[taxid] = rank
    end
    close(f)
    return parents, ranks
end


function _importnames(names_dmp_path::String)
    namaes = Dict{Int,String}()
    f = open(names_dmp_path, "r")
    for line in readlines(f)
        lines = split(line, "\t")
        if lines[7] == "scientific name"
            taxid = parse(Int, lines[1])
            name = lines[3]
            namaes[taxid] = name
        end
    end
    close(f)
    return namaes
end


function DB(db_path::String, nodes_dmp::String, names_dmp::String)
    @assert ispath(db_path)

    nodes_dmp_path = joinpath(db_path, nodes_dmp)
    names_dmp_path = joinpath(db_path, names_dmp)

    return DB(nodes_dmp_path, names_dmp_path)
end

struct Taxon
    taxid::Int
    name::String
    rank::Symbol
    db::DB
end

Base.show(io::IO, taxon::Taxon) = print(io, "Taxon($(taxon.taxid), \"$(taxon.name)\")")
AbstractTrees.printnode(io::IO, taxon::Taxon) = print(io, taxon)

function Taxon(taxid::Int, db::DB)
    name = db.names[taxid]
    rank = get(db.ranks, taxid, Symbol("norank"))
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

struct Lineage <: AbstractVector{Taxon} 
    line::Vector{Taxon}
end

function Lineage(taxon::Taxon)
    line = Taxon[]
    current_taxon = taxon
    push!(line,current_taxon)
    while parent(current_taxon) !== nothing
        current_taxon = parent(current_taxon)
        push!(line, current_taxon)
    end
<<<<<<< HEAD
    return Lineage(line)
=======
    return _lineage
end  

function lineage(taxon::Taxon, ranks::Vector{Symbol})
   _lineage = lineage(taxon)
   return filter(x -> rank(x) in ranks, _lineage)
>>>>>>> 40985771a297f6076277cfd72ee49cf4d3524345
end

Base.size(l::Lineage) = size(l.line)
Base.getindex(l::Lineage, i::Int) = getindex(l.line, i)

function Base.getindex(l::Lineage, s::Symbol)

function lca(taxa::Vector{Taxon})
    lineages = [Lineage(taxon) for taxon in taxa]
    overlap = intersect(lineages...)
    for taxon in lineages[1]
        if taxon in overlap
            return taxon
        end
    end
    return nothing
end

function lca(taxa::Taxon...)
    l = getindex(Taxon, taxa...)
    return lca(l)
end