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