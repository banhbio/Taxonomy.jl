function lca(taxa::Vector{Taxon})
    lineages = [Lineage(taxon) for taxon in taxa]
    overlap = intersect(lineages...)
    for taxon in reverse(lineages[1])
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