function lca(taxa::Vector{Taxon})
    if isempty(taxa)
        return nothing
    end
    lineages = [Lineage(taxon) for taxon in taxa]
    overlap = intersect(lineages...)
    return overlap[end]
end

function lca(taxa::Taxon...)
    l = getindex(Taxon, taxa...)
    return lca(l)
end