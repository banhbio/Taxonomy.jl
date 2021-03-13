const CanonicalRank = [:superkingdom,
                       :phylum,
                       :class,
                       :order,
                       :family,
                       :genus,
                       :species,
                       :subspecies,
                       :strain
                       ]

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

    parents, ranks = importnodes(nodes_dmp)
    namaes = importnames(names_dmp)

    return DB(nodes_dmp, names_dmp, parents, ranks, namaes)
end

function importnodes(nodes_dmp_path::String)
    parents = Dict{Int,Int}()
    ranks = Dict{Int,Symbol}()

    f = open(nodes_dmp_path, "r")
    for line in eachline(f)
        cols = split(line, "\t")
        taxid = parse(Int, cols[1])
        parent = parse(Int, cols[3])
        rank = Symbol(cols[5])

        parent != taxid || continue

        parents[taxid] = parent
        ranks[taxid] = rank
    end
    close(f)
    return parents, ranks
end


function importnames(names_dmp_path::String)
    namaes = Dict{Int,String}()
    f = open(names_dmp_path, "r")
    for line in eachline(f)
        cols = split(line, "\t")
        if cols[7] == "scientific name"
            taxid = parse(Int, cols[1])
            name = cols[3]
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

struct Lineage <: AbstractVector{Union{Taxon,Nothing}}
    line::Vector{Union{Taxon,Nothing}}
    index::Dict{Symbol,Int}
end

function Lineage(taxon::Taxon)
    line = Taxon[]
    current_taxon = taxon
    push!(line,current_taxon)
    while parent(current_taxon) !== nothing
        current_taxon = parent(current_taxon)
        push!(line, current_taxon)
    end
    reverse!(line)
    rankline = map(rank, line)
    index = Dict{Symbol,Int}()
    for crank in CanonicalRank
        position = findfirst(x -> x == crank, rankline)
        position === nothing ? continue : index[crank] = position
    end
    return Lineage(line,index)
end

Base.size(l::Lineage) = size(l.line)
Base.getindex(l::Lineage, i::Int) = getindex(l.line, i)
Base.lastindex(l::Lineage) = lastindex(l.line)

Base.getindex(l::Lineage, s::Symbol) = l.line[l.index[s]]


function Base.getindex(l::Lineage, range::UnitRange{Int})
    line = l.line[range]
    idx = filter(x -> last(x) in range, l.index)
    return Lineage(line,idx)
end

function Base.getindex(l::Lineage, idx::All)
    if isempty(idx.cols)
        return l
    else
        return getindex(l, Cols(idx.cols))
    end
end

function Base.getindex(l::Lineage, idx::Cols)
    line = Union{Taxon,Nothing}[]
    index = Dict{Symbol,Int}()
    count = 0
    for rank in idx.cols
        count += 1
        taxon = getindex(l, rank)
        push!(line, taxon)
        index[rank]=count
    end
    return Lineage(line,index)
end

Base.getindex(l::Lineage, idx::Between{Int,Int}) = l[idx.first:idx.last]
Base.getindex(l::Lineage, idx::Between{Symbol,Int}) = getindex(l, Between(l.index[idx.first], idx.last))
Base.getindex(l::Lineage, idx::Between{Int,Symbol}) = getindex(l, Between(idx.first, l.index[idx.last]))
Base.getindex(l::Lineage, idx::Between{Symbol,Symbol}) = getindex(l, Between(l.index[idx.first], l.index[idx.last]))
Base.getindex(l::Lineage, idx::From{Int}) = l[idx.first:end]
Base.getindex(l::Lineage, idx::From{Symbol}) = getindex(l, From(l.index[idx.first]))
Base.getindex(l::Lineage, idx::Until{Int}) = l[1:idx.last]
Base.getindex(l::Lineage, idx::Until{Symbol}) = getindex(l, Until(l.index[idx.last]))

function Base.get(l::Lineage, idx::Union{Int,Symbol}, default::Any)
    try
        return getindex(l,idx)
    catch
        return default
    end
end

function reformat(l::Lineage, ranks::Vector{Symbol})
    line = Union{Taxon,Nothing}[]
    idx = Dict{Symbol,Int}()
    count = 0
    for rank in ranks
        count += 1
        taxon = get(l, rank, nothing)
        push!(line, taxon)
        idx[rank]=count
    end
    return Lineage(line, idx)
end

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