struct Lineage <: AbstractVector{AbstractTaxon}
    line::Vector{AbstractTaxon}
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
    idx = Dict(key => value - range.start + 1 for (key, value) in l.index if value in range)
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
    line = AbstractTaxon[]
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
    line = AbstractTaxon[]
    idx = Dict{Symbol,Int}()
    count = 0
    for rank in ranks
        count += 1
        taxon = try
            getindex(l, rank)
        catch
            filtered_line = filter(x -> typeof(x) == Taxon, line)
            edge = try
                filtered_line[end]
            catch #if there is no taxon corresponding to the ranks
                l[end]
            end
            UnclassifiedTaxon(rank, edge)
        end
        push!(line, taxon)
        idx[rank]=count
    end
    return Lineage(line, idx)
end

function print_lineage(io::IO, lineage::Lineage; delim::AbstractString=";", fill::Bool=false)
    if !fill
        lineage = filter(x -> typeof(x) == Taxon, lineage)
    end
    if isempty(lineage)
        return nothing
    end
    name_line = map(x -> x.name, lineage)
    l = foldl((x,y) -> x * delim * y, name_line)
    print(io, l)
    return nothing
end

print_lineage(lineage::Lineage; kwargs...) = print_lineage(stdout::IO, lineage; kwargs...)

isdescendant(descendant::Taxon, ancestor::Taxon) = ancestor in Lineage(descendant)
isancestor(ancestor::Taxon, descendant::Taxon) = isdescendant(descendant, ancestor)