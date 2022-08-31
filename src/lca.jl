"""
    lca(taxa::Vector{Taxon})
    lca(taxa::Taxon...)

Return the `Taxon` object that is the lowest common ancestor of the given set of `Taxon`s
"""
function lca(taxa::Vector{Taxon})
    lineages = [Lineage(taxon) for taxon in taxa]
    overlap = intersect(lineages...)
    return overlap[end]
end

function lca(taxa::Taxon...)
    l = getindex(Taxon, taxa...)
    return lca(l)
end