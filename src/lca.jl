"""
    lca(taxa::Vector{Taxon})
    lca(taxa::Taxon...)

Return the `Taxon` object that is the lowest common ancestor of the given set of `Taxon`s.
At least one `Taxon` is required.
"""
function lca(taxa::Vector{Taxon})
    isempty(taxa) && throw(ArgumentError("lca requires at least one Taxon"))
    length(taxa) == 1 && return only(taxa)
    lineages = [Lineage(taxon) for taxon in taxa]
    overlap = intersect(lineages...)
    return overlap[end]
end

function lca(taxa::Taxon...)
    l = getindex(Taxon, taxa...)
    return lca(l)
end
