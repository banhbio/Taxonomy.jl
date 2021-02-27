struct DB
    nodes_dmp::String
    names_dmp::String
    parents::Dict{Int,Int}
    ranks::Dict{Int,String}
    names::Dict{Int,String}
end

function DB(nodes_dmp::String, names_dmp::String)
    function _importnodes(nodes_dmp_path::String)
        parents = Dict{Int,Int}()
        ranks = Dict{Int,String}()

        f = open(nodes_dmp_path, "r")
        for line in readlines(f)
            lines = split(line, "\t")
            taxid = parse(Int, lines[1])
            parent = parse(Int, lines[3])
            rank = lines[5]

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

    @assert isfile(nodes_dmp)
    @assert isfile(names_dmp)
    nodes_dmp_abspath = abspath(nodes_dmp)
    names_dmp_abspath = abspath(names_dmp)

    parents, ranks = _importnodes(nodes_dmp_abspath)
    namaes = _importnames(names_dmp_abspath)

    return DB(nodes_dmp_abspath, names_dmp_abspath, parents, ranks, namaes)
end

function DB(db_path::String, nodes_dmp::String, names_dmp::String)
    @assert ispath(db_path)
    db_abspath = abspath(db_path)

    nodes_dmp_abspath = joinpath(db_abspath, nodes_dmp)
    names_dmp_abspath = joinpath(db_abspath, names_dmp)

    return DB(nodes_dmp_abspath, names_dmp_abspath)
end

struct Taxon
    taxid::Int
    name::String
    db::DB
end

Base.show(io::IO, taxon::Taxon) = print(io, "Taxon($(taxon.taxid), \"$(taxon.name)\")")
AbstractTrees.printnode(io::IO, taxon::Taxon) = print(io, taxon)

function Taxon(taxid::Int, db::DB)
    name = taxDB.names[taxid]
    return Taxon(taxid, name, db)
end

function Taxon(name::String, db::DB)
    taxid_canditates = findall(isequal(name), taxDB.names)
    length(taxid_canditates) == 0 && error("There is no candidates for ",name)
    length(taxid_canditates) == 1 && return Taxon(taxid_canditates[1],db)
    length(taxid_canditates) > 1 && error("There are several candidates for ",name)
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
    taxon.db.ranks[taxon.taxid]
end

function lineage(taxon::Taxon)
    lineage = Taxon[]
    current_taxon = taxon
    push!(lineage,current_taxon)
    while parent(current_taxon) !== nothing
        current_taxon = parent(current_taxon)
        push!(lineage, current_taxon)
    end
    return lineage
end  

function lca(taxa::Vector{Taxon})
    lineages = [lineage(taxon) for taxon in taxa]
    overlap = intersect(lineages...)
    for taxon in lineages[1]
        if taxon in overlap
            return taxon
        end
    end
    return nothing
end