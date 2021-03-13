function lca(taxa::Vector{Taxon})
    lineages = [Lineage(taxon) for taxon in taxa]
    overlap = intersect(lineages...)
    try
        return overlap[end]
    catch
        return nothing
    end
end

function lca(taxa::Taxon...)
    l = getindex(Taxon, taxa...)
    return lca(l)
end